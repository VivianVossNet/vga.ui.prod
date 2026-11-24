-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: The combo points of a rogue, and of a druid in cat form - in Forever they stay on the foe they were gained on, kept there when the target changes, gone when it dies -: the points on the current target earned in VGA's orange, points still held on another foe, read from the player's power, as dimmed orange beyond them, so a turn back is seen to pay -, on the player frame: a row of five flat pills centred under the power bar, halfway between the bar and the frame's lower edge, the earned ones in VGA's orange, the open ones dark, each in a black line; the frame's lines are centred anew with the row's room kept for these classes alone, so a druid's change of form moves nothing; Blizzard's own combo frame stays hidden.

-- {K0795} {K0416} {K0417} {K0420} {K0502} {K0520} {K0532}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local COMBO = Enum and Enum.PowerType and Enum.PowerType.ComboPoints or 4
local ENERGY = 3
local POINTS = 5
local OPEN = { 0.2, 0.21, 0.24 }
local OPEN_LOW = { 0.11, 0.12, 0.14 }
local HELD = { 0.42, 0.25, 0.1 }
local HELD_LOW = { 0.25, 0.14, 0.06 }
local KEEPING = { ROGUE = true, DRUID = true }
local row

local function check_keeping()
    local _, class = UnitClass("player")
    return KEEPING[class or ""] == true
end

local function check_shown()
    local _, class = UnitClass("player")
    if class == "ROGUE" then return true end
    return class == "DRUID" and UnitPowerType("player") == ENERGY
end

local function read_known(ran, points)
    if not ran or type(points) ~= "number" or (issecretvalue and issecretvalue(points)) then return nil end
    return points
end

function vga.read_combo_points()
    local ran, points = pcall(UnitPower, "player", COMBO)
    if not check_shown() then return nil end
    local held = read_known(ran, points)
    local on_target = GetComboPoints and read_known(pcall(GetComboPoints, "player", "target"))
    if not (held or on_target) then return nil end
    if not on_target then return held, held end
    return on_target, math.max(held or 0, on_target)
end

local function update_pill(pill, earned, held)
    local top, bottom = OPEN, OPEN_LOW
    if held then top, bottom = HELD, HELD_LOW end
    if earned then top, bottom = colours.orange, colours.orange_low end
    library.update_pill_shade(pill, top, bottom)
end

local function update_row()
    if not row then return end
    local frame = VGAUnitFrame_player
    local shown = check_shown()
    local points, held = vga.read_combo_points()
    points, held = points or 0, held or 0
    frame.extra_height = library.update_pills(row, frame.power)
    for index, pill in ipairs(row) do
        update_pill(pill, index <= points, index <= held)
        pill:SetShown(shown)
    end
end

local function update_row_safely()
    library.update_safely("combo points", update_row)
end

local function create_row()
    local frame = VGAUnitFrame_player
    if not (frame and frame.power and check_keeping()) then return end
    row = library.create_pills(frame, { count = POINTS })
    frame.extra_height = library.read_pills_room()
    library.create_element("combo", { update = update_row })
    library.update_elements()
end

local events = CreateFrame("Frame")
for _, name in ipairs({ "PLAYER_LOGIN", "UNIT_POWER_UPDATE", "UNIT_DISPLAYPOWER", "UNIT_MAXPOWER", "PLAYER_TARGET_CHANGED" }) do
    events:RegisterEvent(name)
end
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        library.update_safely("combo points login", create_row)
    else
        update_row_safely()
    end
end)
