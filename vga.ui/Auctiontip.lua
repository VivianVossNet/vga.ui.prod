-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.auctions' line beneath the game's item tooltip as the accepted draft draws it (manual/view/vga-tooltip.html, K0604, K0626, K0633): LibVGA's accordion »AUKTIONEN«, closed, the market value at its right in our coins, in a block of its own at the tooltip's foot, below every line of the game's - the room kept by the tooltip's bottom padding, added to whatever padding the game itself sets and laid again whenever the game reckons its padding anew or the tooltip shows, given back when it is cleared - so no line of the game's, as the sell price, ever lies under it and no room stays empty (K0744); the same way a head at the top, by the top padding, for the comparison's verdict (Tipcompare.lua, K0754); nothing where the auction house was never read for the item. Beneath it, for a player who knows Enchanting (K0636), LibVGA's accordion »ENTZAUBERN« with the expected value of disenchanting the item (Disenchant.lua, K0752), »–« where a material has no market value, nothing for an item that cannot be disenchanted; each accordion as high as one, the foot as high as all; the tooltip at least as wide as the widest word and its figure need beside each other, so a short item's tooltip never lets them run into each other (K0752). In the plain tooltip neither carries a chevron, since it cannot be opened there (K0752). Opening them - the graph, market value, lowest now, thirty days, basis; the materials with amount, chance and value - belongs to the fixed window of K0604 (Tipwindow.lua, K0753), whose lines this foot leaves alone.

-- {K0752} {K0604} {K0626} {K0633} {K0744}

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
    if tip.vga_least then tip:SetMinimumWidth(0) end
    tip.vga_least = nil
    update_foot_cleared(tip)
end

function vga.create_tip_room(tip)
    if kept[tip] then return kept[tip] end
    kept[tip] = { used = 0 }
    tip:HookScript("OnTooltipCleared", update_cleared)
    tip:HookScript("OnShow", update_foot_safely)
    return kept[tip]
end

local function read_piece(tip, create)
    local pieces = vga.create_tip_room(tip)
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

local function check_kept(value, padded)
    return padded ~= nil and math.abs(value - padded) < 0.5
end

local function update_labels_placed(tip, height)
    local pieces = kept[tip] or { used = 0 }
    local step = library.read_accordion_height()
    for index = 1, pieces.used do
        local label = pieces[index]
        local rise = BOTTOM + height + (pieces.used - index) * step
        label:ClearAllPoints()
        label:SetPoint("BOTTOMLEFT", tip, "BOTTOMLEFT", INSET, rise)
        label:SetPoint("BOTTOMRIGHT", tip, "BOTTOMRIGHT", -INSET, rise)
    end
end

local function update_foot_room(tip)
    local foot, head = tip.vga_foot or 0, tip.vga_head or 0
    if foot == 0 and head == 0 then return end
    local width, height, left, top = tip:GetPadding()
    left, top = left or 0, top or 0
    if check_kept(height, tip.vga_padded) and check_kept(top, tip.vga_topped) then return end
    if not check_kept(height, tip.vga_padded) then tip.vga_base = height end
    if not check_kept(top, tip.vga_topped) then tip.vga_top_base = top end
    tip.vga_padded, tip.vga_topped = tip.vga_base + foot, tip.vga_top_base + head
    tip:SetPadding(width, tip.vga_padded, left, tip.vga_topped)
    update_labels_placed(tip, tip.vga_base)
end

vga.update_tip_room = update_foot_room

function update_foot_cleared(tip)
    if not (tip.vga_foot or tip.vga_head) then return end
    local width, height, left, top = tip:GetPadding()
    if check_kept(height, tip.vga_padded) or check_kept(top or 0, tip.vga_topped) then tip:SetPadding(width, tip.vga_base or 0, left or 0, tip.vga_top_base or 0) end
    tip.vga_foot, tip.vga_padded, tip.vga_base, tip.vga_head, tip.vga_topped, tip.vga_top_base = nil, nil, nil, nil, nil, nil
end

function update_foot_safely(tip)
    library.update_safely("auctions tooltip foot", update_foot_room, tip)
end

local function update_least_width(tip)
    if not tip.SetMinimumWidth then return end
    local pieces, pad, widest = kept[tip], library.read_draft_size(12), 0
    for index = 1, pieces.used do
        local label = pieces[index]
        local figure = label.money:IsShown() and (label.money.vga_width or 0) or library.read_string_width(label.count)
        widest = math.max(widest, library.read_string_width(label.name) + figure)
    end
    tip:SetMinimumWidth(math.ceil(widest + 3 * pad + 2 * INSET))
    tip.vga_least = true
end

local function write_accordions(tip, rows)
    for _, row in ipairs(rows) do
        local label = read_piece(tip, create_label)
        library.update_accordion(label, library.read_capitals(row.word), nil, 1, row.copper == nil and "–" or nil, row.copper)
    end
    tip.vga_foot, tip.vga_padded = #rows * library.read_accordion_height(), nil
    update_least_width(tip)
    update_foot_room(tip)
end

local function read_rounded(copper)
    return copper and math.floor(copper + 0.5)
end

local function read_tip_rows(item, link)
    local rows = {}
    local market = vga.read_market(item)
    if market then rows[#rows + 1] = { word = library.texts.auctions, copper = read_rounded(market) } end
    local found = vga.check_enchanter() and vga.read_disenchant(link)
    if found then rows[#rows + 1] = { word = library.texts.disenchant, copper = read_rounded(vga.read_disenchant_value(found)) } end
    return rows
end

local function update_item_tip(tip, data)
    local item = data and data.id
    if not (item and tip.GetPadding and tip.SetPadding) or tip.vga_window then return end
    local rows = read_tip_rows(item, data.hyperlink or item)
    if #rows > 0 then write_accordions(tip, rows) end
end

function vga.read_tip_label(tip, index)
    return kept[tip] and kept[tip][index or 1]
end

local function update_item_tip_safely(tip, data)
    library.update_safely("auctions tooltip", update_item_tip, tip, data)
end

if hooksecurefunc and GameTooltip_CalculatePadding then hooksecurefunc("GameTooltip_CalculatePadding", update_foot_safely) end

if TooltipDataProcessor and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, update_item_tip_safely)
end
