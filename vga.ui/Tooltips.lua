-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: Blizzard's tooltips as the accepted template draws .vt-tip (manual/view/vga-template.css): Blizzard's frame hidden, a rounded dark ground at a fixed 0.95 inside a black line and a grey rim, the small gold corner, the texts in Geologica; embedded tooltips left as they are, and a tooltip laid bare inside a window of ours - the fixed item tooltip's lines - without any frame or corner (K0756), each piece of our skin's surfaces hidden on its own (K0758).

-- {K0260} {K0340} {K0756} {K0758}

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

local function update_skin(tip, _, embedded)
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

local function update_skin_safely(tip, style, embedded)
    library.update_safely("tooltip", update_skin, tip, style, embedded)
end

local function update_fonts()
    local plain, size = library.read_font("body"):GetFont()
    local bold = library.read_font("bold"):GetFont()
    local shapes = {
        { GameTooltipHeaderText, bold, library.read_size(1) },
        { GameTooltipText, plain, size },
        { GameTooltipTextSmall, plain, library.read_size(-1) },
    }
    for _, shape in ipairs(shapes) do
        if shape[1] then shape[1]:SetFont(shape[2], shape[3], "") end
    end
end

local function update_tooltips()
    update_fonts()
    for _, tip in ipairs({ GameTooltip, ItemRefTooltip, ShoppingTooltip1, ShoppingTooltip2 }) do
        if tip then update_skin_safely(tip) end
    end
end

if SharedTooltip_SetBackdropStyle then
    hooksecurefunc("SharedTooltip_SetBackdropStyle", update_skin_safely)
end
for _, tip in ipairs({ GameTooltip, ItemRefTooltip, ShoppingTooltip1, ShoppingTooltip2 }) do
    if tip then tip:HookScript("OnShow", update_skin_safely) end
end
library.create_element("tooltips", { update = update_tooltips })
