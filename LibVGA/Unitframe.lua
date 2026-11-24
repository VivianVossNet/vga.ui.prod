-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's unit frame, a meta-object (K0864, K0860): one object in three tiers, each left- or right-aligned by its side - the primary, the player and the target, the secondary, the same frame small for the pets, and the tertiary, a party member's row worn by the party and by the target of target (K0698). The portrait tiers: the level's shield, the name and its class or kind, health and power, the portrait's rim one smooth, rounded frame in one colour over the picture, its corners and sides cut from one texture - seven outside, three thick, four inside -, clicked to target; the group's leader marked by a small filled gold crown centred on the portrait's top edge (K0614), its gold shaded in its own texture, shown untinted (K0724); the player's portrait pulsing red in a fight and blue in a resting place, the red winning until the fight is over (K0551); a dead unit's portrait grey and still until it lives (K0702); a player's class not a word but the class dot where the word stood, its name in a tooltip (K0717); the target's kind beside a chevron and its quest bag at the portrait. The tertiary row: the level in gold, the class dot, the name with the leader's crown after its words on the reading side (K0614, K0755), a thin health bar, all grey with an OFFLINE beneath while the member is offline, and where a pet is given, its bar inside the row, shorter, a secure button of its own. Made by library.create_unit_frame(name, unit, plan) - plan.tier primary, secondary or tertiary, plan.side left or right, plan.widget the widget its corner opens (a widget frame with its own ground), else plan.parent the frame it stands in, plan.pet a row's pet by name and unit -, laid by library.update_unit_frame_layout, filled from its unit by library.update_unit_frame (for a row the whole row), library.update_unit_frame_values (health and power of the portrait tiers) and library.update_unit_frame_glow (the player's pulse); its size read by library.read_unit_frame_size, the level's colour against the player by library.read_level_colour and a power's bar by library.read_power_kind. What a frame shows beyond its tier is asked by its plan, never read from its unit's name (K0865): plan.always for a unit that is always there, never watched - the player -; plan.glow for the pulse in a fight and at rest; plan.kind for the rank's chevron, the quest bag, the name at the right and the enemy's colour of the health.

-- {K0865} {K0864} {K0860} {K0267} {K0268} {K0275} {K0276} {K0277} {K0278} {K0279} {K0294} {K0297} {K0299} {K0300} {K0302} {K0329} {K0330} {K0334} {K0342} {K0345} {K0346} {K0354} {K0360} {K0379} {K0481} {K0551} {K0614} {K0698} {K0702} {K0717} {K0724} {K0755}

local library = LibVGA
local colours = library.colours
local SECURE = "SecureUnitButtonTemplate"
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
local LEVEL_TEXT = { 0.945, 0.812, 0.431 }
local OFFLINE = { 0.5, 0.5, 0.52 }
local OFFLINE_SMALLER = 4
local POWERS = { [0] = "power", [1] = "rage", [2] = "focus", [3] = "energy", [6] = "runic" }
local FIGHT = { 0.86, 0.12, 0.1 }
local RESTING = { 0.2, 0.5, 0.95 }
local FIGHT_LOW = 0.2
local FIGHT_HIGH = 0.75
local FIGHT_PULSE = 1.4
local FIGHT_SPREAD = 64 / 42 * 0.96
local CUT = 28 / 64
local RIM_PIECES = {
    TOPLEFT = { 0, CUT, 0, CUT }, TOPRIGHT = { 1 - CUT, 1, 0, CUT },
    BOTTOMLEFT = { 0, CUT, 1 - CUT, 1 }, BOTTOMRIGHT = { 1 - CUT, 1, 1 - CUT, 1 },
    TOP = { CUT, 1 - CUT, 0, CUT }, BOTTOM = { CUT, 1 - CUT, 1 - CUT, 1 },
    LEFT = { 0, CUT, CUT, 1 - CUT }, RIGHT = { 1 - CUT, 1, CUT, 1 - CUT },
}

function library.read_level_colour(unit, own)
    if not UnitCanAttack("player", unit) then return own end
    local level = UnitLevel(unit)
    if not level or level <= 0 then return SKULL end
    local colour = GetCreatureDifficultyColor and GetCreatureDifficultyColor(level)
    return colour and { colour.r, colour.g, colour.b } or own
end

function library.read_power_kind(kind)
    return POWERS[kind] or "power"
end

local function read_sides(frame)
    if frame.side == "right" then return "RIGHT", "LEFT", -1 end
    return "LEFT", "RIGHT", 1
end

local function read_portrait_side(tier)
    return library.read_size(tier == "secondary" and 4 or 6)
end

local function read_ring(tier)
    return read_portrait_side(tier) + 2 * library.read_size(-6)
end

local function read_column(tier)
    return (tier == "secondary" and library.read_size(4) or library.read_size(6)) * 4
end

function library.read_unit_frame_size(tier)
    local pad = library.read_size(-2)
    if tier == "tertiary" then return library.read_size(6) * 4, library.read_size(4) + 2 * pad end
    local ring = read_ring(tier)
    return ring + read_column(tier) + library.read_size(0) + 2 * pad, ring + 2 * pad
end

local function update_unit_clicks(button, unit)
    button.unit = unit
    button:SetAttribute("unit", unit)
    button:SetAttribute("*type1", "target")
    button:SetAttribute("*type2", "togglemenu")
    button:RegisterForClicks("AnyUp")
end

local function create_unit_button(name, parent, unit)
    local button = CreateFrame("Button", name, parent, SECURE)
    update_unit_clicks(button, unit)
    RegisterUnitWatch(button)
    return button
end

local function create_widget_button(name, unit, plan)
    local frame = library.create_frame(name, plan.parent, SECURE)
    update_unit_clicks(frame, unit)
    frame.corner:SetFrameLevel(frame:GetFrameLevel() + 3)
    frame.ground_key = plan.widget
    frame.corner:SetScript("OnClick", function(corner) library.update_safely("options", library.render_widget, corner, plan.widget) end)
    if not plan.always then
        RegisterUnitWatch(frame)
        frame.unit_watched = true
    end
    return frame
end

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

local function create_crown(owner)
    local crown = owner:CreateTexture(nil, "OVERLAY")
    crown:SetTexture(library.media .. "Crown")
    crown:SetVertexColor(1, 1, 1, 1)
    crown:Hide()
    return crown
end

local function create_portrait(frame)
    frame.rim = frame:CreateTexture(nil, "ARTWORK", nil, 0)
    frame.rim:SetColorTexture(0, 0, 0, 0)
    frame.rim_line = library.create_surface(frame, "ARTWORK", -1, frame.rim)
    frame.well = frame:CreateTexture(nil, "ARTWORK", nil, 1)
    frame.well:SetColorTexture(colours.ground[1], colours.ground[2], colours.ground[3], 1)
    frame.portrait = frame:CreateTexture(nil, "ARTWORK", nil, 2)
    if frame.glow then create_fight_glow(frame) end
    frame.view = CreateFrame("Frame", nil, frame)
    frame.view:SetClipsChildren(true)
    frame.view:SetFrameLevel(frame:GetFrameLevel() + 1)
    frame.model = CreateFrame("PlayerModel", nil, frame.view)
    frame.rounding = CreateFrame("Frame", nil, frame)
    frame.rounding:SetAllPoints()
    frame.rounding:SetFrameLevel(frame:GetFrameLevel() + 12)
    frame.edges = create_rim(frame.rounding)
    frame.crown = create_crown(frame.rounding)
end

local function create_shield(frame)
    frame.shield = CreateFrame("Frame", nil, frame)
    frame.shield:SetFrameLevel(frame:GetFrameLevel() + 13)
    frame.shield.outer = library.create_surface(frame.shield, "BACKGROUND", 0)
    frame.shield.line = library.create_surface(frame.shield, "BACKGROUND", 1)
    frame.shield.inner = library.create_surface(frame.shield, "BACKGROUND", 2)
    frame.level = library.create_text(frame.shield, "figures_caption", LEVEL_TEXT)
    frame.level:SetPoint("CENTER")
end

local function create_portrait_texts(frame)
    frame.name = library.create_text(frame, "bold")
    frame.name:SetJustifyH("LEFT")
    frame.name:SetWordWrap(false)
    frame.class = library.create_text(frame, "small", colours.label)
    frame.class_spot = library.create_class_dot(frame, true)
    if not frame.kind then return end
    frame.name:SetJustifyH("RIGHT")
    frame.chevron = frame:CreateTexture(nil, "OVERLAY")
    frame.chevron:SetTexture(library.media .. "Chevron")
    frame.quest = frame.shield:CreateTexture(nil, "OVERLAY")
    frame.quest:SetTexture(library.media .. "QuestBag")
end

local function create_portrait_bars(frame)
    frame.health = library.create_bar(frame, frame.kind and "enemy" or "health")
    frame.power = library.create_bar(frame, "power")
    for _, bar in ipairs({ frame.health, frame.power }) do
        bar.ratio = library.create_ratio(bar, "figure")
        bar.ratio:SetPoint("CENTER")
        bar.ratio:SetFrameLevel(bar:GetFrameLevel() + 3)
        bar.figures = frame.tier == "primary"
        bar.percent = library.create_text(bar, "figures_figure")
        bar.percent:SetPoint("CENTER")
        bar.percent:SetDrawLayer("OVERLAY", 7)
    end
end

local function create_row(row, pet)
    row.level = library.create_text(row, "figures_caption", LEVEL_TEXT)
    row.level:SetJustifyH("RIGHT")
    row.spot = library.create_class_dot(row)
    row.name = library.create_text(row, "bold")
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
    row.crown = create_crown(row)
    row.health = library.create_bar(row, "health")
    row.offline = library.create_text(row, "small", OFFLINE)
    row.offline:SetText(string.upper(PLAYER_OFFLINE or "Offline"))
    if not pet then return end
    row.pet = create_unit_button(pet.name, row, pet.unit)
    row.pet.health = library.create_bar(row.pet, "health")
    row.pet.health:SetAllPoints()
    row.pet.health:SetAlpha(0.85)
end

function library.create_unit_frame(name, unit, plan)
    local frame = plan.widget and create_widget_button(name, unit, plan) or create_unit_button(name, plan.parent, unit)
    frame.tier, frame.side = plan.tier, plan.side
    frame.glow, frame.kind = plan.glow, plan.kind
    if plan.tier == "tertiary" then
        create_row(frame, plan.pet)
        return frame
    end
    create_portrait(frame)
    create_shield(frame)
    create_portrait_texts(frame)
    create_portrait_bars(frame)
    return frame
end

local function update_shield_size(frame)
    local side = library.read_size(2)
    frame.level:SetFontObject(library.read_font("figures_caption"))
    frame.level:SetTextColor(unpack(frame.level_colour or LEVEL_TEXT))
    local width = math.ceil(frame.level:GetStringWidth()) + 2 * library.read_size(-6)
    frame.shield:SetSize(math.max(side, width), side)
    local radius = library.read_size(-4)
    library.update_surface(frame.shield.outer, -2, radius + 2, colours.gold, colours.gold, BADGE_RING)
    library.update_surface(frame.shield.line, -1, radius + 1, BLACK, BLACK)
    library.update_surface(frame.shield.inner, 0, radius, BADGE_TOP, BADGE_BOTTOM)
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

local function update_rim_colour(frame, colour)
    for _, piece in pairs(frame.edges) do
        piece:SetVertexColor(colour[1], colour[2], colour[3], 1)
    end
end

local function update_bars_layout(frame)
    local small = frame.tier == "secondary"
    local side, away, sign = read_sides(frame)
    local pad, gap, between = library.read_size(-2), library.read_size(-4), library.read_size(-6)
    local column = read_column(frame.tier)
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
end

local function update_texts_layout(frame)
    local gap = library.read_size(-4)
    frame.name:SetFontObject(library.read_frame_font(frame.tier == "secondary" and "caption" or "bold"))
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

local function update_marks_layout(frame, side, away, sign)
    local inset = library.read_size(-4)
    local crown = library.read_size(2)
    frame.crown:SetSize(crown, crown)
    frame.crown:ClearAllPoints()
    frame.crown:SetPoint("CENTER", frame.rim, "TOP", 0, math.floor(crown * 0.2 + 0.5))
    frame.shield:ClearAllPoints()
    update_shield_size(frame)
    frame.shield:SetPoint("BOTTOM" .. away, frame.rim, "BOTTOM" .. away, sign * inset, -inset)
    if not frame.quest then return end
    local bag, offset = library.read_size(3), library.read_size(2) / 2 - inset
    frame.quest:ClearAllPoints()
    frame.quest:SetSize(bag, bag)
    frame.quest:SetPoint("CENTER", frame.rim, "BOTTOM" .. side, sign * offset, offset)
end

local function update_portrait_layout(frame)
    local portrait, ring, radius = read_portrait_side(frame.tier), read_ring(frame.tier), library.read_size(-2)
    local side, away, sign = read_sides(frame)
    frame.rim:ClearAllPoints()
    frame.rim:SetSize(ring, ring)
    frame.rim:SetPoint(side, frame, side, sign * library.read_size(0), 0)
    frame.portrait:ClearAllPoints()
    frame.portrait:SetSize(portrait, portrait)
    frame.portrait:SetPoint("CENTER", frame.rim, "CENTER")
    frame.well:ClearAllPoints()
    frame.well:SetAllPoints(frame.portrait)
    if frame.fight then
        frame.fight:SetSize(ring * FIGHT_SPREAD, ring * FIGHT_SPREAD)
        frame.fight:ClearAllPoints()
        frame.fight:SetPoint("CENTER", frame.rim, "CENTER")
    end
    update_rim(frame.edges, frame.rim, radius)
    library.update_surface(frame.rim_line, -1, radius + 1, BLACK, BLACK)
    update_rim_colour(frame, frame.rim_colour or DARK)
    frame.view:ClearAllPoints()
    frame.view:SetAllPoints(frame.portrait)
    frame.model:SetAllPoints(frame.view)
    update_marks_layout(frame, side, away, sign)
end

local function update_row_layout(row)
    local base, pad = library.read_base(), library.read_size(-2)
    local bar, dot = math.max(4, library.read_size(-4)), library.read_class_dot_size()
    local level = math.floor(base * 1.3 + 0.5)
    local near, far, sign = read_sides(row)
    row.level:SetFontObject(library.read_font("figures_caption"))
    row.level:SetJustifyH(far)
    row.level:ClearAllPoints()
    row.level:SetPoint(near, row, near, sign * pad, 0)
    row.level:SetWidth(level)
    row.spot:ClearAllPoints()
    row.spot:SetPoint(near, row, near, sign * (2 * pad + level), 0)
    row.spot:SetSize(dot, dot)
    row.name:SetFontObject(library.read_frame_font("bold"))
    row.name:SetJustifyH(near)
    row.name:ClearAllPoints()
    row.name:SetPoint("TOP" .. near, row, "TOP" .. near, sign * (2 * pad + level + dot + pad), -pad)
    row.name:SetPoint(far, row, far, -sign * library.read_size(1), 0)
    row.health:ClearAllPoints()
    row.health:SetPoint("TOP" .. near, row.name, "BOTTOM" .. near, 0, -library.read_size(-6))
    row.health:SetPoint(far, row, far, -sign * library.read_size(1), 0)
    row.health:SetHeight(bar)
    library.update_bar_shape(row.health, library.read_size(-6))
    return bar, 2 * pad + level + dot + pad
end

local function update_offline_layout(row)
    local near = read_sides(row)
    local face, size, flags = library.read_font("small"):GetFont()
    row.offline:SetFont(face, math.max(size - OFFLINE_SMALLER, 6), flags or "")
    row.offline:SetTextColor(unpack(OFFLINE))
    row.offline:ClearAllPoints()
    row.offline:SetPoint("TOP" .. near, row.health, "BOTTOM" .. near, 0, -library.read_size(-6))
end

local function update_pet_layout(row, bar, left)
    local near, _, sign = read_sides(row)
    local width = library.read_unit_frame_size("tertiary")
    local below = library.read_size(-2) + library.read_size(1) + library.read_size(-6) + bar + library.read_size(-4)
    row.pet:ClearAllPoints()
    row.pet:SetPoint("TOP" .. near, row, "TOP" .. near, sign * left, -below)
    row.pet:SetSize(math.floor((width - left - library.read_size(1)) * 0.6 + 0.5), bar + 1)
    library.update_bar_shape(row.pet.health, library.read_size(-6))
end

local function update_portrait_frame_layout(frame)
    update_portrait_layout(frame)
    update_bars_layout(frame)
    update_texts_layout(frame)
    frame:SetSize(library.read_unit_frame_size(frame.tier))
end

local function update_row_frame_layout(row)
    row:SetSize(library.read_unit_frame_size(row.tier))
    local bar, left = update_row_layout(row)
    if not row.pet then return end
    update_offline_layout(row)
    update_pet_layout(row, bar, left)
end

function library.update_unit_frame_layout(frame)
    if frame.ground_key then library.update_frame(frame) end
    if frame.tier == "tertiary" then return update_row_frame_layout(frame) end
    update_portrait_frame_layout(frame)
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

function library.update_unit_frame_values(frame)
    local unit = frame.unit
    if not UnitExists(unit) then return end
    local health, most = UnitHealth(unit), UnitHealthMax(unit)
    library.update_bar_value(frame.health, health, most)
    update_bar_text(frame.health, health, most, function() return UnitHealthPercent(unit, true, CurveConstants.ScaleTo100) end)
    local kind = UnitPowerType(unit)
    library.update_bar_kind(frame.power, library.read_power_kind(kind))
    local power, top = UnitPower(unit), UnitPowerMax(unit)
    library.update_bar_value(frame.power, power, top)
    update_bar_text(frame.power, power, top, function() return UnitPowerPercent(unit, kind, false, CurveConstants.ScaleTo100) end)
end

local function read_rim_colour(unit)
    if UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        local colour = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if colour then return { colour.r, colour.g, colour.b } end
        return DARK
    end
    return KINDS[UnitClassification(unit)] or DARK
end

local function update_class_spot(frame)
    local size = library.read_class_dot_size()
    frame.class:SetText(" ")
    frame.class:SetWidth(size)
    library.update_class_dot(frame.class_spot, library.read_class_colour(frame.unit), UnitClass(frame.unit))
    frame.class_spot:ClearAllPoints()
    frame.class_spot:SetPoint("CENTER", frame.class, "CENTER")
    frame.class_spot:Show()
end

local function update_target_kind(frame, kind)
    local unit = frame.unit
    frame.class:SetFontObject(library.read_frame_font(kind and "bold" or "small"))
    if UnitIsPlayer(unit) then
        update_class_spot(frame)
    else
        frame.class_spot:Hide()
        frame.class:SetWidth(0)
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

local function update_target_parts(frame)
    local unit = frame.unit
    local kind = KINDS[UnitClassification(unit)]
    frame.health.fraction = nil
    frame.power.fraction = nil
    frame.chevron:SetShown(kind ~= nil)
    local related = C_QuestLog and C_QuestLog.UnitIsRelatedToActiveQuest and C_QuestLog.UnitIsRelatedToActiveQuest(unit)
    frame.quest:SetShown(not (issecretvalue and issecretvalue(related)) and related == true)
    update_target_kind(frame, kind)
    library.update_bar_kind(frame.health, UnitIsFriend("player", unit) and "health" or "enemy")
end

local function update_face(frame)
    local unit = frame.unit
    SetPortraitTexture(frame.portrait, unit, true)
    frame.dead = UnitIsDeadOrGhost(unit) == true
    frame.portrait:SetDesaturated(frame.dead)
    local moving = library.read_faces_moving() and UnitIsVisible(unit) and not frame.dead
    frame.model:SetShown(moving)
    frame.portrait:SetShown(not moving)
    if moving then
        frame.model:SetUnit(unit)
        frame.model:SetPortraitZoom(1)
        frame.model:SetCamDistanceScale(1)
    end
end

local function update_portrait_frame(frame)
    local unit = frame.unit
    if not UnitExists(unit) then return false end
    frame.name:SetText(library.read_unit_name(unit))
    frame.crown:SetShown(frame.tier == "primary" and UnitIsGroupLeader(unit) == true)
    local level = UnitLevel(unit)
    frame.level:SetText(level and level > 0 and level or "??")
    frame.level_colour = library.read_level_colour(unit, LEVEL_TEXT)
    update_shield_size(frame)
    update_face(frame)
    frame.rim_colour = read_rim_colour(unit)
    update_rim_colour(frame, frame.rim_colour)
    if frame.chevron then
        update_target_parts(frame)
    elseif frame.tier == "primary" then
        update_class_spot(frame)
    else
        frame.class_spot:Hide()
        frame.class:SetText("")
    end
    return true
end

local function update_crown_placed(row)
    local crown = library.read_size(0)
    local box = row.name:GetWidth()
    local written = math.ceil(row.name:GetStringWidth())
    local after = (box and box > 0 and math.min(written, box) or written) + library.read_size(-4)
    row.crown:SetSize(crown, crown)
    row.crown:ClearAllPoints()
    if row.side == "right" then
        row.crown:SetPoint("RIGHT", row.name, "RIGHT", -after, 0)
    else
        row.crown:SetPoint("LEFT", row.name, "LEFT", after, 0)
    end
end

local function update_row(row)
    local unit = row.unit
    if not UnitExists(unit) then return false end
    local level = UnitLevel(unit)
    local online = UnitIsConnected(unit)
    row.level:SetText(level and level > 0 and level or "??")
    row.level:SetTextColor(unpack(online and LEVEL_TEXT or OFFLINE))
    row.name:SetText(library.read_unit_name(unit))
    update_crown_placed(row)
    row.crown:SetShown(UnitIsGroupLeader(unit) == true)
    row.name:SetTextColor(unpack(online and colours.ink or OFFLINE))
    library.update_class_dot(row.spot, online and library.read_class_colour(unit) or OFFLINE)
    library.update_bar_kind(row.health, online and "health" or "tapped")
    row.offline:SetShown(not online)
    library.update_bar_value(row.health, UnitHealth(unit), UnitHealthMax(unit))
    local pet = row.pet and row.pet.unit
    if pet and UnitExists(pet) then library.update_bar_value(row.pet.health, UnitHealth(pet), UnitHealthMax(pet)) end
    return true
end

function library.update_unit_frame(frame)
    if frame.tier == "tertiary" then return update_row(frame) end
    return update_portrait_frame(frame)
end

function library.update_unit_frame_glow(frame)
    local glow = frame and frame.fight
    if not glow then return end
    local fighting = UnitAffectingCombat("player") and true or false
    local resting = not fighting and IsResting and IsResting() and true or false
    local colour = fighting and FIGHT or RESTING
    glow:SetVertexColor(colour[1], colour[2], colour[3], 1)
    glow:SetShown(fighting or resting)
    if (fighting or resting) and not glow.pulse:IsPlaying() then glow.pulse:Play() end
    if not (fighting or resting) then glow.pulse:Stop() end
end
