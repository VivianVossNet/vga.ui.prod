-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's cooldown, as the accepted catalogue names it (manual/view/vga-catalogue.html, K0775): the game's own cooldown frame in one of two kinds - »veil«, the game's dark sweep over a key's picture, laid up to the inner side of the cell's edge (library.update_cell_picture), and »ring«, an aura's drain, the ring picture swept backwards round the aura without edge, flash or figures, above the aura's own parts (K0781). Its owner tells it when a cooldown started and how long it lasts, or hands it to the game's own aura button, which drives it. A progress ring (library.create_progress_ring, library.update_progress_ring) is the aura's ring standing still: the ring darkened beneath, the full colour swept clockwise from the top as far as a share reaches, by a cooldown so long it never moves - a pet's experience round its portrait (K0999).

-- {K0999} {K0781} {K0775}

local library = LibVGA
local STILL = 10000000
local SPENT = 0.32

local function create_ring(parent)
    local cooldown = CreateFrame("Cooldown", nil, parent)
    cooldown:SetFrameLevel(parent:GetFrameLevel() + 2)
    cooldown:SetSwipeTexture(library.media .. "AuraRing")
    cooldown:SetDrawEdge(false)
    cooldown:SetDrawBling(false)
    cooldown:SetHideCountdownNumbers(true)
    cooldown:SetReverse(true)
    return cooldown
end

function library.create_cooldown(parent, kind)
    if kind == "ring" then return create_ring(parent) end
    return CreateFrame("Cooldown", nil, parent, "CooldownFrameTemplate")
end

function library.update_cooldown(cooldown, start, duration)
    if start and duration then cooldown:SetCooldown(start, duration) end
end

function library.create_progress_ring(parent, around)
    local base = parent:CreateTexture(nil, "OVERLAY", nil, 4)
    base:SetTexture(library.media .. "AuraRing")
    base:SetAllPoints(around)
    local drawn = create_ring(parent)
    drawn:SetFrameLevel(parent:GetFrameLevel() + 1)
    drawn:SetAllPoints(around)
    return { base = base, drawn = drawn }
end

function library.update_progress_ring(ring, share, colour)
    local shown = share ~= nil
    ring.base:SetShown(shown)
    ring.drawn:SetShown(shown)
    if not shown then return end
    ring.base:SetVertexColor(colour[1] * SPENT, colour[2] * SPENT, colour[3] * SPENT, 1)
    ring.drawn:SetSwipeColor(colour[1], colour[2], colour[3], 1)
    ring.drawn:SetCooldown(GetTime() - share * STILL, STILL)
end
