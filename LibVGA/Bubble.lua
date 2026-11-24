-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's speech bubble, as the accepted draft draws it (manual/view/vga-npc-chat.html, K0840): words on aged parchment with its edge darkened inside, corners of sixteen draft pixels and the tail's corner of five at the side it speaks from - bottom left for the figure, bottom right for the player -; the figure's bubble the parchment itself with dark brown ink, the player's the same parchment laid over our gold. Its rim is cut by texture coordinates from Media/Bubble.tga, its middle is Media/Parchment.tga repeated, both made by tools/bubble/bubble.py from a parchment made by Gemini. The words wrap at the widest the owner allows, the bubble is as wide as its longest line and twelve draft pixels to each side, eight above and below. Its ground alone may also be laid at a size its owner gives, without a tail and in a tint of its own - the conversation's green bubble of the tick, »Quest angenommen«, across the course (library.update_bubble_ground, K0859).

-- {K0859} {K0840}

local library = LibVGA
local colours = library.colours
local CORNER = 16
local SIDE = 12
local ABOVE = 8
local TILE = 160
local ATLAS_WIDTH, ATLAS_HEIGHT = 512, 256
local SHAPE = 256
local CUT = 32
local STRIP = 112
local TAIL_SHIFT = 256
local WHITE = { 1, 1, 1 }
local INK = { 0.165, 0.118, 0.055 }
local PIECES = { "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT", "TOP", "BOTTOM", "LEFT", "RIGHT" }
local CORNERS = { TOPLEFT = true, TOPRIGHT = true, BOTTOMLEFT = true, BOTTOMRIGHT = true }
local CUTS = {
    TOPLEFT = { 0, 0, CUT, CUT }, TOPRIGHT = { SHAPE - CUT, 0, SHAPE, CUT },
    BOTTOMLEFT = { 0, SHAPE - CUT, CUT, SHAPE }, BOTTOMRIGHT = { SHAPE - CUT, SHAPE - CUT, SHAPE, SHAPE },
    TOP = { STRIP, 0, SHAPE - STRIP, CUT }, BOTTOM = { STRIP, SHAPE - CUT, SHAPE - STRIP, SHAPE },
    LEFT = { 0, STRIP, CUT, SHAPE - STRIP }, RIGHT = { SHAPE - CUT, STRIP, SHAPE, SHAPE - STRIP },
}

function library.create_bubble(parent)
    local bubble = CreateFrame("Frame", nil, parent)
    bubble.pieces = {}
    for _, name in ipairs(PIECES) do
        local piece = bubble:CreateTexture(nil, "BACKGROUND", nil, 1)
        piece:SetTexture(library.media .. "Bubble")
        bubble.pieces[name] = piece
    end
    bubble.middle = bubble:CreateTexture(nil, "BACKGROUND", nil, 0)
    bubble.middle:SetTexture(library.media .. "Parchment", "REPEAT", "REPEAT")
    bubble.words = library.create_text(bubble, "body", INK)
    bubble.words:SetJustifyH("LEFT")
    bubble.words:SetWordWrap(true)
    return bubble
end

local function update_cut(piece, cut, shift)
    piece:SetTexCoord((cut[1] + shift) / ATLAS_WIDTH, (cut[3] + shift) / ATLAS_WIDTH, cut[2] / ATLAS_HEIGHT, cut[4] / ATLAS_HEIGHT)
end

local function update_pieces(bubble, tail, tint, height)
    local corner = math.min(library.read_whole_pixels(library.read_draft_size(CORNER), bubble), math.floor(height / 2))
    local pieces = bubble.pieces
    bubble.tail = tail
    for _, name in ipairs(PIECES) do
        local piece = pieces[name]
        piece:ClearAllPoints()
        update_cut(piece, CUTS[name], name == tail and TAIL_SHIFT or 0)
        piece:SetVertexColor(tint[1], tint[2], tint[3], 1)
        if CORNERS[name] then
            piece:SetSize(corner, corner)
            piece:SetPoint(name, bubble, name)
        end
    end
    pieces.TOP:SetPoint("TOPLEFT", pieces.TOPLEFT, "TOPRIGHT")
    pieces.TOP:SetPoint("BOTTOMRIGHT", pieces.TOPRIGHT, "BOTTOMLEFT")
    pieces.BOTTOM:SetPoint("TOPLEFT", pieces.BOTTOMLEFT, "TOPRIGHT")
    pieces.BOTTOM:SetPoint("BOTTOMRIGHT", pieces.BOTTOMRIGHT, "BOTTOMLEFT")
    pieces.LEFT:SetPoint("TOPLEFT", pieces.TOPLEFT, "BOTTOMLEFT")
    pieces.LEFT:SetPoint("BOTTOMRIGHT", pieces.BOTTOMLEFT, "TOPRIGHT")
    pieces.RIGHT:SetPoint("TOPLEFT", pieces.TOPRIGHT, "BOTTOMLEFT")
    pieces.RIGHT:SetPoint("BOTTOMRIGHT", pieces.BOTTOMRIGHT, "TOPRIGHT")
    bubble.middle:ClearAllPoints()
    bubble.middle:SetPoint("TOPLEFT", pieces.TOPLEFT, "BOTTOMRIGHT")
    bubble.middle:SetPoint("BOTTOMRIGHT", pieces.BOTTOMRIGHT, "TOPLEFT")
    bubble.middle:SetVertexColor(tint[1], tint[2], tint[3], 1)
    return corner
end

function library.read_bubble_text_width(most)
    return most - 2 * library.read_draft_size(SIDE)
end

function library.update_bubble(bubble, words, side, most)
    local text, inside = bubble.words, library.read_bubble_text_width(most)
    local player = side == "right"
    text:SetFontObject(library.read_font("body"))
    text:SetTextColor(INK[1], INK[2], INK[3], 1)
    text:SetWidth(inside)
    text:SetText(words)
    local wide = math.min(inside, math.ceil(library.read_string_width(text)))
    text:SetWidth(wide)
    local side_room, above = library.read_draft_size(SIDE), library.read_draft_size(ABOVE)
    local least = 2 * library.read_whole_pixels(library.read_draft_size(CORNER), bubble)
    local width = math.max(wide + 2 * side_room, least)
    local height = math.max(math.ceil(library.read_string_height(text)) + 2 * above, least)
    library.update_bubble_ground(bubble, width, height, player and "BOTTOMRIGHT" or "BOTTOMLEFT", player and colours.parchment_gold or WHITE)
    text:ClearAllPoints()
    text:SetPoint("LEFT", bubble, "LEFT", side_room, 0)
    return width, height
end

function library.update_bubble_ground(bubble, width, height, tail, tint)
    local corner = update_pieces(bubble, tail or "none", tint, height)
    bubble:SetSize(width, height)
    local tile = library.read_draft_size(TILE)
    bubble.middle:SetTexCoord(0, math.max(width - 2 * corner, 0) / tile, 0, math.max(height - 2 * corner, 0) / tile)
end
