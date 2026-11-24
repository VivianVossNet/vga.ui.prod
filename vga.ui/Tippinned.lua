-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: the blue badge »Angepinnt« in an item's tooltip, as the accepted draft draws place C (manual/view/vga-tooltip-pinned.html, K0900): for every item that stands fixed at the end of the bags - the hearthstone, the tools, the player's own pins (vga.check_bag_pinned, K0898) - LibVGA's chip as a label without a sign, blue, at the right beneath the game's lines and a hairline, above vga.auctions' accordions, a layer of LibVGA's tooltip foot (library.update_tooltip_foot); in every tooltip that shows an item, the fixed window excepted, which carries its own accordions. Beneath everything, the foot's lowest layer, a small quiet line tells how to pin, for an item in the bags alone, where the click works: »Alt + Rechtsklick: anpinnen«, »… lösen« for the player's own pins, »Immer angepinnt« for the hearthstone and the tools, which cannot be loosened (K0902).

-- {K0904} {K0902} {K0900} {K0898} {K0888} {K0780}

local _, vga = ...
local library = LibVGA
local INSET = 10
local GAP = 6
local FOOT_RANK, HINT_RANK = 1, 3
local badges = setmetatable({}, { __mode = "k" })
local hints = setmetatable({}, { __mode = "k" })

local function read_width(tip, content)
    return math.max(tip:GetWidth(), content + 2 * library.read_draft_size(INSET))
end

local function create_badge(tip)
    local frame = CreateFrame("Frame", nil, tip)
    local badge = { frame = frame, chip = library.create_chip(frame) }
    badge.grid = library.create_grid(frame, { columns = { "rest" }, padding = { GAP, INSET, GAP, INSET }, row = 0, x = "right", lines = "all" })
    tip:HookScript("OnTooltipCleared", function() frame:Hide() end)
    return badge
end

local function create_hint(tip)
    local frame = CreateFrame("Frame", nil, tip)
    local hint = { frame = frame, text = library.create_text(frame, "small", library.colours.quiet) }
    hint.grid = library.create_grid(frame, { columns = { "rest" }, padding = { 0, INSET, GAP, INSET }, row = 0 })
    tip:HookScript("OnTooltipCleared", function() frame:Hide() end)
    return hint
end

local function check_bag_owner(tip)
    local owner = tip.GetOwner and tip:GetOwner()
    local holder = owner and owner.GetParent and owner:GetParent()
    local bag = holder and holder.slots and holder:GetID()
    return bag ~= nil and bag >= 0 and bag <= vga.read_final_bag()
end

local function read_hint(item)
    local texts = library.texts
    if vga.check_bag_pin_fixed(item) then return texts.tip_pinned_fixed end
    return vga.check_bag_pinned({ itemID = item }) and texts.tip_unpin_hint or texts.tip_pin_hint
end

local function update_hint_laid(tip)
    local hint = hints[tip]
    local _, height = library.update_grid(hint.grid, { { hint.text } }, read_width(tip, library.read_string_width(hint.text)))
    return height or 0
end

local function update_hint(tip, item)
    if not check_bag_owner(tip) then return end
    hints[tip] = hints[tip] or create_hint(tip)
    local hint = hints[tip]
    hint.text:SetText(read_hint(item))
    hint.frame:Show()
    library.update_tooltip_foot(tip, HINT_RANK, update_hint_laid(tip), update_hint_laid, hint.frame)
end

function vga.read_tip_hint(tip)
    return hints[tip]
end

local function update_badge_laid(tip)
    local badge = badges[tip]
    local _, height = library.update_grid(badge.grid, { { badge.chip } }, read_width(tip, badge.chip:GetWidth()))
    return height or 0
end

local function update_badge(tip, item)
    if not vga.check_bag_pinned({ itemID = item }) then return end
    badges[tip] = badges[tip] or create_badge(tip)
    local badge = badges[tip]
    library.update_chip(badge.chip, "blue", nil, library.texts.tip_pinned)
    badge.frame:Show()
    library.update_tooltip_foot(tip, FOOT_RANK, update_badge_laid(tip), update_badge_laid, badge.frame)
end

function vga.read_tip_badge(tip)
    return badges[tip]
end

local function update_item_tip(tip, data)
    local item = data and data.id
    if not (item and tip.GetPadding and tip.SetPadding) or tip.vga_window then return end
    update_badge(tip, item)
    update_hint(tip, item)
end

if TooltipDataProcessor and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tip, data) library.update_safely("pinned tooltip", update_item_tip, tip, data) end)
end
