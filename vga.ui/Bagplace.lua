-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: Where the bags stand and how large: their size small, normal or large as the settings choose, the whole dialog scaled in proportion; their place kept where they were dragged, across a reload and through a change of size, measured from the screen's nearest corner - the right edge where they stand on the right half, the left on the left, the top on the upper half, the bottom on the lower - in the screen's own share, so they hug the same edges on every screen; a place kept before in plain pixels is turned so when first read (K0555); and the pin in their head beside the close button, which fixes the place so the dialog can no longer be dragged, gold while it holds, its meaning in a tooltip - LibVGA's dialog pin, the state kept in the settings (K0764).

-- {K0415} {K0555}

local _, vga = ...
local library = LibVGA
local colours = library.colours

local function read_scale()
    return (library.read_size_step("bags"))
end

function vga.read_edge_place(left, top)
    local width, height, share = UIParent:GetWidth(), UIParent:GetHeight(), library.read_screen_share()
    local right_side, upper_side = left > width / 2, top > height / 2
    local edge = (upper_side and "TOP" or "BOTTOM") .. (right_side and "RIGHT" or "LEFT")
    local across, down = right_side and left - width or left, upper_side and top - height or top
    return { edge, math.floor(across / share + 0.5), math.floor(down / share + 0.5) }
end

local function read_place()
    local place = LibVGASettings.bags_place
    if place and type(place[1]) == "number" then
        place = vga.read_edge_place(place[1], place[2])
        LibVGASettings.bags_place = place
    end
    return place
end

local function update_anchor(bags)
    local scale, place = read_scale(), read_place()
    local share = library.read_screen_share()
    bags:SetScale(scale)
    bags:ClearAllPoints()
    if place then
        bags:SetPoint("TOPLEFT", UIParent, place[1], place[2] * share / scale, place[3] * share / scale)
    else
        bags:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -library.read_size(6) / scale, library.read_size(12) / scale)
    end
end

local function write_place(bags)
    local scale = read_scale()
    LibVGASettings.bags_place = vga.read_edge_place(bags:GetLeft() * scale, bags:GetTop() * scale)
    update_anchor(bags)
end

local BAG_PIN = {
    read = function() return LibVGASettings.bags_pinned == true end,
    write = function(pinned) LibVGASettings.bags_pinned = pinned or nil end,
    dropped = write_place,
}

function vga.create_bag_place(bags)
    library.update_dialog_pin_state(bags, BAG_PIN)
end

function vga.update_bag_place(bags)
    update_anchor(bags)
    library.update_dialog_pin(bags)
end
