-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.ui's player frame, target frame and pet frames, each where Blizzard's own stands in the player's layout, and the target of target beside the target frame; each fills LibVGA's unit frame (library.create_unit_frame, K0864): the player as the primary tier left-aligned, the target as the primary tier mirrored to it, the player's pet and the target's pet as the secondary tier mirrored below them, the target of target as the tertiary tier - a party member's row - mirrored, on a line with the target frame at its right, a place of its own to be moved (K0698). What is the game's and the place's stays here: which units have a frame, their places, Blizzard's own frames hidden, the events that fill them, the shine of a gain on the player's bars, the player's pulse in a fight or a resting place (K0551), and the target of target shown only while the game's own setting »Ziel des Ziels« (showTargetOfTarget) is on, which the units' settings switch too; the target's pet and the target of target read anew five times a second, since the game sends no events for those units (K0696).

-- {K0999} {K0865} {K0864} {K0789} {K0481} {K0551} {K0267} {K0268} {K0275} {K0276} {K0294} {K0297} {K0299} {K0300} {K0302} {K0329} {K0330} {K0334} {K0342} {K0345} {K0346} {K0360} {K0614} {K0724} {K0696} {K0698} {K0702} {K0717}

local _, vga = ...
local library = LibVGA
local frames = {}
local target_target
local SLIM = "targettarget"
local TICK = 0.2
local GAINS = {
    HEAL = "health", HEAL_CRIT = "health", PERIODIC_HEAL = "health", PERIODIC_HEAL_CRIT = "health",
    ENERGIZE = "power", PERIODIC_ENERGIZE = "power",
}

local function create_unit(unit, plan)
    plan.widget = "units"
    local frame = library.create_unit_frame("VGAUnitFrame_" .. unit, unit, plan)
    frames[unit] = frame
    return frame
end

local update_target_target_shown
local update_watched_units
local update_target_target_layout

local function update_units()
    update_target_target_layout()
    for _, frame in pairs(frames) do
        if not InCombatLockdown() then
            library.update_unit_frame_layout(frame)
        end
        library.update_unit_frame(frame)
        library.update_unit_frame_values(frame)
    end
end

local function delete_blizzard_frames()
    for _, blizzard in ipairs({ PlayerFrame, TargetFrame, PetFrame, ComboFrame }) do
        if blizzard then
            blizzard:UnregisterAllEvents()
            blizzard:Hide()
            blizzard:SetAlpha(0)
        end
    end
end

function update_target_target_shown()
    local frame = target_target
    if not frame or InCombatLockdown() then return end
    if GetCVarBool("showTargetOfTarget") then
        if not frame.unit_watched then RegisterUnitWatch(frame) end
        frame.unit_watched = true
    else
        if frame.unit_watched then UnregisterUnitWatch(frame) end
        frame.unit_watched = false
        frame:Hide()
    end
end

function update_watched_units()
    local pet = frames.targetpet
    if pet and pet:IsShown() then
        library.update_unit_frame(pet)
        library.update_unit_frame_values(pet)
    end
    if target_target and target_target:IsShown() then library.update_unit_frame(target_target) end
end

function update_target_target_layout()
    if not target_target or InCombatLockdown() then return end
    library.update_unit_frame_layout(target_target)
end

local function create_target_target()
    target_target = library.create_unit_frame("VGAUnitFrame_" .. SLIM, SLIM, { tier = "tertiary", side = "right", widget = "units" })
    return target_target
end

function vga.update_target_target_shown()
    update_target_target_shown()
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("CVAR_UPDATE")
local function update_event(event, unit)
    if event == "PLAYER_LOGIN" then
        local player = create_unit("player", { tier = "primary", side = "left", always = true, glow = true })
        library.create_place(player, "player", "CENTER", PlayerFrame or UIParent, 0, 0)
        local target = create_unit("target", { tier = "primary", side = "right", kind = true })
        library.create_place(target, "target", "CENTER", TargetFrame or UIParent, 0, 0)
        local pet = create_unit("pet", { tier = "secondary", side = "right", experience = true })
        library.create_place(pet, "pet", "TOPRIGHT", player, 0, -(library.read_cast_room() + 2 * library.read_size(-4)), "BOTTOMRIGHT")
        local target_pet = create_unit("targetpet", { tier = "secondary", side = "right" })
        library.create_place(target_pet, "targetpet", "TOPRIGHT", target, 0, -(library.read_cast_room() + 2 * library.read_size(-4)), "BOTTOMRIGHT")
        library.create_place(create_target_target(), SLIM, "LEFT", target, library.read_size(0), 0, "RIGHT")
        update_target_target_shown()
        C_Timer.NewTicker(TICK, function() library.update_safely("units watched", update_watched_units) end)
        delete_blizzard_frames()
        library.create_element("units", { title = UNITFRAME_LABEL or "Units", update = update_units })
        for _, name in ipairs({ "PLAYER_TARGET_CHANGED", "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER", "UNIT_LEVEL", "UNIT_NAME_UPDATE", "UNIT_PORTRAIT_UPDATE", "UNIT_CLASSIFICATION_CHANGED", "PLAYER_ENTERING_WORLD", "UNIT_PET", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "UNIT_MODEL_CHANGED", "QUEST_LOG_UPDATE", "UNIT_QUEST_LOG_CHANGED", "COMBAT_TEXT_UPDATE", "PLAYER_UPDATE_RESTING", "PARTY_LEADER_CHANGED", "GROUP_ROSTER_UPDATE", "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST", "UNIT_PET_EXPERIENCE" }) do
            pcall(events.RegisterEvent, events, name)
        end
        update_units()
        C_Timer.After(1, function() library.update_safely("units portrait", update_units) end)
    elseif event == "CVAR_UPDATE" then
        update_target_target_shown()
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_UPDATE_RESTING" then
        library.update_unit_frame_glow(frames.player)
    elseif event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_ENTERING_WORLD" or event == "UNIT_PET" or event == "PLAYER_REGEN_ENABLED" or event == "QUEST_LOG_UPDATE" or event == "UNIT_QUEST_LOG_CHANGED" or event == "PARTY_LEADER_CHANGED" or event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_DEAD" or event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        library.update_unit_frame_glow(frames.player)
        update_units()
    elseif event == "UNIT_PET_EXPERIENCE" then
        if frames.pet then library.update_unit_frame(frames.pet) end
    elseif event == "COMBAT_TEXT_UPDATE" then
        local bar = GAINS[unit] and frames.player and frames.player[GAINS[unit]]
        if bar then library.render_bar_shine(bar) end
    elseif frames[unit] then
        if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" then
            library.update_unit_frame_values(frames[unit])
            if (UnitIsDeadOrGhost(unit) == true) ~= frames[unit].dead then library.update_unit_frame(frames[unit]) end
        else
            library.update_unit_frame(frames[unit])
        end
    end
end

events:SetScript("OnEvent", function(_, event, unit)
    library.update_safely("units " .. event, update_event, event, unit)
end)
