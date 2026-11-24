-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: The nameplate of a friendly player or NPC, as manual/view/vga-plate-friends.html draws form C: no level, no bar - the guild or the NPC's title and the name divided by the line - the name beneath by default, above as the settings say -, as the settings say, by one thin line five pixels longer on either side than the longer of the two - filled in the name's colour as far as the unit's health reaches, grey where it is missing, so a wounded friend shows in passing; without a title the line is there only while health is missing, gone at full health - the game itself decides, by a curve over the secret health, since vga.ui may not read it -, or framed in a faint ground with a thin rounded line, both in the game's own name colour (UnitSelectionColor, as Blizzard's plates colour names); a cast in a fight runs in gold over the line, as thin as it, and goes as soon as the unit no longer casts, asked four times a second while it shows, so no ended cast stays as a full gold line (K0590). The game's friendly plates - players, NPCs, their pets and minions - and its always-show setting are switched on while vga.ui runs, so every friendly unit wears it, the untargeted smaller by the game's own plate scale, and the player's own setting restored at logout.

-- {K0783} {K0782} {K0347} {K0349} {K0350} {K0351} {K0352} {K0381} {K0590}

local CAST_CHECK = 0.25
local _, vga = ...
local library = LibVGA
local SWITCHES = {
    nameplateShowFriendlyPlayers = "1", nameplateShowFriendlyNpcs = "1", nameplateShowAll = "1",
    nameplateShowFriendlyPlayerMinions = "1", nameplateShowFriendlyPlayerPets = "1",
}
local LINE_REACH = 5
local MISSING = { 0.5, 0.5, 0.52 }
local MISSING_ALPHA = 0.25
local LABEL_GROUND = 0.3
local GROUND = { 0.043, 0.047, 0.059 }

function vga.check_friend(unit)
    return UnitIsFriend("player", unit) and not UnitCanAttack("player", unit)
end

local function read_colour(unit)
    local red, green, blue = UnitSelectionColor(unit, true)
    return { red, green, blue }
end

local function read_title(unit)
    if UnitIsPlayer(unit) then return GetGuildInfo(unit) or "" end
    local data = C_TooltipInfo and C_TooltipInfo.GetUnit and C_TooltipInfo.GetUnit(unit)
    local line = data and data.lines and data.lines[2]
    local text = line and line.leftText or ""
    local level = UnitLevel(unit)
    if text:find(LEVEL or "Level", 1, true) or (level and text:find("%f[%d]" .. level .. "%f[%D]")) then return "" end
    return text
end

function vga.create_friend(plate)
    local friend = CreateFrame("Frame", nil, plate)
    friend:SetAllPoints()
    friend.name = library.create_text(friend, "bold")
    friend.name:SetWordWrap(false)
    friend.track = friend:CreateTexture(nil, "ARTWORK")
    friend.track:SetColorTexture(1, 1, 1, 1)
    if friend.track.SetRoundLayoutToNearestPixel then friend.track:SetRoundLayoutToNearestPixel(true) end
    friend.health = library.create_fill(friend)
    friend.health:SetAllPoints(friend.track)
    friend.health:SetFrameLevel(friend:GetFrameLevel() + 1)
    friend.cast = library.create_fill(friend)
    library.update_fill_colour(friend.cast, library.colours.gold)
    friend.cast:SetAllPoints(friend.track)
    friend.cast:SetFrameLevel(friend:GetFrameLevel() + 2)
    friend.cast:HookScript("OnUpdate", vga.update_cast_watch)
    friend.cast:Hide()
    friend.label = CreateFrame("Frame", nil, friend)
    friend.label.ground = library.create_surface(friend.label, "BACKGROUND", 0)
    friend.label.ring = library.create_ring(friend.label, "BORDER", 0)
    friend.label.text = library.create_text(friend.label, "small")
    friend.label.text:SetWordWrap(false)
    friend.label.text:SetPoint("CENTER")
    friend:Hide()
    return friend
end

local function update_frame_style(friend, colour, framed)
    local radius = library.read_size(-4)
    for _, piece in pairs(friend.label.ground.pieces) do piece:SetShown(framed) end
    for _, piece in pairs(friend.label.ring.pieces) do piece:SetShown(framed) end
    if not framed then return end
    library.update_surface(friend.label.ground, 0, radius, GROUND, GROUND, LABEL_GROUND)
    library.update_ring(friend.label.ring, 1, colour, 0.7)
end

function vga.update_friend(friend, unit)
    local colour = read_colour(unit)
    local title = read_title(unit)
    local framed = LibVGASettings.friend_style == "frame"
    local gap, pad = library.read_size(-6), library.read_size(-2)
    friend.name:SetFontObject(library.read_font("bold"))
    friend.name:SetText(library.read_unit_name(unit))
    friend.name:SetTextColor(colour[1], colour[2], colour[3])
    friend.name:ClearAllPoints()
    local above = LibVGASettings.friend_name == "above"
    friend.name:SetPoint(above and "BOTTOM" or "TOP", friend, "CENTER", 0, above and gap or -gap)
    friend.label:SetShown(title ~= "")
    friend.label.text:SetFontObject(library.read_font("small"))
    friend.label.text:SetText(title)
    friend.label.text:SetTextColor(colour[1], colour[2], colour[3])
    local width = math.ceil(friend.label.text:GetStringWidth())
    friend.label:ClearAllPoints()
    friend.label:SetPoint(above and "TOP" or "BOTTOM", friend, "CENTER", 0, above and -gap or gap)
    friend.label:SetSize(width + 2 * pad, library.read_size(1) + gap)
    update_frame_style(friend, colour, framed)
    local widest = math.max(friend.name:GetStringWidth(), title ~= "" and width or 0)
    friend.track:ClearAllPoints()
    friend.track:SetPoint("CENTER", friend, "CENTER")
    friend.track:SetSize(math.ceil(widest) + 2 * LINE_REACH, 1)
    friend.track:SetVertexColor(MISSING[1], MISSING[2], MISSING[3], MISSING_ALPHA)
    friend.track:SetShown(not framed)
    friend.lone = title == ""
    library.update_fill_colour(friend.health, colour)
    friend.health:SetShown(not framed)
    vga.update_friend_health(friend, unit)
end

function vga.check_casting(unit)
    local casting = UnitCastingInfo(unit) or UnitChannelInfo(unit)
    return type(casting) ~= "nil"
end

local function read_whole_curve()
    if not vga.whole_curve and C_CurveUtil then
        vga.whole_curve = C_CurveUtil.CreateCurve()
        vga.whole_curve:AddPoint(0, 1)
        vga.whole_curve:AddPoint(0.995, 1)
        vga.whole_curve:AddPoint(1, 0)
    end
    return vga.whole_curve
end

function vga.update_friend_health(friend, unit)
    friend.health:SetMinMaxValues(0, UnitHealthMax(unit))
    friend.health:SetValue(UnitHealth(unit))
    local curve = friend.lone and read_whole_curve()
    local alpha = curve and UnitHealthPercent(unit, true, curve) or 1
    friend.track:SetAlpha(alpha)
    friend.health:SetAlpha(alpha)
end

function vga.update_cast_watch(bar, elapsed)
    bar.waited = (bar.waited or 0) + elapsed
    if bar.waited < CAST_CHECK then return end
    bar.waited = 0
    if not (bar.unit and vga.check_casting(bar.unit)) then bar:Hide() end
end

function vga.update_friend_cast(friend, unit)
    local duration = vga.check_casting(unit) and ((UnitCastingDuration and UnitCastingDuration(unit)) or (UnitChannelDuration and UnitChannelDuration(unit)))
    friend.cast.unit = unit
    friend.cast:SetShown(duration and true or false)
    if duration then friend.cast:SetTimerDuration(duration) end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_LOGOUT")
events:SetScript("OnEvent", function(_, event)
    if not LibVGASettings then return end
    if event == "PLAYER_LOGIN" then
        library.update_safely("friends on", library.update_switches, "friendly", SWITCHES)
    else
        library.update_safely("friends back", library.update_switches_back, "friendly")
    end
end)
