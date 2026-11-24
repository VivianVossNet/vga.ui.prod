-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's map hatching as the owner chose it (K0812): a fine diagonal hatch, white lines one pixel wide sixteen apart (Media/Map/Hatch), over a darkened ground, laid on LibVGA's map canvas over everything outside the rectangle its owner names - the zone in view -, in four bands round it, none where no rectangle is named. The unexplored inside a zone takes the same hatch once the game's explored pieces or vga.ui's own data name it (K0815).

-- {K0815} {K0812}

local library = LibVGA
local DARK = 0.45
local HATCH_ALPHA = 0.35
local BANDS = 4

local function create_band(holder)
    local band = holder:CreateTexture(nil, "ARTWORK")
    band:SetColorTexture(0, 0, 0, DARK)
    band.hatch = holder:CreateTexture(nil, "ARTWORK", nil, 1)
    band.hatch:SetTexture(library.media .. "Map\\Hatch", "REPEAT", "REPEAT")
    band.hatch:SetHorizTile(true)
    band.hatch:SetVertTile(true)
    band.hatch:SetAlpha(HATCH_ALPHA)
    band.hatch:SetAllPoints(band)
    return band
end

function library.create_map_fog(canvas)
    local fog = { canvas = canvas, bands = {} }
    fog.holder = CreateFrame("Frame", nil, canvas)
    fog.holder:SetAllPoints()
    fog.holder:SetFrameLevel(canvas:GetFrameLevel() + 1)
    for index = 1, BANDS do fog.bands[index] = create_band(fog.holder) end
    return fog
end

local function update_band(fog, band, box)
    local shown = box[3] > box[1] and box[4] > box[2]
    band:SetShown(shown)
    band.hatch:SetShown(shown)
    if not shown then return end
    band:ClearAllPoints()
    band:SetPoint("TOPLEFT", fog.canvas, "TOPLEFT", box[1], -box[2])
    band:SetSize(box[3] - box[1], box[4] - box[2])
end

local function read_boxes(fog, rect)
    local canvas = fog.canvas
    local left, top = library.read_map_view(canvas)
    local width, height, zoom = canvas:GetWidth(), canvas:GetHeight(), canvas.zoom
    local x0 = math.max(0, math.min(width, (rect[1] - left) * zoom))
    local x1 = math.max(0, math.min(width, (rect[2] - left) * zoom))
    local y0 = math.max(0, math.min(height, (rect[3] - top) * zoom))
    local y1 = math.max(0, math.min(height, (rect[4] - top) * zoom))
    return { { 0, 0, width, y0 }, { 0, y1, width, height }, { 0, y0, x0, y1 }, { x1, y0, width, y1 } }
end

function library.update_map_fog(fog, rect)
    local boxes = rect and read_boxes(fog, rect)
    for index, band in ipairs(fog.bands) do update_band(fog, band, boxes and boxes[index] or { 0, 0, 0, 0 }) end
end
