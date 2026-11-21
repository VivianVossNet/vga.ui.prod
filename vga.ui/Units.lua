-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.ui's player frame, target frame and pet frame, each where Blizzard's own stands in the player's layout: the level's shield, the name and its class or kind, health and power, the target mirrored to the player, the portrait's rim one smooth, rounded frame in one colour over the picture, its corners and sides cut from one texture - seven outside, three thick, four inside -, clicked to target; the group's leader marked by a small filled gold crown sitting centred on the portrait's top edge (K0614); Blizzard's own frames hidden. In a resting place - an inn, a city - the same pulse round the player's portrait glows blue instead of red; in a fight the red wins and the blue rests until the fight is over (K0551).

-- {K0481} {K0551} {K0267} {K0268} {K0275} {K0276} {K0294} {K0297} {K0299} {K0300} {K0302} {K0329} {K0330} {K0334} {K0342} {K0345} {K0346} {K0360} {K0614}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local SKULL = { 1, 0.1, 0.1 }
local KINDS = {
    elite = { 0.843, 0.663, 0.271 },
    worldboss = { 0.843, 0.663, 0.271 },
    rareelite = { 0.843, 0.663, 0.271 },
    rare = { 0.722, 0.745, 0.78 },
}
local BLACK = { 0, 0, 0 }
local DARK = { 0.29, 0.31, 0.34 }
local BADGE_RING = 0.667
local BADGE_TOP = { 0.173, 0.184, 0.208 }
local BADGE_BOTTOM = { 0.082, 0.09, 0.106 }
local BADGE_TEXT = { 0.945, 0.812, 0.431 }
local POWERS = { [0] = "power", [1] = "rage", [2] = "focus", [3] = "energy", [6] = "runic" }
local frames = {}
local FIGHT = { 0.86, 0.12, 0.1 }
local RESTING = { 0.2, 0.5, 0.95 }
local FIGHT_LOW = 0.2
local FIGHT_HIGH = 0.75
local FIGHT_PULSE = 1.4
local FIGHT_SPREAD = 64 / 42 * 0.96
local GAINS = {
    HEAL = "health", HEAL_CRIT = "health", PERIODIC_HEAL = "health", PERIODIC_HEAL_CRIT = "health",
    ENERGIZE = "power", PERIODIC_ENERGIZE = "power",
}

local function read_rim_colour(unit)
    if unit == "player" or UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        local colour = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if colour then return { colour.r, colour.g, colour.b } end
        return DARK
    end
    return KINDS[UnitClassification(unit)] or DARK
end

local function update_shield_size(frame)
    local side = library.read_size(2)
    frame.level:SetFontObject(library.read_font("caption"))
    frame.level:SetTextColor(unpack(frame.level_colour or BADGE_TEXT))
    local width = math.ceil(frame.level:GetStringWidth()) + 2 * library.read_size(-6)
    frame.shield:SetSize(math.max(side, width), side)
    local radius = library.read_size(-4)
    library.update_surface(frame.shield.outer, -2, radius + 2, colours.gold, colours.gold, BADGE_RING)
    library.update_surface(frame.shield.line, -1, radius + 1, BLACK, BLACK)
    library.update_surface(frame.shield.inner, 0, radius, BADGE_TOP, BADGE_BOTTOM)
end

local function read_percent_shown()
    return library.read_values_percent() and CurveConstants ~= nil and UnitHealthPercent ~= nil
end

local function update_bar_text(bar, value, most, share)
    local plain = bar.figures and not read_percent_shown()
    bar.ratio:SetShown(plain and true or false)
    bar.percent:SetShown(bar.figures and not plain)
    if plain then
        library.update_ratio(bar.ratio, value, most)
    elseif bar.figures then
        bar.percent:SetFontObject(library.read_font(bar.ratio.left.kind))
        if not pcall(bar.percent.SetFormattedText, bar.percent, "%.0f %%", share()) then bar.percent:SetText("") end
    end
end

local function update_values(frame)
    local unit = frame.unit
    if not UnitExists(unit) then return end
    local health, most = UnitHealth(unit), UnitHealthMax(unit)
    library.update_bar_value(frame.health, health, most)
    update_bar_text(frame.health, health, most, function() return UnitHealthPercent(unit, true, CurveConstants.ScaleTo100) end)
    local kind = UnitPowerType(unit)
    library.update_bar_kind(frame.power, POWERS[kind] or "power")
    local power, top = UnitPower(unit), UnitPowerMax(unit)
    library.update_bar_value(frame.power, power, top)
    update_bar_text(frame.power, power, top, function() return UnitPowerPercent(unit, kind, false, CurveConstants.ScaleTo100) end)
end

local function update_target_kind(frame, kind)
    local unit = frame.unit
    frame.class:SetFontObject(library.read_frame_font(kind and "bold" or "small"))
    if UnitIsPlayer(unit) then
        frame.class:SetText(UnitClass(unit) or "")
        frame.class:SetTextColor(unpack(colours.label))
    else
        frame.class:SetText(kind and library.texts[UnitClassification(unit)] or "")
        frame.class:SetTextColor(unpack(kind and colours.ink or colours.label))
    end
    if kind then frame.chevron:SetVertexColor(kind[1], kind[2], kind[3], 1) end
    local gap = library.read_size(-4)
    frame.class:ClearAllPoints()
    frame.class:SetPoint("BOTTOMLEFT", frame.health, "TOPLEFT", kind and (frame.chevron:GetWidth() + gap) or 0, gap)
    frame.chevron:ClearAllPoints()
    frame.chevron:SetPoint("RIGHT", frame.class, "LEFT", -gap, 0)
end

function vga.read_level_colour(unit, own)
    if not UnitCanAttack("player", unit) then return own end
    local level = UnitLevel(unit)
    if not level or level <= 0 then return SKULL end
    local colour = GetCreatureDifficultyColor and GetCreatureDifficultyColor(level)
    return colour and { colour.r, colour.g, colour.b } or own
end

local function update_identity(frame)
    local unit = frame.unit
    if not UnitExists(unit) then return end
    frame.name:SetText(library.read_unit_name(unit))
    frame.crown:SetShown(unit ~= "pet" and UnitIsGroupLeader(unit) == true)
    local level = UnitLevel(unit)
    frame.level:SetText(level and level > 0 and level or "??")
    frame.level_colour = vga.read_level_colour(unit, BADGE_TEXT)
    update_shield_size(frame)
    SetPortraitTexture(frame.portrait, unit, true)
    local moving = library.read_faces_moving() and UnitIsVisible(unit)
    frame.model:SetShown(moving)
    frame.portrait:SetShown(not moving)
    if moving then
        frame.model:SetUnit(unit)
        frame.model:SetPortraitZoom(1)
        frame.model:SetCamDistanceScale(1)
    end
    local rim = read_rim_colour(unit)
    for _, side in pairs(frame.edges) do
        side:SetVertexColor(rim[1], rim[2], rim[3], 1)
    end
    frame.rim_colour = rim
    if unit == "target" then
        local kind = KINDS[UnitClassification(unit)]
        frame.health.fraction = nil
        frame.power.fraction = nil
        frame.chevron:SetShown(kind ~= nil)
        local related = C_QuestLog and C_QuestLog.UnitIsRelatedToActiveQuest and C_QuestLog.UnitIsRelatedToActiveQuest(unit)
        frame.quest:SetShown(not (issecretvalue and issecretvalue(related)) and related == true)
        update_target_kind(frame, kind)
        library.update_bar_kind(frame.health, UnitIsFriend("player", unit) and "health" or "enemy")
    else
        frame.class:SetText(unit == "player" and UnitClass(unit) or "")
    end
end

local CUT = 28 / 64
local RIM_PIECES = {
    TOPLEFT = { 0, CUT, 0, CUT }, TOPRIGHT = { 1 - CUT, 1, 0, CUT },
    BOTTOMLEFT = { 0, CUT, 1 - CUT, 1 }, BOTTOMRIGHT = { 1 - CUT, 1, 1 - CUT, 1 },
    TOP = { CUT, 1 - CUT, 0, CUT }, BOTTOM = { CUT, 1 - CUT, 1 - CUT, 1 },
    LEFT = { 0, CUT, CUT, 1 - CUT }, RIGHT = { 1 - CUT, 1, CUT, 1 - CUT },
}

local function create_rim(owner)
    local pieces = {}
    for key, cut in pairs(RIM_PIECES) do
        local piece = owner:CreateTexture(nil, "ARTWORK", nil, 3)
        piece:SetTexture(library.media .. "RimFrame")
        piece:SetTexCoord(cut[1], cut[2], cut[3], cut[4])
        if piece.SetRoundLayoutToNearestPixel then piece:SetRoundLayoutToNearestPixel(true) end
        pieces[key] = piece
    end
    return pieces
end

local function update_rim(pieces, around, corner)
    for key, piece in pairs(pieces) do
        piece:ClearAllPoints()
        if #key > 6 then
            piece:SetSize(corner, corner)
            piece:SetPoint(key, around, key)
        elseif key == "TOP" or key == "BOTTOM" then
            piece:SetPoint(key .. "LEFT", around, key .. "LEFT", corner, 0)
            piece:SetPoint(key .. "RIGHT", around, key .. "RIGHT", -corner, 0)
            piece:SetHeight(corner)
        else
            piece:SetPoint("TOP" .. key, around, "TOP" .. key, 0, -corner)
            piece:SetPoint("BOTTOM" .. key, around, "BOTTOM" .. key, 0, corner)
            piece:SetWidth(corner)
        end
    end
end

local function create_fight_glow(frame)
    frame.fight = frame:CreateTexture(nil, "ARTWORK", nil, -3)
    frame.fight:SetTexture(library.media .. "SlotGlow")
    frame.fight:SetVertexColor(FIGHT[1], FIGHT[2], FIGHT[3], 1)
    frame.fight:SetBlendMode("ADD")
    frame.fight.pulse = frame.fight:CreateAnimationGroup()
    frame.fight.pulse:SetLooping("BOUNCE")
    local fade = frame.fight.pulse:CreateAnimation("Alpha")
    fade:SetFromAlpha(FIGHT_LOW)
    fade:SetToAlpha(FIGHT_HIGH)
    fade:SetDuration(FIGHT_PULSE)
    fade:SetSmoothing("IN_OUT")
    frame.fight:Hide()
end

local function update_fight_glow()
    local glow = frames.player and frames.player.fight
    if not glow then return end
    local fighting = UnitAffectingCombat("player") and true or false
    local resting = not fighting and IsResting and IsResting() and true or false
    local colour = fighting and FIGHT or RESTING
    glow:SetVertexColor(colour[1], colour[2], colour[3], 1)
    glow:SetShown(fighting or resting)
    if (fighting or resting) and not glow.pulse:IsPlaying() then glow.pulse:Play() end
    if not (fighting or resting) then glow.pulse:Stop() end
end

local function create_frame(unit, mirrored)
    local frame = library.create_frame("VGAUnitFrame_" .. unit, UIParent, "SecureUnitButtonTemplate")
    frame.unit = unit
    frame.mirrored = mirrored
    frame:SetAttribute("unit", unit)
    frame:SetAttribute("*type1", "target")
    frame:SetAttribute("*type2", "togglemenu")
    frame:RegisterForClicks("AnyUp")
    frame.corner:SetFrameLevel(frame:GetFrameLevel() + 3)
    frame.ground_key = "units"
    frame.corner:SetScript("OnClick", function(corner) library.update_safely("options", library.render_widget, corner, "units") end)
    frame.rim = frame:CreateTexture(nil, "ARTWORK", nil, 0)
    frame.rim:SetColorTexture(0, 0, 0, 0)
    frame.rim_line = library.create_surface(frame, "ARTWORK", -1, frame.rim)
    frame.well = frame:CreateTexture(nil, "ARTWORK", nil, 1)
    frame.well:SetColorTexture(colours.ground[1], colours.ground[2], colours.ground[3], 1)
    frame.portrait = frame:CreateTexture(nil, "ARTWORK", nil, 2)
    if unit == "player" then create_fight_glow(frame) end
    frame.view = CreateFrame("Frame", nil, frame)
    frame.view:SetClipsChildren(true)
    frame.view:SetFrameLevel(frame:GetFrameLevel() + 1)
    frame.model = CreateFrame("PlayerModel", nil, frame.view)
    frame.rounding = CreateFrame("Frame", nil, frame)
    frame.rounding:SetAllPoints()
    frame.rounding:SetFrameLevel(frame:GetFrameLevel() + 12)
    frame.edges = create_rim(frame.rounding)
    frame.crown = frame.rounding:CreateTexture(nil, "OVERLAY")
    frame.crown:SetTexture(library.media .. "Crown")
    frame.crown:SetVertexColor(colours.gold[1], colours.gold[2], colours.gold[3], 1)
    frame.crown:Hide()
    frame.shield = CreateFrame("Frame", nil, frame)
    frame.shield:SetFrameLevel(frame:GetFrameLevel() + 13)
    frame.shield.outer = library.create_surface(frame.shield, "BACKGROUND", 0)
    frame.shield.line = library.create_surface(frame.shield, "BACKGROUND", 1)
    frame.shield.inner = library.create_surface(frame.shield, "BACKGROUND", 2)
    frame.level = library.create_text(frame.shield, "caption", BADGE_TEXT)
    frame.level:SetPoint("CENTER")
    frame.name = library.create_text(frame, "bold")
    frame.name:SetJustifyH("LEFT")
    frame.name:SetWordWrap(false)
    frame.class = library.create_text(frame, "small", colours.label)
    if unit == "target" then
        frame.name:SetJustifyH("RIGHT")
        frame.chevron = frame:CreateTexture(nil, "OVERLAY")
        frame.chevron:SetTexture(library.media .. "Chevron")
        frame.quest = frame.shield:CreateTexture(nil, "OVERLAY")
        frame.quest:SetTexture(library.media .. "QuestBag")
    end
    frame.health = library.create_bar(frame, unit == "target" and "enemy" or "health")
    frame.power = library.create_bar(frame, "power")
    for _, bar in ipairs({ frame.health, frame.power }) do
        bar.ratio = library.create_ratio(bar, "figure")
        bar.ratio:SetPoint("CENTER")
        bar.ratio:SetFrameLevel(bar:GetFrameLevel() + 3)
    end
    for _, bar in ipairs({ frame.health, frame.power }) do
        bar.figures = unit ~= "pet"
        bar.percent = library.create_text(bar, "figure")
        bar.percent:SetPoint("CENTER")
        bar.percent:SetDrawLayer("OVERLAY", 7)
    end
    if unit ~= "player" then
        RegisterUnitWatch(frame)
        frame.unit_watched = true
    end
    frames[unit] = frame
    return frame
end

local function update_bars_layout(frame)
    local small = frame.unit == "pet"
    local side = frame.mirrored and "RIGHT" or "LEFT"
    local away = frame.mirrored and "LEFT" or "RIGHT"
    local sign = frame.mirrored and -1 or 1
    local pad, gap, between = library.read_size(-2), library.read_size(-4), library.read_size(-6)
    local column = (small and library.read_size(4) or library.read_size(6)) * 4
    local bar = library.read_size(small and -4 or 0)
    local line = library.read_size(small and -1 or 1)
    local height = frame.rim:GetHeight()
    local rise = math.floor((height - (line + gap + 2 * bar + between + (frame.extra_height or 0))) / 2 + 0.5)
    for index, each in ipairs({ frame.health, frame.power }) do
        each:ClearAllPoints()
        each:SetSize(column, bar)
        if index == 1 then
            each:SetPoint("TOP" .. side, frame.rim, "TOP" .. away, sign * pad, -(rise + line + gap))
        else
            each:SetPoint("TOP", frame.health, "BOTTOM", 0, -between)
        end
        library.update_bar_shape(each, between)
    end
    return column
end

local function update_texts_layout(frame)
    local small = frame.unit == "pet"
    local gap = library.read_size(-4)
    frame.name:SetFontObject(library.read_frame_font(small and "caption" or "bold"))
    frame.name:ClearAllPoints()
    frame.class:SetFontObject(library.read_frame_font("small"))
    if frame.chevron then
        local size = library.read_size(0)
        frame.chevron:SetSize(size, math.floor(size * 0.75 + 0.5))
        frame.name:SetPoint("BOTTOMRIGHT", frame.health, "TOPRIGHT", 0, gap)
        frame.name:SetPoint("LEFT", frame.class, "RIGHT", gap, 0)
    else
        frame.class:ClearAllPoints()
        frame.class:SetPoint("BOTTOMRIGHT", frame.health, "TOPRIGHT", 0, gap)
        frame.name:SetPoint("BOTTOMLEFT", frame.health, "TOPLEFT", 0, gap)
        frame.name:SetPoint("RIGHT", frame.class, "LEFT", -gap, 0)
    end
end

local function update_portrait_layout(frame)
    local small = frame.unit == "pet"
    local portrait, rim, radius = library.read_size(small and 4 or 6), library.read_size(-6), library.read_size(-2)
    local side = frame.mirrored and "RIGHT" or "LEFT"
    local away = frame.mirrored and "LEFT" or "RIGHT"
    local sign = frame.mirrored and -1 or 1
    local inset = library.read_size(-4)
    frame.rim:ClearAllPoints()
    frame.rim:SetSize(portrait + 2 * rim, portrait + 2 * rim)
    frame.rim:SetPoint(side, frame, side, sign * library.read_size(0), 0)
    frame.portrait:ClearAllPoints()
    frame.portrait:SetSize(portrait, portrait)
    frame.portrait:SetPoint("CENTER", frame.rim, "CENTER")
    frame.well:ClearAllPoints()
    frame.well:SetAllPoints(frame.portrait)
    local crown = library.read_size(2)
    frame.crown:SetSize(crown, crown)
    frame.crown:ClearAllPoints()
    frame.crown:SetPoint("CENTER", frame.rim, "TOP", 0, math.floor(crown * 0.2 + 0.5))
    if frame.fight then
        local glow = (portrait + 2 * rim) * FIGHT_SPREAD
        frame.fight:SetSize(glow, glow)
        frame.fight:ClearAllPoints()
        frame.fight:SetPoint("CENTER", frame.rim, "CENTER")
    end
    update_rim(frame.edges, frame.rim, radius)
    library.update_surface(frame.rim_line, -1, radius + 1, BLACK, BLACK)
    for _, side in pairs(frame.edges) do
        local colour = frame.rim_colour or DARK
        side:SetVertexColor(colour[1], colour[2], colour[3], 1)
    end
    frame.view:ClearAllPoints()
    frame.view:SetAllPoints(frame.portrait)
    frame.model:SetAllPoints(frame.view)
    frame.shield:ClearAllPoints()
    update_shield_size(frame)
    frame.shield:SetPoint("BOTTOM" .. away, frame.rim, "BOTTOM" .. away, sign * inset, -inset)
    if frame.quest then
        local bag, offset = library.read_size(3), library.read_size(2) / 2 - inset
        frame.quest:ClearAllPoints()
        frame.quest:SetSize(bag, bag)
        frame.quest:SetPoint("CENTER", frame.rim, "BOTTOM" .. side, sign * offset, offset)
    end
    return portrait + 2 * rim
end

local function update_layout(frame)
    library.update_frame(frame)
    local pad = library.read_size(-2)
    local ring = update_portrait_layout(frame)
    local column = update_bars_layout(frame)
    update_texts_layout(frame)
    frame:SetSize(ring + column + library.read_size(0) + 2 * pad, ring + 2 * pad)
end

local function update_units()
    for _, frame in pairs(frames) do
        if not InCombatLockdown() then
            update_layout(frame)
        end
        update_identity(frame)
        update_values(frame)
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

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
local function update_event(event, unit)
    if event == "PLAYER_LOGIN" then
        local player = create_frame("player", false)
        library.create_place(player, "player", "CENTER", PlayerFrame or UIParent, 0, 0)
        local target = create_frame("target", true)
        library.create_place(target, "target", "CENTER", TargetFrame or UIParent, 0, 0)
        local pet = create_frame("pet", true)
        library.create_place(pet, "pet", "TOPRIGHT", player, 0, -(library.read_cast_room() + 2 * library.read_size(-4)), "BOTTOMRIGHT")
        delete_blizzard_frames()
        library.create_element("units", { title = UNITFRAME_LABEL or "Units", update = update_units })
        for _, name in ipairs({ "PLAYER_TARGET_CHANGED", "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER", "UNIT_LEVEL", "UNIT_NAME_UPDATE", "UNIT_PORTRAIT_UPDATE", "UNIT_CLASSIFICATION_CHANGED", "PLAYER_ENTERING_WORLD", "UNIT_PET", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "UNIT_MODEL_CHANGED", "QUEST_LOG_UPDATE", "UNIT_QUEST_LOG_CHANGED", "COMBAT_TEXT_UPDATE", "PLAYER_UPDATE_RESTING", "PARTY_LEADER_CHANGED", "GROUP_ROSTER_UPDATE" }) do
            pcall(events.RegisterEvent, events, name)
        end
        update_units()
        C_Timer.After(1, function() library.update_safely("units portrait", update_units) end)
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_UPDATE_RESTING" then
        update_fight_glow()
    elseif event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_ENTERING_WORLD" or event == "UNIT_PET" or event == "PLAYER_REGEN_ENABLED" or event == "QUEST_LOG_UPDATE" or event == "UNIT_QUEST_LOG_CHANGED" or event == "PARTY_LEADER_CHANGED" or event == "GROUP_ROSTER_UPDATE" then
        update_fight_glow()
        update_units()
    elseif event == "COMBAT_TEXT_UPDATE" then
        local bar = GAINS[unit] and frames.player and frames.player[GAINS[unit]]
        if bar then library.render_bar_shine(bar) end
    elseif frames[unit] then
        if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" then
            update_values(frames[unit])
        else
            update_identity(frames[unit])
        end
    end
end

events:SetScript("OnEvent", function(_, event, unit)
    library.update_safely("units " .. event, update_event, event, unit)
end)

function vga.read_power_kind(kind)
    return POWERS[kind] or "power"
end
