-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's route line: a flight's way drawn over a map from point to point, each point at its own exact place on that map - the game's place of a flight point, its centre rounded to a whole pixel, never an approximate one (K0830) -; white while it is only shown, gold while it is the chosen one (K0806). Its owner names the map frame, the places as shares of the map's width and height, and whether the route is chosen (K0835). It draws on the map it is handed when the map was not yet there at its making (K0838).

-- {K0838} {K0835} {K0830} {K0806}

local library = LibVGA
local colours = library.colours
local THICKNESS = 3
local WHITE = { 1, 1, 1 }

function library.create_route_line(parent)
    return { parent = parent, segments = {}, points = {} }
end

local function read_segment(route, index)
    route.segments[index] = route.segments[index] or route.parent:CreateLine(nil, "OVERLAY")
    return route.segments[index]
end

local function read_pixel_places(map, places)
    local width, height = map:GetWidth(), map:GetHeight()
    local points = {}
    for index, place in ipairs(places) do
        points[index] = { math.floor(place[1] * width + 0.5), math.floor(place[2] * height + 0.5) }
    end
    return points
end

function library.update_route_line(route, map, places, chosen)
    route.parent = route.parent or map
    route.points = map and read_pixel_places(map, places or {}) or {}
    local colour = chosen and colours.gold or WHITE
    for index = 1, #route.points - 1 do
        local segment, from, to = read_segment(route, index), route.points[index], route.points[index + 1]
        segment:SetThickness(THICKNESS)
        segment:SetColorTexture(colour[1], colour[2], colour[3], 1)
        segment:SetStartPoint("TOPLEFT", map, from[1], -from[2])
        segment:SetEndPoint("TOPLEFT", map, to[1], -to[2])
        segment:Show()
    end
    for index = math.max(1, #route.points), #route.segments do route.segments[index]:Hide() end
end
