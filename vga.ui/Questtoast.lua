-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: the quest toasts (K1018, after K0998): every change of a quest the player should not miss is told by LibVGA's toast, headed »Quest«, with the quest's title - taken, »„…“ angenommen« with the quest's vaulted gold »!«, once the game confirms it (QUEST_ACCEPTED); handed in, »„…“ abgegeben« with the gold »?« (QUEST_TURNED_IN); and ready, »„…“ ist bereit zur Abgabe« with the gold »?«, once all of a quest's objectives are done out in the world - told a second later and dropped where the quest is handed in meanwhile, nor told again while the game still lists it as complete just after its hand-in, until it is taken anew, never for a quest without objectives, which the game calls complete only in the talk (K1029) - - found at each QUEST_LOG_UPDATE by C_QuestLog.IsComplete against what was complete before, the first reading after login only taking note, so a quest is told ready once. In the talk, by the quests without dialogue or anywhere else alike. They are of the kind »quest«: gold rimmed (K1034), silenced by its switch on the tab »Hinweise« (K1035); »ist bereit zur Abgabe« and »abgegeben« carry the green tick, »angenommen« not (K1039). Each step of an objective is counted by vga.ui/Questprogress.lua (K1038).

-- {K1039} {K1035} {K1034} {K1029} {K1018} {K0998}

local _, vga = ...
local library = LibVGA
local complete
local handed = {}
local WAIT = 1

local function read_title(id)
    return C_QuestLog and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(id) or ""
end

local function render_toast(words, id, sign, colour, done)
    library.render_toast({ head = library.texts.quest_title, line = string.format(words, read_title(id)), picture = library.media .. library.read_sign_picture(sign, colour), kind = "quest", done = done })
end

local function render_taken(first, second)
    handed[second or first] = nil
    render_toast(library.texts.quest_toast_taken, second or first, "offer")
end

local function render_done(id)
    handed[id] = true
    render_toast(library.texts.quest_toast_done, id, "question", "gold", true)
end

local function read_complete()
    local found = {}
    for index = 1, C_QuestLog.GetNumQuestLogEntries() or 0 do
        local entry = C_QuestLog.GetInfo(index)
        if entry and not entry.isHeader and entry.questID and C_QuestLog.IsComplete(entry.questID) then found[entry.questID] = true end
    end
    return found
end

local function check_objectives(id)
    local objectives = C_QuestLog.GetQuestObjectives and C_QuestLog.GetQuestObjectives(id)
    return objectives ~= nil and #objectives > 0
end

local function render_ready(id)
    if handed[id] then return end
    render_toast(library.texts.quest_toast_ready, id, "question", "gold", true)
end

local function update_ready()
    local now = read_complete()
    if complete then
        for id in pairs(now) do
            if not complete[id] and not handed[id] and check_objectives(id) then
                C_Timer.After(WAIT, function() library.update_safely("quest ready toast", render_ready, id) end)
            end
        end
    end
    complete = now
end

local HEARD = { QUEST_ACCEPTED = render_taken, QUEST_TURNED_IN = render_done, QUEST_LOG_UPDATE = update_ready }

local events = CreateFrame("Frame")
library.update_events(events, { "QUEST_ACCEPTED", "QUEST_TURNED_IN", "QUEST_LOG_UPDATE" })
events:SetScript("OnEvent", function(_, event, first, second) library.update_safely("quest toast " .. event, HEARD[event], first, second) end)
