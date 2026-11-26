-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's item table, a meta-object (K0860, K0862) as the accepted drafts draw a list of items under sortable column heads (manual/view/vga-auctions.html, vga-npc-windows.html): one group owning LibVGA's list (library.create_list), a sort head over every column that names one, the words shown while it is empty, and the probes that measure a column's widest money, chip or text. Its owner feeds it a plan once - its columns, each { key, word, sort, tip, least, x, inset - »icon« or draft pixels }, its row's maker and layer, the empty words, what a new sort or a new set of rows asks of it, the gap between columns in draft pixels where it is not LibVGA's least - and its items, width and height at each laying; every column is as wide as its head and the least its owner names (draft pixels, »money«, »money_small«, »chip«, a text sample, or a measure of its own), one column the rest. The rows read the columns it laid from table.columns and table.pad. A click on a sort head sorts by that column's reader (column.sort) and lays the list again itself with the items it was last given, unless its owner asks a new sort of the game (plan.on_sort); every column with a head carries its reader (K0909). One task: lay a sortable list of items.

-- {K0909} {K0862} {K0860} {K0631} {K0632}

local library = LibVGA
local colours = library.colours
local HEAD = 28
local ROW = 40
local PAD = 12
local ICON = 26

local function render_sorted(sheet)
    local laid = sheet.laid
    if laid then library.update_item_table(sheet, laid[1], laid[2], laid[3]) end
end

function library.create_item_table(parent, plan)
    local sheet = library.create_group(parent)
    sheet.plan = plan
    sheet.list = library.create_list(sheet, plan.create_row, plan.update_row)
    sheet.list.on_sort, sheet.list.on_rows, sheet.list.sorters = plan.on_sort or function() render_sorted(sheet) end, plan.on_rows, {}
    sheet.list.read_last = plan.read_last
    sheet.heads = {}
    for index, column in ipairs(plan.columns) do
        if column.sort then sheet.list.sorters[column.key] = column.sort end
        if column.word then sheet.heads[index] = library.create_sort_head(sheet.list, sheet, library.read_capitals(column.word), column.key, column.tip) end
    end
    sheet.empty = library.create_text(sheet, "small", colours.quiet)
    sheet.empty:SetText(plan.empty or "")
    sheet.probe_money = library.create_money(sheet, colours.ink)
    sheet.probe_small = library.create_money(sheet, colours.ink)
    sheet.probe_small.kind = "small"
    sheet.probe_text = library.create_text(sheet, "small", colours.ink)
    sheet.probe_chip = library.create_chip(sheet)
    for _, probe in ipairs({ sheet.probe_money, sheet.probe_small, sheet.probe_text, sheet.probe_chip }) do probe:Hide() end
    return sheet
end

local function read_money_room(sheet)
    return library.read_widest_money(sheet.probe_money)
end

local function read_small_money_room(sheet)
    return library.read_widest_money(sheet.probe_small)
end

local function read_chip_room(sheet)
    return library.read_widest_chip(sheet.probe_chip)
end

local MEASURES = { money = read_money_room, money_small = read_small_money_room, chip = read_chip_room }

function library.read_item_table_text(sheet, words)
    return library.read_widest_text(sheet.probe_text, words)
end

local function read_least(sheet, least)
    if least == nil or least == false then return nil end
    if type(least) == "number" then return library.read_draft_size(least) end
    if type(least) == "function" then return least(sheet) end
    if MEASURES[least] then return MEASURES[least](sheet) end
    return library.read_item_table_text(sheet, least)
end

local function read_sizes(sheet)
    local sizes = {}
    for index, column in ipairs(sheet.plan.columns) do
        local least, head = read_least(sheet, column.least), sheet.heads[index]
        sizes[index] = least and math.max(least, head and head:GetWidth() or 0) or false
    end
    return sizes
end

local function read_pad(plan)
    if type(plan.pad) == "function" then return plan.pad() end
    return library.read_draft_size(plan.pad or PAD)
end

local function update_heads(sheet, head)
    local cells, icon = {}, library.read_draft_size(ICON) + library.read_size(-4)
    for index, column in ipairs(sheet.plan.columns) do
        local heading = sheet.heads[index]
        local inset = column.inset == "icon" and icon or (type(column.inset) == "number" and library.read_draft_size(column.inset) or nil)
        if heading then cells[#cells + 1] = { heading, index, column.x or "left", inset } end
    end
    library.update_grid_columns(sheet, sheet.columns, sheet.pad, cells, { top = 0, height = head })
end

function library.update_item_table(sheet, items, width, height)
    local plan = sheet.plan
    sheet.laid = { items, width, height }
    sheet.pad = read_pad(plan)
    for index, column in ipairs(plan.columns) do
        if sheet.heads[index] then library.update_sort_head(sheet.heads[index], column.x == "right") end
    end
    sheet.columns = library.read_columns(width - 2 * sheet.pad, read_sizes(sheet), plan.gap)
    local head = library.read_whole_pixels(library.read_draft_size(plan.head or HEAD), sheet)
    local row = library.read_draft_size(plan.row or ROW)
    sheet:SetSize(width, height)
    library.update_group(sheet)
    update_heads(sheet, head)
    library.update_list_in_group(sheet, sheet.list, sheet.empty, head, row)
    library.update_list(sheet.list, items, width, height - head, row)
    sheet.empty:SetShown(#items == 0)
end
