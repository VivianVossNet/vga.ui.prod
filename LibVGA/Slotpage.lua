-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's slot page, a meta-object (K0860, K1017): the slots of one container laid as the game's bank lays a tab - so many to a row, rows beneath, all the same size and gap - in a frame of its own on a page; its owner makes the slots, whatever they are - the game's own item buttons for the bank at the bank (library.create_container_slot), LibVGA's cells for the bank kept from the last visit (library.create_cell) - and hands them over, the page lays them and gives back its size. Made by library.create_slot_page(page, plan) - plan.columns, plan.cell and plan.gap in draft pixels -, laid by library.update_slot_page(page, cells), its width read by library.read_slot_page_width(plan). One task: lay a container's slots.

-- {K1017} {K0894}

local library = LibVGA

local function read_columns(plan)
    local columns = {}
    for index = 1, plan.columns do columns[index] = plan.cell end
    return columns
end

local function read_rows(cells, columns)
    local rows = {}
    for index = 1, #cells do
        local row = math.floor((index - 1) / columns) + 1
        rows[row] = rows[row] or {}
        rows[row][#rows[row] + 1] = cells[index]
    end
    return rows
end

function library.read_slot_page_width(plan)
    return plan.columns * library.read_draft_size(plan.cell + plan.gap) - library.read_draft_size(plan.gap)
end

function library.create_slot_page(page, plan)
    page.slot_plan = plan
    page.slots = CreateFrame("Frame", nil, page)
    page.slots_grid = library.create_grid(page.slots, { columns = read_columns(plan), gap = plan.gap, row = plan.cell, row_gap = plan.gap, y = "top" })
    return page.slots
end

function library.update_slot_page(page, cells)
    local size = library.read_draft_size(page.slot_plan.cell)
    for _, cell in ipairs(cells) do
        cell:SetSize(size, size)
        cell:Show()
    end
    page.cells = cells
    local _, height = library.update_grid(page.slots_grid, read_rows(cells, page.slot_plan.columns), nil)
    page.slots:SetSize(library.read_slot_page_width(page.slot_plan), height or 0)
    return height or 0
end
