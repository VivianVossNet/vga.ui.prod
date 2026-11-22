-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: The threat the player draws from the target, as five flat pills under the target frame's power bar, halfway between the bar and the frame's lower edge, as the rogue's combo points stand on the player frame (Combo.lua): each pill lit whole once the threat passes the start of its fifth, every one red, only their number telling how much (K0751), an open pill dark, each in a black line; set by the game from the value even where it is secret, each pill's range a hundredth wide. The row's room is kept on the target frame, so nothing moves; the pills show only while the player stands on the target's threat list.

-- {K0751} {K0344} {K0356} {K0357} {K0366} {K0480}

local library = LibVGA
local STEP = 0.01
local POINTS = 5
local OPEN = { 0.2, 0.21, 0.24 }
local EDGE = { 0, 0, 0 }
local row

local function read_sizes()
    local height = library.read_size(-5)
    return 3 * height, height, library.read_size(-6)
end

local function read_drop(frame, height, between)
    local bar_foot, frame_foot = frame.power:GetBottom(), frame:GetBottom()
    if not (bar_foot and frame_foot) or bar_foot - frame_foot <= height then return between end
    return math.floor((bar_foot - frame_foot - height) / 2 + 0.5)
end

local function create_pill(frame, index, top)
    local pill = CreateFrame("Frame", nil, frame)
    pill.edge = library.create_surface(pill, "ARTWORK", 0)
    pill.back = library.create_surface(pill, "ARTWORK", 1)
    pill.fill = CreateFrame("StatusBar", nil, pill)
    pill.fill:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    pill.fill:GetStatusBarTexture():SetGradient("VERTICAL", library.create_colour({ top[1] * 0.62, top[2] * 0.62, top[3] * 0.62 }), library.create_colour(top))
    pill.fill:SetMinMaxValues(20 * (index - 1), 20 * (index - 1) + STEP)
    pill.fill:SetValue(0)
    return pill
end

local function create_row()
    local frame = VGAUnitFrame_target
    if not (frame and frame.power) then return end
    row = {}
    for index = 1, POINTS do row[index] = create_pill(frame, index, library.colours.threat) end
    local _, height, between = read_sizes()
    frame.extra_height = height + between
end

local function update_row_layout()
    local frame = VGAUnitFrame_target
    if not (row and frame) then return end
    local width, height, between = read_sizes()
    local gap = library.read_size(-6)
    local span = POINTS * width + (POINTS - 1) * gap
    frame.extra_height = height + between
    local drop = read_drop(frame, height, between)
    for index, pill in ipairs(row) do
        pill:SetSize(width, height)
        pill:ClearAllPoints()
        pill:SetPoint("TOPLEFT", frame.power, "BOTTOM", -span / 2 + (index - 1) * (width + gap), -drop)
        library.update_surface(pill.edge, -1, height / 2 + 1, EDGE, EDGE)
        library.update_surface(pill.back, 0, height / 2, OPEN, OPEN)
        pill.fill:SetAllPoints()
    end
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
