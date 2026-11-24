-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's list of switches, the layers panel the accepted world map draws (manual/view/vga-map.html, K0806, K0811): a panel on the pop-up menu's ground, rounded, its rows in groups each under a small quiet heading in capitals, each row a word and LibVGA's switch at its right, laid by LibVGA's grid; a row without anything to show yet greyed and not to be switched. Its owner names the groups, the rows' keys and words, which are on and which can be switched, and hears every change by key.

-- {K0811} {K0806}

local library = LibVGA
local colours = library.colours
local MENU = { 0.102, 0.11, 0.129 }
local WIDTH = 260
local PAD = 10
local GAP = 8

local function create_row(list, row)
    local made = { key = row.key, enabled = row.enabled ~= false }
    made.word = library.create_text(list, "small", colours.ink)
    made.word:SetText(row.word)
    made.word:SetJustifyH("LEFT")
    made.switch = library.create_switch(list, row.on, function(on) list.on_change(row.key, on) end)
    made.switch:EnableMouse(made.enabled)
    made.word:SetAlpha(made.enabled and 1 or 0.4)
    made.switch:SetAlpha(made.enabled and 1 or 0.4)
    return made
end

function library.create_switch_list(parent, groups, on_change)
    local list = CreateFrame("Frame", nil, parent)
    list.ground = library.create_surface(list, "BACKGROUND", 0)
    list.on_change, list.rows, list.lines = on_change, {}, {}
    for _, group in ipairs(groups) do
        local heading = library.create_text(list, "small", colours.quiet)
        heading:SetText(library.read_capitals(group.heading))
        list.lines[#list.lines + 1] = { heading }
        for _, row in ipairs(group.rows) do
            local made = create_row(list, row)
            list.rows[#list.rows + 1] = made
            list.lines[#list.lines + 1] = { made.word, made.switch }
        end
    end
    list.grid = library.create_grid(list, { columns = { "rest", "auto" }, gap = GAP, padding = { PAD, PAD, PAD, PAD }, x = { "left", "right" }, row = 26 })
    return list
end

function library.update_switch_list(list)
    for _, row in ipairs(list.rows) do library.update_switch(row.switch) end
    local width, height = library.update_grid(list.grid, list.lines, library.read_draft_size(WIDTH))
    list:SetSize(width, height)
    library.update_surface(list.ground, 0, library.read_size(-4), MENU, MENU)
    return width, height
end
