-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's chip, every comparison's one look as the accepted drafts draw it (manual/view/vga-tooltip.html, vga-auctions.html, K0605 to K0607): a small rounded ground in its kind's colour, faint, the arrow - up, down, even, a mark, drawn as our own small pictures since the game's faces lack the signs (K0623) - at its left edge and the figure at its right, both in the kind's colour; every chip at least as wide as »8888 %« needs, so a column never changes its width, its height an even number of whole screen pixels so the faint ground's halves meet without a darker line (K0654); the chips of one column made as wide as the widest of them by the caller (library.read_chip_width, library.update_chip_width); its colour and sign picture read out for chips written into a tooltip's text (library.read_chip_colour, library.read_chip_picture, K0626). The widest a chip can be is read from a hidden probe for a list's column (library.read_widest_chip, K0686). Where its owner names a picture of LibVGA's media instead of an arrow, the chip carries that picture in its kind's colour - the talk's anvil beside »Reparatur« (K0848). A chip given no sign is a label - the experience of a quest, »Verfügbar«, »Abgeben«, a trainer's »lernbar« -: it shows its word alone, centred, as wide as the word and its two margins, never a sign it was not given (K0888). Its kinds: gold, green, grey, red and blue - the blue of what is fixed in the bags (K0900).

-- {K0900} {K0888} {K0848} {K0789} {K0607} {K0623} {K0626} {K0654} {K0686}

local library = LibVGA
local colours = library.colours
local KINDS = {
    gold = colours.gold,
    blue = colours.blue,
    green = { 0.247, 0.749, 0.353 },
    grey = colours.quiet,
    red = { 0.886, 0.404, 0.353 },
}
local GROUND = 0.14
local WIDEST = "8888 %"
local ARROWS = { ["▲"] = "ChipUp", ["▼"] = "ChipDown", ["≈"] = "ChipEven", ["◆"] = "ChipMark" }

function library.create_chip(parent)
    local chip = CreateFrame("Frame", nil, parent)
    chip.ground = library.create_surface(chip, "BACKGROUND", 0)
    chip.arrow = chip:CreateTexture(nil, "ARTWORK")
    chip.figure = library.create_text(chip, "caption")
    return chip
end

function library.update_chip(chip, kind, arrow, figure)
    local colour, pad = library.read_chip_colour(kind), library.read_size(-4)
    chip.figure:SetFontObject(library.read_font("figures_caption"))
    chip.figure:SetTextColor(colour[1], colour[2], colour[3], 1)
    chip.figure:SetText(figure)
    local signed = arrow ~= nil and arrow ~= ""
    local mark = signed and math.ceil(library.read_string_height(chip.figure) * 0.8) or nil
    chip.vga_mark = mark
    chip.arrow:SetShown(signed)
    chip.arrow:SetTexture(signed and library.media .. library.read_chip_picture(arrow) or nil)
    chip.arrow:SetVertexColor(colour[1], colour[2], colour[3], 1)
    chip.arrow:SetSize(mark or 1, mark or 1)
    chip.arrow:ClearAllPoints()
    chip.arrow:SetPoint("LEFT", chip, "LEFT", pad, 0)
    chip.figure:ClearAllPoints()
    chip.figure:SetPoint(signed and "RIGHT" or "CENTER", chip, signed and "RIGHT" or "CENTER", signed and -pad or 0, 0)
    local radius = library.read_whole_pixels(math.ceil((library.read_string_height(chip.figure) + 2) / 2), chip)
    chip:SetSize(library.read_whole_pixels(library.read_chip_width(chip), chip), 2 * radius)
    library.update_surface(chip.ground, 0, radius, colour, colour, GROUND)
end

function library.read_chip_colour(kind)
    return KINDS[kind] or KINDS.grey
end

function library.read_chip_picture(arrow)
    return ARROWS[arrow] or (arrow and arrow ~= "" and arrow) or "ChipEven"
end

function library.read_chip_width(chip)
    if not chip.vga_mark then return math.ceil(library.read_string_width(chip.figure)) + 2 * library.read_size(-4) end
    local shown = chip.figure:GetText()
    chip.figure:SetText(WIDEST)
    local room = library.read_string_width(chip.figure)
    chip.figure:SetText(shown)
    return math.ceil(chip.vga_mark + math.max(room, library.read_string_width(chip.figure))) + 3 * library.read_size(-4)
end

function library.update_chip_width(chips)
    local widest = 0
    for _, chip in ipairs(chips) do widest = math.max(widest, library.read_chip_width(chip)) end
    for _, chip in ipairs(chips) do chip:SetWidth(widest) end
    return widest
end

function library.read_widest_chip(probe)
    probe:Hide()
    library.update_chip(probe, "grey", "≈", WIDEST)
    return math.ceil(probe:GetWidth())
end
