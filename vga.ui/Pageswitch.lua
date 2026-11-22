-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: The main bar's page switcher as manual/view/vga-gamemenu.html draws it (K0511): right beside bar 1, five draft pixels apart and belonging to it, a narrow column of the bar's height - 24 by 38 draft pixels, without an edge or a ground of its own, so it reads as part of bar 1 -, at its top a thin chevron up, in its middle the sub-bar's letter in gold, A or B, free between them, at its foot a chevron down; a click on either arrow turns bar 1 between its sub-bars A and B - the game's action pages one and two, not bar 2 -, through the game's own secure paging (type actionbar, action »1, 2«, which turns to the other of the two), so it turns in a fight too, the click taken on press and on release, as the game's setting to act on key down asks - taken on release only, it never arrived (K0538); the letter follows the game's page however it was turned, a page beyond two by its number. Placed by the main bar (Actionbars.lua) as a child of bar 1, so it scales and moves with it. Its arrows say in a tooltip what they do (K0726).

-- {K0511} {K0521} {K0522} {K0538} {K0726}

local _, vga = ...
local library = LibVGA
local DRAFT_BASE = 13
local WIDTH = 24
local HEIGHT = 38
local APART = 5
local ARROW = 12
local CHEVRON_TOP, CHEVRON_FOOT = 0.25, 0.75
local NAMES = { "A", "B" }
local TOGGLE = "1, 2"

local function read_draft(pixels)
    return math.floor(pixels * library.read_base() / DRAFT_BASE + 0.5)
end

local function read_page()
    return GetActionBarPage and GetActionBarPage() or 1
end

local function update_number()
    local switch = vga.page_switch
    if switch then switch.number:SetText(NAMES[read_page()] or tostring(read_page())) end
end

local function create_arrow(switch, point, turned)
    local arrow = CreateFrame("Button", nil, switch, "SecureActionButtonTemplate")
    arrow:SetAttribute("type", "actionbar")
    arrow:SetAttribute("action", TOGGLE)
    arrow:RegisterForClicks("AnyUp", "AnyDown")
    arrow.sign = arrow:CreateTexture(nil, "ARTWORK")
    arrow.sign:SetAllPoints()
    arrow.sign:SetTexture(library.media .. "NaviChevron")
    arrow.sign:SetTexCoord(0, 1, CHEVRON_TOP, CHEVRON_FOOT)
    if turned then arrow.sign:SetRotation(math.pi) end
    local ink = library.colours.ink
    arrow.sign:SetVertexColor(ink[1], ink[2], ink[3], 1)
    arrow.point = point
    vga.create_text_tip(arrow, library.texts.page_switch_tip)
    return arrow
end

function vga.read_page_switch_reach()
    return read_draft(APART) + read_draft(WIDTH)
end

function vga.update_page_switch(bar)
    local switch = vga.page_switch
    switch:SetParent(bar)
    switch:SetSize(read_draft(WIDTH), read_draft(HEIGHT))
    switch:ClearAllPoints()
    switch:SetPoint("LEFT", bar, "RIGHT", read_draft(APART), 0)
    switch.number:SetFontObject(library.read_font("small"))
    for _, arrow in ipairs({ switch.up, switch.down }) do
        arrow:SetSize(read_draft(ARROW), math.floor(read_draft(ARROW) * (CHEVRON_FOOT - CHEVRON_TOP) + 0.5))
        arrow:ClearAllPoints()
        arrow:SetPoint(arrow.point, switch, arrow.point, 0, (arrow.point == "TOP" and -1 or 1) * read_draft(2))
    end
    update_number()
end

local function create_page_switch()
    local switch = CreateFrame("Frame", "VGAPageSwitch", UIParent)
    switch.number = library.create_text(switch, "small", library.colours.gold)
    switch.number:SetPoint("CENTER")
    switch.up = create_arrow(switch, "TOP", false)
    switch.down = create_arrow(switch, "BOTTOM", true)
    switch:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
    switch:SetScript("OnEvent", update_number)
    return switch
end

vga.page_switch = create_page_switch()
