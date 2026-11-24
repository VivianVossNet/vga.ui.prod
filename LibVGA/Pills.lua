-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's pill meter, as the accepted catalogue names it (manual/view/vga-catalogue.html, K0775) after the combo points and the threat pills under the unit frames (manual/view/vga-hud.html, vga-arcs-band.html; K0751): a row of rounded pills, each three times as wide as high, a black line round it and a ground, centred under a bar of its owner's - the frame's power bar - and dropped to the middle of the room left beneath it; each pill may carry a fill of its own (library.create_fill) in a colour shaded darker below. Its owner shades a pill's ground by its state or sets the fills' values (K0795).

-- {K0795} {K0751} {K0775}

local library = LibVGA
local OPEN = { 0.2, 0.21, 0.24 }
local BLACK = { 0, 0, 0 }
local SHADE = 0.62

local function read_sizes()
    local height = library.read_size(-5)
    return 3 * height, height, library.read_size(-6)
end

function library.read_pills_room()
    local _, height, between = read_sizes()
    return height + between
end

local function create_pill(frame, colour)
    local pill = CreateFrame("Frame", nil, frame)
    pill.vga_pill = true
    pill.edge = library.create_surface(pill, "ARTWORK", 0)
    pill.back = library.create_surface(pill, "ARTWORK", 1)
    if colour then
        pill.fill = library.create_fill(pill)
        library.update_fill_colour(pill.fill, colour, { colour[1] * SHADE, colour[2] * SHADE, colour[3] * SHADE })
        pill.fill:SetAllPoints()
    end
    return pill
end

function library.create_pills(frame, plan)
    local pills = { frame = frame }
    for index = 1, plan.count do pills[index] = create_pill(frame, plan.fill) end
    return pills
end

local function read_drop(frame, bar, height, between)
    local bar_foot, frame_foot = bar:GetBottom(), frame:GetBottom()
    if not (bar_foot and frame_foot) or bar_foot - frame_foot <= height then return between end
    return math.floor((bar_foot - frame_foot - height) / 2 + 0.5)
end

function library.update_pill_shade(pill, top, bottom)
    library.update_surface(pill.back, 0, pill:GetHeight() / 2, top, bottom or top)
end

function library.update_pills(pills, bar)
    local width, height, between = read_sizes()
    local gap = library.read_size(-6)
    local span = #pills * width + (#pills - 1) * gap
    local drop = read_drop(pills.frame, bar, height, between)
    for index, pill in ipairs(pills) do
        pill:SetSize(width, height)
        pill:ClearAllPoints()
        pill:SetPoint("TOPLEFT", bar, "BOTTOM", -span / 2 + (index - 1) * (width + gap), -drop)
        library.update_surface(pill.edge, -1, height / 2 + 1, BLACK, BLACK)
        library.update_pill_shade(pill, OPEN)
    end
    return height + between
end
