-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's search bar, an object fed by parameters (K0873, K0860), as the accepted draft draws the tools above the lists of the trainer and the merchant (manual/view/vga-npc-windows.html, K0836): LibVGA's search field, its magnifier at its left and its clearing cross at its right (library.create_input), at the bar's left, LibVGA's segmented choice flush right (library.create_choice), laid side by side on one row by a grid of their own. Its owner feeds it a plan once - { hint, labels, chosen, on_search = what a typed word does, on_choose = what a choice does, gap = the draft pixels between the field and the choice, share = the part of the width the field takes where it is not the rest, y = how the two stand on their row, »middle« unless named } -; at each laying it gets its width and takes the height of its taller part. Its owner reads the word typed in bar.input and the choice in bar.choice. One task: lay a search field beside its choice.

-- {K0873} {K0860} {K0836}

local library = LibVGA
local MOST = 40

function library.create_search_bar(parent, plan)
    local bar = CreateFrame("Frame", nil, parent)
    bar.plan = plan
    bar.input = library.create_input(bar, { hint = plan.hint, picture = "Search", clear = true, most = MOST, on_change = plan.on_search })
    bar.choice = library.create_choice(bar, plan.labels, plan.chosen or 1, plan.on_choose)
    bar.grid = library.create_grid(bar, { columns = { "rest", "auto" }, gap = plan.gap, row = 0, y = plan.y })
    return bar
end

local function read_field_width(bar, width)
    local plan = bar.plan
    if plan.share then return math.floor(width * plan.share) end
    return width - library.read_choice_width(bar.choice) - library.read_grid_length(plan.gap)
end

function library.update_search_bar(bar, width)
    library.update_choice(bar.choice)
    library.update_input(bar.input, read_field_width(bar, width))
    local _, height = library.update_grid(bar.grid, { { bar.input, bar.choice } }, width)
    bar:SetSize(width, height)
    return bar
end
