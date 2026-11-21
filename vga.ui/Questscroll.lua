-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: The quest tracker's body as a scrolling list (K0548): the tracker is at most as high as the settings' slider says - between a fifth and half of the screen's height, half by default (K0550) -, smaller where its quests need less; a longer list scrolls under the head, the foot staying beneath, in LibVGA's scrolling body (LibVGA/Scroll.lua, K0631), its slender bar and its wheel. Quests.lua lays the rows into the body; Questzones.lua's labels too.

-- {K0548} {K0631}

local _, vga = ...
local library = LibVGA
local SHARE = 0.5

function vga.create_quest_body(tracker)
    return library.create_scroll(tracker)
end

function vga.read_quest_room(tracker)
    local screen = UIParent:GetHeight() * UIParent:GetEffectiveScale() / tracker:GetEffectiveScale()
    return math.floor(screen * (vga.read_quest_most_height and vga.read_quest_most_height() or SHARE))
end

function vga.update_quest_body(tracker, head, length, width, foot)
    local body = tracker.body
    local room = math.max(math.min(length, vga.read_quest_room(tracker) - head - foot), 0)
    body:ClearAllPoints()
    body:SetPoint("TOPLEFT", tracker, "TOPLEFT", 0, -head)
    library.update_scroll(body, width, room, length)
    return room
end
