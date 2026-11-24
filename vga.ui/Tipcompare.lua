-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: the item tooltip's comparison with what is worn in the item's place, as the accepted draft draws form B (manual/view/vga-tooltip.html, K0605 to K0607): one verdict on top, in a head of its own whose room LibVGA's tooltip block keeps by moving the game's first line down (K0780) - Besser in green, Schlechter in red, Gemischt in gold, each after the chips' own flat picture of its sign tinted alike, never a glyph, which none of LibVGA's faces carries (K0763), »als Angelegtes« quiet at its right -, judged by the main stat of the player's class and specialisation and stamina: more of the main stat without less stamina better, less of it worse, more with less stamina mixed, and where the main stat stays the same, stamina alone; then beside each value of the game's lines that changed, LibVGA's chip - the arrow left, the number right, green up, red down -, every chip as wide as the others, the line's right text holding their room unseen; a set that would break a line of its own in red, »Bricht Set: name 3 → 2« after the chips' down arrow as an inline picture. What is worn comes from the bags' upgrade (Bagupgrade.lua): the weaker of two places, both hands for a two-hander; an empty place compares with nothing. Only for weapons and armour the player can use, never for the worn item itself (K0754).

-- {K0783} {K0780} {K0754} {K0763} {K0605} {K0606} {K0607}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local STAMINA = "ITEM_MOD_STAMINA_SHORT"
local HEAD = 30
local RESERVE = "|T%s:0|t 8888 %%"
local BREAK = { 0.886, 0.404, 0.353 }
local VERDICTS = {
    up = { arrow = "▲", colour = { 0.247, 0.749, 0.353 }, word = "compare_better" },
    down = { arrow = "▼", colour = BREAK, word = "compare_worse" },
    mixed = { arrow = "◆", colour = colours.gold, word = "compare_mixed" },
}
local kept = setmetatable({}, { __mode = "k" })

local function read_stats(link)
    return link and C_Item.GetItemStats(link) or {}
end

local function read_worn_stats(worn)
    local sum = {}
    for _, link in ipairs(worn) do
        for key, value in pairs(read_stats(link)) do sum[key] = (sum[key] or 0) + value end
    end
    return sum
end

local function read_deltas(fresh, worn)
    local deltas = {}
    for key, value in pairs(fresh) do deltas[key] = value - (worn[key] or 0) end
    for key, value in pairs(worn) do
        if fresh[key] == nil then deltas[key] = -value end
    end
    return deltas
end

local function read_main_delta(deltas)
    local main, sum = vga.read_main_stat(), 0
    for key, value in pairs(deltas) do
        if vga.read_primary(key) == main then sum = sum + value end
    end
    return sum
end

local function read_verdict(deltas)
    local main, stamina = read_main_delta(deltas), deltas[STAMINA] or 0
    if main > 0 then return stamina >= 0 and "up" or "mixed" end
    if main < 0 then return "down" end
    if stamina > 0 then return "up" end
    if stamina < 0 then return "down" end
    return nil
end

local function read_figure(value)
    local plain = math.abs(value)
    if plain == math.floor(plain) then return tostring(plain) end
    return (string.format("%.1f", plain):gsub("%.", ","))
end

local function create_kept(tip)
    local pieces = { chips = {}, used = 0, hidden = {} }
    pieces.verdict = CreateFrame("Frame", nil, tip)
    pieces.verdict.mark = pieces.verdict:CreateTexture(nil, "ARTWORK")
    pieces.verdict.word = library.create_text(pieces.verdict, "bold", colours.ink)
    pieces.verdict.note = library.create_text(pieces.verdict, "small", colours.quiet)
    pieces.verdict.line = library.create_hairline(pieces.verdict)
    pieces.verdict:Hide()
    kept[tip] = pieces
    library.create_tooltip_block(tip)
    tip:HookScript("OnTooltipCleared", function(self) library.update_safely("compare cleared", vga.update_compare_cleared, self) end)
    return pieces
end

function vga.update_compare_cleared(tip)
    local pieces = kept[tip]
    if not pieces then return end
    for _, chip in ipairs(pieces.chips) do chip:Hide() end
    for _, text in ipairs(pieces.hidden) do text:SetAlpha(1) end
    pieces.used, pieces.hidden, pieces.shown_verdict = 0, {}, nil
    pieces.verdict:Hide()
end

local function update_verdict(tip, pieces, verdict)
    local look, frame = VERDICTS[verdict], pieces.verdict
    local pad, head = library.read_draft_size(14), library.read_draft_size(HEAD)
    local mark = library.read_size(-2)
    frame.mark:SetTexture(library.media .. library.read_chip_picture(look.arrow))
    frame.mark:SetVertexColor(look.colour[1], look.colour[2], look.colour[3], 1)
    frame.mark:SetSize(mark, mark)
    frame.mark:ClearAllPoints()
    frame.mark:SetPoint("LEFT", frame, "LEFT", pad, 0)
    frame.word:SetText(library.texts[look.word])
    frame.word:SetTextColor(look.colour[1], look.colour[2], look.colour[3], 1)
    frame.note:SetText(library.texts.compare_worn)
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", tip, "TOPLEFT", 0, -library.read_draft_size(4))
    frame:SetPoint("TOPRIGHT", tip, "TOPRIGHT", 0, -library.read_draft_size(4))
    frame:SetHeight(head)
    frame.word:ClearAllPoints()
    frame.word:SetPoint("LEFT", frame.mark, "RIGHT", library.read_draft_size(6), 0)
    frame.note:ClearAllPoints()
    frame.note:SetPoint("RIGHT", frame, "RIGHT", -pad, 0)
    frame.line:ClearAllPoints()
    frame.line:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    frame.line:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    frame.line:SetHeight(1)
    frame:Show()
    pieces.shown_verdict = frame.word:GetText()
    library.update_tooltip_block(tip, "head", head)
end

local function read_line_for(tip, label)
    local name = tip:GetName()
    for index = 1, tip:NumLines() do
        local left, right = _G[name .. "TextLeft" .. index], _G[name .. "TextRight" .. index]
        local words = left and left:GetText()
        if words and right and (right:GetText() or "") == "" and words:find(label, 1, true) then return right end
    end
end

local function read_chip(tip, pieces)
    pieces.used = pieces.used + 1
    pieces.chips[pieces.used] = pieces.chips[pieces.used] or library.create_chip(tip)
    return pieces.chips[pieces.used]
end

local function write_chip(tip, pieces, right, value)
    right:SetText(string.format(RESERVE, library.media .. library.read_chip_picture("▲")))
    right:SetAlpha(0)
    right:Show()
    pieces.hidden[#pieces.hidden + 1] = right
    local chip = read_chip(tip, pieces)
    library.update_chip(chip, value > 0 and "green" or "red", value > 0 and "▲" or "▼", read_figure(value))
    chip:ClearAllPoints()
    chip:SetPoint("RIGHT", right, "RIGHT", 0, 0)
    chip:Show()
end

local function write_chips(tip, pieces, deltas)
    for key, value in pairs(deltas) do
        local label = _G[key]
        local right = value ~= 0 and type(label) == "string" and read_line_for(tip, label)
        if right then write_chip(tip, pieces, right, value) end
    end
    local shown = {}
    for index = 1, pieces.used do shown[index] = pieces.chips[index] end
    library.update_chip_width(shown)
end

local function read_inline_mark(arrow, colour)
    local tint = math.floor(colour[1] * 255) .. ":" .. math.floor(colour[2] * 255) .. ":" .. math.floor(colour[3] * 255)
    return "|T" .. library.media .. library.read_chip_picture(arrow) .. ":0:0:0:0:32:32:0:32:0:32:" .. tint .. "|t"
end

local function read_set_count(set)
    local count = 0
    for place = 1, 19 do
        local link = GetInventoryItemLink("player", place)
        if link and select(16, C_Item.GetItemInfo(link)) == set then count = count + 1 end
    end
    return count
end

local function write_set_break(tip, link, worn)
    local set = worn[1] and select(16, C_Item.GetItemInfo(worn[1]))
    if not set or select(16, C_Item.GetItemInfo(link)) == set then return end
    local count = read_set_count(set)
    if count < 2 then return end
    local name = C_Item.GetItemSetInfo and C_Item.GetItemSetInfo(set) or ""
    tip:AddLine(read_inline_mark("▼", BREAK) .. " " .. string.format(library.texts.compare_breaks_set, name, count, count - 1), BREAK[1], BREAK[2], BREAK[3], true)
end

local function read_worn(link)
    local worn = vga.read_worn_links(link)
    if not worn then return nil end
    for _, other in ipairs(worn) do
        if other == link then return nil end
    end
    return worn
end

local function check_comparable(link)
    local item = C_Item.GetItemInfoInstant(link)
    if C_PlayerInfo and C_PlayerInfo.CanUseItem and type(item) == "number" and not C_PlayerInfo.CanUseItem(item) then return false end
    return true
end

local function update_compare(tip, data)
    if not (tip.GetName and tip:GetName() and tip.GetPadding and data) then return end
    local link = data.hyperlink or (tip.GetItem and select(2, tip:GetItem()))
    if not (type(link) == "string" and check_comparable(link)) then return end
    local worn = read_worn(link)
    if not worn then return end
    local pieces = kept[tip] or create_kept(tip)
    vga.update_compare_cleared(tip)
    local deltas = read_deltas(read_stats(link), read_worn_stats(worn))
    write_chips(tip, pieces, deltas)
    write_set_break(tip, link, worn)
    local verdict = read_verdict(deltas)
    if verdict then update_verdict(tip, pieces, verdict) end
end

function vga.read_tip_verdict(tip)
    return kept[tip] and kept[tip].shown_verdict
end

function vga.read_tip_verdict_mark(tip)
    return kept[tip] and kept[tip].verdict.mark
end

function vga.read_tip_chips(tip)
    return kept[tip] and kept[tip].chips
end

if TooltipDataProcessor and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tip, data)
        library.update_safely("tooltip compare", update_compare, tip, data)
    end)
end
