-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's confirm dialog, a meta-object (K0860) made once and filled with a plan wherever a step costs something and is asked first (K0897), as the accepted draft draws it (manual/view/vga-bank.html »die Rückfrage vor dem Kauf«) after the stack split's dialog (manual/view/vga-stacksplit.html, K0757): LibVGA's dialog of a fixed width, in the middle of the screen in front of everything, its title the plan's; in its body the picture of what is bought in a cell, its name bold beside it and a quiet line beneath, both cut with »…« where too long; the question, wrapping; beneath a line the amount's label and the amount in our coins; in its foot »Abbrechen« and the gold confirming word. Enter confirms, Escape cancels; only the gold button or Enter calls the plan's on_confirm, and the dialog is closed before it. Plan: title, icon, name, meta, question, label, copper, word, on_confirm.

-- {K0897} {K0860} {K0757}

local library = LibVGA
local colours = library.colours
local WIDTH = 300
local CELL = 40
local SIDE = 14
local GAP = 10
local dialog

local function render_cancel()
    dialog:Hide()
end

local function render_confirmed()
    local on_confirm = dialog.plan.on_confirm
    dialog:Hide()
    if on_confirm then on_confirm() end
end

local function update_key(self, key)
    local handled = key == "ENTER" or key == "NUMPADENTER" or key == "ESCAPE"
    if key == "ESCAPE" then render_cancel() elseif handled then render_confirmed() end
    if self.SetPropagateKeyboardInput and not InCombatLockdown() then self:SetPropagateKeyboardInput(not handled) end
end

local function create_confirm()
    local texts = library.texts
    dialog = library.create_dialog("VGAConfirm", "", { buttons = { { texts.cancel, "plain", render_cancel }, { texts.buy, "gold", render_confirmed } } })
    dialog.confirm = dialog.foot.buttons[2]
    dialog.cell = library.create_cell(dialog.body, { kind = "slot" })
    dialog.name = library.create_text(dialog.body, "bold", colours.ink)
    dialog.meta = library.create_text(dialog.body, "small", colours.quiet)
    dialog.question = library.create_text(dialog.body, "small", colours.label)
    dialog.question:SetWordWrap(true)
    dialog.question:SetJustifyH("LEFT")
    dialog.label = library.create_text(dialog.body, "small", colours.label)
    dialog.label:SetWordWrap(true)
    dialog.label:SetJustifyH("LEFT")
    dialog.amount = library.create_money(dialog.body, colours.ink)
    dialog.amount.kind = "small"
    dialog.item_grid = library.create_grid(dialog.body, { columns = { CELL, "rest" }, gap = GAP, padding = { SIDE, SIDE, 0, SIDE }, row = CELL, y = { "top", "middle" }, cut = { [2] = true } })
    dialog.question_grid = library.create_grid(dialog.body, { columns = { "rest" }, padding = { SIDE + CELL + GAP, SIDE, 0, SIDE }, row = 0, y = "top" })
    dialog.grid = library.create_grid(dialog.body, { columns = { "rest", "auto" }, gap = GAP, padding = { 0, SIDE, SIDE, SIDE }, row = 0, y = "middle", x = { "left", "right" }, lines = "all" })
    dialog:SetScript("OnKeyDown", function(self, key) library.update_safely("confirm key", update_key, self, key) end)
    dialog:Hide()
end

local function update_texts(plan, inner)
    dialog.title:SetText(plan.title or "")
    library.update_cell_size(dialog.cell, library.read_draft_size(CELL))
    library.update_cell(dialog.cell, { picture = plan.icon })
    dialog.name:SetText(plan.name or "")
    dialog.meta:SetText(plan.meta or "")
    dialog.question:SetText(plan.question or "")
    dialog.question:SetWidth(inner)
    dialog.label:SetText(plan.label or "")
    library.update_money(dialog.amount, plan.copper or 0)
    dialog.confirm.words = plan.word or library.texts.buy
    dialog.confirm.text:SetText(dialog.confirm.words)
    library.update_button_enabled(dialog.confirm, plan.ready ~= false)
end

local function update_layout(plan)
    local width = library.read_draft_size(WIDTH)
    local side = library.read_draft_size(SIDE)
    local inner = width - 2 * side
    library.update_dialog(dialog)
    update_texts(plan, inner)
    library.update_grid(dialog.item_grid, { { dialog.cell, { stack = { dialog.name, dialog.meta }, gap = { pixels = 2 } } } }, width)
    local _, asked = library.update_grid(dialog.question_grid, { { dialog.question } }, width)
    local top = (asked or 0) + library.read_draft_size(GAP)
    dialog.grid.plan.padding = { { pixels = top }, SIDE, SIDE, SIDE }
    dialog.label:SetWidth(inner - library.read_draft_size(GAP) - dialog.amount:GetWidth())
    local _, height = library.update_grid(dialog.grid, { { dialog.label, dialog.amount } }, width)
    library.update_dialog(dialog)
    dialog:SetSize(width, library.read_dialog_frame_height(dialog) + (height or 0))
end

function library.render_confirm(plan)
    if not dialog then create_confirm() end
    dialog.plan = plan
    update_layout(plan)
    dialog:ClearAllPoints()
    dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    dialog:EnableKeyboard(not InCombatLockdown())
    dialog:Show()
    dialog:Raise()
end

function library.read_confirm()
    return dialog
end
