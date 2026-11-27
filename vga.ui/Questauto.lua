-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: quests without dialogue (K0981), a switch on the comfort page, off unless the player turns it on (LibVGASettings.quest_auto): speaking with a figure, every quest it offers is taken and every quest it can take back is handed in, without the talk; the talk opens only where a choice is the player's - a reward to choose among several, a hand-in that costs gold -, and, once the figure's quests are done, where it still offers something else, its services or its words; a figure with nothing left is closed. Shift held while speaking with it opens the talk as before for that visit, and while the talk is open nothing is done for the player. A quest the game would not let go - a full log, say - is tried once per figure and then left. The game's gossip and quest windows stay veiled as the talk veils them. vga.ui/Gossip.lua and vga.ui/Questdialog.lua ask here first and draw the talk only where it answers no.

-- {K0981}

local _, vga = ...
local library = LibVGA
local tried = {}
local tried_figure

local function check_on()
    if not LibVGASettings.quest_auto then return false end
    if IsShiftKeyDown and IsShiftKeyDown() then return false end
    local talk = vga.read_talk_window and vga.read_talk_window()
    return not (talk and talk:IsShown())
end

local function update_game_veiled()
    library.update_game_veiled(GossipFrame, true)
    library.update_game_veiled(QuestFrame, true)
end

local function check_untried(key)
    local figure = UnitGUID and UnitGUID("npc")
    if figure ~= tried_figure then tried, tried_figure = {}, figure end
    if tried[key] then return false end
    tried[key] = true
    return true
end

local function read_gossip_quest()
    for _, quest in ipairs(C_GossipInfo.GetAvailableQuests and C_GossipInfo.GetAvailableQuests() or {}) do
        if check_untried(quest.questID) then return C_GossipInfo.SelectAvailableQuest, quest.questID end
    end
    for _, quest in ipairs(C_GossipInfo.GetActiveQuests and C_GossipInfo.GetActiveQuests() or {}) do
        if quest.isComplete and check_untried(quest.questID) then return C_GossipInfo.SelectActiveQuest, quest.questID end
    end
    return nil
end

function vga.update_quest_auto_gossip()
    if not check_on() then return false end
    update_game_veiled()
    local choose, id = read_gossip_quest()
    if choose then
        choose(id)
        return true
    end
    if #(C_GossipInfo.GetOptions and C_GossipInfo.GetOptions() or {}) > 0 then return false end
    C_GossipInfo.CloseGossip()
    return true
end

local function read_greeting_quest()
    for index = 1, GetNumAvailableQuests() do
        if check_untried("offered:" .. tostring(GetAvailableTitle(index))) then return SelectAvailableQuest, index end
    end
    for index = 1, GetNumActiveQuests() do
        local title, done = GetActiveTitle(index)
        if done and check_untried("done:" .. tostring(title)) then return SelectActiveQuest, index end
    end
    return nil
end

function vga.update_quest_auto_greeting()
    if not check_on() then return false end
    update_game_veiled()
    local choose, index = read_greeting_quest()
    if choose then choose(index) else CloseQuest() end
    return true
end

local function check_detail()
    if QuestGetAutoAccept and QuestGetAutoAccept() and AcknowledgeAutoAcceptQuest then AcknowledgeAutoAcceptQuest() else AcceptQuest() end
    return true
end

local function check_progress()
    if not IsQuestCompletable() or (GetQuestMoneyToGet() or 0) > 0 then return false end
    CompleteQuest()
    return true
end

local function check_complete()
    local choices = GetNumQuestChoices() or 0
    if choices > 1 then return false end
    GetQuestReward(choices)
    return true
end

local MOMENTS = { detail = check_detail, progress = check_progress, complete = check_complete }

function vga.update_quest_auto(moment)
    if not check_on() then return false end
    update_game_veiled()
    return MOMENTS[moment]()
end
