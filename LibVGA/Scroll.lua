-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's scrolling body, first built for the quest tracker (K0548) and lifted here as an element of its own (K0631): a scroll frame with its content, scrolled by the mouse wheel and by dragging a slender bar at the right in the way of macOS - a rounded thumb, white at a third of full strength, its length the share of the content in view, with no track behind it, shown only while the content is longer than the room, always the topmost layer, above every row and its ring (K0648); whoever uses it sets its room and the content's length, and may hear of every scroll (body.on_scroll). The list element (LibVGA/List.lua) brings it with it.

-- {K0548} {K0631} {K0648}

local library = LibVGA
local DRAFT_BASE = 13
local THUMB = 4
local THUMB_ALPHA = 0.35
local INSET = 3
local WHEEL = 40
local THUMB_SHORTEST = 24
local TOP_LEVEL = 200

local function read_draft(pixels)
    return math.floor(pixels * library.read_base() / DRAFT_BASE + 0.5)
end

local function update_thumb(body)
    local room, length = body:GetHeight(), body.length or 0
    local shown = length > room + 0.5
    body.thumb:SetShown(shown)
    if not shown then return end
    body.thumb:SetFrameLevel(body:GetFrameLevel() + TOP_LEVEL)
    local inset = read_draft(INSET)
    local track = room - 2 * inset
    local size = math.max(read_draft(THUMB_SHORTEST), track * room / length)
    local travel = (track - size) * body:GetVerticalScroll() / math.max(length - room, 1)
    local width = read_draft(THUMB)
    body.thumb:SetSize(width, size)
    body.thumb:ClearAllPoints()
    body.thumb:SetPoint("TOPRIGHT", body, "TOPRIGHT", -inset, -inset - travel)
    library.update_surface(body.thumb.face, 0, width / 2, { 1, 1, 1 }, { 1, 1, 1 }, THUMB_ALPHA)
end

function library.update_scrolled(body, offset)
    local most = math.max((body.length or 0) - body:GetHeight(), 0)
    body:SetVerticalScroll(math.min(math.max(offset, 0), most))
    update_thumb(body)
    if body.on_scroll then body.on_scroll(body) end
end

local function update_wheel(body, delta)
    library.update_scrolled(body, body:GetVerticalScroll() - delta * read_draft(WHEEL))
end

local function update_drag(thumb)
    local body = thumb:GetParent()
    local _, cursor = GetCursorPosition()
    cursor = cursor / thumb:GetEffectiveScale()
    local room = body:GetHeight() - 2 * read_draft(INSET) - thumb:GetHeight()
    local moved = (thumb.grab - cursor) / math.max(room, 1)
    library.update_scrolled(body, thumb.from + moved * math.max((body.length or 0) - body:GetHeight(), 0))
end

local function update_drag_safely(thumb)
    library.update_safely("scroll drag", update_drag, thumb)
end

local function update_grab(thumb)
    local _, cursor = GetCursorPosition()
    thumb.grab, thumb.from = cursor / thumb:GetEffectiveScale(), thumb:GetParent():GetVerticalScroll()
    thumb:SetScript("OnUpdate", update_drag_safely)
end

local function update_release(thumb)
    thumb:SetScript("OnUpdate", nil)
end

function library.create_scroll(parent)
    local body = CreateFrame("ScrollFrame", nil, parent)
    body.content = CreateFrame("Frame", nil, body)
    body:SetScrollChild(body.content)
    body:EnableMouseWheel(true)
    body:SetScript("OnMouseWheel", update_wheel)
    body.thumb = CreateFrame("Frame", nil, body)
    body.thumb.face = library.create_surface(body.thumb, "OVERLAY", 0)
    body.thumb:EnableMouse(true)
    body.thumb:SetScript("OnMouseDown", update_grab)
    body.thumb:SetScript("OnMouseUp", update_release)
    body.thumb:SetFrameLevel(body:GetFrameLevel() + 10)
    return body
end

function library.update_scroll(body, width, room, length)
    body:SetSize(width, room)
    body.content:SetSize(width, math.max(length, 1))
    body.length = length
    library.update_scrolled(body, body:GetVerticalScroll())
end
