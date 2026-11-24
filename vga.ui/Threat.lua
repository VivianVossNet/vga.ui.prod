-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: The threat the player draws from the target, as five flat pills under the target frame's power bar, halfway between the bar and the frame's lower edge, as the rogue's combo points stand on the player frame (Combo.lua): each pill lit whole once the threat passes the start of its fifth, every one red, only their number telling how much (K0751), an open pill dark, each in a black line; set by the game from the value even where it is secret, each pill's range a hundredth wide. The row's room is kept on the target frame, so nothing moves; the pills show only while the player stands on the target's threat list.

-- {K0795} {K0782} {K0751} {K0344} {K0356} {K0357} {K0366} {K0480}

local library = LibVGA
local STEP = 0.01
local POINTS = 5
local row

local function create_row()
    local frame = VGAUnitFrame_target
    if not (frame and frame.power) then return end
    row = library.create_pills(frame, { count = POINTS, fill = library.colours.threat })
    for index, pill in ipairs(row) do
        pill.fill:SetMinMaxValues(20 * (index - 1), 20 * (index - 1) + STEP)
        pill.fill:SetValue(0)
    end
    frame.extra_height = library.read_pills_room()
end

local function update_row_layout()
    local frame = VGAUnitFrame_target
    if not (row and frame) then return end
    frame.extra_height = library.update_pills(row, frame.power)
end

local function update_row_value()
    if not row then return end
    local status = UnitExists("target") and UnitThreatSituation("player", "target")
    local listed = (issecretvalue and issecretvalue(status)) or status ~= nil
    local shown = UnitExists("target") and UnitCanAttack("player", "target") and listed
    local _, _, share = UnitDetailedThreatSituation("player", "target")
    for _, pill in ipairs(row) do
        pill:SetShown(shown and true or false)
        pill.fill:SetValue(shown and share or 0)
    end
end

local function update_threat()
    update_row_layout()
    update_row_value()
end

local function update_event(event)
    if event == "PLAYER_LOGIN" then
        create_row()
        library.create_element("threat", { update = update_threat })
        library.update_elements()
    else
        update_row_value()
    end
end

local events = CreateFrame("Frame")
for _, name in ipairs({ "PLAYER_LOGIN", "PLAYER_TARGET_CHANGED", "UNIT_THREAT_LIST_UPDATE", "UNIT_THREAT_SITUATION_UPDATE" }) do
    pcall(events.RegisterEvent, events, name)
end
events:SetScript("OnEvent", function(_, event)
    library.update_safely("threat " .. event, update_event, event)
end)
