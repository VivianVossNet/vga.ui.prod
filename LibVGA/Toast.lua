-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's toast, as the accepted catalogue draws it (manual/view/vga-catalogue.html »Toast«, K0772, K0775) after vga-auctions.html's toast with the tooltip's gold corner: a small notice of what must be reported - a picture at its left, its head word in small gold capitals, its line beneath and a second where one is given, each broken over as many lines as its words need, never cut off, the toast growing with them, only the head kept to one line (K1022) -, on the dark ground in a fine line, rounded ten draft pixels, 360 wide; at the top centre of the screen, at most three, the newest on top, each going after a few seconds, fading out. A toast given a key (plan.key) that is still shown is counted on in its place, its words new and its time begun again, never a second stacked - a quest's objective, a profession's rank (K1038). A toast of a thing done, and done well, carries LibVGA's green tick at its right, kept while it shows (plan.done, library.update_tick_kept); its room is kept in every toast so nothing moves (K1039, K1042). It stays as long as the tab »Hinweise« says - two, four or six seconds, four by default (LibVGASettings.toast_stay, library.read_toast_stays, K1041). Its user names its kind (plan.kind), and the kind gives the rim, after manual/view/vga-toast-colours.html (K1034): blue for the rest area, the map's features and the mail, gold for a quest, a discovery and the character's rise, copper for PvP and a duel, wine red for damaged gear and full bags, green for trade (K1040), and for every other notice the light grey, quiet, which stands off the black outline as clearly as the colours (K1033). A discovery and a level reached carry (plan.ornate), centred above and beneath, the book ornament of Z1 in the rim's colour, four pixels clear of the rim, the one beneath turned over, and the toasts stacked keep room for it (Media/Ornament.tga, tools/questmark/ornament.py, K1037). Each kind can be silenced on the settings' tab »Hinweise«: library.render_toast shows nothing of a kind switched off (LibVGASettings.notices, library.read_notice_on, library.write_notice, K1035); library.read_toast_rim gives the tab each kind's colour. Its user names picture, head, line, second line and kind and calls library.render_toast; nothing else (K0794).

-- {K1042} {K1041} {K1040} {K1039} {K1038} {K1037} {K1035} {K1034} {K1033} {K1032} {K1022} {K0794} {K0772} {K0775}

local library = LibVGA
local colours = library.colours
local MOST = 3
local WIDTH = 360
local PICTURE = 26
local PAD = 12
local GAP = 6
local FROM_TOP = 96
local STAY = 4
local STAYS = { 2, 4, 6 }
local FADE = 0.6
local GROUND = { 0.039, 0.043, 0.051 }
local BLACK = { 0, 0, 0 }
local KINDS = { quest = "gold", discovery = "gold", rise = "gold", rest = "blue", map = "blue", mail = "blue", pvp = "copper", duel = "copper", gear = "wine", bags = "wine", trade = "green", other = "quiet" }
local ORNAMENT = { 144, 18 }
local CLEAR = 4
local toasts = {}

function library.read_toast_stays()
    return STAYS
end

function library.read_toast_stay()
    return LibVGASettings and LibVGASettings.toast_stay or STAY
end

local function update_faded(toast, elapsed)
    toast.time = toast.time + elapsed
    local left = library.read_toast_stay() + FADE - toast.time
    toast:SetAlpha(math.max(0, math.min(1, left / FADE)))
    if left <= 0 then toast:Hide() end
end

local function create_one()
    local toast = CreateFrame("Frame", nil, UIParent)
    toast:SetFrameStrata("HIGH")
    toast:EnableMouse(false)
    toast.outline = library.create_surface(toast, "BACKGROUND", 0)
    toast.edge = library.create_surface(toast, "BACKGROUND", 1)
    toast.ground = library.create_surface(toast, "BACKGROUND", 2)
    toast.picture = toast:CreateTexture(nil, "ARTWORK")
    toast.head = library.create_text(toast, "caption", colours.gold)
    toast.line = library.create_text(toast, "body", colours.ink)
    toast.second = library.create_text(toast, "small", colours.quiet)
    for _, text in ipairs({ toast.head, toast.line, toast.second }) do text:SetJustifyH("LEFT") end
    toast.head:SetWordWrap(false)
    toast.line:SetWordWrap(true)
    toast.second:SetWordWrap(true)
    toast.ornaments = { toast:CreateTexture(nil, "ARTWORK"), toast:CreateTexture(nil, "ARTWORK") }
    for index, ornament in ipairs(toast.ornaments) do
        ornament:SetTexture(library.media .. "Ornament")
        ornament:SetTexCoord(0, 1, index == 1 and 0 or 1, index == 1 and 1 or 0)
    end
    toast.tick = library.create_tick(toast)
    toast.corner = library.create_corner(toast)
    toast.corner:EnableMouse(false)
    toast:SetScript("OnUpdate", update_faded)
    toast:Hide()
    return toast
end

function library.create_toast()
    for index = #toasts + 1, MOST do toasts[index] = create_one() end
    return toasts
end

function library.read_toasts()
    return toasts
end

function library.read_toast_rim(kind)
    return library.colours[KINDS[kind] or KINDS.other]
end

function library.read_notice_on(kind)
    return not (LibVGASettings and LibVGASettings.notices and LibVGASettings.notices[kind] == false)
end

function library.write_notice(kind, on)
    LibVGASettings.notices = LibVGASettings.notices or {}
    if on then LibVGASettings.notices[kind] = nil else LibVGASettings.notices[kind] = false end
end

local function update_ornaments(toast, ornate, rim)
    local width, height = library.read_draft_size(ORNAMENT[1]), library.read_draft_size(ORNAMENT[2])
    for index, ornament in ipairs(toast.ornaments) do
        ornament:SetShown(ornate)
        ornament:SetSize(width, height)
        ornament:SetVertexColor(rim[1], rim[2], rim[3], 1)
        ornament:ClearAllPoints()
        if index == 1 then ornament:SetPoint("BOTTOM", toast, "TOP", 0, CLEAR) else ornament:SetPoint("TOP", toast, "BOTTOM", 0, -CLEAR) end
    end
end

local function update_text(text, kind, words, left, width)
    text:SetFontObject(library.read_font(kind))
    text:SetText(words or "")
    text:SetShown(words ~= nil)
    text:SetWidth(width)
    text:ClearAllPoints()
    text:SetPoint("TOPLEFT", text:GetParent(), "TOPLEFT", left, 0)
end

local function update_toast_tick(toast, plan, pad)
    library.update_tick(toast.tick)
    toast.tick:ClearAllPoints()
    toast.tick:SetPoint("RIGHT", toast, "RIGHT", -pad, 0)
    if plan.done then library.update_tick_kept(toast.tick) else toast.tick.picture:SetAlpha(0) end
end

local function update_look(toast, plan)
    local draft = library.read_draft_size
    local width, pad, picture, radius = draft(WIDTH), draft(PAD), draft(PICTURE), draft(10)
    library.update_surface(toast.outline, -2, radius + 2, BLACK, BLACK)
    local rim = library.read_toast_rim(plan.kind)
    library.update_surface(toast.edge, -1, radius + 1, rim, rim)
    toast.ornate = plan.ornate == true
    update_ornaments(toast, toast.ornate, rim)
    library.update_surface(toast.ground, 0, radius, GROUND, GROUND, 0.95)
    toast.picture:SetTexture(plan.picture or library.media .. "Mark")
    toast.picture:SetSize(picture, picture)
    toast.picture:ClearAllPoints()
    toast.picture:SetPoint("LEFT", toast, "LEFT", pad, 0)
    local left, room = pad + picture + draft(10), width - 2 * pad - picture - 2 * draft(10) - library.read_tick_room()
    update_toast_tick(toast, plan, pad)
    update_text(toast.head, "caption", plan.head and library.read_capitals(plan.head), left, room)
    update_text(toast.line, "body", plan.line, left, room)
    update_text(toast.second, "small", plan.second, left, room)
    local top, step = pad, 2
    for _, text in ipairs({ toast.head, toast.line, toast.second }) do
        if text:IsShown() then
            text:SetPoint("TOPLEFT", toast, "TOPLEFT", left, -top)
            top = top + library.read_string_height(text) + step
        end
    end
    toast:SetSize(width, math.max(picture + 2 * pad, top - step + pad))
    library.update_corner(toast.corner)
end

local function update_stack()
    local top = FROM_TOP
    for _, toast in ipairs(toasts) do
        if toast:IsShown() then
            local around = toast.ornate and library.read_draft_size(ORNAMENT[2]) + CLEAR or 0
            toast:ClearAllPoints()
            toast:SetPoint("TOP", UIParent, "TOP", 0, -(top + around))
            top = top + toast:GetHeight() + 2 * around + library.read_draft_size(GAP)
        end
    end
end

local function read_toast_kept(key)
    if not key then return nil end
    for index, toast in ipairs(toasts) do
        if toast.key == key and toast:IsShown() then return table.remove(toasts, index) end
    end
end

function library.render_toast(plan)
    if not library.read_notice_on(plan.kind or "other") then return end
    library.create_toast()
    local toast = read_toast_kept(plan.key) or table.remove(toasts)
    toast.key = plan.key
    table.insert(toasts, 1, toast)
    update_look(toast, plan)
    toast.time = 0
    toast:SetAlpha(1)
    toast:Show()
    update_stack()
end
