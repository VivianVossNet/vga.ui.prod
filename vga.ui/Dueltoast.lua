-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: the duel toasts (K1036), LibVGA's toast of the kind »duel«, copper rimmed (K1034), silenced by its switch on the tab »Hinweise« (K1035), as manual/view/vga-toast-colours.html words them: a challenge, »<Name> fordert dich zum Duell« (DUEL_REQUESTED, its name the game's); the outcome, read from the game's own sentence of it in the system chat - won by a blow (DUEL_WINNER_KNOCKOUT) or by the other's flight (DUEL_WINNER_RETREAT), read in the player's language by vga.read_game_sentence -, »Du hast das Duell gewonnen« or »<Name> hat das Duell gewonnen«; only a duel the player fought, a duel won with LibVGA's green tick (K1042), never two others' nearby, whose sentence the game shows too. The picture is the game's crossed blades, not yet seen in Forever.

-- {K1042} {K1036} {K1035} {K1034}

local _, vga = ...
local library = LibVGA
local PICTURE = "Interface\\Icons\\Ability_DualWield"
local OUTCOMES = { "DUEL_WINNER_KNOCKOUT", "DUEL_WINNER_RETREAT" }

local function render(line, done)
    library.render_toast({ head = library.texts.toast_duel, line = line, picture = PICTURE, kind = "duel", done = done })
end

local function render_asked(name)
    render(string.format(library.texts.duel_asked, name or ""))
end

local function read_outcome(message)
    for _, key in ipairs(OUTCOMES) do
        local words = vga.read_game_sentence(_G[key], message)
        if words then return words[1], words[2] end
    end
end

local function render_outcome(message)
    local winner, loser = read_outcome(message)
    local me = UnitName("player")
    if not winner or (winner ~= me and loser ~= me) then return end
    if winner == me then return render(library.texts.duel_won_self, true) end
    render(string.format(library.texts.duel_won, winner))
end

local HEARD = { DUEL_REQUESTED = render_asked, CHAT_MSG_SYSTEM = render_outcome }

local events = CreateFrame("Frame")
library.update_events(events, { "DUEL_REQUESTED", "CHAT_MSG_SYSTEM" })
events:SetScript("OnEvent", function(_, event, first) library.update_safely("duel toast " .. event, HEARD[event], first) end)
