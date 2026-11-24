-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's ledger page, a meta-object (K0870, K0860) as the accepted draft draws the auction's pages Verlauf, Meine Auktionen and Depot (manual/view/vga-auctions.html): on its parent, stacked fourteen draft pixels apart, its areas objects of their own - LibVGA's figure strip on top (library.create_figure_strip, K0869), LibVGA's item table beneath (library.create_item_table, K0862) - and under the table a quiet note, four draft pixels in and six below it. Its owner feeds it a plan once - { strip = the figure strip's plan, table = the item table's plan, note = its words } -, fills the strip's values, and at each laying gives it the items, the width, the room it has and whatever of its own stands between the strip and the table, each laid by its owner beforehand; the table takes the room the strip, those between, the gaps and forty draft pixels for the note leave, at least its head and three rows. One task: lay a ledger page.

-- {K0870} {K0869} {K0862} {K0860}

local library = LibVGA
local colours = library.colours
local GAP = 14
local NOTE = 40
local HEAD = 28
local ROW = 40
local LEAST_ROWS = 3
local NOTE_IN = 4
local NOTE_BELOW = 6

function library.create_ledger_page(parent, plan)
    local ledger = { plan = plan }
    ledger.strip = library.create_figure_strip(parent, plan.strip)
    ledger.table = library.create_item_table(parent, plan.table)
    ledger.stack = library.create_grid(parent, { columns = { "rest" }, row = 0, row_gap = GAP, y = "top" })
    ledger.note = library.create_text(parent, "small", colours.quiet)
    ledger.note:SetJustifyH("LEFT")
    ledger.note:SetText(plan.note or "")
    return ledger
end

local function update_note(ledger, width)
    local note = ledger.note
    note:SetFontObject(library.read_font("small"))
    note:ClearAllPoints()
    note:SetPoint("TOPLEFT", ledger.table, "BOTTOMLEFT", library.read_draft_size(NOTE_IN), -library.read_draft_size(NOTE_BELOW))
    note:SetWidth(width - library.read_draft_size(2 * NOTE_IN))
end

function library.update_ledger_page(ledger, items, width, room, between)
    local gap = library.read_draft_size(GAP)
    local top, rows = library.update_figure_strip(ledger.strip, width) + gap, { { ledger.strip } }
    for _, frame in ipairs(between or {}) do
        top = top + frame:GetHeight() + gap
        rows[#rows + 1] = { frame }
    end
    local least = library.read_draft_size(HEAD) + LEAST_ROWS * library.read_draft_size(ROW)
    library.update_item_table(ledger.table, items, width, math.max(room - top - library.read_draft_size(NOTE), least))
    rows[#rows + 1] = { ledger.table }
    library.update_grid(ledger.stack, rows, width)
    update_note(ledger, width)
end
