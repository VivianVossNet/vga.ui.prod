-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's list page, a meta-object (K0871, K0860) as the accepted draft draws the lists of the trainer, the flight master and the merchant's pages (manual/view/vga-npc-windows.html, K0836): on its parent, stacked by a grid of its owner's plan, an optional row of tools above - its own frame, laid by a grid of its own - and LibVGA's item table beneath (library.create_item_table, K0862), its head 26 draft pixels, its rows 40, its cells kept LibVGA's small pad from its edges, unless its owner names others. Its owner feeds it a plan once - { table = the item table's plan, grid = the stack's grid plan, leave = the draft lengths the table leaves of its room, each reckoned on its own, tools = { grid = the tools' grid plan, create, update } where it has tools } -: create(frame, listing) makes the tools on the tools' frame and gives them back as listing.tools, update(listing, width) lays them to the width inside the stack's padding and gives back their row, which is laid after the table, so a region of the table may stand in it. At each laying it gets the items, its width and its room; the table takes the width inside the padding and the room the leave does not take. One task: lay a list of items under its tools.

-- {K0871} {K0860} {K0862} {K0836}

local library = LibVGA
local HEAD = 26
local ROW = 40

local function read_pad()
    return library.read_size(-2)
end

function library.create_list_page(parent, plan)
    local sheet, tools = plan.table, plan.tools
    sheet.head, sheet.row, sheet.pad = sheet.head or HEAD, sheet.row or ROW, sheet.pad or read_pad
    local listing = { plan = plan }
    listing.table = library.create_item_table(parent, sheet)
    listing.grid = library.create_grid(parent, plan.grid)
    if not tools then return listing end
    listing.holder = CreateFrame("Frame", nil, parent)
    listing.tools_grid = library.create_grid(listing.holder, tools.grid)
    listing.tools = tools.create(listing.holder, listing)
    return listing
end

local function read_inner(plan, width)
    local padding = plan.grid.padding or { 0, 0, 0, 0 }
    return width - library.read_grid_length(padding[2]) - library.read_grid_length(padding[4])
end

local function read_leave(plan)
    local leave = 0
    for _, length in ipairs(plan.leave or {}) do leave = leave + library.read_draft_size(length) end
    return leave
end

local function update_holder(listing, row, width)
    local _, height = library.update_grid(listing.tools_grid, { row }, width)
    listing.holder:SetSize(width, height)
    return { { listing.holder }, { listing.table } }
end

function library.update_list_page(listing, items, width, room)
    local plan = listing.plan
    local inner = read_inner(plan, width)
    local tools = plan.tools and plan.tools.update(listing, inner)
    library.update_item_table(listing.table, items, inner, room - read_leave(plan))
    library.update_grid(listing.grid, tools and update_holder(listing, tools, inner) or { { listing.table } }, width)
end
