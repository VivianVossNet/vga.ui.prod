-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's plain fill: the game's status bar with nothing round it - white or a picture of its owner's, as an arc's segment -, coloured flat or shaded from its lower colour to its upper, with an alpha; where asked, a slanted shine clipped to what is filled, swept by its owner. It is what LibVGA's rounded bar (library.create_bar) and its two shadows are made of, and what a fill of its own needs - an arc's segment, the rested share of the experience bar, the friend plate's health and cast, a threat pill (K0782).

-- {K0782} {K0765}

local library = LibVGA
local WHITE = "Interface\\Buttons\\WHITE8X8"

local function create_shine(fill)
    fill.clip = CreateFrame("Frame", nil, fill)
    fill.clip:SetPoint("TOPLEFT")
    fill.clip:SetPoint("BOTTOMRIGHT", fill:GetStatusBarTexture(), "BOTTOMRIGHT")
    fill.clip:SetClipsChildren(true)
    fill.shine = fill.clip:CreateTexture(nil, "OVERLAY")
    fill.shine:SetTexture(library.media .. "Shine")
    fill.shine:SetBlendMode("ADD")
    fill.shine:Hide()
end

function library.create_fill(parent, plan)
    local fill = CreateFrame("StatusBar", nil, parent)
    fill:SetStatusBarTexture(plan and plan.picture or WHITE)
    if plan and plan.shine then create_shine(fill) end
    return fill
end

function library.update_fill_colour(fill, top, bottom, alpha)
    if not bottom then return fill:SetStatusBarColor(top[1], top[2], top[3], alpha or 1) end
    local lower = CreateColor(bottom[1], bottom[2], bottom[3], alpha or 1)
    local upper = CreateColor(top[1], top[2], top[3], alpha or 1)
    fill:GetStatusBarTexture():SetGradient("VERTICAL", lower, upper)
end
