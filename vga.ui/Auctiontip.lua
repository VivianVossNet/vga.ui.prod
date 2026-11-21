-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.auctions' line beneath the game's item tooltip as the accepted draft draws it (manual/view/vga-tooltip.html, K0604, K0626, K0633): LibVGA's accordion »AUKTIONEN«, closed, the market value at its right in our coins, laid over a line the tooltip keeps free for it; nothing where the auction house was never read for the item. Opening it - the graph, market value, lowest now, thirty days, basis - belongs to the fixed window of K0604; Entzaubern follows with its table.

-- {K0604} {K0626} {K0633}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local SPACER = "Interface\\Common\\spacer"
local INSET = 10
local kept = {}

local function update_cleared(tip)
    for _, piece in ipairs(kept[tip] or {}) do piece:Hide() end
    if kept[tip] then kept[tip].used = 0 end
end

local function read_piece(tip, create)
    if not kept[tip] then
        kept[tip] = { used = 0 }
        tip:HookScript("OnTooltipCleared", update_cleared)
    end
    local pieces = kept[tip]
    pieces.used = pieces.used + 1
    pieces[pieces.used] = pieces[pieces.used] or create(tip)
    pieces[pieces.used]:Show()
    return pieces[pieces.used]
end

local function read_line_text(tip, side)
    return _G[tip:GetName() .. "Text" .. side .. tip:NumLines()]
end

local function create_label(tip)
    local label = library.create_accordion(tip)
    label:EnableMouse(false)
    return label
end

local function write_accordion(tip, word, copper)
    local height = library.read_accordion_height()
    tip:AddDoubleLine("|T" .. SPACER .. ":" .. height .. ":1|t", " ")
    local left, right = read_line_text(tip, "Left"), read_line_text(tip, "Right")
    if not (left and right) then return end
    local label = read_piece(tip, create_label)
    library.update_accordion(label, library.read_capitals(word), false, 1, nil, copper)
    label:ClearAllPoints()
    label:SetPoint("TOPLEFT", left, "TOPLEFT", -INSET, 0)
    label:SetPoint("BOTTOMRIGHT", right, "BOTTOMRIGHT", INSET, 0)
end

local function update_item_tip(tip, data)
    local item = data and data.id
    if not (item and tip.AddDoubleLine and tip.GetName and tip:GetName()) then return end
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

if TooltipDataProcessor and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, update_item_tip_safely)
end
