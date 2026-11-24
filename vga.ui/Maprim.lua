-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: The minimap frame's two rims, as the owner set them, equally high and every sign and word in each set at its vertical middle: above the map a small magnifier left-aligned at the map's left edge, then a little apart the zone's name, the coordinates right-aligned at its right edge; beneath the map a calendar, a little larger, left-aligned under its left edge, a button of its own that opens the game's calendar, the time and the day's sign - a sun by day, a moon by night - right-aligned at its right edge, resting on either showing a tooltip: »Tag« or »Nacht« in gold, beneath it the realm time and the local time (K0750), the time's digits lowered half a pixel so their middle meets the sign's. The magnifier opens the game's tracking menu, the game's own button lying invisible over it so the menu opens where the sign is. Beside the calendar, a little apart, a letter in the same ink and at its size, shown only while mail waits, the bags' new-item shimmer running round it three draft pixels outside, so the letter keeps its whole size, without their brightening, its tooltip the game's latest senders. The game's zone bar, clock, addon compartment, day sun, coordinates and mail sign are put away.

-- {K0802} {K0792} {K0789} {K0750} {K0424} {K0429} {K0430} {K0439} {K0446} {K0509}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local UPDATE_EVERY = 0.2
local CALENDAR = 1.35
local GLINT_OUT = 3
local DIGIT_DROP = 0.5
local rim

local read_draft = library.read_draft_size

function vga.read_map_line()
    return library.read_size(-1) + read_draft(8)
end

local function read_game_parts()
    local cluster = MinimapCluster or {}
    local container = cluster.MinimapContainer or {}
    local indicator = type(cluster.IndicatorFrame) == "table" and cluster.IndicatorFrame or {}
    return { cluster.ZoneTextButton, TimeManagerClockButton, AddonCompartmentFrame, cluster.DielFrame, container.PlayerCoords, GameTimeFrame, indicator.MailFrame, MiniMapMailFrame }
end

local function update_game_parts()
    for _, part in pairs(read_game_parts()) do
        part:SetAlpha(0)
        if part.EnableMouse then part:EnableMouse(false) end
    end
end

local function update_over(part, sign)
    if not part then return end
    part:SetAlpha(0)
    part:ClearAllPoints()
    part:SetPoint("CENTER", sign, "CENTER")
    part:SetSize(sign:GetWidth(), sign:GetHeight())
end

local function read_time()
    if GameTime_GetTime then return GameTime_GetTime(false) end
    return date("%H:%M")
end

local function check_day()
    return not (C_DateAndTime and C_DateAndTime.IsDayTime and C_DateAndTime.IsDayTime() == false)
end

local function read_day_sign()
    return library.media .. (check_day() and "DaySun" or "NightMoon")
end

local function read_realm_time()
    if not GetGameTime then return read_time() end
    local hour, minute = GetGameTime()
    return string.format("%02d:%02d", hour, minute)
end

local function render_day_tip(day)
    local texts = library.texts
    GameTooltip:SetOwner(day, "ANCHOR_LEFT")
    GameTooltip:SetText(check_day() and texts.map_day or texts.map_night, colours.gold[1], colours.gold[2], colours.gold[3])
    GameTooltip:AddDoubleLine(texts.map_realm_time, read_realm_time(), colours.ink[1], colours.ink[2], colours.ink[3], colours.ink[1], colours.ink[2], colours.ink[3])
    GameTooltip:AddDoubleLine(texts.map_local_time, date("%H:%M"), colours.ink[1], colours.ink[2], colours.ink[3], colours.ink[1], colours.ink[2], colours.ink[3])
    GameTooltip:Show()
end

local function update_day_left()
    GameTooltip:Hide()
end

local function render_mail_tip(mail)
    GameTooltip:SetOwner(mail, "ANCHOR_LEFT")
    GameTooltip:SetText(HAVE_MAIL_FROM or library.texts.mail, colours.gold[1], colours.gold[2], colours.gold[3])
    for _, sender in ipairs({ GetLatestThreeSenders and GetLatestThreeSenders() }) do GameTooltip:AddLine(sender, colours.ink[1], colours.ink[2], colours.ink[3]) end
    GameTooltip:Show()
end

local function update_mail_left()
    GameTooltip:Hide()
end

local function update_mail()
    local waiting = HasNewMail and HasNewMail() and true or false
    rim.mail:SetShown(waiting)
    if not waiting then return end
    library.update_shimmer(rim.mail.glint, library.read_shimmer_phase(), rim.mail.glint:GetWidth())
    rim.mail.glint.vga_bright:Hide()
end

local function update_texts()
    local map = C_Map.GetBestMapForUnit("player")
    local spot = map and C_Map.GetPlayerMapPosition(map, "player")
    if spot then rim.coords:SetFormattedText("%.1f, %.1f", spot.x * 100, spot.y * 100) else rim.coords:SetText("") end
    rim.zone:SetText(GetMinimapZoneText and GetMinimapZoneText() or "")
    rim.time:SetText(read_time())
    rim.day:SetTexture(read_day_sign())
end

local function update_texts_safely(_, elapsed)
    library.update_safely("map mail", update_mail)
    rim.since = (rim.since or 0) + elapsed
    if rim.since < UPDATE_EVERY then return end
    rim.since = 0
    library.update_safely("map rim", update_texts)
end

local function update_sign(sign, size)
    sign:SetSize(size, size)
    sign:ClearAllPoints()
end

function vga.update_map_rim(view, band)
    if not rim then return end
    local size, middle, text = library.read_size(-1), band / 2, library.read_font("small")
    for _, line in ipairs({ rim.zone, rim.coords, rim.time }) do line:SetFontObject(text) end
    update_sign(rim.glass, size)
    rim.zone:SetFontObject(library.read_font("caption"))
    local calendar = math.floor(size * CALENDAR + 0.5)
    rim.calendar:SetSize(calendar, calendar)
    rim.mail:SetSize(calendar, calendar)
    rim.mail.glint:SetSize(calendar + 2 * read_draft(GLINT_OUT), calendar + 2 * read_draft(GLINT_OUT))
    update_sign(rim.day, size)
    for _, grid in ipairs({ rim.above, rim.below }) do
        grid.frame, grid.plan.row = view, { pixels = band }
    end
    local width = view:GetWidth()
    library.update_grid(rim.above, { { rim.glass, rim.zone, rim.coords } }, width, -band)
    library.update_grid(rim.below, { { rim.calendar, rim.mail, nil, rim.day } }, width, view:GetHeight())
    rim.time:ClearAllPoints()
    rim.time:SetPoint("RIGHT", rim.day, "LEFT", -read_draft(6), -DIGIT_DROP)
    rim.hover:ClearAllPoints()
    rim.hover:SetPoint("TOP", rim.day, "TOP")
    rim.hover:SetPoint("BOTTOM", rim.day, "BOTTOM")
    rim.hover:SetPoint("RIGHT", rim.day, "RIGHT")
    rim.hover:SetPoint("LEFT", rim.time, "LEFT")
    update_game_parts()
    update_over(MinimapCluster and MinimapCluster.Tracking, rim.glass)
    update_texts()
end

local function create_sign(widget, media)
    local sign = widget:CreateTexture(nil, "OVERLAY")
    sign:SetTexture(library.media .. media)
    sign:SetVertexColor(colours.ink[1], colours.ink[2], colours.ink[3], 1)
    return sign
end

local function render_calendar()
    if ToggleCalendar then
        ToggleCalendar()
    elseif Calendar_LoadUI then
        Calendar_LoadUI()
        if Calendar_Toggle then Calendar_Toggle() end
    end
end

local function render_calendar_safely()
    library.update_safely("map calendar", render_calendar)
end

local function create_calendar(widget)
    local calendar = library.create_icon_button(widget, "Calendar", render_calendar_safely, { name = "VGAMapCalendar", tint = colours.ink })
    calendar:SetFrameLevel(widget:GetFrameLevel() + 6)
    return calendar
end

local function create_day_hover(widget)
    local hover = CreateFrame("Frame", "VGAMapDay", widget)
    hover:SetFrameLevel(widget:GetFrameLevel() + 6)
    hover:EnableMouse(true)
    hover:SetScript("OnEnter", render_day_tip)
    hover:SetScript("OnLeave", update_day_left)
    return hover
end

local function create_mail(widget)
    local mail = library.create_icon_button(widget, "Mail", nil, { frame = "Frame", name = "VGAMapMail", tint = colours.ink, on_enter = render_mail_tip, on_leave = update_mail_left })
    mail:SetFrameLevel(widget:GetFrameLevel() + 6)
    mail.glint = CreateFrame("Frame", nil, mail)
    mail.glint:SetPoint("CENTER")
    library.create_shimmer(mail.glint)
    mail:EnableMouse(true)
    mail:Hide()
    return mail
end

function vga.create_map_rim(widget)
    rim = { widget = widget }
    rim.above = library.create_grid(widget, { columns = { "auto", "rest", "auto" }, gaps = { 6, 0 }, x = { "left", "left", "right" } })
    rim.below = library.create_grid(widget, { columns = { "auto", "auto", "rest", "auto" }, gaps = { 6, 0, 0 }, x = { "left", "left", "left", "right" } })
    rim.glass = create_sign(widget, "Search")
    rim.calendar = create_calendar(widget)
    rim.mail = create_mail(widget)
    rim.day = create_sign(widget, "DaySun")
    rim.hover = create_day_hover(widget)
    rim.zone = library.create_text(widget, "caption", colours.gold)
    rim.coords = library.create_text(widget, "figures_small", colours.ink)
    rim.time = library.create_text(widget, "figures_small", colours.ink)
    local tracking = MinimapCluster and MinimapCluster.Tracking
    if tracking then
        tracking:SetParent(widget)
        tracking:SetFrameLevel(widget:GetFrameLevel() + 6)
    end
    local ticker = CreateFrame("Frame", nil, widget)
    ticker:SetScript("OnUpdate", update_texts_safely)
end
