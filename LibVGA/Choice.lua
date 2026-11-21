-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's segmented choice, the chosen part in gold; one size for every part, the weight alone changing, every part as wide as the widest in its bold state, or as a given width allows, so a choice moves nothing; a part may show an icon in place of its word, the word then its tooltip; the parts joined over a black ground, its outer corners rounded, as vga-scale.html and vga-probe.html's .vt-seg draw it. A choice of off and on is a switch instead, in the way of macOS: a rounded track, gold while on, a light knob at its end (K0565). Its parts can be named anew and their number changed (library.update_choice_labels), and a choice marked natural gives each part its own width where equal parts would not fit (K0634). Given a most width, a choice wider than that gives every part an equal share and its word ends in »…« (K0637). Every part's width, place and the seam between parts lie on whole screen pixels, so no part slides half over its neighbour and leaves a hairline (K0653).

-- {K0256} {K0330} {K0334} {K0337} {K0409} {K0565} {K0634} {K0637} {K0653}

local library = LibVGA
local SWITCH_RATIO = 1.65
local update_switch_look
local SWITCH_OFF = { 0.173, 0.184, 0.208 }
local colours = library.colours

local function render_tip(button)
    GameTooltip:SetOwner(button, "ANCHOR_TOP")
    GameTooltip:AddLine(button.tip, colours.ink[1], colours.ink[2], colours.ink[3])
    GameTooltip:Show()
end

local function update_tip_left()
    GameTooltip:Hide()
end

local function create_icon(button, label)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetTexture(library.media .. label.icon)
    button.icon:SetPoint("CENTER")
    button.tip = label.tip
    button:SetScript("OnEnter", render_tip)
    button:SetScript("OnLeave", update_tip_left)
end

local function read_part_width(button, pad)
    if button.icon then return library.read_size(1) + 2 * pad end
    return math.ceil(button.text:GetStringWidth()) + 2 * pad
end

local function render_part(button)
    local choice = button:GetParent()
    choice.chosen = button.index
    library.update_choice(choice)
    choice.on_choose(button.index)
end

local function create_part(choice, index, label)
    local button = CreateFrame("Button", nil, choice)
    button.index = index
    button.face = button:CreateTexture(nil, "BACKGROUND")
    button.face:SetAllPoints()
    button.face:SetColorTexture(1, 1, 1, 1)
    button.text = library.create_text(button, "small")
    button.text:SetPoint("CENTER")
    if type(label) == "table" then create_icon(button, label) else button.text:SetText(label) end
    button:SetScript("OnClick", render_part)
    return button
end

local function read_parts(choice)
    local parts = {}
    for index = 1, choice.count or #choice.buttons do parts[index] = choice.buttons[index] end
    return parts
end

function library.update_choice_labels(choice, labels, chosen)
    for index, label in ipairs(labels) do
        choice.buttons[index] = choice.buttons[index] or create_part(choice, index, label)
        choice.buttons[index].text:SetText(label)
        choice.buttons[index]:Show()
    end
    for index = #labels + 1, #choice.buttons do choice.buttons[index]:Hide() end
    choice.count, choice.chosen = #labels, chosen
end

function library.create_choice(parent, labels, chosen, on_choose)
    local choice = CreateFrame("Frame", nil, parent)
    choice.ground = library.create_surface(choice, "BACKGROUND", 0)
    choice.rounding = CreateFrame("Frame", nil, choice)
    choice.rounding:SetAllPoints()
    choice.rounding:SetFrameLevel(choice:GetFrameLevel() + 3)
    choice.notches = library.create_notches(choice.rounding, "OVERLAY", 0)
    choice.buttons, choice.on_choose = {}, on_choose
    for index, label in ipairs(labels) do choice.buttons[index] = create_part(choice, index, label) end
    choice.count = #labels
    choice.chosen = chosen
    return choice
end

function library.read_choice_width(choice)
    local pad, widest = library.read_size(-2), 0
    local parts, total = read_parts(choice), 0
    for _, button in ipairs(parts) do
        button.text:SetFontObject(library.read_font("caption"))
        widest = math.max(widest, read_part_width(button, pad))
        total = total + read_part_width(button, pad)
    end
    if choice.natural then return total + #parts - 1 end
    return widest * #parts + #parts - 1
end

function library.update_choice(choice, wanted)
    if choice.switch then
        if choice.chosen then choice.on = choice.chosen == choice.on_index end
        update_switch_look(choice)
        return
    end
    choice.wanted = wanted or choice.wanted
    wanted = choice.wanted
    local parts = read_parts(choice)
    local height, count, pad = library.read_size(2), #parts, library.read_size(-2)
    local width = math.floor((math.max(wanted or 0, library.read_choice_width(choice)) - (count - 1)) / count)
    for _, button in ipairs(parts) do button.text:SetWidth(0) end
    local too_wide = choice.most and library.read_choice_width(choice) > choice.most
    local x, seam = 0, library.read_whole_pixels(1, choice)
    for index, button in ipairs(parts) do
        button.text:SetFontObject(library.read_font("caption"))
        button.text:SetWidth(0)
        local own = choice.natural and read_part_width(button, pad) or width
        if too_wide then
            own = math.floor((choice.most - (count - 1)) / count)
            button.text:SetWidth(own - 2 * pad)
            button.text:SetWordWrap(false)
        end
        own = library.read_whole_pixels(own, choice)
        button.text:SetFontObject(library.read_font(index == choice.chosen and "caption" or "small"))
        button:ClearAllPoints()
        button:SetSize(own, library.read_whole_pixels(height, choice))
        button:SetPoint("LEFT", choice, "LEFT", x, 0)
        x = x + own + seam
        if index == choice.chosen then
            button.face:SetGradient("VERTICAL", CreateColor(0.765, 0.588, 0.184, 1), CreateColor(colours.gold_high[1], colours.gold_high[2], colours.gold_high[3], 1))
            button.text:SetTextColor(0.102, 0.082, 0.043)
            if button.icon then button.icon:SetVertexColor(0.102, 0.082, 0.043, 1) end
        else
            button.face:SetGradient("VERTICAL", CreateColor(0.125, 0.133, 0.153, 1), CreateColor(0.173, 0.184, 0.208, 1))
            button.text:SetTextColor(unpack(colours.quiet))
            if button.icon then button.icon:SetVertexColor(colours.quiet[1], colours.quiet[2], colours.quiet[3], 1) end
        end
        if button.icon then button.icon:SetSize(library.read_size(1), library.read_size(1)) end
    end
    choice:SetSize(x - seam, library.read_whole_pixels(height, choice))
    local radius = library.read_size(-6)
    library.update_surface(choice.ground, -1, radius + 1, { 0, 0, 0 }, { 0, 0, 0 })
    library.update_notches(choice.notches, choice, radius, { 0, 0, 0 })
end

function update_switch_look(switch)
    local height = library.read_size(1)
    local width, knob = math.floor(height * SWITCH_RATIO + 0.5), height - 4
    switch:SetSize(width, height)
    local track = switch.on and colours.gold or SWITCH_OFF
    library.update_surface(switch.track, 0, height / 2, track, track)
    switch.knob:SetSize(knob, knob)
    switch.knob:ClearAllPoints()
    switch.knob:SetPoint(switch.on and "RIGHT" or "LEFT", switch, switch.on and "RIGHT" or "LEFT", switch.on and -2 or 2, 0)
    library.update_surface(switch.knob.face, 0, knob / 2, colours.ink, colours.ink)
end

local function render_switched(switch)
    switch.on = not switch.on
    if switch.on_index then switch.chosen = switch.on and switch.on_index or 3 - switch.on_index end
    update_switch_look(switch)
    switch.on_change(switch.on)
end

function library.create_switch(parent, on, on_change)
    local switch = CreateFrame("Button", nil, parent)
    switch.switch, switch.on, switch.on_change = true, on and true or false, on_change
    switch.track = library.create_surface(switch, "BACKGROUND", 0)
    switch.knob = CreateFrame("Frame", nil, switch)
    switch.knob.face = library.create_surface(switch.knob, "ARTWORK", 0)
    switch:SetScript("OnClick", render_switched)
    update_switch_look(switch)
    return switch
end

function library.update_switch(switch)
    update_switch_look(switch)
end
