-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.ui's own dialog for splitting a stack and for buying an amount, after the accepted draft manual/view/vga-stacksplit.html (K0757): wherever the game opens its split frame - a shift-click on a stack in the bags, on a ware at a merchant - the game's frame is put away at once and this one opens at the same place, always in front: LibVGA's dialog headed »Stapel teilen« or »Menge kaufen«, the item with its picture, its quality's rim and its count, its name in its quality's colour, cut short with »…« where it is too long, beneath it how many are in the stack or how many one purchase gives at what price; LibVGA's stepper for the amount, in steps of one or of the merchant's bundle, from one bundle up to what the game allows; digits typed set it, Backspace takes one back, Enter confirms, Escape cancels; when buying, the price of the chosen amount in our coins; »Abbrechen« and the gold »Teilen« or »Kaufen«, which hand the amount to the game's own SplitStack of the clicked button. The dialog never grows with its content.

-- {K0757}

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
    slot.icon:ClearAllPoints()
    slot.icon:SetPoint("TOPLEFT", library.read_draft_size(4), -library.read_draft_size(4))
    slot.icon:SetPoint("BOTTOMRIGHT", -library.read_draft_size(4), library.read_draft_size(4))
    slot.count:SetFontObject(library.read_font("figure"))
    slot.count:SetText(item.count or item.bundle or "")
    slot.count:ClearAllPoints()
    slot.count:SetPoint("BOTTOMRIGHT", -library.read_draft_size(4), library.read_draft_size(2))
end

local function read_meta(item)
    local texts = library.texts
    if not dialog.buying then return string.format(texts.split_in_stack, item.count or dialog.most) end
    return string.format(texts.buy_per_purchase, dialog.bundle, library.read_money_text(item.price or 0))
end

local function update_row(row, label, control, top, width)
    local pad = library.read_draft_size(2)
    row.line:ClearAllPoints()
    row.line:SetPoint("TOPLEFT", dialog.body, "TOPLEFT", library.read_draft_size(14), -top)
    row.line:SetSize(width, 1)
    row.label:SetFontObject(library.read_font("small"))
    row.label:SetText(label)
    row.label:ClearAllPoints()
    row.label:SetPoint("LEFT", row.line, "TOPLEFT", pad, -library.read_draft_size(15))
    control:ClearAllPoints()
    control:SetPoint("RIGHT", row.line, "TOPRIGHT", -pad, -library.read_draft_size(15))
    return top + library.read_draft_size(30)
end

local function update_layout()
    local texts, item = library.texts, dialog.item
    local width, pad = library.read_draft_size(WIDTH), library.read_draft_size(14)
    local inner = width - 2 * library.read_size(-4) - 2 * pad
    library.update_dialog(dialog)
    dialog.title:SetText(dialog.buying and texts.buy_title or texts.split_title)
    update_slot(item)
    dialog.slot:ClearAllPoints()
    dialog.slot:SetPoint("TOPLEFT", dialog.body, "TOPLEFT", pad, -pad)
    dialog.name:SetFontObject(library.read_font("bold"))
    dialog.name:SetText(read_name(item))
    dialog.name:SetTextColor(unpack(read_quality_colour(item.quality)))
    dialog.name:SetWidth(inner - library.read_draft_size(SLOT + 10))
    dialog.name:ClearAllPoints()
    dialog.name:SetPoint("BOTTOMLEFT", dialog.slot, "RIGHT", library.read_draft_size(10), 1)
    dialog.meta:SetFontObject(library.read_font("small"))
    dialog.meta:SetText(read_meta(item))
    dialog.meta:SetWidth(inner - library.read_draft_size(SLOT + 10))
    dialog.meta:ClearAllPoints()
    dialog.meta:SetPoint("TOPLEFT", dialog.slot, "RIGHT", library.read_draft_size(10), -1)
    local top = pad + library.read_draft_size(SLOT) + pad
    top = update_row(dialog.amount_row, dialog.buying and texts.split_amount or texts.split_take, dialog.stepper, top, inner)
    dialog.price_row.line:SetShown(dialog.buying)
    dialog.price_row.label:SetShown(dialog.buying)
    dialog.price:SetShown(dialog.buying)
    if dialog.buying then top = update_row(dialog.price_row, texts.price, dialog.price, top, inner) end
    dialog.confirm.words = dialog.buying and texts.buy or texts.split_do
    dialog.confirm.text:SetText(dialog.confirm.words)
    library.update_button(dialog.confirm)
    library.update_button(dialog.cancel)
    dialog.confirm:ClearAllPoints()
    dialog.confirm:SetPoint("TOPRIGHT", dialog.body, "TOPRIGHT", -pad, -(top + library.read_draft_size(6)))
    dialog.cancel:ClearAllPoints()
    dialog.cancel:SetPoint("RIGHT", dialog.confirm, "LEFT", -library.read_draft_size(8), 0)
    local head = library.read_size(4) + library.read_size(-4)
    dialog:SetSize(width, head + top + library.read_draft_size(6) + library.read_size(2) + pad + library.read_size(-4))
end

local function create_row()
    return { line = dialog.body:CreateTexture(nil, "ARTWORK"), label = library.create_text(dialog.body, "small", colours.label) }
end

local function create_dialog()
    dialog = library.create_dialog("VGAStackSplit", "")
    dialog.slot = CreateFrame("Frame", nil, dialog.body)
    dialog.slot.ground = library.create_surface(dialog.slot, "BACKGROUND", 0)
    dialog.slot.icon = dialog.slot:CreateTexture(nil, "ARTWORK")
    dialog.slot.edge = library.create_ring(dialog.slot, "OVERLAY", 5, nil, true)
    dialog.slot.count = library.create_text(dialog.slot, "figure", colours.ink)
    dialog.name = library.create_text(dialog.body, "bold", colours.ink)
    dialog.name:SetWordWrap(false)
    dialog.name:SetJustifyH("LEFT")
    dialog.meta = library.create_text(dialog.body, "small", colours.quiet)
    dialog.meta:SetWordWrap(false)
    dialog.meta:SetJustifyH("LEFT")
    dialog.amount_row, dialog.price_row = create_row(), create_row()
    for _, row in ipairs({ dialog.amount_row, dialog.price_row }) do row.line:SetColorTexture(colours.edge[1], colours.edge[2], colours.edge[3], 1) end
    dialog.stepper = library.create_stepper(dialog.body, render_step)
    dialog.price = library.create_money(dialog.body, colours.ink)
    dialog.price.kind = "small"
    dialog.cancel = library.create_button(dialog.body, library.texts.cancel, "plain", render_cancel)
    dialog.confirm = library.create_button(dialog.body, library.texts.split_do, "gold", render_confirm)
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
