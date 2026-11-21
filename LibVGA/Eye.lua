-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's preview eye as manual/view/vga-arcs-preview.html draws it (K0574): a small button before a row's control, an open eye in gold while its element shows a sample of itself without the situation it needs, a struck eye, quiet, otherwise; a click turns it; under the mouse its ink lightens and a thin ring shows that stands, unseen, at rest too, so nothing moves; every open preview eye closes when the settings close; an eye given its own two tooltips - to turn on, to turn off - keeps its state and may be set without telling its owner (library.update_eye_shown), as the auction window's watch eyes do (K0655).

-- {K0574} {K0655}

local library = LibVGA
local colours = library.colours
local EDGE = { 0.173, 0.184, 0.208 }
local eyes = {}

local function update_eye_look(eye)
    local ink = eye.on and colours.gold or (eye.hovered and colours.label or colours.quiet)
    eye.icon:SetTexture(library.media .. (eye.on and "EyeOpen" or "EyeShut"))
    eye.icon:SetVertexColor(ink[1], ink[2], ink[3], 1)
    library.update_ring(eye.edge, 1, EDGE, eye.hovered and 1 or 0)
end

local function update_entered(eye)
    eye.hovered = true
    update_eye_look(eye)
    GameTooltip:SetOwner(eye, "ANCHOR_TOP")
    GameTooltip:SetText(eye.tips and (eye.on and eye.tips[2] or eye.tips[1]) or library.texts.preview)
    GameTooltip:Show()
end

local function update_left(eye)
    eye.hovered = nil
    update_eye_look(eye)
    GameTooltip:Hide()
end

function library.update_eye_shown(eye, on)
    eye.on = on
    update_eye_look(eye)
end

function library.update_eye(eye, on)
    eye.on = on
    update_eye_look(eye)
    eye.on_change(on)
end

local function render_turned(eye)
    library.update_eye(eye, not eye.on)
end

function library.create_eye(parent, on_change, tips)
    local eye = CreateFrame("Button", nil, parent)
    eye.eye, eye.on_change, eye.tips = true, on_change, tips
    eye.icon = eye:CreateTexture(nil, "ARTWORK")
    eye.icon:SetPoint("CENTER")
    eye.edge = library.create_ring(eye, "BORDER", 0)
    eye:SetScript("OnEnter", update_entered)
    eye:SetScript("OnLeave", update_left)
    eye:SetScript("OnClick", render_turned)
    if not tips then eyes[#eyes + 1] = eye end
    return eye
end

function library.update_eye_layout(eye)
    local size, icon = library.read_size(2), library.read_size(0)
    eye:SetSize(size, size)
    eye.icon:SetSize(icon, icon)
    update_eye_look(eye)
end

function library.update_eyes_closed()
    for _, eye in ipairs(eyes) do
        if eye.on then library.update_eye(eye, false) end
    end
end
