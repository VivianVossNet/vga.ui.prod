-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's bar, rounded as the drafts draw it: a gain previewed darkened, filled and swept by a slanted shine; a loss left as a muted trail; with secret values the same two shadows run as bars of their own, one at once and one delayed, eased by the game, and the shine sweeps the whole filled bar whenever a gain is told by the caller, since a secret value cannot tell it. A thin bar with a small caption beneath it - the cast bar under a unit frame - takes library.read_cast_height, and the room it keeps there library.read_cast_room, moved here from vga.ui's Casts.lua (K0795). A bar may also be shaded across by any colour, darkened from left to right, as the damage meter's rows in their class's colour (K0721).

-- {K0795} {K0782} {K0300} {K0334} {K0339} {K0342} {K0348} {K0721}

local library = LibVGA

local BARS = {
    health = { { 0.498, 0.816, 0.416 }, { 0.243, 0.541, 0.18 } },
    power = { { 0.455, 0.659, 0.925 }, { 0.184, 0.373, 0.659 } },
    enemy = { { 0.886, 0.376, 0.247 }, { 0.604, 0.184, 0.11 } },
    rage = { { 0.851, 0.388, 0.345 }, { 0.545, 0.157, 0.133 } },
    focus = { { 0.925, 0.643, 0.384 }, { 0.639, 0.341, 0.122 } },
    energy = { { 0.957, 0.878, 0.522 }, { 0.659, 0.565, 0.173 } },
    runic = { { 0.459, 0.812, 0.902 }, { 0.165, 0.475, 0.573 } },
    gold = { { 0.965, 0.863, 0.557 }, { 0.612, 0.455, 0.141 } },
    tapped = { { 0.62, 0.62, 0.62 }, { 0.36, 0.36, 0.38 } },
    silver = { { 0.831, 0.851, 0.878 }, { 0.459, 0.478, 0.518 } },
    bronze = { { 0.886, 0.592, 0.38 }, { 0.49, 0.29, 0.149 } },
    orange = { { 0.976, 0.565, 0.188 }, { 0.6, 0.29, 0.063 } },
    hunter = { { 0.667, 0.827, 0.447 }, { 0.329, 0.471, 0.176 } },
    mage = { { 0.247, 0.78, 0.922 }, { 0.09, 0.42, 0.553 } },
    violet = { { 0.706, 0.565, 0.945 }, { 0.388, 0.247, 0.651 } },
}

local LIGHT = { energy = true, gold = true }
local TRAIL_ALPHA = 0.5
local BLACK = { 0, 0, 0 }
local TRACK = { 0.031, 0.035, 0.043 }
local EASED = Enum and Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.ExponentialEaseOut
local PREVIEW, FILL, SHINE, HOLD, DRAIN = 1, 0.45, 0.7, 0.6, 0.4

local function read_smooth(share)
    if share < 0.5 then return 2 * share * share end
    return 1 - ((-2 * share + 2) ^ 2) / 2
end

local function update_span(texture, bar, from, to)
    local width = bar:GetWidth()
    texture:ClearAllPoints()
    texture:SetPoint("TOPLEFT", bar, "TOPLEFT", width * math.min(from, to), 0)
    texture:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", width * math.min(from, to), 0)
    texture:SetWidth(math.max(width * math.abs(to - from), 0.01))
    texture:SetShown(math.abs(to - from) > 0.0005)
end

local function update_motion(bar, elapsed)
    local motion = bar.motion
    motion.time = motion.time + elapsed
    local time = motion.time
    if motion.kind == "gain" then
        if time < PREVIEW then return end
        local share = math.min(1, (time - PREVIEW) / FILL)
        bar:SetValue(motion.from + (motion.to - motion.from) * library.read_eased(share))
        if share < 1 then return end
        bar.preview:Hide()
        local sweep = math.min(1, (time - PREVIEW - FILL) / SHINE)
        local reach = bar:GetWidth() * motion.to
        bar.shine:ClearAllPoints()
        bar.shine:SetPoint("TOPLEFT", bar.clip, "TOPLEFT", -bar.shine:GetWidth() + (reach + bar.shine:GetWidth()) * read_smooth(sweep), 2)
        bar.shine:Show()
        if sweep >= 1 then
            bar.shine:Hide()
            bar.motion = nil
            bar:SetScript("OnUpdate", nil)
        end
    else
        if time < HOLD then return end
        local share = math.min(1, (time - HOLD) / DRAIN)
        update_span(bar.trail, bar, motion.to, motion.from + (motion.to - motion.from) * read_smooth(share))
        if share >= 1 then
            bar.trail:Hide()
            bar.motion = nil
            bar:SetScript("OnUpdate", nil)
        end
    end
end

local function update_sweep(clip, elapsed)
    clip.time = clip.time + elapsed
    local sweep = math.min(1, clip.time / SHINE)
    local bar = clip:GetParent()
    local width, shine = bar:GetWidth(), bar.shine:GetWidth()
    bar.shine:ClearAllPoints()
    bar.shine:SetPoint("TOPLEFT", bar, "TOPLEFT", -shine + (width + shine) * read_smooth(sweep), 2)
    if sweep >= 1 then
        bar.shine:Hide()
        clip:SetScript("OnUpdate", nil)
    end
end

function library.render_bar_shine(bar)
    if bar.motion then return end
    bar.clip.time = 0
    bar.shine:SetSize(bar:GetHeight() * 4, bar:GetHeight() + 4)
    bar.shine:Show()
    bar.clip:SetScript("OnUpdate", update_sweep)
end

local function update_secret_value(bar, value, most)
    bar.fraction = nil
    bar.preview:Hide()
    bar.trail:Hide()
    for _, shadow in ipairs({ bar, bar.ahead, bar.behind }) do shadow:SetMinMaxValues(0, most) end
    bar.ahead:SetValue(value)
    if not EASED or not bar.started then
        bar.started = true
        bar:SetValue(value)
        bar.behind:SetValue(value)
        return
    end
    bar:SetValue(value, EASED)
    C_Timer.After(HOLD, function() bar.behind:SetValue(value, EASED) end)
end

function library.update_bar_value(bar, value, most)
    local secret = issecretvalue and (issecretvalue(value) or issecretvalue(most))
    bar.ahead:SetShown(secret and true or false)
    bar.behind:SetShown(secret and true or false)
    if secret then
        update_secret_value(bar, value, most)
        return
    end
    if not bar:IsVisible() then
        bar:SetMinMaxValues(0, most)
        bar:SetValue(value)
        bar.fraction = nil
        return
    end
    local to = (most and most > 0) and math.min(1, math.max(0, value / most)) or 0
    local from = bar.fraction
    bar.fraction = to
    bar:SetMinMaxValues(0, 1)
    if not from or math.abs(to - from) < 0.0005 then
        if not bar.motion then bar:SetValue(to) end
        return
    end
    if to > from then
        bar:SetValue(from)
        update_span(bar.preview, bar, from, to)
        bar.trail:Hide()
        bar.shine:SetSize(bar:GetHeight() * 4, bar:GetHeight() + 4)
        bar.motion = { kind = "gain", from = from, to = to, time = 0 }
    else
        bar:SetValue(to)
        bar.preview:Hide()
        update_span(bar.trail, bar, to, from)
        bar.motion = { kind = "loss", from = from, to = to, time = 0 }
    end
    bar:SetScript("OnUpdate", update_motion)
end

function library.update_bar_shape(bar, radius)
    local base = bar:GetParent():GetFrameLevel()
    bar.ground:SetFrameLevel(base + 1)
    bar.ahead:SetFrameLevel(base + 2)
    bar.behind:SetFrameLevel(base + 2)
    bar:SetFrameLevel(base + 3)
    local round = math.min(radius, math.floor((bar:GetHeight() or 0) / 2))
    library.update_surface(bar.line, -1, round + 1, BLACK, BLACK)
    library.update_surface(bar.back, 0, round, TRACK, TRACK, 0.9)
    library.update_notches(bar.notches, bar, round, BLACK)
end

function library.read_bar_colour(kind)
    return (BARS[kind] or BARS.power)[1]
end

function library.read_bar_colours(kind)
    local shade = BARS[kind] or BARS.power
    return shade[1], shade[2]
end

function library.create_bar(parent, kind)
    local bar = library.create_fill(parent, { shine = true })
    bar.ground = CreateFrame("Frame", nil, bar)
    bar.ground:SetAllPoints()
    bar.line = library.create_surface(bar.ground, "BACKGROUND", 0)
    bar.back = library.create_surface(bar.ground, "BACKGROUND", 1)
    for _, name in ipairs({ "behind", "ahead" }) do
        local shadow = library.create_fill(bar)
        shadow:SetAllPoints()
        shadow:Hide()
        bar[name] = shadow
    end
    bar.notches = library.create_notches(bar, "OVERLAY", 6)
    library.update_bar_shape(bar, 0)
    bar.preview = bar:CreateTexture(nil, "BORDER")
    bar.preview:SetColorTexture(1, 1, 1, 1)
    bar.preview:Hide()
    bar.trail = bar:CreateTexture(nil, "BORDER")
    bar.trail:SetColorTexture(1, 1, 1, 1)
    bar.trail:Hide()
    bar.text = library.create_text(bar, "small")
    bar.text:SetPoint("CENTER")
    bar.text:SetDrawLayer("OVERLAY", 7)
    library.update_bar_kind(bar, kind)
    return bar
end

function library.update_bar_shade(bar, colour, left, right)
    local start = CreateColor(colour[1] * left, colour[2] * left, colour[3] * left, 1)
    local finish = CreateColor(colour[1] * right, colour[2] * right, colour[3] * right, 1)
    bar:GetStatusBarTexture():SetGradient("HORIZONTAL", start, finish)
end

function library.update_bar_kind(bar, kind)
    local shade = BARS[kind] or BARS.health
    local top, bottom = shade[1], shade[2]
    bar:GetStatusBarTexture():SetGradient("VERTICAL", CreateColor(bottom[1], bottom[2], bottom[3], 1), CreateColor(top[1], top[2], top[3], 1))
    bar.preview:SetVertexColor(top[1] * 0.42, top[2] * 0.42, top[3] * 0.42, 1)
    bar.trail:SetVertexColor(top[1] * 0.38, top[2] * 0.38, top[3] * 0.38, TRAIL_ALPHA)
    bar.ahead:SetStatusBarColor(top[1] * 0.42, top[2] * 0.42, top[3] * 0.42, 1)
    bar.behind:SetStatusBarColor(top[1] * 0.38, top[2] * 0.38, top[3] * 0.38, TRAIL_ALPHA)
    if bar.ratio then library.update_ratio_kind(bar.ratio, LIGHT[kind] and "figure_dark" or "figure") end
end

function library.read_cast_height()
    return math.max(4, library.read_size(-4)) + library.read_size(-6) + library.read_size(-1) + 2
end

function library.read_cast_room()
    return library.read_size(-4) + library.read_cast_height()
end
