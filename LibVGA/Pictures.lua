-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's choice by pictures as the accepted draft draws it (manual/view/vga-settings.html): tiles with a small picture of what is chosen, or a sample in a font, and a word under it (.tile), small boxes with a picture of a shape (.grids), or smooth round swatches of colour (.swatches), the chosen swatch ringed in gold a pixel clear of its colour; the chosen tile or box ringed in gold, its picture gold; drawn from rectangles in the draft's own units, so nothing needs a texture of its own.

-- {K0794} {K0383}

local library = LibVGA
local colours = library.colours
local QUIET_INK = { 0.435, 0.424, 0.4 }
local BOX = { 0.043, 0.047, 0.059 }
local EDGE = { 0.18, 0.192, 0.22 }

local function create_cell(choice, item, index, on_choose)
    local cell = CreateFrame("Button", nil, choice)
    cell.edge = library.create_surface(cell, "BACKGROUND", 0)
    cell.box = library.create_surface(cell, "BACKGROUND", 1)
    cell.marks = {}
    for place, rect in ipairs(item.rects or {}) do
        cell.marks[place] = cell:CreateTexture(nil, "ARTWORK")
        cell.marks[place]:SetColorTexture(1, 1, 1, 1)
        cell.marks[place].rect = rect
    end
    if item.colour then
        cell.ring = cell:CreateTexture(nil, "ARTWORK", nil, 1)
        cell.ring:SetTexture(library.media .. "Disc")
        cell.gap = cell:CreateTexture(nil, "ARTWORK", nil, 2)
        cell.gap:SetTexture(library.media .. "Disc")
        cell.gap:SetVertexColor(colours.ground[1], colours.ground[2], colours.ground[3], 1)
        cell.dot = cell:CreateTexture(nil, "ARTWORK", nil, 3)
        cell.dot:SetTexture(library.media .. "Disc")
        cell.dot:SetVertexColor(item.colour[1], item.colour[2], item.colour[3], 1)
    end
    if item.label then
        cell.text = library.create_text(cell, "small")
        cell.text:SetText(item.label)
    end
    if item.sample then
        cell.sample = cell:CreateFontString(nil, "ARTWORK")
        cell.sample:SetFont(item.face, library.read_size(1), "")
        cell.sample:SetText(item.sample)
    end
    cell:SetScript("OnClick", function()
        choice.chosen = index
        library.update_pictures(choice)
        on_choose(index)
        library.render_control_changed(choice)
    end)
    return cell
end

function library.create_pictures(parent, items, chosen, on_choose, kind)
    local choice = CreateFrame("Frame", nil, parent)
    choice.pictures, choice.kind, choice.chosen = {}, kind, chosen
    for index, item in ipairs(items) do
        choice.pictures[index] = create_cell(choice, item, index, on_choose)
        choice.pictures[index].item = item
    end
    return choice
end

local function read_tile_width(choice)
    local widest = 0
    for _, cell in ipairs(choice.pictures) do
        if cell.text then
            cell.text:SetFontObject(library.read_font("small"))
            widest = math.max(widest, math.ceil(cell.text:GetStringWidth()))
        end
    end
    return math.max(math.floor(library.read_size(0) * 5), widest + 2 * library.read_size(-2))
end

local function read_cell_size(choice)
    local unit = library.read_size(0)
    if choice.kind == "tile" then return read_tile_width(choice), math.floor(unit * 4.4) end
    if choice.kind == "swatch" then return math.floor(unit * 1.6), math.floor(unit * 1.6) end
    return math.floor(unit * 2), math.floor(unit * 1.7)
end

function library.read_pictures_width(choice)
    local width = read_cell_size(choice)
    local gap = choice.kind == "tile" and library.read_size(-2) or math.max(2, library.read_size(-6))
    return #choice.pictures * width + (#choice.pictures - 1) * gap
end

local function update_marks(cell, on, width, height)
    local box = cell.item.box
    local scale = math.min(width / box[1], (cell.text and height * 0.55 or height) / box[2]) * 0.8
    local left = (width - box[1] * scale) / 2
    local top = cell.text and height * 0.12 or (height - box[2] * scale) / 2
    local ink = on and colours.gold or QUIET_INK
    for _, mark in ipairs(cell.marks) do
        local x, y, across, down = unpack(mark.rect)
        mark:ClearAllPoints()
        mark:SetPoint("TOPLEFT", cell, "TOPLEFT", math.floor(left + x * scale + 0.5), -math.floor(top + y * scale + 0.5))
        mark:SetSize(math.max(1, math.floor(across * scale + 0.5)), math.max(1, math.floor(down * scale + 0.5)))
        mark:SetVertexColor(ink[1], ink[2], ink[3], 1)
    end
end

local function update_cell(choice, cell, on, width, height)
    local radius = choice.kind == "swatch" and 0 or library.read_size(-6)
    cell:SetSize(width, height)
    local frame = on and colours.gold or EDGE
    library.update_surface(cell.edge, 0, radius, frame, frame, choice.kind == "swatch" and 0 or 1)
    library.update_surface(cell.box, 1, math.max(radius - 1, 0), BOX, BOX, choice.kind == "swatch" and 0 or 1)
    if cell.dot then
        local ring = math.max(1, library.read_size(-6) - 1)
        for place, disc in ipairs({ cell.ring, cell.gap, cell.dot }) do
            local inset = math.min(place - 1, 1) * ring + (place == 3 and 1 or 0)
            disc:ClearAllPoints()
            disc:SetPoint("CENTER")
            disc:SetSize(width - 2 * inset, height - 2 * inset)
        end
        cell.ring:SetVertexColor(colours.gold[1], colours.gold[2], colours.gold[3], 1)
        cell.ring:SetShown(on)
        cell.gap:SetShown(on)
    end
    if cell.text then
        cell.text:SetFontObject(library.read_font("small"))
        cell.text:SetTextColor(unpack(on and colours.gold or colours.quiet))
        cell.text:ClearAllPoints()
        cell.text:SetPoint("BOTTOM", cell, "BOTTOM", 0, library.read_size(-4))
    end
    if cell.item.box then update_marks(cell, on, width, height) end
    if cell.sample then
        cell.sample:SetFont(cell.item.face, math.floor(height * 0.36), "")
        cell.sample:SetTextColor(unpack(on and colours.gold or colours.ink))
        cell.sample:ClearAllPoints()
        cell.sample:SetPoint("CENTER", cell, "CENTER", 0, math.floor(height * 0.12))
    end
end

function library.update_pictures(choice, wanted)
    choice.wanted = wanted or choice.wanted
    local width, height = read_cell_size(choice)
    local gap = choice.kind == "tile" and library.read_size(-2) or math.max(2, library.read_size(-6))
    if choice.kind == "tile" and choice.wanted then
        width = math.max(width, math.floor((choice.wanted - (#choice.pictures - 1) * gap) / #choice.pictures))
    end
    for index, cell in ipairs(choice.pictures) do
        cell:ClearAllPoints()
        cell:SetPoint("LEFT", choice, "LEFT", (index - 1) * (width + gap), 0)
        update_cell(choice, cell, index == choice.chosen, width, height)
    end
    choice:SetSize(#choice.pictures * width + (#choice.pictures - 1) * gap, height)
end
