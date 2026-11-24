-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.ui's nameplates as the accepted draft draws them: the bar on top in a black rim, grey when another holds the loot, the level either in a tab centred on it that ends flat on the bar, its number in the enemy's difficulty colour and the kind's chevron beside it, or as a bare number at the bar's left above it in a thick black edge, the kind's chevron after it, as the settings say; the name beneath, a thin cast bar under the name, gone as soon as the unit no longer casts (K0590), the quest bag right behind the bar, Blizzard's own debuff list moved above our bar, so the player's debuffs show in a fight too; an edge behind the bar and the tab together - on the current target in the game's own difficulty colour, as Blizzard colours the level, grey easy to red hard, gold where there is none, black on every other plate; Blizzard's own plate hidden, and kept hidden when it sets its alpha again; another addon's icon on the plate hidden, so only our bag shows; a friendly player or NPC wears the friends' plate of Friends.lua instead, and so does an enemy while the simple plates of Platesimple.lua are switched on (K0743).

-- {K0789} {K0269} {K0270} {K0271} {K0272} {K0273} {K0274} {K0301} {K0321} {K0323} {K0326} {K0328} {K0329} {K0330} {K0334} {K0341} {K0347} {K0348} {K0360} {K0351} {K0364} {K0365} {K0367} {K0368} {K0369} {K0590} {K0743}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local KINDS = {
    elite = { 0.843, 0.663, 0.271 },
    worldboss = { 0.843, 0.663, 0.271 },
    rareelite = { 0.843, 0.663, 0.271 },
    rare = { 0.769, 0.792, 0.824 },
}
local BAR_RADIUS = 2
local TAB_GROUND = { 0.071, 0.078, 0.094 }
local BLACK = { 0, 0, 0 }
local WIDTH_SHARE = 195 / 12
local plates = {}
vga.plates = plates
local silenced = {}

local function read_reaction(unit)
    if not UnitPlayerControlled(unit) and UnitIsTapDenied(unit) then return "tapped" end
    local reaction = UnitReaction(unit, "player") or 4
    if reaction <= 3 then return "enemy" end
    if reaction == 4 then return "energy" end
    return "health"
end

local function create_plate(owner)
    local plate = CreateFrame("Frame", nil, owner)
    plate:SetPoint("CENTER")
    plate.halo = CreateFrame("Frame", nil, plate)
    plate.halo:SetFrameLevel(plate:GetFrameLevel())
    plate.crest = CreateFrame("Frame", nil, plate.halo)
    plate.crest:SetFrameLevel(plate:GetFrameLevel())
    plate.halo.tab = library.create_surface(plate.crest, "BACKGROUND", 0)
    plate.tab = CreateFrame("Frame", nil, plate)
    plate.tab:SetFrameLevel(plate:GetFrameLevel() + 1)
    plate.bar = library.create_bar(plate, "enemy")
    plate.halo:SetAllPoints()
    plate.halo.bar = library.create_surface(plate.halo, "BACKGROUND", 1, plate.bar)
    plate.tab.rim = library.create_surface(plate.tab, "BACKGROUND", 0)
    plate.tab.ground = library.create_surface(plate.tab, "BACKGROUND", 1)
    for _, surface in ipairs({ plate.tab.rim, plate.tab.ground, plate.halo.tab }) do surface.flat = true end
    plate.mark = CreateFrame("Frame", nil, plate)
    plate.mark:SetAllPoints()
    plate.mark:SetFrameLevel(plate:GetFrameLevel() + 4)
    plate.level = library.create_text(plate.mark, "figures_bold")
    plate.shade = plate.mark:CreateTexture(nil, "ARTWORK", nil, 2)
    plate.shade:SetTexture(library.media .. "Chevron")
    plate.shade:SetVertexColor(0, 0, 0, 1)
    plate.chevron = plate.mark:CreateTexture(nil, "OVERLAY")
    plate.chevron:SetTexture(library.media .. "Chevron")
    plate.quest = plate.mark:CreateTexture(nil, "OVERLAY")
    plate.quest:SetTexture(library.media .. "QuestBag")
    plate.name = library.create_text(plate, "bold", { 1, 1, 1 })
    plate.name:SetWordWrap(false)
    plate.cast = library.create_bar(plate, "gold")
    plate.cast:HookScript("OnUpdate", vga.update_cast_watch)
    plate.cast:Hide()
    plate.friend = vga.create_friend(plate)
    plate.parts = { plate.halo, plate.tab, plate.bar, plate.mark, plate.name }
    return plate
end

local function update_plate_shield(plate, base, tab)
    plate.tab:Show()
    plate.crest:Show()
    local kind, gap = plate.kind_colour, math.floor(base * 0.3 + 0.5)
    plate.chevron:SetShown(kind ~= nil)
    plate.chevron:SetSize(math.floor(base * 1.05 + 0.5), math.floor(base * 0.75 + 0.5))
    if kind then plate.chevron:SetVertexColor(kind[1], kind[2], kind[3], 1) end
    plate.level:SetFontObject(library.read_font("figures_bold"))
    plate.level:SetTextColor(unpack(plate.difficulty or { 1, 1, 1 }))
    local chevron = kind and plate.chevron:GetWidth() + gap or 0
    local inner = plate.level:GetStringWidth() + chevron + 2 * math.floor(base * 0.55 + 0.5)
    plate.tab:ClearAllPoints()
    plate.tab:SetWidth(math.max(math.floor(base * 2.4 + 0.5), inner))
    plate.tab:SetPoint("TOP", plate.bar, "TOP", 0, tab)
    plate.tab:SetPoint("BOTTOM", plate.bar, "TOP")
    library.update_surface(plate.tab.rim, -1, 4, BLACK, BLACK)
    library.update_surface(plate.tab.ground, 0, 3, TAB_GROUND, TAB_GROUND)
    plate.crest:ClearAllPoints()
    plate.crest:SetAllPoints(plate.tab)
    library.update_surface(plate.halo.tab, -2, 5, plate.edge or BLACK, plate.edge or BLACK)
    plate.level:ClearAllPoints()
    plate.level:SetPoint("CENTER", plate.bar, "TOP", -chevron / 2, tab / 2)
    plate.chevron:ClearAllPoints()
    plate.chevron:SetPoint("LEFT", plate.level, "RIGHT", math.floor(base * 0.18 + 0.5) + 3, 0)
end

local function update_plate_number(plate, base, tab)
    local air = math.floor(base * 0.18 + 0.5) + 3
    plate.tab:Hide()
    plate.crest:Hide()
    local kind = plate.kind_colour
    plate.level:SetFontObject(library.read_font(LibVGASettings.plate_outline == "light" and "number_light" or "number"))
    plate.level:ClearAllPoints()
    plate.level:SetPoint("LEFT", plate.bar, "TOPLEFT", 0, tab / 2)
    plate.chevron:SetShown(kind ~= nil)
    plate.chevron:SetSize(math.floor(base * 1.05 + 0.5), math.floor(base * 0.75 + 0.5))
    if kind then plate.chevron:SetVertexColor(kind[1], kind[2], kind[3], 1) end
    plate.chevron:ClearAllPoints()
    plate.chevron:SetPoint("LEFT", plate.level, "RIGHT", air, 0)
end

local function update_plate_layout(plate)
    local base = library.read_base()
    local width = math.floor(base * WIDTH_SHARE + 0.5)
    local bar = math.max(5, math.floor(base * 7 / 12 + 0.5))
    local tab = math.floor(base * 1.5 + 0.5)
    plate.tab_height = tab
    plate:SetSize(width, tab + bar + library.read_size(1) + bar)
    plate.bar:ClearAllPoints()
    plate.bar:SetSize(width, bar)
    plate.bar:SetPoint("TOP", plate, "TOP", 0, -tab)
    library.update_bar_shape(plate.bar, BAR_RADIUS)
    library.update_surface(plate.halo.bar, -2, BAR_RADIUS + 2, plate.edge or BLACK, plate.edge or BLACK)
    if library.read_plate_number() then
        update_plate_number(plate, base, tab)
    else
        update_plate_shield(plate, base, tab)
    end
    plate.shade:SetShown(plate.chevron:IsShown())
    plate.shade:SetSize(plate.chevron:GetWidth() + 2, plate.chevron:GetHeight() + 2)
    plate.shade:ClearAllPoints()
    plate.shade:SetPoint("CENTER", plate.chevron, "CENTER")
    plate.quest:ClearAllPoints()
    plate.quest:SetSize(tab, tab)
    plate.quest:SetPoint("LEFT", plate.bar, "RIGHT", library.read_size(-4), 0)
    plate.name:SetFontObject(library.read_font("bold"))
    plate.name:ClearAllPoints()
    plate.name:SetPoint("TOP", plate.bar, "BOTTOM", 0, -3)
    plate.name:SetWidth(width)
    plate.cast:ClearAllPoints()
    plate.cast:SetSize(width, math.max(4, bar - 2))
    plate.cast:SetPoint("TOP", plate.name, "BOTTOM", 0, -3)
    library.update_bar_shape(plate.cast, 2)
end

local function update_plate_identity(plate, unit)
    plate.name:SetText(library.read_unit_name(unit))
    local level = UnitLevel(unit)
    plate.level:SetText((level and level > 0) and level or "??")
    plate.difficulty = library.read_level_colour(unit, nil)
    plate.step = library.read_level_colour(unit, nil)
    local kind = KINDS[UnitClassification(unit)]
    plate.kind_colour = kind
    local related = C_QuestLog and C_QuestLog.UnitIsRelatedToActiveQuest and C_QuestLog.UnitIsRelatedToActiveQuest(unit)
    plate.quest:SetShown(not (issecretvalue and issecretvalue(related)) and related == true)
    library.update_bar_kind(plate.bar, read_reaction(unit))
    plate.bar.fraction = nil
end

local moved = setmetatable({}, { __mode = "k" })
local placing = false

local function update_debuff_place(list)
    local plate = moved[list]
    if not plate or placing then return end
    placing = true
    list:ClearAllPoints()
    list:SetPoint("BOTTOM", plate.bar, "TOP", 0, plate.tab_height + library.read_size(-4) + 2)
    placing = false
end

local function update_blizzard_debuffs(owner)
    local auras = owner.UnitFrame and owner.UnitFrame.AurasFrame
    local list = auras and auras.DebuffListFrame
    if not list then return end
    list:SetParent(owner.vga)
    if moved[list] == nil then hooksecurefunc(list, "SetPoint", update_debuff_place) end
    moved[list] = owner.vga
    update_debuff_place(list)
end

local function update_plate_focus(plate)
    local chosen = plate:GetParent() == C_NamePlate.GetNamePlateForUnit("target")
    plate.edge = chosen and (plate.step or colours.gold) or BLACK
    library.update_surface(plate.halo.bar, -2, BAR_RADIUS + 2, plate.edge, plate.edge)
    library.update_surface(plate.halo.tab, -2, 5, plate.edge, plate.edge)
end

local function update_foreign_icons(owner)
    for _, child in ipairs({ owner:GetChildren() }) do
        if child ~= owner.UnitFrame and child ~= owner.vga and child.Icon then child:SetAlpha(0) end
    end
end

local function update_plate_values(plate, unit)
    if plate.friend:IsShown() then vga.update_friend_health(plate.friend, unit) end
    library.update_bar_value(plate.bar, UnitHealth(unit), UnitHealthMax(unit))
    update_foreign_icons(plate:GetParent())
end

local function update_plate_cast(plate, unit, ended)
    if ended then
        plate.friend.cast:Hide()
        plate.cast:Hide()
        return
    end
    if plate.friend:IsShown() then
        vga.update_friend_cast(plate.friend, unit)
        plate.cast:Hide()
        return
    end
    local duration = vga.check_casting(unit) and ((UnitCastingDuration and UnitCastingDuration(unit)) or (UnitChannelDuration and UnitChannelDuration(unit)))
    plate.cast.unit = unit
    if duration and plate.cast.SetTimerDuration then
        plate.cast:SetTimerDuration(duration)
        plate.cast:Show()
    else
        plate.cast:Hide()
    end
end

local function update_blizzard_hidden(frame, alpha)
    if alpha ~= 0 then frame:SetAlpha(0) end
end

local function update_blizzard_plate(owner)
    local frame = owner.UnitFrame
    if not frame then return end
    frame:SetAlpha(0)
    if not silenced[frame] then
        silenced[frame] = true
        hooksecurefunc(frame, "SetAlpha", update_blizzard_hidden)
    end
end

local function update_plate(unit)
    local owner = C_NamePlate.GetNamePlateForUnit(unit)
    if not owner then return end
    update_blizzard_plate(owner)
    update_foreign_icons(owner)
    C_Timer.After(0, function() library.update_safely("plate icons", update_foreign_icons, owner) end)
    owner.vga = owner.vga or create_plate(owner)
    plates[unit] = owner.vga
    owner.vga:Show()
    update_plate_layout(owner.vga)
    local friendly = vga.check_friend(unit) or vga.check_simple_plate(unit)
    owner.vga.friend:SetShown(friendly and true or false)
    for _, part in ipairs(owner.vga.parts) do part:SetShown(not friendly) end
    if friendly then
        owner.vga.cast:Hide()
        vga.update_friend(owner.vga.friend, unit)
        return
    end
    update_plate_identity(owner.vga, unit)
    update_plate_focus(owner.vga)
    update_plate_layout(owner.vga)
    update_plate_values(owner.vga, unit)
    update_plate_cast(owner.vga, unit)
    update_blizzard_debuffs(owner)
end

local function update_plates()
    for unit in pairs(plates) do
        library.update_safely("plate", update_plate, unit)
    end
end

local function update_plates_focus()
    for _, plate in pairs(plates) do
        update_plate_focus(plate)
    end
end

local ENDS = {
    UNIT_SPELLCAST_STOP = true, UNIT_SPELLCAST_FAILED = true, UNIT_SPELLCAST_INTERRUPTED = true, UNIT_SPELLCAST_CHANNEL_STOP = true,
}

local CASTS = {
    UNIT_SPELLCAST_START = true, UNIT_SPELLCAST_STOP = true, UNIT_SPELLCAST_FAILED = true,
    UNIT_SPELLCAST_INTERRUPTED = true, UNIT_SPELLCAST_CHANNEL_START = true, UNIT_SPELLCAST_CHANNEL_STOP = true,
}

local function update_event(event, unit)
    if event == "NAME_PLATE_UNIT_ADDED" then
        update_plate(unit)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        if plates[unit] then plates[unit]:Hide() end
        plates[unit] = nil
    elseif event == "PLAYER_TARGET_CHANGED" then
        update_plates_focus()
    elseif event == "QUEST_LOG_UPDATE" or event == "GROUP_ROSTER_UPDATE" or event == "UNIT_FACTION" then
        update_plates()
    elseif plates[unit] then
        if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
            update_plate_values(plates[unit], unit)
        elseif CASTS[event] then
            update_plate_cast(plates[unit], unit, ENDS[event])
        elseif event == "UNIT_FLAGS" then
            update_plate(unit)
        else
            update_plate_identity(plates[unit], unit)
            update_plate_layout(plates[unit])
        end
    end
end

local events = CreateFrame("Frame")
for _, name in ipairs({
    "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_LEVEL", "UNIT_FLAGS", "GROUP_ROSTER_UPDATE", "UNIT_FACTION",
    "UNIT_NAME_UPDATE", "UNIT_CLASSIFICATION_CHANGED", "QUEST_LOG_UPDATE", "UNIT_SPELLCAST_START",
    "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED",
    "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_STOP", "PLAYER_TARGET_CHANGED",
}) do
    pcall(events.RegisterEvent, events, name)
end
events:SetScript("OnEvent", function(_, event, unit)
    library.update_safely("plates " .. event, update_event, event, unit)
end)
library.create_element("plates", { update = update_plates })
