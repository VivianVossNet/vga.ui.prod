-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's shimmer for something new: the button brightened, every three seconds a light running once round its rim that ends in a star flashing at its corner - the bags' new items' (K0403, K0477) and the action keys' newly learned spells' (K0482) -, laid by its owner each frame with the cycle's phase and the button's side, taken away whole by delete_shimmer; or, by create_running_shimmer, laid once as an animation that runs by itself, for frames the addon may not touch each frame - the game's aura buttons while auras are secret (K0615). Its light runs round the rim in four straight legs of Translation animations, one after another - right, down, left, up -, not along a Path: Forever's Path has no SetCurve, whose call broke every own debuff's button on foes since K0615 (K0719), and without it the light ran the top edge alone and stood at the right (K0720). And a timed run for a key whose work repeats at a known pace - the auto attack's swings (K0881): library.create_swing_run makes, on a frame of its own above the key, the bags' bold ring in white at the key's rim width, so it lies exactly on the key's rim; library.render_swing_run starts it anew for a given number of seconds - and, given a reader of the next round's seconds, starts it again at once at each round's end, for as long as it runs (K0883) -, the white frame growing from the top's left end clockwise round the rim, from nothing to whole, as manual/view/vga-mainbar.html's section C draws it, and standing whole once the time is over; library.update_swing_run_stopped takes it away. A duration the game keeps secret, or none, starts nothing. It touches no attribute of the key, which may be protected. And the same run once round any rectangle, for a notice that earns it - the gold place toast of a discovery (K1048): library.create_rim_run makes it on a frame, library.render_rim_run lays its legs to the frame's width and height, each leg as long in time as in length, and plays it once, the light starting at the top left, running clockwise all round and ending in the star flashing at that corner, as the bags' does.

-- {K1048} {K0719} {K0720} {K0403} {K0482} {K0615} {K0881} {K0883}

local library = LibVGA
local colours = library.colours
local CYCLE = 3
local RUN_END = 0.26
local STAR_FROM, STAR_PEAK, STAR_END = 0.24, 0.27, 0.34
local TRAIL = { { 0, 1 }, { 0.025, 0.6 }, { 0.05, 0.3 } }

local function read_draft(pixels)
    return library.read_draft_size(pixels)
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

local RIM_LEGS = { { 1, 0 }, { 0, -1 }, { -1, 0 }, { 0, 1 } }

local function update_running_legs(slides, width, height, delay)
    local run, round = RUN_END * CYCLE, 2 * (width + height)
    local start = delay
    for leg, move in ipairs(RIM_LEGS) do
        local length = move[1] ~= 0 and width or height
        local slide = slides[leg]
        slide:SetOffset(move[1] * width, move[2] * height)
        slide:SetStartDelay(start)
        slide:SetDuration(run * length / round)
        start = start + run * length / round
    end
end

local function create_running_dot(frame, group, width, height, index, step)
    local dot, size = frame:CreateTexture(nil, "OVERLAY", nil, 7), read_draft(4)
    local colour = index == 1 and { 1, 1, 1 } or colours.gold_high
    dot:SetTexture(library.media .. "Disc")
    dot:SetBlendMode("ADD")
    dot:SetSize(size, size)
    dot:SetPoint("CENTER", frame, "TOPLEFT", 0, 0)
    dot:SetVertexColor(colour[1], colour[2], colour[3], 1)
    dot:SetAlpha(0)
    local delay, run, slides = step[1] * RUN_END * CYCLE, RUN_END * CYCLE, {}
    for leg in ipairs(RIM_LEGS) do
        slides[leg] = group:CreateAnimation("Translation")
        slides[leg]:SetTarget(dot)
    end
    update_running_legs(slides, width, height, delay)
    create_alpha(group, dot, step[2], step[2], delay, run)
    return slides
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
    for index, step in ipairs(TRAIL) do create_running_dot(frame, group, side, side, index, step) end
    create_running_star(frame, group)
    create_alpha(group, bright, 1, 1, 0, CYCLE)
    group:Play()
    return group
end

function library.create_rim_run(frame)
    local run = { group = frame:CreateAnimationGroup(), trail = {} }
    run.group:SetLooping("NONE")
    for index, step in ipairs(TRAIL) do run.trail[index] = create_running_dot(frame, run.group, 1, 1, index, step) end
    create_running_star(frame, run.group)
    return run
end

function library.render_rim_run(run, width, height)
    for index, step in ipairs(TRAIL) do update_running_legs(run.trail[index], width, height, step[1] * RUN_END * CYCLE) end
    run.group:Stop()
    run.group:Play()
end

function library.delete_shimmer(button)
    button.vga_bright:Hide()
    for _, dot in ipairs(button.vga_trail) do dot:Hide() end
    button.vga_star:Hide()
end

local WHITE = { 1, 1, 1 }
local RUN_PATH = {
    { "EDGETOP", "TOPLEFT", 1, 0, true }, { "TOPRIGHT" }, { "EDGERIGHT", "TOPRIGHT", 0, -1, false }, { "BOTTOMRIGHT" },
    { "EDGEBOTTOM", "BOTTOMRIGHT", -1, 0, true }, { "BOTTOMLEFT" }, { "EDGELEFT", "BOTTOMLEFT", 0, 1, false }, { "TOPLEFT" },
}

local function check_plain_seconds(seconds)
    if issecretvalue and issecretvalue(seconds) then return false end
    return type(seconds) == "number" and seconds > 0
end

local function update_run_edge(run, piece, step, length)
    local thickness, radius = run.thickness_whole, run.radius
    piece:SetShown(length > 0)
    if length <= 0 then return end
    piece:ClearAllPoints()
    piece:SetPoint(step[2], run, step[2], step[3] * radius, step[4] * radius)
    if step[5] then piece:SetSize(length, thickness) else piece:SetSize(thickness, length) end
end

local function update_run_path(run)
    local straight = math.max(0, run:GetWidth() - 2 * run.radius)
    local bend = run.radius * math.pi / 2
    local walked, start = run.share * 4 * (straight + bend), 0
    for _, step in ipairs(RUN_PATH) do
        local piece, length = run.ring.pieces[step[1]], step[2] and straight or bend
        local reached = math.min(math.max(walked - start, 0), length)
        if step[2] then update_run_edge(run, piece, step, reached) else piece:SetShown(length > 0 and reached >= length / 2) end
        start = start + length
    end
end

local function update_swing_run_share(run)
    run.share = math.min((GetTime() - run.start) / run.seconds, 1)
    update_run_path(run)
    if run.share < 1 then return end
    run:SetScript("OnUpdate", nil)
    if run.read_next then library.render_swing_run(run, run.read_next(), run.read_next) end
end

local function update_swing_run_safely(run)
    library.update_safely("swing run", update_swing_run_share, run)
end

function library.create_swing_run(frame, thickness)
    local run = CreateFrame("Frame", nil, frame)
    run:SetAllPoints(frame)
    run:SetFrameLevel(frame:GetFrameLevel() + 2)
    run.thickness = thickness
    run.ring = library.create_ring(run, "OVERLAY", 7, nil, true)
    run:Hide()
    return run
end

function library.render_swing_run(run, seconds, read_next)
    if not check_plain_seconds(seconds) then return end
    run.read_next = read_next
    library.update_ring(run.ring, run.thickness, WHITE, 1)
    run.thickness_whole = library.read_whole_pixels(run.thickness, run)
    run.radius = run.ring.ratio * run.thickness_whole
    run.start, run.seconds = GetTime(), seconds
    run:Show()
    run:SetScript("OnUpdate", update_swing_run_safely)
    update_swing_run_share(run)
end

function library.update_swing_run_stopped(run)
    run:SetScript("OnUpdate", nil)
    run:Hide()
end
