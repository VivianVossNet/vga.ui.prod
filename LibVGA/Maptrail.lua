-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's map trail, a meta-object for any map surface (K0948, as the layer of map signs is, K0925): the way the player walked laid down as small filled circles in VGA's orange, six draft pixels, one every two yards, each lying where it was laid, as if dropped behind; a circle fades over the last four yards before fifty yards from the player - the last two - and is gone beyond. Its owner gives it at every frame the player's place on the plane, the plane's size in yards and its own reckoning of a point on the surface; a circle is shown only while it lies wholly inside the surface. One task: draw the trail.

-- {K0948}

local library = LibVGA
local colours = library.colours
local STEP, REACH, FADE, SIZE = 2, 50, 4, 6

function library.create_map_trail(surface)
    return { surface = surface, points = {}, dots = {} }
end

local function read_yards(point, here, scale)
    return math.sqrt(((point[1] - here[1]) * scale[1]) ^ 2 + ((point[2] - here[2]) * scale[2]) ^ 2)
end

local function read_dot(trail, index)
    local dot = trail.dots[index]
    if dot then return dot end
    dot = trail.surface:CreateTexture(nil, "ARTWORK")
    dot:SetTexture(library.media .. "Dot")
    dot:SetVertexColor(colours.orange[1], colours.orange[2], colours.orange[3], 1)
    trail.dots[index] = dot
    return dot
end

local function write_points(trail, here, scale)
    local points, last = trail.points, trail.points[#trail.points]
    if not last or read_yards(last, here, scale) >= STEP then points[#points + 1] = { here[1], here[2] } end
    local kept = {}
    for _, point in ipairs(points) do
        if read_yards(point, here, scale) <= REACH then kept[#kept + 1] = point end
    end
    trail.points = kept
end

local function update_dot(trail, dot, point, here, scale, read_point)
    local size, surface = library.read_draft_size(SIZE), trail.surface
    local x, y = read_point(surface, point[1], point[2])
    local half = size / 2
    local inside = x - half >= 0 and x + half <= surface:GetWidth() and y - half >= 0 and y + half <= surface:GetHeight()
    dot:SetShown(inside)
    if not inside then return end
    dot:SetSize(size, size)
    dot:ClearAllPoints()
    dot:SetPoint("CENTER", surface, "TOPLEFT", x, -y)
    dot:SetAlpha(math.min(1, (REACH - read_yards(point, here, scale)) / FADE))
end

function library.update_map_trail(trail, here, scale, read_point)
    write_points(trail, here, scale)
    for index, point in ipairs(trail.points) do update_dot(trail, read_dot(trail, index), point, here, scale, read_point) end
    for index = #trail.points + 1, #trail.dots do trail.dots[index]:Hide() end
end

function library.update_map_trail_cleared(trail)
    trail.points = {}
    for _, dot in ipairs(trail.dots) do dot:Hide() end
end
