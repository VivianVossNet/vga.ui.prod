-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's list dialog, a meta-object (K0871, K0860) as the accepted draft draws the trainer and the flight master (manual/view/vga-npc-windows.html, K0836): LibVGA's dialog of a fixed size with its foot's buttons and a status line carrying the player's gold, its body one area of its own - LibVGA's list page (library.create_list_page), fourteen draft pixels in from the body's edges, its tools beside one another ten apart and ten above the table. Its owner feeds it a plan once - { title, buttons, width, height in draft pixels, table = the item table's plan, tools = { create, update } where it has tools, as the list page takes them } - and at each laying the items and the foot's note; the table takes what the frame, the padding and, where there are tools, their row leave. One task: lay a list dialog.

-- {K0871} {K0860} {K0836}

local library = LibVGA
local SIDE = 14
local GAP = 10
local LEAVE_BARE = 28
local LEAVE_TOOLS = 76

function library.create_list_dialog(name, plan)
    local dialog = library.create_dialog(name, plan.title, { status = true, buttons = plan.buttons })
    dialog.plan = plan
    local grid = { columns = { "rest" }, padding = { SIDE, SIDE, SIDE, SIDE }, row = 0, row_gap = GAP, y = "top" }
    local tools = plan.tools and { grid = { columns = { "rest", "auto" }, gap = GAP, row = 0 }, create = plan.tools.create, update = plan.tools.update }
    dialog.listing = library.create_list_page(dialog.body, { table = plan.table, grid = grid, leave = { tools and LEAVE_TOOLS or LEAVE_BARE }, tools = tools })
    return dialog
end

function library.update_list_dialog(dialog, items, note)
    local plan = dialog.plan
    local width, height = library.read_draft_size(plan.width), library.read_draft_size(plan.height)
    library.update_dialog(dialog)
    library.update_list_page(dialog.listing, items, width - 2 * library.read_size(-4), height - library.read_dialog_frame_height(dialog))
    library.update_dialog_foot(dialog, note or "")
    library.update_dialog_status(dialog, library.texts.gold_label, GetMoney and GetMoney() or 0)
    dialog:SetSize(width, height)
end
