-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: Two transparent arcs either side of the character, wide enough to clear it and centred on its middle, as manual/view/vga-hud.html draws them (D): twelve segments each, lit one by one - or, as the settings say (arc_shape), half arcs, half as high, of six segments for the same values, the beads closer together -; behind each arc, as the settings say (»Rahmen«, off by default), a broad stroke of the frames' own ground and opacity, rounded at its ends, eight draft pixels clear of the segments and beads all round, so the arc reads on a light ground (K0563); an arc with nothing to show fades slowly out, each on its own, and back in when it has. Each side shows what the settings choose - the range, the threat, the target's cast or its health, the player's own health - filled in green as the target's, with or without a target -, the player's own resource, named as the game names the class's power - Mana, Wut, Energie, for a druid all three -, filling the arc in the power bar's colour, with or without a target, a rogue's or cat's combo points as five beads beside it, lit in VGA's orange when earned -, or nothing -, by default the range at the left and the threat at the right. The range to an attackable target filling from its foot as the target comes nearer - the distance known in steps by the game's own range checks - the player's harmful spells and a few items, each at the range the game gives its spell, and the interact distances of 10 and 28 yards -, shown as the smallest step the target stands within, »>« before the largest when beyond it -, its lit segments in one colour that tells the reach - red when the target stands near, through orange and yellow to a deep green at the edge of the best range of the player's class, by the steps' yards -; every segment grey where it stands beyond that range or beyond every step; the threat drawn from the target fills in the threat meter's five colours, the health in green, each segment set by the game from the value even where it is secret; the target's cast fills as it runs, gold while it can be interrupted, grey while not, its spell's name at the head - for the moment to interrupt. Each arc's value stands at its head or its foot, or not at all, as the settings say. At each arc's foot a small gold corner, the only part of the arcs that takes the mouse, opens the settings on the arcs' tab, where every change shows live; there each arc is one row with a pop-up menu whose sections are »Ich« - the resource, the own health - and »Ziel« - range, threat, cast, health -, then none (K0564, K0565). Free to be placed while arranging. As the settings say (»Sichtbar«, »Im Kampf« by default), out of combat both arcs fade slowly out, over three seconds, and show at once, without a fade, the moment a fight begins; with »Immer« they stand as before; an arc's preview eye shows it out of combat too (K0675). Each arc's gold corner fades with its arc and takes no mouse while the arc is gone (K0677).

-- {K0392} {K0393} {K0395} {K0400} {K0416} {K0417} {K0418} {K0501} {K0502} {K0563} {K0564} {K0574} {K0581} {K0582} {K0583} {K0675} {K0677}

local _, vga = ...
local library = LibVGA
local DRAFT_BASE = 13
local SEGMENTS = 12
local SPAN = 120
local RADIUS = 150
local RANGE_MOST = 40
local STEP = 0.01
local FADE = 1.5
local FADE_CALM = 3
local TRACK = { 0, 0, 0, 0.35 }
local GREY = { 0.54, 0.55, 0.57 }
local MELEE = 10
local REACH = { { 0.9, 0.28, 0.24 }, { 0.96, 0.55, 0.2 }, { 0.95, 0.79, 0.25 }, { 0.16, 0.6, 0.27 } }
local OUT_OF_REACH = { 0.45, 0.46, 0.48 }
local HEALTH = { 0.37, 0.82, 0.42 }
local MARK_OPEN = { 0.2, 0.21, 0.24 }
local COMBO_MARKS = 5
local BAND_GROUND = { 0.071, 0.075, 0.09 }
local CORNER_OUT = 22
local BANDS = {
    full = { file = "ArcBandFull", left = -177.5, top = 146.73, width = 128, height = 512 },
    half = { file = "ArcBandHalf", left = -177.5, top = 83.82, width = 64, height = 256 },
}
local BEST = { HUNTER = 75, MAGE = 133, WARLOCK = 686, PRIEST = 585, DRUID = 5176, SHAMAN = 403, WARRIOR = 78, ROGUE = 1752 }
local RANGE_ITEMS = { 8149, 10645, 835, 4941, 18904, 13289, 9328, 7734, 4945, 17202 }
local RANGED_YARDS = { HUNTER = 35, MAGE = 35, WARLOCK = 30, PRIEST = 30, DRUID = 30, SHAMAN = 30, WARRIOR = 30, ROGUE = 30 }
local MELEE_YARDS = 5
local NEAR = 11
local SAMPLE = 67
local SAMPLE_YARDS = 13
local previews = {}
local checks = {}
local arcs

local function read_draft(pixels)
    return math.floor(pixels * library.read_base() / DRAFT_BASE + 0.5)
end

local function read_mix(from, to, share)
    return { from[1] + (to[1] - from[1]) * share, from[2] + (to[2] - from[2]) * share, from[3] + (to[3] - from[3]) * share }
end

local function read_range_colour(yards, best_yards, best)
    if not yards or (yards > best_yards and not best) then return OUT_OF_REACH end
    local place = math.max(0, math.min(1, yards / best_yards)) * (#REACH - 1)
    local from = math.min(math.floor(place) + 1, #REACH - 1)
    return read_mix(REACH[from], REACH[from + 1], place - (from - 1))
end

local function create_segment(side)
    local segment = CreateFrame("StatusBar", nil, side)
    segment:SetStatusBarTexture(library.media .. "ArcSegment")
    segment:SetMinMaxValues(0, STEP)
    segment:SetValue(0)
    segment.track = segment:CreateTexture(nil, "BACKGROUND")
    segment.track:SetTexture(library.media .. "ArcSegment")
    segment.track:SetAllPoints()
    segment.track:SetVertexColor(TRACK[1], TRACK[2], TRACK[3], TRACK[4])
    return segment
end

local function update_corner_faded(side)
    local corner = side.corner
    if not corner then return end
    local alpha = side:IsShown() and side:GetAlpha() or 0
    if corner:GetAlpha() == alpha then return end
    corner:SetAlpha(alpha)
    corner:EnableMouse(alpha > 0)
end

local function update_fade(side, elapsed)
    local alpha = side:GetAlpha()
    update_corner_faded(side)
    if alpha == side.wanted then return end
    local step = elapsed / (side.fade or FADE)
    side:SetAlpha(side.wanted > alpha and math.min(side.wanted, alpha + step) or math.max(side.wanted, alpha - step))
    update_corner_faded(side)
end

local function read_count()
    return LibVGASettings.arc_shape == "half" and SEGMENTS / 2 or SEGMENTS
end

local function read_span()
    return LibVGASettings.arc_shape == "half" and SPAN / 2 or SPAN
end

local function create_side(mirror)
    local side = CreateFrame("Frame", nil, arcs)
    side:SetAllPoints(arcs)
    side.mirror = mirror
    side.segments = {}
    side.band = side:CreateTexture(nil, "BACKGROUND")
    side.band:Hide()
    for index = 1, SEGMENTS do side.segments[index] = create_segment(side) end
    side.value = library.create_text(side, "small", library.colours.ink)
    side.wanted = 0
    side:SetAlpha(0)
    side:SetScript("OnUpdate", update_fade)
    return side
end

local function update_band(side)
    local band, shape = side.band, LibVGASettings.arc_shape == "half" and BANDS.half or BANDS.full
    band:SetShown(LibVGASettings.arc_band == "on")
    if not band:IsShown() then return end
    local ground = library.read_ground()
    band:SetTexture(library.media .. shape.file)
    band:SetVertexColor(BAND_GROUND[1], BAND_GROUND[2], BAND_GROUND[3], ground)
    band:SetSize(read_draft(shape.width), read_draft(shape.height))
    band:ClearAllPoints()
    if side.mirror < 0 then
        band:SetTexCoord(0, 1, 0, 1)
        band:SetPoint("TOPLEFT", arcs, "CENTER", read_draft(shape.left), read_draft(shape.top))
    else
        band:SetTexCoord(1, 0, 0, 1)
        band:SetPoint("TOPRIGHT", arcs, "CENTER", -read_draft(shape.left), read_draft(shape.top))
    end
end

local function update_arc_corner(side, radius)
    local corner = side.corner
    if not corner then return end
    local size, angle = library.read_size(-2), math.rad(-read_span() / 2)
    local reach = radius + read_draft(CORNER_OUT)
    corner:SetSize(size, size)
    corner:ClearAllPoints()
    corner:SetPoint("CENTER", arcs, "CENTER", side.mirror * reach * math.cos(angle), reach * math.sin(angle))
    if side.mirror < 0 then corner.art:SetTexCoord(1, 0, 1, 0) else corner.art:SetTexCoord(0, 1, 1, 0) end
end

local function update_side_layout(side)
    local radius, size = read_draft(RADIUS), read_draft(16)
    local count, span = read_count(), read_span()
    for index, segment in ipairs(side.segments) do
        local share = (index - 0.5) / count
        local angle = math.rad(-span / 2 + share * span)
        segment:SetShown(index <= count)
        segment:SetSize(size, size)
        segment:ClearAllPoints()
        segment:SetPoint("CENTER", arcs, "CENTER", side.mirror * radius * math.cos(angle), radius * math.sin(angle))
        local turn = math.pi / 2 + side.mirror * angle
        segment:GetStatusBarTexture():SetRotation(turn)
        segment.track:SetRotation(turn)
    end
    update_band(side)
    update_arc_corner(side, radius)
    local foot = LibVGASettings.arc_values == "bottom"
    local head = math.rad((foot and -1 or 1) * read_span() / 2)
    side.value:SetFontObject(library.read_font("small"))
    side.value:ClearAllPoints()
    side.value:SetPoint(foot and "TOP" or "BOTTOM", arcs, "CENTER", side.mirror * radius * math.cos(head), radius * math.sin(head) + (foot and -1 or 1) * read_draft(10))
end

local function read_spell_range(spell)
    local known = spell and C_Spell.GetSpellInfo(spell)
    if not known or (known.minRange or 0) > 0 or (known.maxRange or 0) <= 0 then return nil end
    return known.maxRange
end

local function write_check(yards, check)
    for _, kept in ipairs(checks) do
        if kept[1] == yards then return end
    end
    checks[#checks + 1] = { yards, check }
end

local function write_spell_checks()
    local lines = C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines and C_SpellBook.GetNumSpellBookSkillLines() or 0
    for line = 1, lines do
        local skill = C_SpellBook.GetSpellBookSkillLineInfo(line)
        for slot = skill.itemIndexOffset + 1, skill.itemIndexOffset + skill.numSpellBookItems do
            local item = C_SpellBook.GetSpellBookItemInfo(slot, Enum.SpellBookSpellBank.Player)
            local spell = item and item.spellID
            local yards = spell and C_Spell.IsSpellHarmful(spell) and read_spell_range(spell)
            if yards then write_check(yards, function() return C_Spell.IsSpellInRange(spell, "target") end) end
        end
    end
end

local function write_item_checks()
    for _, item in ipairs(RANGE_ITEMS) do
        if C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(item) end
        local _, spell = C_Item.GetItemSpell(item)
        local yards = read_spell_range(spell)
        if yards then write_check(yards, function() return C_Item.IsItemInRange(item, "target") end) end
    end
end

local function write_steps_measure()
    local steps = {}
    for _, step in ipairs(checks) do steps[#steps + 1] = step[1] end
    LibVGASettings.measures = LibVGASettings.measures or {}
    LibVGASettings.measures.range_steps = table.concat(steps, " ")
end

local function write_checks()
    checks = {}
    write_check(10, function() return CheckInteractDistance("target", 3) end)
    write_check(28, function() return CheckInteractDistance("target", 1) end)
    pcall(write_spell_checks)
    pcall(write_item_checks)
    table.sort(checks, function(one, other) return one[1] < other[1] end)
    write_steps_measure()
end

local function read_range()
    for _, step in ipairs(checks) do
        local ran, near = pcall(step[2])
        if ran and near then return step[1] end
    end
    return nil
end

local function read_best_yards()
    local _, class = UnitClass("player")
    local known = BEST[class or ""] and C_Spell and C_Spell.GetSpellInfo(BEST[class])
    return known and (known.maxRange or 0) > 0 and known.maxRange or MELEE
end

local function check_best_range()
    local _, class = UnitClass("player")
    local spell = BEST[class or ""]
    if not spell then return CheckInteractDistance("target", 3) and true or false end
    return C_Spell and C_Spell.IsSpellInRange and C_Spell.IsSpellInRange(spell, "target") == true
end

local function read_reach_colour(yards)
    local _, class = UnitClass("player")
    local ranged = RANGED_YARDS[class or ""]
    if not ranged then return read_range_colour(yards, read_best_yards(), yards and check_best_range()) end
    if not yards or yards > ranged then return OUT_OF_REACH end
    if yards <= MELEE_YARDS then return REACH[1] end
    return yards <= NEAR and REACH[3] or REACH[4]
end

local function update_range(side)
    local yards, foe = read_range(), UnitCanAttack("player", "target")
    side.wanted = (yards or foe) and 1 or 0
    local share = yards and (RANGE_MOST - yards) / RANGE_MOST or 0
    local lit = math.max(foe and 1 or 0, math.ceil(share * read_count()))
    local colour = read_reach_colour(yards)
    if colour == OUT_OF_REACH then lit = read_count() end
    for index, segment in ipairs(side.segments) do
        segment:SetStatusBarColor(colour[1], colour[2], colour[3], 0.9)
        segment:SetMinMaxValues(0, STEP)
        segment:SetValue(index <= lit and STEP or 0)
    end
    local farthest = checks[#checks] and checks[#checks][1] or 35
    side.value:SetText(yards and vga.render_distance(yards) or ("> " .. vga.render_distance(farthest)))
end

local function update_by_game(side, share, colour_of)
    for index, segment in ipairs(side.segments) do
        local colour = colour_of(index)
        segment:SetStatusBarColor(colour[1], colour[2], colour[3], 0.9)
        segment:SetMinMaxValues((index - 1) * 100 / read_count(), (index - 1) * 100 / read_count() + STEP)
        segment:SetValue(share or 0)
    end
    pcall(side.value.SetFormattedText, side.value, "%d %%", share or 0)
end

local function read_threat_colour(index)
    return library.colours.steps[math.min(5, math.floor((index - 1) / read_count() * 5) + 1)]
end

local function update_threat(side)
    local status = UnitThreatSituation("player", "target")
    side.wanted = ((issecretvalue and issecretvalue(status)) or status ~= nil) and 1 or 0
    local _, _, share = UnitDetailedThreatSituation("player", "target")
    update_by_game(side, share, read_threat_colour)
end

local function read_health_colour()
    return HEALTH
end

local function update_health(side)
    side.wanted = 1
    local share = UnitHealthPercent and CurveConstants and UnitHealthPercent("target", true, CurveConstants.ScaleTo100)
    update_by_game(side, share, read_health_colour)
end

local function update_own_health(side)
    side.wanted = 1
    local share = UnitHealthPercent and CurveConstants and UnitHealthPercent("player", true, CurveConstants.ScaleTo100)
    update_by_game(side, share, read_health_colour)
end

local function read_cast_share(start, finish, channel)
    local now = GetTime() * 1000
    local share = (now - start) / math.max(finish - start, 1)
    return math.max(0, math.min(1, channel and 1 - share or share))
end

local function update_cast(side)
    local name, _, _, start, finish, _, _, locked = UnitCastingInfo("target")
    local channel = false
    if not name then
        name, _, _, start, finish, _, locked = UnitChannelInfo("target")
        channel = name ~= nil
    end
    side.wanted = name and 1 or 0
    if not name then return end
    local ran, share = pcall(read_cast_share, start, finish, channel)
    local lit = math.ceil((ran and share or 1) * read_count())
    local colour = locked and GREY or library.colours.gold
    for index, segment in ipairs(side.segments) do
        segment:SetStatusBarColor(colour[1], colour[2], colour[3], 0.9)
        segment:SetMinMaxValues(0, STEP)
        segment:SetValue(index <= lit and STEP or 0)
    end
    side.value:SetText(vga.read_cast_label(name))
end

local function update_marks(side, shown)
    local points, held
    if shown then points, held = vga.read_combo_points() end
    local radius, size = read_draft(RADIUS + 14), read_draft(7)
    side.marks = side.marks or {}
    for index = 1, COMBO_MARKS do
        side.marks[index] = side.marks[index] or library.create_bead(side, "OVERLAY", 3)
        local bead, angle = side.marks[index], math.rad(-read_span() / 2 + (index - 0.5) / COMBO_MARKS * read_span())
        local colour = points and index <= points and library.colours.orange or held and index <= held and library.colours.orange_low or MARK_OPEN
        bead:SetSize(size, size)
        bead:SetVertexColor(colour[1], colour[2], colour[3], 1)
        bead:ClearAllPoints()
        bead:SetPoint("CENTER", arcs, "CENTER", side.mirror * radius * math.cos(angle), radius * math.sin(angle))
        library.update_bead_shown(bead, points ~= nil)
    end
end

local function read_resource_wanted(points)
    local ran, empty = pcall(function() return UnitPower("player") == 0 end)
    if ran and empty and (points or 0) == 0 then return 0 end
    return 1
end

local function update_resource(side)
    local kind = UnitPowerType("player")
    local colour = library.read_bar_colour(vga.read_power_kind(kind))
    local share = UnitPowerPercent and CurveConstants and UnitPowerPercent("player", kind, false, CurveConstants.ScaleTo100)
    side.wanted = read_resource_wanted(vga.read_combo_points())
    update_by_game(side, share, function() return colour end)
    update_marks(side, true)
end

local SHOWS = { range = update_range, threat = update_threat, cast = update_cast, health = update_health, resource = update_resource, own_health = update_own_health }

local function check_target()
    return UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target")
end

local function read_show(side)
    local chosen = LibVGASettings[side.key] or side.default
    return SHOWS[chosen] and chosen or nil
end

local function read_sample_colour(show, index)
    if show == "threat" then return read_threat_colour(index) end
    if show == "range" then return REACH[4] end
    return show == "cast" and library.colours.gold or HEALTH
end

local function update_preview(side, show, target)
    side.wanted = 1
    if target or show == "resource" or show == "own_health" then return end
    update_by_game(side, SAMPLE, function(index) return read_sample_colour(show, index) end)
    if show == "range" then side.value:SetText(vga.render_distance(SAMPLE_YARDS)) end
    if show == "cast" then side.value:SetText(library.texts.cast_arc) end
end

local function update_calm(side)
    local calm = LibVGASettings.arc_shown ~= "always" and not UnitAffectingCombat("player") and not previews[side.key]
    side.fade = calm and FADE_CALM or FADE
    if calm then side.wanted = 0 end
end

local function update_values()
    if not arcs then return end
    local target = check_target()
    for _, side in ipairs({ arcs.left, arcs.right }) do
        local show = read_show(side)
        side:SetShown(show ~= nil)
        side.value:SetShown(LibVGASettings.arc_values ~= "off")
        if side.marks and show ~= "resource" then update_marks(side, false) end
        if show == "resource" or show == "own_health" then
            SHOWS[show](side)
        elseif not target then
            side.wanted = 0
        elseif show then
            SHOWS[show](side)
        end
        if previews[side.key] and show then update_preview(side, show, target) end
        update_calm(side)
        update_corner_faded(side)
    end
end

local function update_fight_begun()
    update_values()
    for _, side in ipairs({ arcs.left, arcs.right }) do
        if side.wanted > 0 then side:SetAlpha(side.wanted) end
        update_corner_faded(side)
    end
end

local function update_arcs()
    if not arcs then return end
    local radius = read_draft(RADIUS)
    arcs:SetSize(2 * radius + read_draft(40), 2 * radius)
    update_side_layout(arcs.left)
    update_side_layout(arcs.right)
    update_values()
end

local function read_resource_name()
    local _, class = UnitClass("player")
    if class == "DRUID" then return (MANA or "Mana") .. "/" .. (RAGE or "Rage") .. "/" .. (ENERGY or "Energy") end
    local _, token = UnitPowerType("player")
    return token and _G[token] or library.texts.resource_arc
end

local PLACES = { "top", "bottom", "off" }

local function read_place(list, wanted, fallback)
    for index, value in ipairs(list) do
        if value == (wanted or fallback) then return index end
    end
    return 1
end

local function create_side_row(page, side, key, fallback)
    local texts = library.texts
    local sections = {
        { title = texts.arc_own, items = { { "resource", read_resource_name() }, { "own_health", texts.own_health_arc } } },
        { title = texts.arc_target, items = { { "range", texts.range_arc }, { "threat", texts.threat_arc }, { "cast", texts.cast_arc }, { "health", texts.health_arc } } },
        { items = { { "off", texts.off } } },
    }
    local row = library.create_row(page, side)
    row.control = library.create_popup(row, sections, LibVGASettings[key] or fallback, function(value)
        library.update_choice_setting(key, value)
    end)
    row.eye = library.create_eye(row, function(on)
        previews[key] = on or nil
        update_values()
    end)
    return row
end

local function write_arc_band(index)
    library.update_choice_setting("arc_band", index == 2 and "on" or "off")
end

local function write_arc_shown(index)
    library.update_choice_setting("arc_shown", index == 1 and "always" or "combat")
end

local function write_arc_shape(index)
    library.update_choice_setting("arc_shape", index == 2 and "half" or "full")
end

local function create_arcs_page(page)
    local texts = library.texts
    page.rows = {
        create_side_row(page, texts.left_arc, "arc_left", "range"),
        create_side_row(page, texts.right_arc, "arc_right", "threat"),
        library.create_choice_row(page, texts.values_shown, { texts.top, texts.bottom, texts.off }, read_place(PLACES, LibVGASettings.arc_values, "top"), function(index)
            library.update_choice_setting("arc_values", PLACES[index])
        end),        library.create_choice_row(page, texts.arc_shape, { texts.full_arc, texts.half_arc }, LibVGASettings.arc_shape == "half" and 2 or 1, write_arc_shape),
        library.create_choice_row(page, texts.frame, { texts.off, texts.on }, LibVGASettings.arc_band == "on" and 2 or 1, write_arc_band),
        library.create_choice_row(page, texts.arcs_shown, { texts.always, texts.in_fight }, LibVGASettings.arc_shown == "always" and 1 or 2, write_arc_shown),
    }
end

local function render_arcs_settings()
    library.update_safely("arcs settings", library.render_settings, "arcs")
end

local function create_arcs()
    arcs = CreateFrame("Frame", "VGAArcs", UIParent)
    arcs:SetFrameStrata("BACKGROUND")
    arcs.left = create_side(-1)
    arcs.left.key, arcs.left.default = "arc_left", "range"
    arcs.right = create_side(1)
    arcs.right.key, arcs.right.default = "arc_right", "threat"
    library.create_place(arcs, "arcs", "CENTER", UIParent, 0, -read_draft(165))
    for _, side in ipairs({ arcs.left, arcs.right }) do
        side.corner = library.create_corner(arcs, false, render_arcs_settings)
    end
    library.create_element("arcs", { title = library.texts.arcs, icon = "TabArcs", update = update_arcs, tab = create_arcs_page })
    write_checks()
    C_Timer.After(5, function() library.update_safely("arcs checks", write_checks) end)
    C_Timer.NewTicker(0.2, function() library.update_safely("arcs", update_values) end)
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("SPELLS_CHANGED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then library.update_safely("arcs login", create_arcs) end
    if event == "SPELLS_CHANGED" and arcs then library.update_safely("arcs checks", write_checks) end
    if event == "PLAYER_REGEN_DISABLED" and arcs then return library.update_safely("arcs fight", update_fight_begun) end
    library.update_safely("arcs", update_values)
end)

vga.read_range_colour = read_range_colour
vga.read_reach_colour = read_reach_colour
