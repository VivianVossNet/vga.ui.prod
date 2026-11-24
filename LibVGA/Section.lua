-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's section, an object fed by parameters (K0873, K0860): a small heading in capitals in the quiet colour over the rows it heads, laid one beneath the other by a grid of one column, the heading and every row a gap apart - as the talk's options head their answers (manual/view/vga-npc-chat.html .answers, K0859), the quest's card its objectives and its rewards, the bank its bag places and their buying (manual/view/vga-npc-windows.html, K0836). Its owner feeds it a plan once - { kind = the heading's face, »small« unless named, gap = the draft pixels between the rows, six unless named, padding = the grid's padding where it has one } -, makes the rows it heads on the section itself, and at each laying gives the heading's words, the rows and the width; the section takes the height its rows need and gives it back. One task: head a group of rows.

-- {K0873} {K0860} {K0859} {K0836}

local library = LibVGA
local colours = library.colours
local KIND = "small"
local GAP = 6

function library.create_section(parent, plan)
    local section = CreateFrame("Frame", nil, parent)
    section.kind = plan.kind or KIND
    section.heading = library.create_text(section, section.kind, colours.quiet)
    section.grid = library.create_grid(section, { columns = { "rest" }, padding = plan.padding, row = 0, row_gap = plan.gap or GAP, y = "top" })
    return section
end

function library.update_section(section, heading, rows, width)
    section.heading:SetFontObject(library.read_font(section.kind))
    section.heading:SetText(library.read_capitals(heading or ""))
    section.heading:Show()
    local laid = { { section.heading } }
    for _, row in ipairs(rows) do laid[#laid + 1] = row end
    local _, height = library.update_grid(section.grid, laid, width)
    section:SetSize(width, height)
    section:Show()
    return height
end
