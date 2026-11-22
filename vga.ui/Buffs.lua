-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: The player's buffs as the accepted draft draws .buffs and .buff (manual/view/vga-probe.html): icons in a ring with gently rounded corners like the bag slots' - green for a helpful effect, red for a harmful one, white for a lasting search such as Find Minerals or Track Beasts, those following the buffs as a group of their own (K0618) -, the ring's full colour drawing back round the rim as the effect runs out, over a darkened ring of the same width and colour that always stays, driven by the game's own cooldown of the aura so it runs in a fight too, a lasting effect staying full (K0620), the time left small beneath each; from the player frame's left edge above it to the right, as many to a row as the frame's width holds, two rows at most; Blizzard's own buff frame hidden. Above the target frame the same, mirrored as the target frame is, from its right edge to the left: the target's buffs, then on a row of their own its debuffs, red (K0580) - the player's own first, each with the bags' shimmer of a light running round its rim and a star flashing at its corner, the others after them on the same row (K0615). Both are the game's own aura containers (K0584), which the game fills itself, in a fight too, where an addon may not read auras: each icon shows the game's tooltip of its aura under the mouse, and a click on one of the player's own buffs ends it; the time beneath each written short, one letter for its unit, in the smallest face, so neighbours do not run into each other (K0588); a dead target's auras are hidden, and so are the last target's once none is chosen (K0585, K0586); on a change of target the container is told to read its auras anew, which it does not do by itself, so no foe's auras pass to the next (K0591). Every row stands clear of the times beneath the row below it: the height of a time in its face, its drop of two pixels and four draft pixels more, both between a group's own rows (lineSpacing) and where a group begins a row of its own (groupLineSpacing, which the game's aura container keeps apart and which was nought, so a second row ran into the first row's times), and as much between the frame and the first row (K0694). Above the target of target its own small row of debuffs, after manual/view/vga-tot.html: the icons scaled as that frame is to the target frame, no time, only the ring running down, growing from its right edge, a child of that frame so it shows and hides with it (K0696). Besides, at the top of the screen, an area of its own for the player and one for the target, each showing exactly what its frame's shows, in the same look, but every aura, growing downwards: by default straight above its frame at the screen's top edge, a place of its own to be moved; the units' settings choose for each, apart, whether its auras stand at the frame, at the top or both, at the frame by default; at the frame at most two rows a group, as before, at the top up to forty (K0713); a top area made only once it is chosen, so at the frame alone each unit has one aura container, as before (K0718). An aura's stack count lies above the ring that runs down, on a layer of its own, so the ring never covers it (K0735). The game's own buff frame, hidden in play but shown by the game's edit mode, and its debuff frame, which shows the player's own debuffs, stand left of our map, eight draft pixels from it, the debuffs beneath the buffs, laid there again whenever the edit mode begins or ends and whenever the elements are laid, never in a fight (K0742). The own debuffs' shimmer is laid guarded, so its failure never keeps a debuff from showing - Forever's missing SetCurve hid every own debuff on foes until K0719 (K0719).

-- {K0261} {K0355} {K0580} {K0584} {K0585} {K0586} {K0588} {K0591} {K0615} {K0618} {K0620} {K0694} {K0696} {K0713} {K0718} {K0719} {K0735} {K0742}

local library = LibVGA
local colours = library.colours
local ROWS = 2
local GOOD = { 0.247, 0.749, 0.353 }
local HARM = { 0.886, 0.404, 0.353 }
local STEADY = { 0.92, 0.92, 0.9 }
local SPENT = 0.32
local TRACKING = { [1494] = true, [1284017] = true, [2383] = true, [8387] = true, [2481] = true, [2580] = true, [8388] = true, [5225] = true, [19883] = true, [5500] = true, [5502] = true, [5503] = true, [1241115] = true, [19878] = true, [19879] = true, [19880] = true, [19882] = true, [19884] = true, [19885] = true, [43308] = true }
local GROW = { right = 1, left = -1, up = 1, down = -1 }
local STRIPS = {
    { unit = "player", frame = "VGAUnitFrame_player", name = "VGABuffs", choice = "buffs_player", corner = "BOTTOMLEFT", grow = GROW.right, groups = { { key = "buffs", filter = "HELPFUL", line = GOOD, cancel = true, candidate = { excludeSpellIDs = TRACKING } }, { key = "tracking", filter = "HELPFUL", line = STEADY, cancel = true, follows = true, candidate = { includeSpellIDs = TRACKING } } } },
    { unit = "targettarget", frame = "VGAUnitFrame_targettarget", name = "VGATargetTargetAuras", corner = "BOTTOMRIGHT", grow = GROW.left, scaled = true, groups = { { key = "debuffs", filter = "HARMFUL", line = HARM, timeless = true } } },
    { unit = "target", frame = "VGAUnitFrame_target", name = "VGATargetAuras", choice = "buffs_target", corner = "BOTTOMRIGHT", grow = GROW.left, groups = { { key = "buffs", filter = "HELPFUL", line = GOOD }, { key = "own", filter = "HARMFUL|PLAYER", line = HARM, shimmer = true }, { key = "debuffs", filter = "HARMFUL|!PLAYER", line = HARM, follows = true } } },
}
local strips = {}
local create_top_place
local update_top_strips_made
local TOP_MOST = 40
local TOP_CORNERS = { BOTTOMLEFT = "TOPLEFT", BOTTOMRIGHT = "TOPRIGHT" }
local SCALE = 0.6
local TIME_DROP = 2
local ROW_GAP = 4
local DOCK_GAP = 8
local DOCKING = {}
local time_probe

local function read_scale()
    local small, full = VGAUnitFrame_targettarget, VGAUnitFrame_target
    local ratio = small and full and full:GetHeight() > 0 and small:GetHeight() / full:GetHeight()
    return ratio and ratio > 0 and ratio or SCALE
end

local function read_icon_size(scaled)
    local size, gap = library.read_size(3), library.read_size(-4)
    if scaled then size = math.floor(size * read_scale() + 0.5) end
    return size, gap
end

local function create_time_formatter()
    local formatter = C_StringUtil.CreateSecondsFormatter()
    formatter:SetDefaultAbbreviation(Enum.SecondsFormatterAbbreviation.OneLetter)
    formatter:SetRounding(Enum.SecondsFormatterRounding.Truncate)
    formatter:SetMinInterval(Enum.SecondsFormatterInterval.Seconds)
    formatter:SetDesiredUnitCount(1)
    return formatter
end

local function update_time_text(button)
    local made, formatter = pcall(create_time_formatter)
    if made and pcall(button.SetDurationText, button, button.time, { textFormatter = formatter }) then return end
    button:SetDurationText(button.time)
end

local function read_edge(size)
    return math.max(2, math.floor(size / 9 + 0.5))
end

local function update_button_look(button)
    local size = read_icon_size(button.scaled)
    local edge = read_edge(size)
    button:SetSize(size, size)
    local colour = button.colour
    button.ring:SetVertexColor(colour[1], colour[2], colour[3], 1)
    button.ring:SetAllPoints()
    if button.drain then
        button.drain:SetAllPoints()
        button.drain:SetSwipeColor(colour[1] * SPENT, colour[2] * SPENT, colour[3] * SPENT, 1)
    end
    library.update_cell_picture(button.art, button, edge)
    button.time:SetFontObject(library.read_frame_font("tiny"))
    button.count:SetFontObject(library.read_frame_font("caption"))
end

local function create_button_parts(button, group, strip)
    button.colour, button.scaled = group.line, strip.scaled
    button.art = button:CreateTexture(nil, "ARTWORK")
    button.art:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.ring = button:CreateTexture(nil, "OVERLAY", nil, 2)
    button.ring:SetTexture(library.media .. "AuraRing")
    if button.SetDurationCooldown then
        button.drain = CreateFrame("Cooldown", nil, button)
        button.drain:SetFrameLevel(button:GetFrameLevel() + 2)
        button.drain:SetSwipeTexture(library.media .. "AuraRing")
        button.drain:SetDrawEdge(false)
        button.drain:SetDrawBling(false)
        button.drain:SetHideCountdownNumbers(true)
        button.drain:SetReverse(true)
        button:SetDurationCooldown(button.drain)
    end
    button.lift = CreateFrame("Frame", nil, button)
    button.lift:SetAllPoints()
    button.lift:SetFrameLevel(button:GetFrameLevel() + 3)
    button.count = library.create_text(button.lift, "caption")
    button.count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, -1)
    button.time = library.create_text(button, "small", colours.ink)
    button.time:SetPoint("TOP", button, "BOTTOM", 0, -TIME_DROP)
    button:SetIcon(button.art)
    button.time:SetShown(not group.timeless)
    if not group.timeless then update_time_text(button) end
    button:SetApplicationCount(button.count)
    if group.cancel then button:SetCancelAuraButtons("LeftButtonUp RightButtonUp") end
    if group.shimmer then library.update_safely("buffs shimmer", library.create_running_shimmer, button, read_icon_size()) end
    update_button_look(button)
end

local function create_initializer(strip, group)
    return function(button)
        create_button_parts(button, group, strip)
        strip.buttons[#strip.buttons + 1] = button
    end
end

local function read_time_room()
    time_probe = time_probe or UIParent:CreateFontString(nil, "OVERLAY")
    time_probe:Hide()
    time_probe:SetFontObject(library.read_frame_font("tiny"))
    time_probe:SetText("10 s")
    return math.ceil(time_probe:GetStringHeight()) + TIME_DROP + library.read_draft_size(ROW_GAP)
end

local function read_group_layout(index, group, scaled)
    local size, gap = read_icon_size(scaled)
    local room = group.timeless and gap or read_time_room()
    return { elementWidth = size, elementHeight = size, elementSpacing = gap, lineSpacing = room, groupLineSpacing = room, forceNewLine = index > 1 and not group.follows, layoutIndex = index }
end

local function check_strip_shown(strip)
    local chosen = strip.choice and LibVGASettings[strip.choice] or "frame"
    if strip.top then return chosen ~= "frame" end
    return chosen ~= "top"
end

local function update_strip(strip)
    local frame = _G[strip.frame]
    if not frame or InCombatLockdown() then return end
    local size, gap = read_icon_size(strip.scaled)
    local per_row = math.max(1, math.floor((frame:GetWidth() + gap) / (size + gap)))
    local container = strip.container
    if strip.scaled and container:GetParent() ~= frame then container:SetParent(frame) end
    if not strip.top then
        container:ClearAllPoints()
        container:SetPoint(strip.corner, frame, strip.corner == "BOTTOMLEFT" and "TOPLEFT" or "TOPRIGHT", 0, strip.scaled and gap or read_time_room())
    end
    container:SetFlowLayoutMaximumLineSize(frame:GetWidth())
    local most = check_strip_shown(strip) and (strip.top and TOP_MOST or per_row * ROWS) or 0
    for index, group in ipairs(strip.groups) do
        container:SetAuraGroupLayout(group.key, read_group_layout(index, group, strip.scaled))
        container:SetAuraGroupMaxFrameCount(group.key, most)
    end
    for _, button in ipairs(strip.buttons) do pcall(update_button_look, button) end
end

local function update_dead_target()
    for _, strip in ipairs(strips) do
        if strip.unit == "target" then strip.container:SetAlpha((UnitExists("target") and not UnitIsDead("target")) and 1 or 0) end
    end
end

local function update_new_target()
    for _, strip in ipairs(strips) do
        if strip.unit == "target" or strip.unit == "targettarget" then strip.container:UpdateAllAuras() end
    end
    update_dead_target()
end

local function update_game_auras_docked()
    if InCombatLockdown() or not (VGAMapFrame and BuffFrame and DebuffFrame) then return end
    local gap = library.read_draft_size(DOCK_GAP)
    BuffFrame:ClearAllPoints()
    BuffFrame:SetPoint("TOPRIGHT", VGAMapFrame, "TOPLEFT", -gap, 0)
    DebuffFrame:ClearAllPoints()
    DebuffFrame:SetPoint("TOPRIGHT", BuffFrame, "BOTTOMRIGHT", 0, -gap)
end

local function update_game_auras_safely()
    library.update_safely("game auras docked", update_game_auras_docked)
end

local function update_buffs()
    update_game_auras_docked()
    update_top_strips_made()
    for _, strip in ipairs(strips) do update_strip(strip) end
    update_dead_target()
end

function create_top_place(strip)
    local frame, edge = _G[strip.frame], library.read_size(-2)
    local left = strip.corner == "TOPLEFT"
    local x = frame and (left and (frame:GetLeft() or 0) or ((frame:GetRight() or 0) - (UIParent:GetRight() or 0))) or 0
    library.create_place(strip.container, strip.container:GetName(), strip.corner, UIParent, x, -edge)
end

local function create_strip(shape)
    local strip = { unit = shape.unit, frame = shape.frame, corner = shape.corner, groups = shape.groups, scaled = shape.scaled, choice = shape.choice, top = shape.top, buttons = {} }
    local container = CreateFrame("AuraContainer", shape.name, UIParent, "CustomAuraContainerTemplate")
    container:SetUnit(shape.unit)
    container:SetFlowLayoutAnchorPoint(shape.corner)
    container:SetFlowLayoutGrowthDirection(shape.grow, shape.top and GROW.down or GROW.up)
    for index, group in ipairs(shape.groups) do
        container:AddAuraGroup(group.key, group.filter, { initializeFrame = create_initializer(strip, group), layout = read_group_layout(index, group, shape.scaled), candidateFilters = group.candidate })
    end
    strip.container = container
    strips[#strips + 1] = strip
    if shape.top then create_top_place(strip) end
end

local function read_top_shape(shape)
    local top = {}
    for key, value in pairs(shape) do top[key] = value end
    top.name, top.top, top.corner = shape.name .. "Top", true, TOP_CORNERS[shape.corner]
    return top
end

function update_top_strips_made()
    if InCombatLockdown() then return end
    for _, shape in ipairs(STRIPS) do
        local chosen = shape.choice and LibVGASettings[shape.choice]
        if chosen and chosen ~= "frame" and not _G[shape.name .. "Top"] then create_strip(read_top_shape(shape)) end
    end
end

local function create_buffs()
    for _, shape in ipairs(STRIPS) do create_strip(shape) end

    if BuffFrame then
        BuffFrame:UnregisterAllEvents()
        BuffFrame:Hide()
        BuffFrame:SetAlpha(0)
    end
    library.create_element("buffs", { update = update_buffs })
    if EventRegistry then
        EventRegistry:RegisterCallback("EditMode.Enter", update_game_auras_safely, DOCKING)
        EventRegistry:RegisterCallback("EditMode.Exit", update_game_auras_safely, DOCKING)
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
pcall(events.RegisterUnitEvent, events, "UNIT_HEALTH", "target")
pcall(events.RegisterUnitEvent, events, "UNIT_FLAGS", "target")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        library.update_safely("buffs login", create_buffs)
    elseif event == "PLAYER_TARGET_CHANGED" then
        library.update_safely("buffs new target", update_new_target)
    else
        library.update_safely("buffs dead target", update_dead_target)
    end
end)
