-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: a quest's progress as LibVGA's toast (K1038), as manual/view/vga-toast-colours.html draws it: each step of an objective - »Krumpeliger Kiefer: 1/4« - told in a gold toast of the kind »quest«, headed with the quest's name; the next step of the same objective counts that same toast on in its place, its time begun again (plan.key), and a full objective carries LibVGA's green tick (K1039). Found at each QUEST_LOG_UPDATE by the objectives' fulfilled count (C_QuestLog.GetQuestObjectives) against the last reading, the first reading only taking note. While the kind »quest« is on, the game's own yellow line of the same progress in the screen's middle is switched off by the game's own way, UIErrorsFrame:SetMessageTypeEnabled, for the quest message types the game knows, and on again when the kind is off (manual/16 R1.7). Whether Forever knows each of those types is not yet seen in the game.

-- {K1039} {K1038} {K1035}

local library = LibVGA
local LINES = { "LE_GAME_ERR_QUEST_ADD_KILL_SII", "LE_GAME_ERR_QUEST_ADD_ITEM_SII", "LE_GAME_ERR_QUEST_ADD_FOUND_SII", "LE_GAME_ERR_QUEST_ADD_PLAYER_KILL_SII", "LE_GAME_ERR_QUEST_OBJECTIVE_COMPLETE_S", "LE_GAME_ERR_QUEST_UNKNOWN_COMPLETE" }
local counts
local lines_on

local function update_game_lines()
    local on = not library.read_notice_on("quest")
    if on == lines_on or not (UIErrorsFrame and UIErrorsFrame.SetMessageTypeEnabled) then return end
    lines_on = on
    for _, name in ipairs(LINES) do
        if _G[name] then UIErrorsFrame:SetMessageTypeEnabled(_G[name], on) end
    end
end

local function render_step(entry, index, objective)
    library.render_toast({ head = entry.title, line = objective.text, picture = library.media .. library.read_sign_picture("offer"), kind = "quest", key = "progress:" .. entry.questID .. ":" .. index, done = objective.finished == true })
end

local function read_steps(entry, now, told)
    for index, objective in ipairs(C_QuestLog.GetQuestObjectives(entry.questID) or {}) do
        local key = entry.questID .. ":" .. index
        now[key] = objective.numFulfilled or 0
        if told and told[key] and now[key] > told[key] then render_step(entry, index, objective) end
    end
end

local function update_progress()
    update_game_lines()
    local now = {}
    for index = 1, C_QuestLog.GetNumQuestLogEntries() or 0 do
        local entry = C_QuestLog.GetInfo(index)
        if entry and not entry.isHeader and entry.questID then read_steps(entry, now, counts) end
    end
    counts = now
end

local events = CreateFrame("Frame")
library.update_events(events, { "QUEST_LOG_UPDATE" })
events:SetScript("OnEvent", function() library.update_safely("quest progress", update_progress) end)
