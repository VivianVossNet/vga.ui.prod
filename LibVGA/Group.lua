-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's group as the accepted draft draws .grp (manual/view/vga-auctions.html, K0632): a rounded box of ten draft pixels, its ground a faint white over the window's, inside a fine line; whatever belongs together - a list, the figures, a graph, a row of controls - stands in one, the group at its parent's own frame level, so the parent's other children lie above it and are never covered (K0634); its hairlines between rows in the darker line.

-- {K0632} {K0634}

local library = LibVGA
local DRAFT_BASE = 13
local RADIUS = 10
local GROUND = { 0.091, 0.095, 0.106 }
local LINE = { 0.137, 0.149, 0.173 }
local HAIRLINE = { 0.122, 0.133, 0.153 }

local function read_draft(pixels)
    return math.floor(pixels * library.read_base() / DRAFT_BASE + 0.5)
end

function library.create_group(parent)
    local group = CreateFrame("Frame", nil, parent)
    group:SetFrameLevel(parent:GetFrameLevel())
    group.edge = library.create_surface(group, "BACKGROUND", 0)
    group.ground = library.create_surface(group, "BACKGROUND", 1)
    return group
end

function library.update_group(group)
    local radius = read_draft(RADIUS)
    library.update_surface(group.edge, 0, radius, LINE, LINE)
    library.update_surface(group.ground, 1, radius - 1, GROUND, GROUND)
end

function library.create_hairline(parent)
    local line = parent:CreateTexture(nil, "BORDER")
    line:SetColorTexture(HAIRLINE[1], HAIRLINE[2], HAIRLINE[3], 1)
    return line
end

function library.read_draft_size(pixels)
    return read_draft(pixels)
end
