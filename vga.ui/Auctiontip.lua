-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.auctions' line beneath the game's item tooltip as the accepted draft draws it (manual/view/vga-tooltip.html, K0604, K0626, K0633): LibVGA's accordion »AUKTIONEN«, closed, the market value at its right in our coins, in a block of its own at the tooltip's foot, below every line of the game's - the room kept by the tooltip's bottom padding, added to whatever padding the game itself sets and laid again whenever the game reckons its padding anew or the tooltip shows, given back when it is cleared - so no line of the game's, as the sell price, ever lies under it and no room stays empty (K0744); nothing where the auction house was never read for the item. Opening it - the graph, market value, lowest now, thirty days, basis - belongs to the fixed window of K0604; Entzaubern follows with its table.

-- {K0604} {K0626} {K0633} {K0744}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local INSET = 10
local BOTTOM = 10
local kept = {}

local update_foot_cleared, update_foot_safely

local function update_cleared(tip)
    for _, piece in ipairs(kept[tip] or {}) do piece:Hide() end
    if kept[tip] then kept[tip].used = 0 end
    update_foot_cleared(tip)
end

local function read_piece(tip, create)
    if not kept[tip] then
        kept[tip] = { used = 0 }
        tip:HookScript("OnTooltipCleared", update_cleared)
        tip:HookScript("OnShow", update_foot_safely)
    end
    local pieces = kept[tip]
    pieces.used = pieces.used + 1
    pieces[pieces.used] = pieces[pieces.used] or create(tip)
    pieces[pieces.used]:Show()
    return pieces[pieces.used]
end

local function create_label(tip)
    local label = library.create_accordion(tip)
    label:EnableMouse(false)
    return label
end

local function update_foot_room(tip)
    local foot = tip.vga_foot
    if not foot then return end
    local width, height = tip:GetPadding()
    if tip.vga_padded and math.abs(height - tip.vga_padded) < 0.5 then return end
    tip.vga_base = height
    tip.vga_padded = height + foot
    tip:SetPadding(width, tip.vga_padded)
    local label = kept[tip] and kept[tip][1]
    if not label then return end
    label:ClearAllPoints()
    label:SetPoint("BOTTOMLEFT", tip, "BOTTOMLEFT", INSET, BOTTOM + height)
    label:SetPoint("BOTTOMRIGHT", tip, "BOTTOMRIGHT", -INSET, BOTTOM + height)
end

function update_foot_cleared(tip)
    if not tip.vga_foot then return end
    local width, height = tip:GetPadding()
    if tip.vga_padded and math.abs(height - tip.vga_padded) < 0.5 then tip:SetPadding(width, tip.vga_base or 0) end
    tip.vga_foot, tip.vga_padded, tip.vga_base = nil, nil, nil
end

function update_foot_safely(tip)
    library.update_safely("auctions tooltip foot", update_foot_room, tip)
end

local function write_accordion(tip, word, copper)
    local label = read_piece(tip, create_label)
    library.update_accordion(label, library.read_capitals(word), false, 1, nil, copper)
    tip.vga_foot, tip.vga_padded = library.read_accordion_height(), nil
    update_foot_room(tip)
end

local function update_item_tip(tip, data)
    local item = data and data.id
    if not (item and tip.GetPadding and tip.SetPadding) then return end
    local market = vga.read_market(item)
    if not market then return end
    write_accordion(tip, library.texts.auctions, math.floor(market + 0.5))
end

function vga.read_tip_label(tip)
    return kept[tip] and kept[tip][1]
end

local function update_item_tip_safely(tip, data)
    library.update_safely("auctions tooltip", update_item_tip, tip, data)
end

if hooksecurefunc and GameTooltip_CalculatePadding then hooksecurefunc("GameTooltip_CalculatePadding", update_foot_safely) end

if TooltipDataProcessor and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, update_item_tip_safely)
end
