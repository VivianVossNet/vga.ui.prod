-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's class dot, an object of the unit frame's (K0864): a round dot in the colour of a unit's class, standing where the class's word stood so the name keeps its width, a tooltip naming the class where asked (K0717); made by library.create_class_dot, sized and coloured by library.update_class_dot, its side read by library.read_class_dot_size and a unit's class colour by library.read_class_colour, the quiet colour where the unit has no class.

-- {K0864} {K0860} {K0717}

local library = LibVGA
local colours = library.colours

function library.read_class_dot_size()
    return math.floor(library.read_base() * 0.77 + 0.5)
end

function library.read_class_colour(unit)
    local _, class = UnitClass(unit)
    local colour = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if colour then return { colour.r, colour.g, colour.b } end
    return colours.quiet
end

local function render_class_tip(spot)
    if not spot.word then return end
    GameTooltip:SetOwner(spot, "ANCHOR_TOP")
    GameTooltip:SetText(spot.word, 1, 1, 1)
    GameTooltip:Show()
end

local function update_class_tip_hidden()
    GameTooltip:Hide()
end

function library.create_class_dot(parent, tipped)
    local spot = CreateFrame("Frame", nil, parent)
    spot.dot = library.create_surface(spot, "ARTWORK", 0)
    if tipped then
        spot:EnableMouse(true)
        spot:SetScript("OnEnter", render_class_tip)
        spot:SetScript("OnLeave", update_class_tip_hidden)
    end
    return spot
end

function library.update_class_dot(spot, colour, word)
    local size = library.read_class_dot_size()
    spot:SetSize(size, size)
    spot.word = word
    library.update_surface(spot.dot, 0, size / 2, colour, colour)
end
