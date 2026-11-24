-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.ui's talk with a figure, as the accepted draft draws it (manual/view/vga-npc-chat.html, K0840), filling LibVGA's talk, a meta-object (library.create_talk, K0860), with what the game says and offers: one dialog of a fixed size for the gossip and the quests alike, headed with the figure's name; LibVGA's conversation fills it from the top - the figure's words in parchment bubbles at the left, the player's answers in gold at the right, the green tick in its green bubble when a quest was taken or handed in -; beneath it and its line, where the player acts, while the figure offers a choice the answers as LibVGA's item rows on a group with the accepted flat icons, headed »Antworten«, and while a quest is open its card instead, as wide, headed by the quest's moment as its owner names it - »Neue Quest«, »Questfortschritt«, »Questabgabe« (K0859); the foot carries »Auf Wiedersehen« in the gossip and the quest's own pair - Ablehnen and Annehmen, Schließen and Weiter, Zurück and Abschließen. vga.ui/Gossip.lua and vga.ui/Questdialog.lua fill it. The course belongs to one visit: it is kept while the game passes from the gossip to a quest and back, and cleared when a talk begins anew. The game's gossip and quest windows are veiled, never hidden; closing ours ends the talk and the quest (K0833, K0834). The course is paced unless the player turns immersion off: the figure types each bubble as long as it takes to read, the typing dots meanwhile, and the answers come only once it has said everything (K0844, on by default since K0889). Every answer - a chosen one, the gold one, the plain one of the foot - stands at once in the course as the player's bubble, and reaches the game only after the reading time the player set, one second unless changed (K0889, before two), 0 to 3 in half seconds, so it can be read; meanwhile the answers are gone, the gold button is off and a second click is not heard; a talk ended or moved on in the meantime does nothing more (K0847, before for the services alone, K0841); with a reading time of 0 the answer reaches the game first and is drawn after, and the drawing is guarded, so nothing it meets can keep a quest from being taken (K0845).

-- {K0889} {K0860} {K0859} {K0847} {K0845} {K0844} {K0840} {K0839} {K0838} {K0834} {K0833}

local _, vga = ...
local library = LibVGA
local WIDTH, HEIGHT = 460, 600
local ENDING = 0.2
local window

local function render_read(action, value, visit)
    if not (window:IsShown() and window.visit == visit and window.reading) then return end
    window.reading = nil
    action(value)
end

local function render_hidden()
    window:Hide()
end

local function render_answered(words, action, value)
    if window.reading then return end
    local wait = LibVGASettings.talk_delay or library.talk_delay_default
    if wait <= 0 then action(value) end
    library.write_conversation_words(window.conversation, "right", words)
    if wait > 0 then
        window.reading, window.answers_offered = true, nil
        local visit = window.visit
        C_Timer.After(wait, function() library.update_safely("talk answered", render_read, action, value, visit) end)
    end
    library.update_safely("talk answer drawn", vga.update_talk)
end

local function render_answer(answer)
    render_answered(answer.said or answer.name, answer.choose, answer)
end

local function read_options()
    if window.card_plan then return { heading = window.card_plan.heading, card = window.card_plan } end
    local answers = window.answers_offered or {}
    if #answers == 0 then return nil end
    return { heading = library.texts.talk_answers, answers = answers }
end

local function read_foot()
    local plan = window.foot_plan or { plain = library.texts.goodbye }
    return { plain = plan.plain, gold = plan.gold, ready = plan.ready ~= false and not window.reading, note = plan.note }
end

function vga.update_talk()
    if not (window and window:IsShown()) then return end
    library.update_talk(window, { options = read_options(), foot = read_foot() })
end

local function render_closed()
    library.render_game_ended(GossipFrame, C_GossipInfo and C_GossipInfo.CloseGossip)
    library.render_game_ended(QuestFrame, CloseQuest)
end

local function render_plain()
    local plan = window.foot_plan or { plain = library.texts.goodbye }
    render_answered(plan.plain, plan.on_plain or render_hidden)
end

local function render_gold()
    local plan = window.foot_plan
    if not (plan and plan.on_gold) then return end
    render_answered(plan.gold, plan.on_gold)
end

local function create_window()
    local buttons = { { library.texts.goodbye, "plain", render_plain }, { library.texts.quest_accept, "gold", render_gold } }
    window = library.create_talk("VGATalkWindow", { width = WIDTH, height = HEIGHT, buttons = buttons, on_choose = render_answer })
    window.visit = 0
    window.conversation.on_change = vga.update_talk
    library.update_dialog_closing(window, function() library.update_safely("talk closed", render_closed) end)
end

function vga.read_talk_window()
    if not window then create_window() end
    return window
end

function vga.render_talk_opened(plan)
    local talk = vga.read_talk_window()
    library.update_game_veiled(GossipFrame, true)
    library.update_game_veiled(QuestFrame, true)
    if not talk:IsShown() then library.update_conversation_cleared(talk.conversation) end
    library.update_conversation_paced(talk.conversation, LibVGASettings.talk_immersion ~= false)
    talk.visit, talk.reading = talk.visit + 1, nil
    talk.title:SetText(library.read_figure_name())
    talk.answers_offered, talk.foot_plan, talk.card_plan = plan.answers, plan.foot, plan.card
    library.update_dialog_placed(talk)
    talk:Show()
    return talk
end

function vga.write_talk_figure(words)
    local last = window.conversation.entries[#window.conversation.entries]
    if last and last.side == "left" and last.words == words then return end
    library.write_conversation_words(window.conversation, "left", words)
end

local function update_ended(visit)
    if window and window.visit == visit and window:IsShown() then window:Hide() end
end

function vga.update_talk_ending()
    if not (window and window:IsShown()) then return end
    local visit = window.visit
    C_Timer.After(ENDING, function() library.update_safely("talk ended", update_ended, visit) end)
end

local function render_ticked(words)
    if not (window and window:IsShown()) then return end
    library.write_conversation_tick(window.conversation, words)
    vga.update_talk()
end

local function read_quest_title(id)
    return C_QuestLog and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(id) or ""
end

local function render_taken(first, second)
    render_ticked(library.texts.quest_taken .. " · " .. read_quest_title(second or first))
end

local function render_done(id)
    render_ticked(library.texts.quest_done .. " · " .. read_quest_title(id))
end

local function update_faces()
    if window and window:IsShown() then library.update_conversation_faces(window.conversation) end
end

local HEARD = { QUEST_ACCEPTED = render_taken, QUEST_TURNED_IN = render_done, UNIT_PORTRAIT_UPDATE = update_faces, PORTRAITS_UPDATED = update_faces }

local events = CreateFrame("Frame")
library.update_events(events, { "QUEST_ACCEPTED", "QUEST_TURNED_IN", "UNIT_PORTRAIT_UPDATE", "PORTRAITS_UPDATED" })
events:SetScript("OnEvent", function(_, event, first, second) library.update_safely("talk " .. event, HEARD[event], first, second) end)
