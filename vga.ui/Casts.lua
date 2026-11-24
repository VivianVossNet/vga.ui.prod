-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.ui's cast bar under the player frame and, mirrored, under the target frame, as manual/view/vga-cast.html draws way C: a thin gold bar the frame's width, the spell's name small beneath it - none where the game gives an empty name or a placeholder such as »Opening - No Text« -, fixed to the frame's portrait side - left under the player, right under the mirrored target - and its time quiet at the other; its room kept always, seen only while a spell is cast; Blizzard's own cast bar hidden.

-- {K0795} {K0789} {K0267} {K0331} {K0334} {K0527}

local _, vga = ...
local library = LibVGA
local NO_TEXT = "no text"
local colours = library.colours
local casts = {}


local function create_cast(unit)
    local cast = CreateFrame("Frame", nil, UIParent)
    cast.unit = unit
    cast.bar = library.create_bar(cast, "gold")
    cast.name = library.create_text(cast, "caption")
    cast.name:SetWordWrap(false)
    cast.time = library.create_text(cast, "figures_small", colours.quiet)
    cast:Hide()
    casts[unit] = cast
    return cast
end

local function update_cast_layout(cast)
    local frame = _G["VGAUnitFrame_" .. cast.unit]
    if not frame then return end
    cast.anchored = true
    local gap, bar = library.read_size(-4), math.max(4, library.read_size(-4))
    cast:ClearAllPoints()
    cast:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -gap)
    cast:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, -gap)
    cast:SetHeight(library.read_cast_height())
    cast.bar:ClearAllPoints()
    cast.bar:SetPoint("TOPLEFT")
    cast.bar:SetPoint("TOPRIGHT")
    cast.bar:SetHeight(bar)
    local near, far, sign = "LEFT", "RIGHT", 1
    if cast.unit == "target" then near, far, sign = "RIGHT", "LEFT", -1 end
    cast.name:SetFontObject(library.read_frame_font("caption"))
    cast.name:SetJustifyH(near)
    cast.name:ClearAllPoints()
    cast.name:SetPoint("TOP" .. near, cast.bar, "BOTTOM" .. near, sign * 2, -library.read_size(-6))
    cast.name:SetPoint(far, cast.time, near, -sign * gap, 0)
    cast.time:SetFontObject(library.read_frame_font("figures_small"))
    cast.time:ClearAllPoints()
    cast.time:SetPoint("TOP" .. far, cast.bar, "BOTTOM" .. far, -sign * 2, -library.read_size(-6))
    library.update_bar_shape(cast.bar, library.read_size(-6))
end

local function render_seconds(value)
    return (string.format("%.1f", value):gsub("%.", DECIMAL_SEPERATOR or "."))
end

local function update_cast_time(cast)
    local now = GetTime()
    local done = cast.channel and (cast.finish - now) or (now - cast.start)
    local total = cast.finish - cast.start
    cast.bar:SetValue(math.max(0, math.min(done, total)))
    cast.time:SetText(render_seconds(math.max(0, done)) .. " / " .. render_seconds(total) .. " " .. library.texts.seconds)
end

local function update_cast_timer(cast)
    local duration = (UnitCastingDuration and UnitCastingDuration(cast.unit)) or (UnitChannelDuration and UnitChannelDuration(cast.unit))
    cast.bar:SetScript("OnUpdate", nil)
    cast.time:SetText("")
    if duration and cast.bar.SetTimerDuration then
        local direction = Enum.StatusBarTimerDirection
        cast.bar:SetTimerDuration(duration, 0, cast.channel and direction and direction.RemainingTime or direction and direction.ElapsedTime or 0)
    end
end

function vga.read_cast_label(name)
    if issecretvalue and issecretvalue(name) then return name end
    if type(name) ~= "string" or name:match("^%s*$") or name:lower():find(NO_TEXT, 1, true) then return "" end
    return name
end

local function update_cast(cast)
    local unit = cast.unit
    if not cast.anchored then update_cast_layout(cast) end
    local name, _, _, start, finish = UnitCastingInfo(unit)
    cast.channel = false
    if not name then
        name, _, _, start, finish = UnitChannelInfo(unit)
        cast.channel = name ~= nil
    end
    cast:SetShown(name ~= nil)
    if not name then
        cast.bar:SetScript("OnUpdate", nil)
        return
    end
    cast.name:SetText(vga.read_cast_label(name))
    if issecretvalue and (issecretvalue(start) or issecretvalue(finish)) then
        update_cast_timer(cast)
        return
    end
    cast.start, cast.finish = start / 1000, finish / 1000
    cast.bar:SetMinMaxValues(0, cast.finish - cast.start)
    cast.bar:SetScript("OnUpdate", function() update_cast_time(cast) end)
    update_cast_time(cast)
end

local function update_casts()
    for _, cast in pairs(casts) do
        update_cast_layout(cast)
        update_cast(cast)
    end
end

local function delete_blizzard_cast()
    for _, blizzard in ipairs({ PlayerCastingBarFrame, CastingBarFrame }) do
        if blizzard then
            blizzard:UnregisterAllEvents()
            blizzard:Hide()
        end
    end
end

local CASTS = {
    "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED",
    "UNIT_SPELLCAST_DELAYED", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_UPDATE", "UNIT_SPELLCAST_CHANNEL_STOP",
}

local function update_event(event, unit)
    if event == "PLAYER_LOGIN" then
        create_cast("player")
        create_cast("target")
        delete_blizzard_cast()
        library.create_element("casts", { update = update_casts })
    elseif event == "PLAYER_TARGET_CHANGED" then
        update_cast(casts.target)
    elseif casts[unit] then
        update_cast(casts[unit])
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
for _, name in ipairs(CASTS) do
    pcall(events.RegisterEvent, events, name)
end
events:SetScript("OnEvent", function(_, event, unit)
    library.update_safely("casts " .. event, update_event, event, unit)
end)
