-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.ui's own dialog for splitting a stack and for buying an amount, after the accepted draft manual/view/vga-stacksplit.html (K0757): wherever the game opens its split frame - a shift-click on a stack in the bags, on a ware at a merchant - the game's frame is put away at once and this one opens at the same place, always in front: LibVGA's dialog headed »Stapel teilen« or »Menge kaufen«, the item with its picture, its quality's rim and its count, its name in its quality's colour, cut short with »…« where it is too long, beneath it how many are in the stack or how many one purchase gives at what price; LibVGA's stepper for the amount, in steps of one or of the merchant's bundle, from one bundle up to what the game allows; digits typed set it, Backspace takes one back, Enter confirms, Escape cancels; when buying, the price of the chosen amount in our coins; »Abbrechen« and the gold »Teilen« or »Kaufen« in the foot LibVGA's dialog owns, which hand the amount to the game's own SplitStack of the clicked button; the rows laid by LibVGA's grid, each parted by its hairline with eight draft pixels above and below (K0783). The dialog never grows with its content.

-- {K0802} {K0793} {K0789} {K0783} {K0757}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local WIDTH = 300
local SLOT = 40
local SLOT_GROUND = { 0.071, 0.075, 0.09 }
local SLOT_EDGE = { 0.29, 0.31, 0.341 }
local UNCOMMON = 2
local dialog

local function read_bag_item(owner)
    local bag = owner.GetBagID and owner:GetBagID() or (owner:GetParent() and owner:GetParent():GetID())
    local found = bag and C_Container.GetContainerItemInfo(bag, owner:GetID())
    if not found then return {} end
    return { icon = found.iconFileID, count = found.stackCount, quality = found.quality, link = found.hyperlink }
end

local function read_merchant_ware(index)
    local found = C_MerchantFrame and C_MerchantFrame.GetItemInfo and C_MerchantFrame.GetItemInfo(index)
    if type(found) == "table" then return found.name, found.texture, found.price, found.stackCount end
    if GetMerchantItemInfo then return GetMerchantItemInfo(index) end
end

local function read_merchant_item(owner)
    local index = owner:GetID()
    local name, icon, price, bundle = read_merchant_ware(index)
    local link = GetMerchantItemLink and GetMerchantItemLink(index)
    local quality = link and select(3, C_Item.GetItemInfo(link))
    return { name = type(name) == "string" and name or nil, icon = icon, price = type(price) == "number" and price or owner.price, bundle = bundle, quality = quality, link = type(link) == "string" and link or nil }
end

local function read_name(item)
    if item.name then return item.name end
    return item.link and C_Item.GetItemInfo(item.link) or ""
end

local function read_quality_colour(quality)
    if quality and quality >= UNCOMMON then return { C_Item.GetItemQualityColor(quality) } end
    return colours.ink
end

local function read_clamped(amount)
    local bundle = dialog.bundle
    local most = math.max(bundle, math.floor(dialog.most / bundle) * bundle)
    return math.max(bundle, math.min(most, math.floor(amount / bundle) * bundle))
end

local function update_amount(amount)
    dialog.amount = read_clamped(amount)
    library.update_stepper(dialog.stepper, dialog.amount)
    if not dialog.buying then return end
    library.update_money(dialog.price, math.floor((dialog.item.price or 0) * dialog.amount / dialog.bundle + 0.5))
end

local function render_step(_, step)
    dialog.typing = nil
    update_amount(dialog.amount + step * dialog.bundle)
end

local function render_confirm()
    local owner, amount = dialog.owner, dialog.amount
    dialog:Hide()
    if owner and owner.SplitStack then owner.SplitStack(owner, amount) end
end

local function render_cancel()
    dialog:Hide()
end

local function update_typed(key)
    local digit = tonumber((key:gsub("^NUMPAD", "")))
    if not digit then return false end
    local before = dialog.typing or 0
    dialog.typing = before * 10 + digit
    update_amount(dialog.typing)
    return true
end

local function update_key(self, key)
    local handled = true
    if key == "ENTER" or key == "NUMPADENTER" then
        render_confirm()
    elseif key == "ESCAPE" then
        render_cancel()
    elseif key == "BACKSPACE" then
        dialog.typing = math.floor((dialog.typing or dialog.amount) / 10)
        update_amount(dialog.typing)
    else
        handled = update_typed(key)
    end
    if self.SetPropagateKeyboardInput and not InCombatLockdown() then self:SetPropagateKeyboardInput(not handled) end
end

local function update_slot(item)
    local slot, size = dialog.slot, library.read_draft_size(SLOT)
    local radius = library.read_draft_size(6)
    slot:SetSize(size, size)
    library.update_surface(slot.ground, 0, radius, SLOT_GROUND, SLOT_GROUND)
    local edge = item.quality and item.quality >= UNCOMMON and read_quality_colour(item.quality) or SLOT_EDGE
    library.update_ring(slot.edge, library.read_draft_size(3), edge, 1)
    slot.icon:SetTexture(item.icon)
    slot.count:SetFontObject(library.read_font("figures_figure"))
    slot.count:SetText(item.count or item.bundle or "")
    library.update_cell_inside(slot, slot.icon, slot.count, library.read_draft_size(4))
end

local function read_meta(item)
    local texts = library.texts
    if not dialog.buying then return string.format(texts.split_in_stack, item.count or dialog.most) end
    return string.format(texts.buy_per_purchase, dialog.bundle, library.read_money_text(item.price or 0))
end

local function read_rows()
    local rows = { { dialog.amount_label, dialog.stepper } }
    if dialog.buying then rows[2] = { dialog.price_label, dialog.price } end
    return rows
end

local function update_item(item, width)
    update_slot(item)
    dialog.name:SetFontObject(library.read_font("bold"))
    dialog.name:SetText(read_name(item))
    dialog.name:SetTextColor(unpack(library.read_quality_colour(item.quality)))
    dialog.meta:SetFontObject(library.read_font("small"))
    dialog.meta:SetText(read_meta(item))
    library.update_grid(dialog.item_grid, { { dialog.slot, { stack = { dialog.name, dialog.meta }, gap = { pixels = 2 } } } }, width)
end

local function update_layout()
    local texts, width = library.texts, library.read_draft_size(WIDTH)
    library.update_dialog(dialog)
    dialog.title:SetText(dialog.buying and texts.buy_title or texts.split_title)
    update_item(dialog.item, width - 2 * library.read_size(-4))
    dialog.amount_label:SetText(dialog.buying and texts.split_amount or texts.split_take)
    dialog.price_label:SetText(texts.price)
    dialog.price_label:SetShown(dialog.buying)
    dialog.price:SetShown(dialog.buying)
    library.update_stepper(dialog.stepper, dialog.amount)
    dialog.confirm.words = dialog.buying and texts.buy or texts.split_do
    dialog.confirm.text:SetText(dialog.confirm.words)
    library.update_dialog(dialog)
    local _, height = library.update_grid(dialog.grid, read_rows(), width - 2 * library.read_size(-4))
    dialog:SetSize(width, library.read_dialog_frame_height(dialog) + height)
end

local function create_dialog()
    local texts = library.texts
    dialog = library.create_dialog("VGAStackSplit", "", { buttons = { { texts.cancel, "plain", render_cancel }, { texts.split_do, "gold", render_confirm } } })
    dialog.cancel, dialog.confirm = dialog.foot.buttons[1], dialog.foot.buttons[2]
    dialog.slot = CreateFrame("Frame", nil, dialog.body)
    library.create_cell_dress(dialog.slot, { ground = 0, edge = 5 })
    dialog.slot.ground = dialog.slot.vga_ground
    dialog.slot.icon = dialog.slot:CreateTexture(nil, "ARTWORK")
    dialog.slot.edge = dialog.slot.vga_edge
    dialog.slot.count = library.create_text(dialog.slot, "figures_figure", colours.ink)
    dialog.name = library.create_text(dialog.body, "bold", colours.ink)
    dialog.meta = library.create_text(dialog.body, "small", colours.quiet)
    for _, text in ipairs({ dialog.name, dialog.meta }) do
        text:SetWordWrap(false)
        text:SetJustifyH("LEFT")
    end
    dialog.amount_label = library.create_text(dialog.body, "small", colours.label)
    dialog.price_label = library.create_text(dialog.body, "small", colours.label)
    dialog.stepper = library.create_stepper(dialog.body, render_step)
    dialog.price = library.create_money(dialog.body, colours.ink)
    dialog.price.kind = "small"
    dialog.item_grid = library.create_grid(dialog.body, { columns = { SLOT, "rest" }, gap = 10, padding = { 14, 14, 0, 14 }, row = SLOT, y = { "top", "middle" }, cut = { [2] = true } })
    local top = 14 + SLOT + 6
    dialog.grid = library.create_grid(dialog.body, { columns = { "rest", "auto" }, gap = 10, padding = { top, 14, 6, 14 }, x = { "left", "right" }, lines = "all" })
    dialog:SetScript("OnKeyDown", function(self, key) library.update_safely("stack split key", update_key, self, key) end)
    dialog:Hide()
end

local function render_dialog(game, most, owner, anchor, anchor_to, bundle)
    if not (owner and most and most >= 1) then return end
    if not dialog then create_dialog() end
    game:Hide()
    dialog.owner, dialog.most, dialog.typing = owner, most, nil
    dialog.buying = owner.price ~= nil
    dialog.item = dialog.buying and read_merchant_item(owner) or read_bag_item(owner)
    dialog.bundle = math.max(1, bundle or 1)
    dialog.amount = dialog.bundle
    update_layout()
    update_amount(dialog.bundle)
    dialog:ClearAllPoints()
    dialog:SetPoint(anchor or "BOTTOMRIGHT", owner, anchor_to or "TOPRIGHT", 0, 0)
    dialog:EnableKeyboard(not InCombatLockdown())
    dialog:Show()
    dialog:Raise()
end

local function create_hook()
    if not (StackSplitFrame and StackSplitFrame.OpenStackSplitFrame) then return end
    hooksecurefunc(StackSplitFrame, "OpenStackSplitFrame", function(game, most, owner, anchor, anchor_to, bundle)
        library.update_safely("stack split", render_dialog, game, most, owner, anchor, anchor_to, bundle)
    end)
end

local function create_on_login()
    create_dialog()
    create_hook()
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function() library.update_safely("stack split login", create_on_login) end)
