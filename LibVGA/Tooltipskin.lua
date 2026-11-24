-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's tooltip skin, as the accepted template draws .vt-tip (manual/view/vga-template.css, K0340) and the catalogue names it (K0775): a game tooltip's own frame hidden, a rounded dark ground at a fixed 0.95 inside a black line and a grey rim, the small gold corner; embedded tooltips left as they are; a tooltip laid bare inside a window of ours - the fixed item tooltip's lines - without any frame or corner (K0756), each piece of the skin's surfaces hidden on its own (K0758). Moved here from vga.ui's Tooltips.lua, which only hooks the game's tooltips to it (K0795).

-- {K0795} {K0340} {K0756} {K0758} {K0775}

local library = LibVGA
local colours = library.colours
local TIP_GROUND = 0.95
local GROUND_TOP = { 0.071, 0.075, 0.09 }
local GROUND_BOTTOM = { 0.043, 0.047, 0.059 }
local BLACK = { 0, 0, 0 }
local skins = setmetatable({}, { __mode = "k" })

local function create_skin(tip)
    local skin = {
        rim = library.create_surface(tip, "BACKGROUND", -8),
        line = library.create_surface(tip, "BACKGROUND", -7),
        ground = library.create_surface(tip, "BACKGROUND", -6),
        corner = tip:CreateTexture(nil, "OVERLAY"),
    }
    skin.corner:SetTexture(library.media .. "GoldCornerSmall")
    skin.corner:SetVertexColor(unpack(colours.gold))
    skins[tip] = skin
    return skin
end

function library.update_tooltip_bare(tip)
    tip.vga_bare = true
    if type(tip.NineSlice) == "table" then tip.NineSlice:SetAlpha(0) end
    local skin = skins[tip]
    if not skin then return end
    for _, part in pairs(skin) do
        if part.pieces then
            for _, piece in pairs(part.pieces) do piece:Hide() end
        else
            part:Hide()
        end
    end
end

function library.check_tooltip_skinned(tip)
    local skin = skins[tip]
    return skin ~= nil and (skin.corner:IsShown() or skin.ground.pieces.MIDDLE:IsShown())
end

function library.update_tooltip_skin(tip, _, embedded)
    if tip.vga_bare then return library.update_tooltip_bare(tip) end
    if embedded or tip.IsEmbedded or not tip.NineSlice then return end
    local skin = skins[tip] or create_skin(tip)
    tip.NineSlice:SetAlpha(0)
    local radius = library.read_size(-2)
    library.update_surface(skin.rim, -2, radius + 2, colours.edge, colours.edge, TIP_GROUND)
    library.update_surface(skin.line, -1, radius + 1, BLACK, BLACK, TIP_GROUND)
    library.update_surface(skin.ground, 0, radius, GROUND_TOP, GROUND_BOTTOM, TIP_GROUND)
    local corner = library.read_size(0)
    skin.corner:SetSize(corner, corner)
    skin.corner:ClearAllPoints()
    skin.corner:SetPoint("TOPRIGHT", tip, "TOPRIGHT", -library.read_size(-6), -library.read_size(-6))
end
