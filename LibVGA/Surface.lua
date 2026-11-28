-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's rounded surfaces, drawn of a corner texture and three bands; notches, the inverse corners that round whatever lies beneath them; thin rings, a line with rounded corners and nothing inside, or bold ones whose corners round by twice their width ({K0413}); and the gold corner that opens an element's options. A cell's picture - an action key's, a bag's, a menu button's - fills the cell up to its edge's inner side, its square corners under the edge's rounding (read_cell_inset, update_cell_picture; K0536, K0544). Every inset, radius and thickness is laid on whole screen pixels in its frame's own scale (read_whole_pixels, the game's PixelUtil), so lines keep one width and the pieces of a surface meet without a seam (K0562). The gold corner's arc is three eighths of its size - measured in GoldCornerSmall and GoldCornerLarge, 24 of 64 pixels - and it sits three pixels inside its frame; library.read_corner_parallel_radius gives the radius a frame's own corners take to run parallel to that arc, its arc plus those three pixels (K1051).

-- {K1051} {K0256} {K0267} {K0334} {K0346} {K0349} {K0413} {K0536} {K0544} {K0562}

local CORNER_INSET = 3
local CORNER_ARC = 0.375
local library = LibVGA
local CELL_GAP = 0

function library.read_cell_inset(edge)
    return edge + CELL_GAP
end

function library.update_cell_picture(picture, cell, edge)
    local inset = library.read_cell_inset(edge)
    picture:ClearAllPoints()
    picture:SetPoint("TOPLEFT", cell, "TOPLEFT", inset, -inset)
    picture:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", -inset, inset)
end

function library.create_colour(colour, alpha)
    return CreateColor(colour[1], colour[2], colour[3], alpha or 1)
end

local CORNERS = {
    { "TOPLEFT", 0, 1, 0, 1 },
    { "TOPRIGHT", 1, 0, 0, 1 },
    { "BOTTOMLEFT", 0, 1, 1, 0 },
    { "BOTTOMRIGHT", 1, 0, 1, 0 },
}

local function update_pixel_round(region)
    if region.SetRoundLayoutToNearestPixel then region:SetRoundLayoutToNearestPixel(true) end
end

function library.create_surface(frame, layer, level, around)
    local surface = { frame = around or frame, pieces = {} }
    update_pixel_round(frame)
    for _, corner in ipairs(CORNERS) do
        local piece = frame:CreateTexture(nil, layer, nil, level)
        update_pixel_round(piece)
        piece:SetTexture(library.media .. "Corner")
        piece:SetTexCoord(corner[2], corner[3], corner[4], corner[5])
        surface.pieces[corner[1]] = piece
    end
    for _, side in ipairs({ "TOP", "BOTTOM", "MIDDLE" }) do
        local piece = frame:CreateTexture(nil, layer, nil, level)
        update_pixel_round(piece)
        piece:SetColorTexture(1, 1, 1, 1)
        surface.pieces[side] = piece
    end
    return surface
end

local function update_flat_foot(surface, inset, radius)
    local frame, pieces = surface.frame, surface.pieces
    pieces.BOTTOMLEFT:Hide()
    pieces.BOTTOMRIGHT:Hide()
    pieces.BOTTOM:Hide()
    pieces.MIDDLE:ClearAllPoints()
    pieces.MIDDLE:SetPoint("TOPLEFT", frame, "TOPLEFT", inset, -inset - radius)
    pieces.MIDDLE:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, inset)
end

function library.read_whole_pixels(units, region)
    if not (PixelUtil and PixelUtil.GetNearestPixelSize and region and region.GetEffectiveScale) then return units end
    local sign = units < 0 and -1 or 1
    return sign * PixelUtil.GetNearestPixelSize(math.abs(units), region:GetEffectiveScale(), units ~= 0 and 1 or 0)
end

function library.update_surface(surface, inset, radius, top, bottom, alpha)
    local frame, pieces = surface.frame, surface.pieces
    inset = library.read_whole_pixels(inset, frame)
    radius = library.read_whole_pixels(math.max(radius, 1), frame)
    for _, corner in ipairs(CORNERS) do
        local point = corner[1]
        local piece = pieces[point]
        piece:ClearAllPoints()
        piece:SetSize(radius, radius)
        local x = point:find("LEFT") and inset or -inset
        local y = point:find("TOP") and -inset or inset
        piece:SetPoint(point, frame, point, x, y)
        local colour = point:find("TOP") and top or bottom
        piece:SetVertexColor(colour[1], colour[2], colour[3], alpha or 1)
    end
    pieces.TOP:ClearAllPoints()
    pieces.TOP:SetPoint("TOPLEFT", pieces.TOPLEFT, "TOPRIGHT")
    pieces.TOP:SetPoint("BOTTOMRIGHT", pieces.TOPRIGHT, "BOTTOMLEFT")
    pieces.BOTTOM:ClearAllPoints()
    pieces.BOTTOM:SetPoint("TOPLEFT", pieces.BOTTOMLEFT, "TOPRIGHT")
    pieces.BOTTOM:SetPoint("BOTTOMRIGHT", pieces.BOTTOMRIGHT, "BOTTOMLEFT")
    pieces.MIDDLE:ClearAllPoints()
    pieces.MIDDLE:SetPoint("TOPLEFT", frame, "TOPLEFT", inset, -inset - radius)
    pieces.MIDDLE:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, inset + radius)
    pieces.TOP:SetVertexColor(top[1], top[2], top[3], alpha or 1)
    pieces.BOTTOM:SetVertexColor(bottom[1], bottom[2], bottom[3], alpha or 1)
    pieces.MIDDLE:SetGradient("VERTICAL", library.create_colour(bottom, alpha), library.create_colour(top, alpha))
    if surface.flat then update_flat_foot(surface, inset, radius) end
end

function library.create_corner(frame, large, on_click)
    local corner = CreateFrame("Button", nil, frame)
    corner:SetFrameLevel(frame:GetFrameLevel() + 5)
    local art = corner:CreateTexture(nil, "OVERLAY")
    art:SetAllPoints()
    art:SetTexture(library.media .. (large and "GoldCornerLarge" or "GoldCornerSmall"))
    art:SetVertexColor(unpack(library.colours.gold))
    corner.art = art
    corner.large = large
    corner:SetScript("OnEnter", function(self) self.art:SetVertexColor(unpack(library.colours.gold_high)) end)
    corner:SetScript("OnLeave", function(self) self.art:SetVertexColor(unpack(library.colours.gold)) end)
    corner:RegisterForClicks("LeftButtonUp")
    corner:SetHitRectInsets(-6, -6, -6, -6)
    if on_click then
        corner:SetScript("OnClick", on_click)
    end
    return corner
end

function library.update_corner(corner)
    local size = library.read_size(corner.large and 2 or -2)
    corner:ClearAllPoints()
    corner:SetSize(size, size)
    corner:SetPoint("TOPRIGHT", corner:GetParent(), "TOPRIGHT", -CORNER_INSET, -CORNER_INSET)
end

function library.read_corner_parallel_radius(large)
    return library.read_size(large and 2 or -2) * CORNER_ARC + CORNER_INSET
end

function library.create_notches(frame, layer, level, art)
    local notches = {}
    for _, corner in ipairs(CORNERS) do
        local piece = frame:CreateTexture(nil, layer, nil, level)
        update_pixel_round(piece)
        piece:SetTexture(library.media .. (art or "CornerInverse"))
        piece:SetTexCoord(corner[2], corner[3], corner[4], corner[5])
        notches[corner[1]] = piece
    end
    return notches
end

function library.update_notches(notches, around, radius, colour)
    for point, piece in pairs(notches) do
        piece:ClearAllPoints()
        piece:SetSize(math.max(radius, 0.01), math.max(radius, 0.01))
        piece:SetPoint(point, around, point)
        piece:SetVertexColor(colour[1], colour[2], colour[3], 1)
        piece:SetShown(radius > 0)
    end
end

function library.create_ring(frame, layer, level, around, bold)
    local ring = { frame = around or frame, pieces = {}, ratio = bold and 2 or 4 }
    for _, corner in ipairs(CORNERS) do
        local piece = frame:CreateTexture(nil, layer, nil, level)
        update_pixel_round(piece)
        piece:SetTexture(library.media .. (bold and "CornerRingBold" or "CornerRing"))
        piece:SetTexCoord(corner[2], corner[3], corner[4], corner[5])
        ring.pieces[corner[1]] = piece
    end
    for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
        local piece = frame:CreateTexture(nil, layer, nil, level)
        update_pixel_round(piece)
        piece:SetColorTexture(1, 1, 1, 1)
        ring.pieces["EDGE" .. side] = piece
    end
    return ring
end

function library.update_ring(ring, thickness, colour, alpha)
    local frame = ring.frame
    thickness = library.read_whole_pixels(thickness, frame)
    local pieces, radius = ring.pieces, ring.ratio * thickness
    for _, corner in ipairs(CORNERS) do
        local piece = pieces[corner[1]]
        piece:ClearAllPoints()
        piece:SetSize(radius, radius)
        piece:SetPoint(corner[1], frame, corner[1])
    end
    local edges = {
        EDGETOP = { "TOPLEFT", "TOPRIGHT", radius, 0, -radius, 0, nil, thickness },
        EDGEBOTTOM = { "BOTTOMLEFT", "BOTTOMRIGHT", radius, 0, -radius, 0, nil, thickness },
        EDGELEFT = { "TOPLEFT", "BOTTOMLEFT", 0, -radius, 0, radius, thickness, nil },
        EDGERIGHT = { "TOPRIGHT", "BOTTOMRIGHT", 0, -radius, 0, radius, thickness, nil },
    }
    for key, edge in pairs(edges) do
        local piece = pieces[key]
        piece:ClearAllPoints()
        piece:SetPoint(edge[1], frame, edge[1], edge[3], edge[4])
        piece:SetPoint(edge[2], frame, edge[2], edge[5], edge[6])
        if edge[7] then piece:SetWidth(edge[7]) else piece:SetHeight(edge[8]) end
    end
    for _, piece in pairs(pieces) do piece:SetVertexColor(colour[1], colour[2], colour[3], alpha or 1) end
end
