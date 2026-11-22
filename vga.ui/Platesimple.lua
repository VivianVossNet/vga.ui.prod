-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: The enemies' simple plates (K0743): the game's enemy plates stay switched on while vga.ui runs, since with them off the game draws names of its own no addon may style; the key the player has bound to the game's enemy plates - V by default - is taken over and switches between the full enemy plate and the simple one, the friends' plate of Friends.lua, the game's own setting standing for the simple one where it was off; a change of the setting elsewhere, in the game's options, read the same way; the player's own setting written back at logout as the simple mode stands; bindings and the game's setting changed only out of combat, the switch itself in combat too, as it changes only our drawing.

-- {K0743}

local _, vga = ...
local library = LibVGA
local SETTING = "nameplateShowEnemies"
local COMMAND = "NAMEPLATES"
local owner

function vga.check_simple_plate(unit)
    return LibVGASettings.plates_simple == true and not vga.check_friend(unit)
end

local function update_plates_drawn()
    library.update_element("plates")
end

local function render_plate_switch()
    LibVGASettings.plates_simple = not LibVGASettings.plates_simple
    update_plates_drawn()
end

local function update_plate_key()
    if InCombatLockdown() or not owner then return end
    ClearOverrideBindings(owner)
    for _, key in ipairs({ GetBindingKey(COMMAND) }) do
        if key then SetOverrideBindingClick(owner, false, key, "VGAPlateToggle") end
    end
end

local function update_setting_kept()
    if InCombatLockdown() then return end
    if GetCVar(SETTING) == "0" then
        LibVGASettings.plates_simple = true
        SetCVar(SETTING, "1")
        update_plates_drawn()
    end
end

local function update_setting_back()
    if GetCVar(SETTING) == nil then return end
    SetCVar(SETTING, LibVGASettings.plates_simple and "0" or "1")
end

local function create_plate_switch()
    owner = CreateFrame("Button", "VGAPlateToggle")
    owner:SetScript("OnClick", render_plate_switch)
    update_setting_kept()
    update_plate_key()
end

local events = CreateFrame("Frame")
for _, name in ipairs({ "PLAYER_LOGIN", "UPDATE_BINDINGS", "CVAR_UPDATE", "PLAYER_REGEN_ENABLED", "PLAYER_LOGOUT" }) do pcall(events.RegisterEvent, events, name) end
events:SetScript("OnEvent", function(_, event)
    if not LibVGASettings then return end
    if event == "PLAYER_LOGIN" then return library.update_safely("plate switch", create_plate_switch) end
    if event == "PLAYER_LOGOUT" then return library.update_safely("plate switch back", update_setting_back) end
    if event == "UPDATE_BINDINGS" then return library.update_safely("plate key", update_plate_key) end
    library.update_safely("plate setting", update_setting_kept)
    if event == "PLAYER_REGEN_ENABLED" then library.update_safely("plate key", update_plate_key) end
end)
