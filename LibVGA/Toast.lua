-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's toast, as the accepted catalogue draws it (manual/view/vga-catalogue.html »Toast«, K0772, K0775) after vga-auctions.html's toast with the tooltip's gold corner: a small notice of what must be reported - a picture at its left, its head word in small gold capitals, one line beneath ending in »…«, a second where one is given -, on the dark ground in a fine line, rounded ten draft pixels, 360 wide; at the top centre of the screen, at most three, the newest on top, each going after a few seconds, fading out. Its user names picture, head, line and second line and calls library.render_toast; nothing else (K0794).

-- {K0794} {K0772} {K0775}

local library = LibVGA
local colours = library.colours
local MOST = 3
local WIDTH = 360
local PICTURE = 26
local PAD = 12
local GAP = 6
local FROM_TOP = 96
local STAY = 4
local FADE = 0.6
local GROUND = { 0.039, 0.043, 0.051 }
local BLACK = { 0, 0, 0 }
local toasts = {}

local function update_faded(toast, elapsed)
    toast.time = toast.time + elapsed
    local left = STAY + FADE - toast.time
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
    for _, text in ipairs({ toast.head, toast.line, toast.second }) do
        text:SetWordWrap(false)
        text:SetJustifyH("LEFT")
    end
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

local function update_text(text, kind, words, left, width)
    text:SetFontObject(library.read_font(kind))
    text:SetText(words or "")
    text:SetShown(words ~= nil)
    text:SetWidth(width)
    text:ClearAllPoints()
    text:SetPoint("TOPLEFT", text:GetParent(), "TOPLEFT", left, 0)
end

local function update_look(toast, plan)
    local draft = library.read_draft_size
    local width, pad, picture, radius = draft(WIDTH), draft(PAD), draft(PICTURE), draft(10)
    library.update_surface(toast.outline, -2, radius + 2, BLACK, BLACK)
    library.update_surface(toast.edge, -1, radius + 1, colours.edge, colours.edge)
    library.update_surface(toast.ground, 0, radius, GROUND, GROUND, 0.95)
    toast.picture:SetTexture(plan.picture or library.media .. "Mark")
    toast.picture:SetSize(picture, picture)
    toast.picture:ClearAllPoints()
    toast.picture:SetPoint("LEFT", toast, "LEFT", pad, 0)
    local left, room = pad + picture + draft(10), width - 2 * pad - picture - draft(10)
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
            toast:ClearAllPoints()
            toast:SetPoint("TOP", UIParent, "TOP", 0, -top)
            top = top + toast:GetHeight() + library.read_draft_size(GAP)
        end
    end
end

function library.render_toast(plan)
    library.create_toast()
    local toast = table.remove(toasts)
    table.insert(toasts, 1, toast)
    update_look(toast, plan)
    toast.time = 0
    toast:SetAlpha(1)
    toast:Show()
    update_stack()
end
