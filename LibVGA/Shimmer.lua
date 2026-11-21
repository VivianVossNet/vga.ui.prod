-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's shimmer for something new: the button brightened, every three seconds a light running once round its rim that ends in a star flashing at its corner - the bags' new items' (K0403, K0477) and the action keys' newly learned spells' (K0482) -, laid by its owner each frame with the cycle's phase and the button's side, taken away whole by delete_shimmer; or, by create_running_shimmer, laid once as an animation that runs by itself, for frames the addon may not touch each frame - the game's aura buttons while auras are secret (K0615).

-- {K0403} {K0482} {K0615}

local library = LibVGA
local colours = library.colours
local DRAFT_BASE = 13
local CYCLE = 3
local RUN_END = 0.26
local STAR_FROM, STAR_PEAK, STAR_END = 0.24, 0.27, 0.34
local TRAIL = { { 0, 1 }, { 0.025, 0.6 }, { 0.05, 0.3 } }

local function read_draft(pixels)
    return math.floor(pixels * library.read_base() / DRAFT_BASE + 0.5)
end

function library.create_shimmer(button)
    button.vga_bright = button:CreateTexture(nil, "OVERLAY", nil, 1)
    button.vga_bright:SetAllPoints()
    button.vga_bright:SetColorTexture(1, 1, 1, 0.18)
    button.vga_bright:SetBlendMode("ADD")
    button.vga_trail = {}
    for index in ipairs(TRAIL) do
        local dot = button:CreateTexture(nil, "OVERLAY", nil, 7)
        dot:SetTexture(library.media .. "Disc")
        dot:SetBlendMode("ADD")
        button.vga_trail[index] = dot
    end
    button.vga_star = button:CreateTexture(nil, "OVERLAY", nil, 7)
    button.vga_star:SetTexture(library.media .. "Star")
    button.vga_star:SetBlendMode("ADD")
end

local function read_point(share, side)
    local walked = (share % 1) * 4
    local edge, along = math.floor(walked), walked % 1
    if edge == 0 then return along * side, 0 end
    if edge == 1 then return side, -along * side end
    if edge == 2 then return side - along * side, -side end
    return 0, -side + along * side
end

local function update_trail(button, phase, side)
    local dot = read_draft(4)
    for index, step in ipairs(TRAIL) do
        local piece = button.vga_trail[index]
        local share = phase / RUN_END - step[1]
        piece:SetShown(phase < RUN_END and share >= 0)
        if piece:IsShown() then
            local across, down = read_point(share, side)
            local colour = index == 1 and { 1, 1, 1 } or colours.gold_high
            piece:SetSize(dot, dot)
            piece:ClearAllPoints()
            piece:SetPoint("CENTER", button, "TOPLEFT", across, down)
            piece:SetVertexColor(colour[1], colour[2], colour[3], step[2])
        end
    end
end

local function update_star(button, phase)
    local star = button.vga_star
    star:SetShown(phase >= STAR_FROM and phase <= STAR_END)
    if not star:IsShown() then return end
    local rising = phase <= STAR_PEAK
    local share = rising and (phase - STAR_FROM) / (STAR_PEAK - STAR_FROM) or (phase - STAR_PEAK) / (STAR_END - STAR_PEAK)
    local scale = rising and 0.3 + 0.9 * share or 1.2 - 0.8 * share
    local size = read_draft(14) * scale
    star:SetSize(size, size)
    star:ClearAllPoints()
    star:SetPoint("CENTER", button, "TOPLEFT", read_draft(1), -read_draft(1))
    star:SetRotation(math.rad(rising and 45 * share or 45 + 45 * share))
    star:SetAlpha(rising and share or 1 - share)
end

function library.read_shimmer_phase()
    return (GetTime() % CYCLE) / CYCLE
end

function library.update_shimmer(button, phase, side)
    button.vga_bright:Show()
    update_trail(button, phase, side)
    update_star(button, phase)
end

local function create_alpha(group, target, from, to, delay, duration)
    local fade = group:CreateAnimation("Alpha")
    fade:SetTarget(target)
    fade:SetFromAlpha(from)
    fade:SetToAlpha(to)
    fade:SetStartDelay(delay)
    fade:SetDuration(duration)
    return fade
end

local function create_running_dot(frame, group, side, index, step)
    local dot, size = frame:CreateTexture(nil, "OVERLAY", nil, 7), read_draft(4)
    local colour = index == 1 and { 1, 1, 1 } or colours.gold_high
    dot:SetTexture(library.media .. "Disc")
    dot:SetBlendMode("ADD")
    dot:SetSize(size, size)
    dot:SetPoint("CENTER", frame, "TOPLEFT", 0, 0)
    dot:SetVertexColor(colour[1], colour[2], colour[3], 1)
    dot:SetAlpha(0)
    local delay, run = step[1] * RUN_END * CYCLE, RUN_END * CYCLE
    local path = group:CreateAnimation("Path")
    path:SetTarget(dot)
    path:SetCurve("NONE")
    path:SetStartDelay(delay)
    path:SetDuration(run)
    for _, corner in ipairs({ { side, 0 }, { side, -side }, { 0, -side }, { 0, 0 } }) do
        path:CreateControlPoint():SetOffset(corner[1], corner[2])
    end
    create_alpha(group, dot, step[2], step[2], delay, run)
end

local function create_scale(group, target, from, to, delay, duration)
    local grow = group:CreateAnimation("Scale")
    grow:SetTarget(target)
    if grow.SetScaleFrom then
        grow:SetScaleFrom(from, from)
        grow:SetScaleTo(to, to)
    else
        grow:SetFromScale(from, from)
        grow:SetToScale(to, to)
    end
    grow:SetStartDelay(delay)
    grow:SetDuration(duration)
end

local function create_running_star(frame, group)
    local star, size = frame:CreateTexture(nil, "OVERLAY", nil, 7), read_draft(14)
    star:SetTexture(library.media .. "Star")
    star:SetBlendMode("ADD")
    star:SetSize(size, size)
    star:SetPoint("CENTER", frame, "TOPLEFT", read_draft(1), -read_draft(1))
    star:SetAlpha(0)
    local rise, fall = (STAR_PEAK - STAR_FROM) * CYCLE, (STAR_END - STAR_PEAK) * CYCLE
    create_alpha(group, star, 0, 1, STAR_FROM * CYCLE, rise)
    create_alpha(group, star, 1, 0, STAR_PEAK * CYCLE, fall)
    create_scale(group, star, 0.3, 1.2, STAR_FROM * CYCLE, rise)
    create_scale(group, star, 1.2, 0.4, STAR_PEAK * CYCLE, fall)
    local turn = group:CreateAnimation("Rotation")
    turn:SetTarget(star)
    turn:SetDegrees(-90)
    turn:SetStartDelay(STAR_FROM * CYCLE)
    turn:SetDuration(rise + fall)
end

function library.create_running_shimmer(frame, side)
    local bright = frame:CreateTexture(nil, "OVERLAY", nil, 1)
    bright:SetAllPoints()
    bright:SetColorTexture(1, 1, 1, 0.12)
    bright:SetBlendMode("ADD")
    local group = frame:CreateAnimationGroup()
    group:SetLooping("REPEAT")
    for index, step in ipairs(TRAIL) do create_running_dot(frame, group, side, index, step) end
    create_running_star(frame, group)
    create_alpha(group, bright, 1, 1, 0, CYCLE)
    group:Play()
    return group
end

function library.delete_shimmer(button)
    button.vga_bright:Hide()
    for _, dot in ipairs(button.vga_trail) do dot:Hide() end
    button.vga_star:Hide()
end
