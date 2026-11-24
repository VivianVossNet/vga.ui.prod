-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's options, the area beneath the talk's line where the player acts, as the accepted draft draws .answers (manual/view/vga-npc-chat.html, K0840, K0859): LibVGA's section (library.create_section, K0873) - a small heading in capitals, and beneath it either the answers - LibVGA's item rows on a group, each with its sign, a long one wrapping onto at most two lines, its row growing with it (K0866, K0867), a click choosing it - or a card its owner gives, fourteen draft pixels in from either side of the area, which spans its owner's whole width (K0861). Its owner feeds it a plan: { heading, answers } or { heading, card = { frame, lay } }; no plan hides it. One task: lay the options; what a choice does is its owner's (K0860).

-- {K0873} {K0867} {K0866} {K0861} {K0860} {K0859} {K0840}

local library = LibVGA
local ROW = 32
local PAD = 4
local GAP = 6
local SIDE = 14
local LINES = 2

function library.create_options(parent, on_choose)
    local options = library.create_section(parent, { gap = GAP, padding = { 0, SIDE, 0, SIDE } })
    options.rows, options.on_choose = {}, on_choose
    options.answers = library.create_group(options)
    options.answers_grid = library.create_grid(options.answers, { columns = { "rest" }, padding = { PAD, PAD, PAD, PAD }, row = 0, y = "top" })
    return options
end

local function render_chosen(row)
    local options = row:GetParent():GetParent()
    if row.answer and options.on_choose then options.on_choose(row.answer) end
end

local function read_row(options, index)
    options.rows[index] = options.rows[index] or library.create_item_row(options.answers, { chosen = true, on_click = render_chosen })
    return options.rows[index]
end

local function update_rows_hidden(options, from)
    for index = from, #options.rows do options.rows[index]:Hide() end
end

local function update_answers(options, answers, width)
    local pad, row_height, laid, total = library.read_draft_size(PAD), library.read_draft_size(ROW), {}, 0
    for index, answer in ipairs(answers) do
        local row = read_row(options, index)
        row.answer = answer
        row:SetSize(width - 2 * pad, row_height)
        library.update_item_row(row, { icon = library.media .. answer.icon, name = answer.name, quality = 1, tag = answer.tag, lines = LINES }, library.read_size(-2), width - 2 * pad)
        row:SetHeight(library.read_item_row_height(row, row_height))
        total = total + row:GetHeight()
        library.update_item_row_chosen(row, false)
        row:Show()
        laid[index] = { row }
    end
    update_rows_hidden(options, #answers + 1)
    if #answers == 0 then return nil end
    library.update_grid(options.answers_grid, laid, width)
    options.answers:SetSize(width, 2 * pad + total)
    library.update_group(options.answers)
    options.answers:Show()
    return options.answers
end

local function update_card(options, card, width)
    options.answers:Hide()
    update_rows_hidden(options, 1)
    card.frame:SetParent(options)
    card.lay(card.frame, width)
    card.frame:Show()
    return card.frame
end

local function update_card_gone(options, kept)
    if options.card and options.card ~= kept then options.card:Hide() end
    options.card = kept
end

function library.update_options(options, plan, width)
    local inner = width - 2 * library.read_draft_size(SIDE)
    update_card_gone(options, plan and plan.card and plan.card.frame)
    local part = plan and (plan.card and update_card(options, plan.card, inner) or update_answers(options, plan.answers or {}, inner))
    if not part then
        options:Hide()
        return 0
    end
    return library.update_section(options, plan.heading, { { part } }, width)
end
