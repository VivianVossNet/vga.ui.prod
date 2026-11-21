-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: The layout vga.ui is delivered with, the owner's own - his profile »Prinzessin« as it stood on 20 November 2026 (K0555), before that his layout of 19 November -: a new character starts with it where no profile was saved or loaded before, and »Alles zurücksetzen …« returns to it. Places are kept from the nearest edges in the owner's screen units, so they fit every screen - the bags too, from the lower right corner; the profile's flag that the chat's font was set is left out, so a new player's chat gets its 12 pixels.

-- {K0449} {K0555}

local library = LibVGA

local DEFAULTS = {
    alignment = "grid",
    arc_left = "resource",
    arc_right = "health",
    arc_shape = "full",
    arc_band = "off",
    arc_shown = "combat",
    bags_place = { "BOTTOMRIGHT", -417, 332 },
    bar_end_left = "dragon",
    bar_end_right = "dragon",
    bars_shown = { [4] = true, [5] = false, [6] = false, [7] = false, [8] = false },
    chat_sized = true,
    cursor = "on",
    dialog = 1,
    face = "geologica",
    faces = "moving",
    friend_name = "below",
    friend_style = "line",
    ground = 0.25,
    grounds = { party = 0, quests = 0.1, units = 0.25 },
    mainbar_form = "two",
    menu_icons = "game",
    places = {
        bar4 = { "RIGHT", "RIGHT", -27, 9 },
        map = { "TOPRIGHT", "TOPRIGHT", -21, -23 },
        quests = { "TOPRIGHT", "TOPRIGHT", -96, -320 },
    },
    plate_level = "number",
    quest_most_height = 0.45,
    quest_most_width = 302,
    quests_outer = true,
    reputation_colour = "hunter",
    size = "large",
    sizes = { bags = "small" },
    target_health = "absolute",
    xp_both = "both",
    xp_colour = "mage",
    xp_labels = "on",
    xp_money = "on",
    xp_pace = "minute",
    xp_system = "on",
}

local function read_copy(source)
    if type(source) ~= "table" then return source end
    local copy = {}
    for key, value in pairs(source) do copy[key] = read_copy(value) end
    return copy
end

function library.read_defaults()
    return read_copy(DEFAULTS)
end
