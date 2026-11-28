-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: the discovery toast (K1037), LibVGA's toast of the kind »discovery«, gold rimmed with the book ornament above and beneath (Z1 of manual/view/vga-toast-colours.html), silenced by its switch on the tab »Hinweise« (K1035): an area the player discovers is told »Entdeckt: <Gebiet>«, the experience it gave beneath, »+120 EP«. Read from the game's own sentence of it in the player's language - with experience (ERR_ZONE_EXPLORED_XP) or without (ERR_ZONE_EXPLORED), read by vga.read_game_sentence - in the system chat or the game's info message, whichever brings it (CHAT_MSG_SYSTEM, UI_INFO_MESSAGE); which of them Forever sends is not yet measured, so both are heard and one discovery told once. The picture is the game's map, not yet seen in Forever.

-- {K1037} {K1035} {K1034}

local _, vga = ...
local library = LibVGA
local PICTURE = "Interface\\Icons\\INV_Misc_Map_01"
local SAME = 3
local last = {}

local function read_discovery(message)
    local words = vga.read_game_sentence(ERR_ZONE_EXPLORED_XP, message)
    if words then return words[1], tonumber(words[2]) end
    words = vga.read_game_sentence(ERR_ZONE_EXPLORED, message)
    if words then return words[1] end
end

local function check_new(area)
    local now = GetTime()
    if last.area == area and now - last.at < SAME then return false end
    last.area, last.at = area, now
    return true
end

local function render_discovery(message)
    local area, points = read_discovery(message)
    if not area or not check_new(area) then return end
    local texts = library.texts
    library.render_toast({ head = texts.discovery_title, line = string.format(texts.discovery_line, area), second = points and string.format(texts.discovery_xp, points), picture = PICTURE, kind = "discovery", ornate = true })
end

local function render_from_message(_, message)
    render_discovery(message)
end

local HEARD = { CHAT_MSG_SYSTEM = render_discovery, UI_INFO_MESSAGE = render_from_message }

local events = CreateFrame("Frame")
library.update_events(events, { "CHAT_MSG_SYSTEM", "UI_INFO_MESSAGE" })
events:SetScript("OnEvent", function(_, event, first, second) library.update_safely("discovery toast " .. event, HEARD[event], first, second) end)
