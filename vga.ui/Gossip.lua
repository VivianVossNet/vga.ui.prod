-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.ui's gossip, written into the talk with the figure (vga.ui/Talk.lua, K0840): the figure's words in its bubbles; its offers as the answers beneath - the quests first, to take with the vaulted gold »!«, to hand in with a vaulted gold »?«, still under way with the same »?« in silver, as the game shows it grey (K0852); every sign LibVGA's (library.read_sign_picture, K0857); then the services (K0833), each with its vaulted sign (K0853) - the merchant a stack of coins, the trainer an open book, the flight master a gryphon, the inn a hearthstone with its blue swirl, the bank a temple, in gold, since gold is what can be used now (K0854) -, every sign made by tools/questmark/talksigns.py from the owner's pictures by Grok, any other answer a speech bubble (K0855); a merchant who repairs with the vaulted gold anvil after its words, »Reparatur« its tooltip (K0855) - known from the merchant's own window at an earlier visit, else from Questie's repairers where it is installed (K0848) -; a chosen answer stands in the course as the player's gold bubble before the game answers it, a quest as »Sprechen wir über „…“.« in the player's language (K0877); every answer reaches the game after the talk's reading time (vga.ui/Talk.lua, K0847, K0841); »Auf Wiedersehen« in the foot. The figure's portrait is drawn again whenever the game has it ready (K0839). A figure that offers only quests greets through the game's quest window instead of its gossip - an apothecary, say -: its greeting is heard as well and written into the same talk, its words in the figure's bubble, its quests as the answers with the same signs, the offered first (QUEST_GREETING, K0879). With quests without dialogue on, both ask vga.ui/Questauto.lua first and draw the talk only where it leaves a choice to the player (K0981).

-- {K0981} {K0879} {K0877} {K0857} {K0855} {K0854} {K0853} {K0852} {K0848} {K0847} {K0841} {K0840} {K0839} {K0833}

local _, vga = ...
local library = LibVGA
local SERVICE_SIGNS = { [132060] = "coins", [132058] = "book", [132057] = "gryphon", [132052] = "hearthstone", [132050] = "temple" }

local function render_available(answer)
    C_GossipInfo.SelectAvailableQuest(answer.id)
end

local function render_active(answer)
    C_GossipInfo.SelectActiveQuest(answer.id)
end

local function render_service(answer)
    C_GossipInfo.SelectOption(answer.id)
end

local VENDOR_ICON = 132060

local function check_questie_repairer(id)
    if not (QuestieLoader and Questie and Questie.API and Questie.API.isReady) then return false end
    local folk = QuestieLoader:ImportModule("Townsfolk")
    for _, known in pairs(folk and folk.townsfolk and folk.townsfolk.Repair or {}) do
        if tostring(known) == id then return true end
    end
    return false
end

local function check_repairer()
    local id = library.read_figure_id()
    if not id then return false end
    local kept = LibVGAAccount.repairers and LibVGAAccount.repairers[id]
    if kept ~= nil then return kept end
    local ok, known = pcall(check_questie_repairer, id)
    return ok and known
end

local function read_repair_tag(icon)
    if icon ~= VENDOR_ICON or not check_repairer() then return nil end
    return { sign = "anvil", word = library.texts.map_repair }
end

local function read_said(title)
    return string.format(library.texts.talk_quest_said, title or "")
end

local function read_answers()
    local answers = {}
    for _, quest in ipairs(C_GossipInfo.GetAvailableQuests and C_GossipInfo.GetAvailableQuests() or {}) do
        answers[#answers + 1] = { id = quest.questID, name = quest.title, said = read_said(quest.title), icon = library.read_sign_picture("offer"), choose = render_available }
    end
    for _, quest in ipairs(C_GossipInfo.GetActiveQuests and C_GossipInfo.GetActiveQuests() or {}) do
        answers[#answers + 1] = { id = quest.questID, name = quest.title, said = read_said(quest.title), icon = library.read_sign_picture("question", quest.isComplete and "gold" or "silver"), choose = render_active }
    end
    for _, option in ipairs(C_GossipInfo.GetOptions and C_GossipInfo.GetOptions() or {}) do
        answers[#answers + 1] = { id = option.gossipOptionID, name = option.name, icon = library.read_sign_picture(SERVICE_SIGNS[option.icon] or "chat"), tag = read_repair_tag(option.icon), choose = render_service }
    end
    return answers
end

local function render_greeting_available(answer)
    SelectAvailableQuest(answer.id)
end

local function render_greeting_active(answer)
    SelectActiveQuest(answer.id)
end

local function read_greeting_answers()
    local answers = {}
    for index = 1, GetNumAvailableQuests and GetNumAvailableQuests() or 0 do
        local title = GetAvailableTitle(index)
        answers[#answers + 1] = { id = index, name = title, said = read_said(title), icon = library.read_sign_picture("offer"), choose = render_greeting_available }
    end
    for index = 1, GetNumActiveQuests and GetNumActiveQuests() or 0 do
        local title, done = GetActiveTitle(index)
        answers[#answers + 1] = { id = index, name = title, said = read_said(title), icon = library.read_sign_picture("question", done and "gold" or "silver"), choose = render_greeting_active }
    end
    return answers
end

local function update_greeting()
    if vga.update_quest_auto_greeting() then return end
    vga.render_talk_opened({ answers = read_greeting_answers() })
    vga.write_talk_figure(GetGreetingText and GetGreetingText() or "")
    vga.update_talk()
end

local function update_opened()
    if vga.update_quest_auto_gossip() then return end
    vga.render_talk_opened({ answers = read_answers() })
    vga.write_talk_figure(C_GossipInfo.GetText and C_GossipInfo.GetText() or "")
    vga.update_talk()
end

local HEARD = { GOSSIP_SHOW = update_opened, GOSSIP_CLOSED = vga.update_talk_ending, QUEST_GREETING = update_greeting }

local events = CreateFrame("Frame")
library.update_events(events, { "GOSSIP_SHOW", "GOSSIP_CLOSED", "QUEST_GREETING" })
events:SetScript("OnEvent", function(_, event) library.update_safely("gossip " .. event, HEARD[event]) end)
