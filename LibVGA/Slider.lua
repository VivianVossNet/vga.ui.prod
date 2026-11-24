-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's slider as the accepted draft draws it (manual/view/vga-probe.html, .sl): a flat dark track with rounded ends and a fine edge, a rounded gold fill, a round gold thumb ringed in black that rests on its stops - the opacities in steps of ten per cent -, a value between them shown at the nearest, the value grey beside it. A slider may carry its own way of writing its value (render), as the quest tracker's width in pixels. Its value reaches its owner at most once a frame however fast it is dragged, and once more, through on_settle, when the mouse lets it go (K0554).

-- {K0794} {K0319} {K0322} {K0330} {K0337}

local library = LibVGA
local colours = library.colours
local TRACK_EDGE = { 0.18, 0.192, 0.22 }
local TRACK = { 0.031, 0.035, 0.043 }

local function update_flushed(slider)
    slider.waiting = nil
    library.update_safely("slider", slider.on_change, slider.pending)
    library.render_control_changed(slider)
end

local function update_changed(slider, index)
    library.update_slider(slider)
    if slider.quiet then return end
    slider.pending = slider.stops[math.floor(index + 0.5)]
    if slider.waiting then return end
    slider.waiting = true
    C_Timer.After(0, function() update_flushed(slider) end)
end

local function update_settled(slider)
    if slider.on_settle then library.update_safely("slider settled", slider.on_settle, slider.pending) end
end

function library.create_slider(parent, stops, value, on_change)
    local slider = CreateFrame("Slider", nil, parent)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(1, #stops)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    slider.stops = stops
    slider.rail = CreateFrame("Frame", nil, slider)
    slider.rail:SetFrameLevel(slider:GetFrameLevel())
    slider.edge = library.create_surface(slider.rail, "BACKGROUND", 0)
    slider.track = library.create_surface(slider.rail, "BACKGROUND", 1)
    slider.bed = CreateFrame("Frame", nil, slider.rail)
    slider.fill = library.create_surface(slider.bed, "BORDER", 0)
    slider:SetThumbTexture(library.media .. "Thumb")
    slider.label = library.create_text(slider, "small", colours.quiet)
    library.update_slider_value(slider, value)
    slider.on_change = on_change
    slider:SetScript("OnValueChanged", update_changed)
    slider:HookScript("OnMouseUp", update_settled)
    return slider
end

function library.update_slider_value(slider, value)
    local position, nearest = 1, math.huge
    for index, stop in ipairs(slider.stops) do
        if math.abs(stop - value) < nearest then position, nearest = index, math.abs(stop - value) end
    end
    slider.quiet = true
    slider:SetValue(position)
    slider.quiet = false
end

function library.read_slider_width()
    return math.floor((library.read_size(6) * 2 + library.read_size(-2) + library.read_size(4)) * 1.5 + 0.5)
end

function library.update_slider(slider, wanted)
    local thumb = library.read_size(0) + 1
    slider.wanted = wanted or slider.wanted
    local width = (slider.wanted or library.read_slider_width()) - library.read_size(-2) - library.read_size(4)
    local track = math.max(4, library.read_size(-6) + 1)
    local inset = (thumb - track) / 2
    slider.reach = thumb / 2
    slider:SetSize(width - thumb, thumb)
    slider.rail:ClearAllPoints()
    slider.rail:SetPoint("TOPLEFT", slider, "TOPLEFT", -slider.reach, 0)
    slider.rail:SetPoint("BOTTOMRIGHT", slider, "BOTTOMRIGHT", slider.reach, 0)
    library.update_surface(slider.edge, inset - 1, track / 2 + 1, TRACK_EDGE, TRACK_EDGE)
    library.update_surface(slider.track, inset, track / 2, TRACK, TRACK)
    local share = (slider:GetValue() - 1) / math.max(#slider.stops - 1, 1)
    slider.bed:ClearAllPoints()
    slider.bed:SetPoint("LEFT", slider.rail, "LEFT")
    slider.bed:SetSize(math.max((width - thumb) * share + thumb, track), thumb)
    library.update_surface(slider.fill, inset, track / 2, colours.gold, colours.gold)
    slider:GetThumbTexture():SetSize(thumb, thumb)
    slider.label:SetFontObject(library.read_font("small"))
    slider.label:ClearAllPoints()
    slider.label:SetPoint("LEFT", slider.rail, "RIGHT", library.read_size(-2), 0)
    local stop = slider.stops[math.floor(slider:GetValue() + 0.5)]
    slider.label:SetText(slider.like or (slider.render and slider.render(stop)) or (math.floor(stop * 100 + 0.5) .. " %"))
end
