-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.ui's quests, written into the talk with the figure (vga.ui/Talk.lua, K0840), for the three moments of a quest - taking it, its progress and handing it in (K0834): the quest's words in the figure's bubbles; the quest's card on a group beneath the talk's line, where the answers stand, as wide as they, headed »Neue Quest«, »Questfortschritt« or »Questabgabe« (K0859) - its title with the quest's vaulted sign as the talk's answers carry it, the gold »!« and after the title the green chip »Verfügbar« for a quest offered, the gold chip »Abgeben« after the title of one that can be handed in (K0880), the gold »?« for one to hand in, the silver »?« for one still under way (K0854), its objectives and its rewards each under LibVGA's section, its small heading in capitals (library.create_section, K0873), the rewards as item rows with their picture, quality, kind or count, their tooltip only over picture and name (K0786), where there is a choice each choice an item row, the chosen one marked only by LibVGA's active row (K0830) - chosen only when the quest is handed in; offered, the rewards are only shown, headed »Angebotene Belohnungen« where one is to be chosen (K0913), taking no click, their tooltips kept, each veiled red where the player cannot use it (K0911) -, the experience as a gold chip flush right, the money left of it with a gap (K0836, K0855) -; a quest handed in without items shows no card, only its money and experience, bare, flush right beneath the line (K0843, K0855, K0859); the foot carries Ablehnen and the gold Annehmen, Schließen and Weiter (only once it can be handed in), Zurück and Abschließen, Abschließen off until a reward is chosen where the game offers a choice (K0876); the gold answer stands in the course as the player's bubble before the game answers it. With quests without dialogue on, each moment asks vga.ui/Questauto.lua first and is drawn only where a choice is the player's (K0981).

-- {K0981} {K0913} {K0911} {K0880} {K0876} {K0873} {K0860} {K0859} {K0857} {K0855} {K0854} {K0843} {K0840} {K0836} {K0834} {K0830} {K0786}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local ROW = 40
local TITLE_ROW = 34
local PAD = 10
local GAP = 6
local card

local function read_reward(kind, index)
    local name, icon, count, quality = GetQuestItemInfo(kind, index)
    local link = GetQuestItemLink and GetQuestItemLink(kind, index)
    local sort = link and select(7, C_Item.GetItemInfo(link))
    local line = (count or 1) > 1 and string.format(library.texts.pieces, count) or (type(sort) == "string" and sort or nil)
    return { kind = kind, index = index, name = name or "", icon = icon, count = count, quality = quality, sub = line, link = link }
end

local function read_rewards(kind, count)
    local rewards = {}
    for index = 1, count do rewards[index] = read_reward(kind, index) end
    return rewards
end

local function update_choice_marks()
    for index, row in ipairs(card.choices) do library.update_active_mark(row.mark, row:IsShown() and index == card.chosen) end
end

local function render_choice(row)
    if not row.reward or row.reward.kind ~= "choice" or card.mode ~= "complete" then return end
    card.chosen = row.reward.index
    update_choice_marks()
    local talk = vga.read_talk_window()
    if talk.foot_plan then talk.foot_plan.ready = true end
    vga.update_talk()
end

local function update_reward_tip(row, tip)
    local reward = row.reward
    if not reward then return false end
    tip:SetQuestItem(reward.kind, reward.index)
    if tip:NumLines() == 0 and reward.link then tip:SetHyperlink(reward.link) end
    return tip:NumLines() > 0
end

local function read_pool_row(pool, index)
    pool[index] = pool[index] or library.create_item_row(card.rewards, { chosen = true, cell = true, on_click = render_choice, tip = update_reward_tip })
    if not pool[index].mark then pool[index].mark = library.create_active_mark(pool[index], pool[index].name) end
    return pool[index]
end

local function write_rewards(rows, pool, rewards, width)
    for index, reward in ipairs(rewards) do
        local row = read_pool_row(pool, index)
        row.reward = reward
        row:SetSize(width, library.read_draft_size(ROW))
        library.update_item_row(row, { icon = reward.icon, id = reward.link, name = reward.name, quality = reward.quality, count = reward.count, sub = reward.sub, choosable = card.mode == "complete" }, library.read_size(-2), width)
        library.update_item_row_chosen(row, false)
        row:Show()
        rows[#rows + 1] = { row }
    end
    for index = #rewards + 1, #pool do pool[index]:Hide() end
end

local function read_sign()
    if card.mode == "detail" then return library.read_sign_picture("offer") end
    if card.mode == "progress" and not (IsQuestCompletable and IsQuestCompletable()) then return library.read_sign_picture("question", "silver") end
    return library.read_sign_picture("question")
end

local function read_state_tag()
    local texts = library.texts
    if card.mode == "detail" then return { kind = "green", word = texts.quest_available } end
    if card.mode == "complete" or (IsQuestCompletable and IsQuestCompletable()) then return { kind = "gold", word = texts.quest_hand_in } end
    return nil
end

local function update_heading(width)
    local new = read_state_tag()
    card.heading:SetSize(width, library.read_draft_size(TITLE_ROW))
    library.update_item_row(card.heading, { icon = library.media .. read_sign(), name = GetTitleText and GetTitleText() or "", quality = 1, tag = new }, 0, width)
end

local function update_objectives(rows, width)
    local words = card.mode == "detail" and GetObjectiveText and GetObjectiveText() or ""
    card.objectives:SetShown(words ~= "")
    if words == "" then return end
    card.goals:SetFontObject(library.read_font("small"))
    card.goals:SetWidth(width)
    card.goals:SetText(words)
    library.update_section(card.objectives, library.texts.quest_objectives, { { card.goals } }, width)
    rows[#rows + 1] = { card.objectives }
end

local function update_rewards(rows, width, choices, fixed)
    local laid = {}
    write_rewards(laid, card.choices, choices, width)
    write_rewards(laid, card.fixed, fixed, width)
    card.rewards:SetShown(#laid > 0)
    if #laid == 0 then return end
    local texts = library.texts
    library.update_section(card.rewards, #choices > 1 and (card.mode == "detail" and texts.quest_offered or texts.quest_choose) or texts.quest_rewards, laid, width)
    rows[#rows + 1] = { card.rewards }
end

local function update_gains(rows, width, rewarding)
    local copper = rewarding and GetRewardMoney and GetRewardMoney() or 0
    local xp = rewarding and GetRewardXP and GetRewardXP() or 0
    card.money:SetShown(copper > 0)
    card.xp:SetShown(xp > 0)
    card.gains:SetShown(copper + xp > 0)
    library.update_money(card.money, copper)
    library.update_chip(card.xp, "gold", nil, string.format(library.texts.xp_points, xp))
    if copper + xp == 0 then return end
    library.update_grid(card.gains_grid, { { card.money, card.xp } }, width)
    card.gains:SetSize(width, math.max(card.xp:GetHeight(), card.money:GetHeight()))
    rows[#rows + 1] = { card.gains }
end

local function read_gains_height(width)
    for _, part in ipairs({ card.heading, card.objectives, card.rewards }) do part:Hide() end
    write_rewards({}, card.choices, {}, width)
    write_rewards({}, card.fixed, {}, width)
    local rows = {}
    update_gains(rows, width, true)
    local _, height = library.update_grid(card.bare_grid, rows, width)
    card:SetSize(width, height)
    library.update_group_bare(card, true)
    return height
end

local function read_card_height(_, width)
    local rewarding = card.mode ~= "progress"
    local choices = rewarding and read_rewards("choice", GetNumQuestChoices and GetNumQuestChoices() or 0) or {}
    local fixed = rewarding and read_rewards("reward", GetNumQuestRewards and GetNumQuestRewards() or 0) or {}
    if card.mode == "complete" and #choices + #fixed == 0 then return read_gains_height(width) end
    library.update_group_bare(card, false)
    card.heading:Show()
    local inner = width - 2 * library.read_draft_size(PAD)
    update_heading(inner)
    local rows = { { card.heading } }
    update_objectives(rows, inner)
    update_rewards(rows, inner, choices, fixed)
    update_gains(rows, inner, rewarding)
    local _, height = library.update_grid(card.grid, rows, width)
    card:SetSize(width, height)
    library.update_group(card)
    update_choice_marks()
    return height
end

local function create_card(parent)
    card = library.create_group(parent)
    card.choices, card.fixed, card.chosen = {}, {}, 0
    card.heading = library.create_item_row(card, {})
    card.objectives = library.create_section(card, { gap = GAP })
    card.goals = library.create_text(card.objectives, "small", colours.label)
    card.goals:SetJustifyH("LEFT")
    card.goals:SetWordWrap(true)
    card.rewards = library.create_section(card, { gap = GAP })
    card.gains = CreateFrame("Frame", nil, card)
    card.xp = library.create_chip(card.gains)
    card.money = library.create_money(card.gains, colours.ink)
    card.gains_grid = library.create_grid(card.gains, { columns = { "rest", "auto" }, gap = 10, row = 0, x = { "right", "left" } })
    card.grid = library.create_grid(card, { columns = { "rest" }, padding = { PAD, PAD, PAD, PAD }, row = 0, row_gap = GAP, y = "top" })
    card.bare_grid = library.create_grid(card, { columns = { "rest" }, row = 0, y = "top" })
end

local function read_words(mode)
    if mode == "progress" then return GetProgressText and GetProgressText() or "" end
    if mode == "complete" then return GetRewardText and GetRewardText() or "" end
    return GetQuestText and GetQuestText() or ""
end

local function render_accepted()
    AcceptQuest()
end

local function render_declined()
    if DeclineQuest then DeclineQuest() end
end

local function render_continued()
    CompleteQuest()
end

local function render_rewarded()
    if (GetNumQuestChoices and GetNumQuestChoices() or 0) > 1 and card.chosen == 0 then return end
    GetQuestReward(card.chosen > 0 and card.chosen or 1)
end

local function render_back()
    vga.read_talk_window():Hide()
end

local function read_foot(mode)
    local texts = library.texts
    if mode == "detail" then return { plain = texts.quest_decline, on_plain = render_declined, gold = texts.quest_accept, on_gold = render_accepted } end
    if mode == "progress" then return { plain = texts.close, on_plain = render_back, gold = texts.quest_continue, on_gold = render_continued, ready = (IsQuestCompletable and IsQuestCompletable()) or false } end
    return { plain = texts.cancel, on_plain = render_back, gold = texts.quest_complete, on_gold = render_rewarded, ready = (GetNumQuestChoices and GetNumQuestChoices() or 0) <= 1 }
end

local HEADINGS = { detail = "talk_quest_new", progress = "talk_quest_progress", complete = "talk_quest_complete" }

local function render_mode(mode)
    if not card then create_card(vga.read_talk_window().options) end
    card.mode, card.chosen = mode, 0
    local talk = vga.render_talk_opened({ foot = read_foot(mode), card = { frame = card, lay = read_card_height, heading = library.texts[HEADINGS[mode]] } })
    talk.choices, talk.xp = card.choices, card.xp
    vga.write_talk_figure(read_words(mode))
    vga.update_talk()
end

local function render_detail()
    if vga.update_quest_auto("detail") then return end
    render_mode("detail")
end

local function render_progress()
    if vga.update_quest_auto("progress") then return end
    render_mode("progress")
end

local function render_complete()
    if vga.update_quest_auto("complete") then return end
    render_mode("complete")
end

local HEARD = { QUEST_DETAIL = render_detail, QUEST_PROGRESS = render_progress, QUEST_COMPLETE = render_complete, QUEST_FINISHED = vga.update_talk_ending }

local events = CreateFrame("Frame")
library.update_events(events, { "QUEST_DETAIL", "QUEST_PROGRESS", "QUEST_COMPLETE", "QUEST_FINISHED" })
events:SetScript("OnEvent", function(_, event) library.update_safely("quest " .. event, HEARD[event]) end)
