-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: A compass rose in the minimap, simply white with thin lines: only north, east, south and west, each a very short tick at the visible map's edge and its letter just inside it, in the reader's language; turning with the player when the game turns the minimap. Its turn and its reach to the map's edge are lent to the rim triangle, so it follows the compass (vga.read_compass_turn, vga.read_compass_reach, K0982).

-- {K0982} {K0439} {K0441}

local _, vga = ...
local library = LibVGA
local TICK = 6
local EDGE = 2
local LETTER_ROOM = 8
local LINE_ALPHA = 0.6
local LETTER_ALPHA = 0.85
local EVERY = 0.05
local rose

local read_draft = library.read_draft_size

local function read_turn()
    if GetCVar and GetCVar("rotateMinimap") == "1" and GetPlayerFacing then return -(GetPlayerFacing() or 0) end
    return 0
end

local function read_reach(across, down, half_width, half_height)
    local reach_x = across ~= 0 and half_width / math.abs(across) or math.huge
    local reach_y = down ~= 0 and half_height / math.abs(down) or math.huge
    return math.min(reach_x, reach_y)
end

local function update_point(index, turn, half_width, half_height)
    local angle = (index - 1) * math.pi / 2 + turn
    local across, down = math.sin(angle), math.cos(angle)
    local reach = read_reach(across, down, half_width, half_height)
    local line, letter = rose.lines[index], rose.letters[index]
    local tick, room = read_draft(TICK), read_draft(LETTER_ROOM)
    line:SetStartPoint("CENTER", rose, across * reach, down * reach)
    line:SetEndPoint("CENTER", rose, across * (reach - tick), down * (reach - tick))
    letter:ClearAllPoints()
    letter:SetPoint("CENTER", rose, "CENTER", across * (reach - tick - room), down * (reach - tick - room))
end

local function update_rose()
    if not rose then return end
    local half_width, half_height = rose:GetWidth() / 2 - read_draft(EDGE), rose:GetHeight() / 2 - read_draft(EDGE)
    local turn = read_turn()
    for index = 1, 4 do update_point(index, turn, half_width, half_height) end
    for _, letter in ipairs(rose.letters) do letter:SetFontObject(library.read_font("caption")) end
end

local function update_rose_safely(_, elapsed)
    rose.since = (rose.since or 0) + elapsed
    if rose.since < EVERY then return end
    rose.since = 0
    library.update_safely("map rose", update_rose)
end

vga.read_compass_turn = read_turn
vga.read_compass_reach = read_reach

function vga.create_map_rose(view)
    rose = CreateFrame("Frame", nil, view)
    rose:SetAllPoints()
    rose:SetFrameLevel(Minimap:GetFrameLevel() + 2)
    rose.lines, rose.letters = {}, {}
    for index, word in ipairs(library.texts.compass) do
        local line = rose:CreateLine(nil, "ARTWORK")
        line:SetThickness(1)
        line:SetColorTexture(1, 1, 1, LINE_ALPHA)
        rose.lines[index] = line
        local letter = library.create_text(rose, "caption", { 1, 1, 1 })
        letter:SetText(word)
        letter:SetAlpha(LETTER_ALPHA)
        rose.letters[index] = letter
    end
    rose:SetScript("OnUpdate", update_rose_safely)
end

vga.update_map_rose = update_rose
