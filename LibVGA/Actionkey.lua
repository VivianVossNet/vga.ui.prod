-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's action key, the meta-object of every action bar (K0883, K0860): the owner on 24 November 2026 judged the key, which vga.ui/Actionbars.lua had put together by hand from the cell dress, the shimmer and the swing run, »Metaobjekt« in the register of K0863. library.create_action_key makes one protected key on the game's ActionBarButtonTemplate, on its bar's page, and owns all of it: the template's frame, slot art, slot ground and mask laid away, the icon cropped and set in by the rim, the cooldown likewise, the cell dress - a black line and the bags' bold edge -, the shimmer of a newly learned spell (K0482), the hover, press and checked fills in white at 0.15 over the icon, the hotkey in the caption face or, for the game's range dot, in Arial Narrow, since our faces lack the glyph (K0419); library.update_action_key lays it at its size and place, the line, the three-pixel edge in the slot's grey and the hotkey in its corner, as manual/view/vga-mainbar.html draws the key. The key holding the auto attack - melee's attack or a repeating shot, known by the game's IsAttackAction and IsAutoRepeatAction for its action - shows its picture as every key does (K0881): the template's red Flash is laid at alpha 0, so its blinking shows nothing, and the checked fill, which the template's additive blend lit the whole time the attack ran, is laid clear on such a key each time the template lays its flash; every other key keeps its checked look. While the attack runs, the key's swing run lays a white frame round its rim at the weapon's speed. Melee's swings cannot be heard - Forever gives addons no combat log, and registering for it blocks the addon (K0119) -, so, the owner on 24 November 2026: »er läuft einfch bis zum ende des kampfes immer gleich schnell herum. das blinken der original ui ist auch nicht tiefgründiger« (read: einfach) (K0883): from PLAYER_ENTER_COMBAT the frame runs round again and again, each round as long as the main hand's UnitAttackSpeed, read anew at each round, until PLAYER_LEAVE_COMBAT. A repeating shot's frame begins with START_AUTOREPEAT_SPELL at UnitRangedDamage's speed, begins anew at each shot the player's UNIT_SPELLCAST_SUCCEEDED names for the key's spell, and goes with STOP_AUTOREPEAT_SPELL. Nothing protected is touched in a fight.

-- {K0883} {K0881} {K0860} {K0482} {K0419}

local library = LibVGA
local EDGE_WIDTH = 3
local BLACK = { 0, 0, 0 }
local SLOT_EDGE = { 0.18, 0.192, 0.22 }
local STATE_ALPHA = 0.15
local DOT_FONT = "Fonts\\ARIALN.TTF"
local keys = {}

local function update_hotkey_face(hotkey, text)
    if text == RANGE_INDICATOR then
        local _, size = library.read_font("caption"):GetFont()
        hotkey:SetFont(DOT_FONT, size or 10, "OUTLINE")
    else
        hotkey:SetFontObject(library.read_font("caption"))
    end
end

local function check_action(name, slot)
    local check = C_ActionBar and C_ActionBar[name] or _G[name]
    return slot ~= nil and check ~= nil and check(slot) and true or false
end

local function check_melee_key(key)
    return check_action("IsAttackAction", key.action)
end

local function check_ranged_key(key)
    return check_action("IsAutoRepeatAction", key.action)
end

local function check_not_ranged(key)
    return not check_ranged_key(key)
end

local function check_not_meleeing(key)
    return not (check_melee_key(key) and check_action("IsCurrentAction", key.action))
end

local function check_shot_key(key, spell)
    if not check_ranged_key(key) or (issecretvalue and issecretvalue(spell)) then return false end
    local kind, id = GetActionInfo(key.action)
    return kind == "spell" and id == spell
end

local function update_checked_look(key)
    local hidden = check_melee_key(key) or check_ranged_key(key)
    key:GetCheckedTexture():SetVertexColor(1, 1, 1, hidden and 0 or STATE_ALPHA)
end

local function read_melee_seconds()
    return UnitAttackSpeed and (UnitAttackSpeed("player"))
end

local function read_ranged_seconds()
    return UnitRangedDamage and (UnitRangedDamage("player"))
end

local function update_template_parts(key)
    for _, part in ipairs({ key.NormalTexture, key.SlotArt, key.SlotBackground, key.IconMask, key.Flash }) do
        if part then part:SetAlpha(0) end
    end
    if key.icon and key.IconMask then key.icon:RemoveMaskTexture(key.IconMask) end
    if key.icon then
        key.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        library.update_cell_picture(key.icon, key, EDGE_WIDTH)
    end
    if key.cooldown then library.update_cell_picture(key.cooldown, key, EDGE_WIDTH) end
end

local function update_state_fills(key)
    for _, state in ipairs({ key:GetHighlightTexture(), key:GetPushedTexture(), key:GetCheckedTexture() }) do
        state:SetTexture("Interface\\Buttons\\WHITE8X8")
        state:SetVertexColor(1, 1, 1, STATE_ALPHA)
        state:SetAllPoints(key.icon)
    end
end

function library.create_action_key(bar, name, index, command)
    local key = CreateFrame("CheckButton", name .. index, bar, "ActionBarButtonTemplate")
    key:SetID(index)
    key.buttonType = command
    key:SetAttribute("actionpage", bar.page)
    key:RegisterForClicks("AnyUp")
    key.command = command .. index
    if key.HotKey then hooksecurefunc(key.HotKey, "SetText", update_hotkey_face) end
    if key.UpdateHotkeys then key:UpdateHotkeys(command) end
    update_template_parts(key)
    library.create_cell_dress(key, { line = -8, edge = 6 })
    library.create_shimmer(key)
    library.delete_shimmer(key)
    update_state_fills(key)
    if key.UpdateFlash then hooksecurefunc(key, "UpdateFlash", update_checked_look) end
    key.vga_swing_run = library.create_swing_run(key, EDGE_WIDTH)
    keys[#keys + 1] = key
    return key
end

function library.update_action_key(key, size, across, down)
    local radius = 2 * EDGE_WIDTH
    key:SetSize(size, size)
    key:ClearAllPoints()
    key:SetPoint("TOPLEFT", key:GetParent(), "TOPLEFT", across, -down)
    library.update_surface(key.vga_line, -1, radius + 1, BLACK, BLACK)
    library.update_ring(key.vga_edge, EDGE_WIDTH, SLOT_EDGE, 1)
    if key.HotKey then
        update_hotkey_face(key.HotKey, key.HotKey:GetText())
        key.HotKey:ClearAllPoints()
        key.HotKey:SetPoint("TOPRIGHT", key, "TOPRIGHT", -library.read_draft_size(4), -library.read_draft_size(2))
    end
end

local SWING_EVENTS = {
    PLAYER_ENTER_COMBAT = { check_melee_key, "render_swing_run", read_melee_seconds, read_melee_seconds },
    PLAYER_LEAVE_COMBAT = { check_not_ranged, "update_swing_run_stopped" },
    START_AUTOREPEAT_SPELL = { check_ranged_key, "render_swing_run", read_ranged_seconds },
    STOP_AUTOREPEAT_SPELL = { check_not_meleeing, "update_swing_run_stopped" },
    UNIT_SPELLCAST_SUCCEEDED = { check_shot_key, "render_swing_run", read_ranged_seconds },
}

local function update_swing_runs(event, spell)
    local plan = SWING_EVENTS[event]
    local layer, seconds = library[plan[2]], plan[3] and plan[3]()
    for _, key in ipairs(keys) do
        if plan[1](key, spell) then layer(key.vga_swing_run, seconds, plan[4]) end
    end
end

local events = CreateFrame("Frame")
library.update_events(events, { "PLAYER_ENTER_COMBAT", "PLAYER_LEAVE_COMBAT", "START_AUTOREPEAT_SPELL", "STOP_AUTOREPEAT_SPELL" })
pcall(events.RegisterUnitEvent, events, "UNIT_SPELLCAST_SUCCEEDED", "player")
events:SetScript("OnEvent", function(_, event, _, _, third)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then return library.update_safely("swing runs", update_swing_runs, event, third) end
    library.update_safely("swing runs", update_swing_runs, event)
end)
