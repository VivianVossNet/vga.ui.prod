-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's money as the accepted draft draws it (manual/view/vga-windows.html .money): gold, silver and copper, each figure followed by its coin, the coin centred on the figure's line, two draft pixels between figure and coin and six between the groups, closer than the draft's four and twelve since the owner's word of 20 November 2026 (K0539), so a separator beside the money reads as one; leading empty groups left out, the copper always shown; shared by every element that shows money; read as text with the coins as inline pictures for lines of text and tooltips (library.read_money_text, K0632); greyed, its figures in LibVGA's grey and its coins without colour and darkened, as a loot entry taken shows it (library.update_money_greyed, K0874). library.update_money_tinted sets the figures in a colour of their own, red where the player cannot pay, its own ink again without one (K0994).

-- {K0994} {K0874} {K0789} {K0258} {K0388} {K0403} {K0539} {K0632}

local library = LibVGA
local DRAFT_BASE = 13
local NEAR = 2
local DIMMED = 0.6
local APART = 6
local COINS = { { 10000, "CoinGold" }, { 100, "CoinSilver" }, { 1, "CoinCopper" } }

function library.create_money(parent, colour)
    local money = CreateFrame("Frame", nil, parent)
    money.groups, money.vga_colour = {}, colour or library.colours.ink
    for index, coin in ipairs(COINS) do
        local group = { text = library.create_text(money, "body", colour), coin = money:CreateTexture(nil, "ARTWORK") }
        group.coin:SetTexture(library.media .. coin[2])
        money.groups[index] = group
    end
    return money
end

local function update_group(money, group, count, x)
    local scale = library.read_base() / DRAFT_BASE
    local size, near = math.floor(10 * scale + 0.5), math.floor(NEAR * scale + 0.5)
    group.text:SetFontObject(library.read_frame_font("figures_" .. (money.kind or "body")))
    group.text:SetText(count)
    group.text:ClearAllPoints()
    group.text:SetPoint("TOPLEFT", money, "TOPLEFT", x, 0)
    group.coin:SetSize(size, size)
    group.coin:ClearAllPoints()
    group.coin:SetPoint("LEFT", group.text, "RIGHT", near, 0)
    return x + math.ceil(library.read_string_width(group.text)) + near + size
end

function library.update_money(money, copper)
    local apart = library.read_draft_size(APART)
    local left, x, shown = copper or 0, 0, false
    for index, coin in ipairs(COINS) do
        local group = money.groups[index]
        local count = math.floor(left / coin[1])
        left = left - count * coin[1]
        shown = shown or count > 0 or index == #COINS
        group.text:SetShown(shown)
        group.coin:SetShown(shown)
        if shown then x = update_group(money, group, count, x) + apart end
    end
    money.vga_width = math.max(1, x - apart)
    money:SetWidth(money.vga_width)
    money:SetHeight(math.ceil(library.read_string_height(money.groups[#COINS].text)))
end

function library.update_money_tinted(money, colour)
    local ink = colour or money.vga_colour
    for _, group in ipairs(money.groups) do group.text:SetTextColor(ink[1], ink[2], ink[3], 1) end
end

function library.update_money_greyed(money, greyed)
    local ink, light = greyed and library.colours.greyed or money.vga_colour, greyed and DIMMED or 1
    for _, group in ipairs(money.groups) do
        group.text:SetTextColor(ink[1], ink[2], ink[3], 1)
        group.coin:SetDesaturated(greyed)
        group.coin:SetVertexColor(light, light, light)
    end
end

function library.read_money_text(copper)
    local parts = {}
    for index, coin in ipairs(COINS) do
        local count = math.floor(copper / coin[1])
        if index > 1 then count = count % 100 end
        if count > 0 or (index == #COINS and #parts == 0) then parts[#parts + 1] = count .. "|T" .. library.media .. coin[2] .. ":0|t" end
    end
    return table.concat(parts, " ")
end
