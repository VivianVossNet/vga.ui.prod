-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's talk, a meta-object (K0860) as the accepted draft draws the talk with a figure (manual/view/vga-npc-chat.html, K0840): LibVGA's dialog of a fixed size, its two areas objects of their own - the chat above (library.create_conversation), a hairline across the whole dialog between them (K0861), the options beneath it (library.create_options: the answers or a card, K0859) - and the dialog's foot with a plain and a gold button. The chat fills what the options and the foot leave, and the options come only once the chat has said everything (K0844). Its owner feeds it a plan at each laying - { options = { heading, answers | card }, foot = { plain, gold, ready, note } } -; what is said and chosen is its owner's. One task: lay the talk.

-- {K0861} {K0860} {K0859} {K0844} {K0840}

local library = LibVGA
local GAP = 6
local SIDE = 14

function library.create_talk(name, plan)
    local talk = library.create_dialog(name, "", { buttons = plan.buttons })
    talk.size = { plan.width, plan.height }
    talk.conversation = library.create_conversation(talk.body)
    talk.options = library.create_options(talk.body, plan.on_choose)
    talk.line = library.create_hairline(talk.body)
    talk.grid = library.create_grid(talk.body, { columns = { "rest" }, padding = { 0, SIDE, SIDE, 0 }, row = 0, row_gap = GAP, y = "top" })
    return talk
end

local function update_button(button, words)
    button.words = words
    button.text:SetText(words)
end

local function update_foot(talk, foot)
    local plain, gold = talk.foot.buttons[1], talk.foot.buttons[2]
    update_button(plain, foot.plain)
    gold:SetShown(foot.gold ~= nil)
    if foot.gold then
        update_button(gold, foot.gold)
        library.update_button_enabled(gold, foot.ready ~= false)
    end
    library.update_dialog_foot(talk, foot.note or "")
end

local function update_line(talk, shown, width)
    local line = talk.line
    line:SetShown(shown)
    if not shown then return end
    line:ClearAllPoints()
    line:SetPoint("BOTTOMLEFT", talk.options, "TOPLEFT", 0, library.read_whole_pixels(library.read_draft_size(GAP) / 2, talk))
    line:SetSize(width, 1)
end

function library.update_talk(talk, plan)
    library.update_dialog(talk)
    update_foot(talk, plan.foot)
    library.update_dialog(talk)
    local width, height = library.read_draft_size(talk.size[1]), library.read_draft_size(talk.size[2])
    local outer = width - 2 * library.read_size(-4)
    local full = height - library.read_dialog_frame_height(talk)
    library.update_conversation(talk.conversation, outer, full)
    local done = library.read_conversation_done(talk.conversation)
    local options = library.update_options(talk.options, done and plan.options or nil, outer)
    local rows = { { talk.conversation.scroll } }
    update_line(talk, options > 0, outer)
    if options > 0 then
        library.update_conversation(talk.conversation, outer, full - options - library.read_draft_size(GAP))
        rows[2] = { talk.options }
    end
    library.update_grid(talk.grid, rows, outer)
    talk:SetSize(width, height)
end
