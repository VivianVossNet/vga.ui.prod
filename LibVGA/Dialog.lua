-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's dialog as the accepted drafts draw it (manual/view/vga-scale.html .dlg, vga-template.css .vt): the metal frame, the head with the mark, the gold title - on one line, left, ending before the leftmost of the head's buttons, a title too long for it cut with »…« (K0907) - and the close button, further buttons of the same make with an icon to its left where a dialog asks for them, its rows divided by hairlines; always free to move, its ground down to a floor. Rows that stand together outside a fieldset stand on one rounded, faintly lighter card, in the way of the macOS System Settings (K0565). A stepper in a row is measured as it is laid (K0721). The dialog opened or clicked last stands in front of every other, whole, so no two dialogs interleave (K0737). A row may carry, where its maker is given a look, a note beneath its name in the small quiet face and, before both, a stripe in a colour of its user's, four draft pixels wide, ten clear of the name - the row twice as tall as its name and note need, its words measured with them (library.create_row's look, library.read_row_label_width, K1035). A row may carry LibVGA's mark of the active row - the whole row on a quiet gold ground, its name gold and bold (library.create_active_mark, K0779; before a gold pill, K0778, and an orange chevron, K0729) -, so the label never moves; the profiles mark the active one so. A dialog may own a foot, named when it is made: a quiet note at its left, its buttons at its right - plain ones first, the gold one last -, ten draft pixels above a row of 22 and fourteen below, fourteen from the sides, eight between the buttons; its user names their words, kinds and actions and never lays them, and the dialog's frame height with or without it is read by library.read_dialog_frame_height (K0783). A foot with buttons may carry a status line of its own beneath them - its note at the left, money at the right, under a hairline (plan.status, library.update_dialog_status, K0836), as the merchant's gold stands under its repair row. A foot without buttons is a status line thirty draft pixels high - the bags' and the loot window's -, its note at the left and, where asked, the money at the right, where asked on a darker band under a hairline; its user fills it by library.update_dialog_foot (K0784). Every row but a heading keeps the room of LibVGA's applied tick at its right, its control beside it, so a setting shows its tick when applied and nothing moves (library.create_tick, K0794). A dialog shown before it was ever placed stands in the middle of the screen (library.update_dialog_placed, K0816); one that belongs beside a window of the game stands at its right (library.update_dialog_beside, K0835), since the game draws no frame without a place. Every dialog carries LibVGA's pin in its head as its own part, beside the close, made by the dialog's maker (K0767): grey while free, when the dialog can be dragged, gold while pinned, when its place is fixed and it cannot; its meaning in a tooltip, with a note of the owner's where it means more; its state kept on the dialog unless its user hands another keeper (library.update_dialog_pin_state), so the bags remember theirs and a fixed tooltip starts free (K0764). A foot without buttons is its status line alone (K0836). A window that ends a visit of the game when it closes hears its closing only after its first hiding (library.update_dialog_closing, K0838): a new frame stands shown, so hiding it once at its making would end the very visit that made it, the merchant's, the talk, the quest, the trainer's, the flight master's, the bank's, as the auction house's did (K0681). A window for a figure of the game names it by library.read_figure_name - the game's »npc«, else the target, since a merchant reached through its talk is not always given as »npc« - and is titled »word · name« by library.read_figure_title, the word alone where no name is known (K0839); library.read_figure_id reads the figure's number from its GUID, nil where it is no creature or kept secret (K0848). A foot's button its user hides is passed over, the shown ones closing up at the right, so one dialog may change its pair of buttons with its moment - the talk's »Auf Wiedersehen« alone, the quest's two (K0840). The foot may carry a badge at its left, LibVGA's chip of a kind and a word, the note after it - a positive hint as the trainer's own skill rank (badge, K0938).

-- {K1035} {K0938} {K0907} {K0848} {K0840} {K0839} {K0838} {K0681} {K0794} {K0792} {K0784} {K0783} {K0779} {K0778} {K0767} {K0764} {K0256} {K0296} {K0299} {K0324} {K0330} {K0337} {K0415} {K0565} {K0721} {K0729} {K0737}

local library = LibVGA
local CARD = { 1, 1, 1 }
local CARD_ALPHA = 0.04
local FOOT_TOP = 10
local FOOT_ROW = 22
local FOOT_BOTTOM = 14
local FOOT_SIDE = 14
local FOOT_GAP = 8
local TICK_GAP = 8
local FOOT_STATUS = 30
local FOOT_INK = { 0.467, 0.451, 0.42 }
local FOOT_GROUND = { 0.039, 0.043, 0.051 }
local colours = library.colours
local BLACK = { 0, 0, 0 }
local HAIRLINE = { 0.137, 0.149, 0.173 }
local FIELDSET = { 0.235, 0.247, 0.282 }
local STRIPE = { 4, 10 }
local FIELDSET_LINES = { "top_left", "top_right", "left", "right", "bottom" }

local function create_close(dialog)
    local close = library.create_icon_button(dialog, nil, function() dialog:Hide() end, { kind = "head" })
    close.strokes = {}
    for index, angle in ipairs({ 45, -45 }) do
        local stroke = close:CreateTexture(nil, "ARTWORK")
        stroke:SetColorTexture(colours.gold[1], colours.gold[2], colours.gold[3], 1)
        stroke:SetRotation(math.rad(angle))
        close.strokes[index] = stroke
    end
    return close
end

function library.create_dialog_button(dialog, icon, on_click)
    local button = library.create_icon_button(dialog, icon, on_click, { kind = "head" })
    dialog.head_buttons = dialog.head_buttons or {}
    dialog.head_buttons[#dialog.head_buttons + 1] = button
    return button
end

function library.update_dialog_pin(dialog)
    local pinned = dialog.pin_state.read()
    local colour = pinned and colours.gold or colours.quiet
    dialog.pin.picture:SetVertexColor(colour[1], colour[2], colour[3], 1)
    dialog:SetMovable(not pinned)
end

local function render_pin_tip(pin)
    local dialog = pin:GetParent()
    local pinned, texts = dialog.pin_state.read(), library.texts
    GameTooltip:SetOwner(pin, "ANCHOR_TOP")
    GameTooltip:AddLine(pinned and texts.unpin_place or texts.pin_place, colours.ink[1], colours.ink[2], colours.ink[3])
    local note = dialog.pin_state.read_note and dialog.pin_state.read_note(pinned)
    if note then GameTooltip:AddLine(note, colours.quiet[1], colours.quiet[2], colours.quiet[3], true) end
    GameTooltip:Show()
end

local function update_pin_left()
    GameTooltip:Hide()
end

local function write_pin(pin)
    local dialog = pin:GetParent()
    dialog.pin_state.write(not dialog.pin_state.read())
    library.update_dialog_pin(dialog)
    render_pin_tip(pin)
end

local function update_dragged(dialog)
    if dialog.pin_state.read() then return end
    dialog:StartMoving()
end

local function update_dropped(dialog)
    dialog:StopMovingOrSizing()
    if dialog.pin_state.dropped then dialog.pin_state.dropped(dialog) end
end

local function read_own_pinned(dialog)
    return function() return dialog.pinned == true end
end

local function write_own_pinned(dialog)
    return function(pinned) dialog.pinned = pinned or nil end
end

function library.update_dialog_pin_state(dialog, state)
    dialog.pin_state = {
        read = state.read or read_own_pinned(dialog),
        write = state.write or write_own_pinned(dialog),
        read_note = state.read_note,
        dropped = state.dropped,
    }
    library.update_dialog_pin(dialog)
end

local function create_pin(dialog)
    dialog.pin = library.create_dialog_button(dialog, "Pin", write_pin)
    dialog.pin:SetScript("OnEnter", render_pin_tip)
    dialog.pin:SetScript("OnLeave", update_pin_left)
    dialog:SetScript("OnDragStart", update_dragged)
    dialog:SetScript("OnDragStop", update_dropped)
    library.update_dialog_pin_state(dialog, {})
end

local function update_close(close, size)
    library.update_icon_button(close, size)
    local arm = math.floor(size * 0.42 + 0.5)
    for _, stroke in ipairs(close.strokes) do
        stroke:ClearAllPoints()
        stroke:SetSize(arm, 1.5)
        stroke:SetPoint("CENTER")
    end
end

local function update_raised(dialog)
    dialog:Raise()
end

local function create_band(foot)
    foot.band = foot:CreateTexture(nil, "BACKGROUND")
    foot.band:SetAllPoints()
    foot.line = library.create_hairline(foot)
    foot.line:SetPoint("TOPLEFT")
    foot.line:SetPoint("TOPRIGHT")
    foot.line:SetHeight(1)
end

local function create_foot(dialog, plan)
    local foot = CreateFrame("Frame", nil, dialog)
    if plan.band then create_band(foot) end
    if plan.money then
        foot.money = library.create_money(foot, FOOT_INK)
        foot.money.kind = "small"
    end
    foot.note = library.create_text(foot, "small", FOOT_INK)
    foot.note:SetWordWrap(false)
    foot.note:SetJustifyH("LEFT")
    foot.note:SetText(plan.note or "")
    if plan.status then
        foot.status_line = library.create_hairline(foot)
        foot.status_note = library.create_text(foot, "small", FOOT_INK)
        foot.status_money = library.create_money(foot, FOOT_INK)
        foot.status_money.kind = "small"
    end
    foot.buttons = {}
    for index, button in ipairs(plan.buttons or {}) do
        foot.buttons[index] = library.create_button(foot, button[1], button[2], button[3])
    end
    return foot
end

function library.read_dialog_foot_height(dialog)
    if not dialog.foot then return 0 end
    local draft = library.read_draft_size
    if #dialog.foot.buttons == 0 then return draft(FOOT_STATUS) end
    local status = dialog.foot.status_note and draft(FOOT_STATUS) or 0
    return draft(FOOT_TOP) + draft(FOOT_ROW) + draft(FOOT_BOTTOM) + status
end

function library.update_dialog_status(dialog, note, copper)
    local foot = dialog.foot
    foot.status_note:SetText(note or "")
    library.update_money(foot.status_money, copper or 0)
end

local function update_status(foot)
    local draft = library.read_draft_size
    local top = #foot.buttons == 0 and 0 or draft(FOOT_TOP) + draft(FOOT_ROW) + draft(FOOT_BOTTOM)
    local middle = -(top + draft(FOOT_STATUS) / 2)
    foot.status_line:ClearAllPoints()
    foot.status_line:SetPoint("TOPLEFT", foot, "TOPLEFT", 0, -top)
    foot.status_line:SetPoint("TOPRIGHT", foot, "TOPRIGHT", 0, -top)
    foot.status_line:SetHeight(1)
    foot.status_note:SetFontObject(library.read_font("small"))
    foot.status_note:ClearAllPoints()
    foot.status_note:SetPoint("LEFT", foot, "TOPLEFT", draft(FOOT_SIDE), middle)
    foot.status_money:ClearAllPoints()
    foot.status_money:SetPoint("RIGHT", foot, "TOPRIGHT", -draft(FOOT_SIDE), middle)
end

local function read_foot_middle(foot)
    local draft = library.read_draft_size
    if #foot.buttons == 0 then return -draft(FOOT_STATUS) / 2 end
    return -(draft(FOOT_TOP) + draft(FOOT_ROW) / 2)
end

local function update_foot_badge(foot, badge)
    if badge and not foot.badge then foot.badge = library.create_chip(foot) end
    if not foot.badge then return end
    local draft, middle = library.read_draft_size, read_foot_middle(foot)
    foot.badge:SetShown(badge ~= nil)
    if not badge then return foot.note:SetPoint("LEFT", foot, "TOPLEFT", draft(FOOT_SIDE), middle) end
    library.update_chip(foot.badge, badge.kind, nil, badge.word)
    foot.badge:ClearAllPoints()
    foot.badge:SetPoint("LEFT", foot, "TOPLEFT", draft(FOOT_SIDE), middle)
    foot.note:SetPoint("LEFT", foot.badge, "RIGHT", draft(FOOT_GAP), 0)
end

function library.update_dialog_foot(dialog, note, copper, badge)
    local foot = dialog.foot
    foot.note:SetText(note or "")
    if foot.money and copper then library.update_money(foot.money, copper) end
    update_foot_badge(foot, badge)
end

local function update_foot(dialog, inner)
    local foot, draft = dialog.foot, library.read_draft_size
    foot:ClearAllPoints()
    foot:SetPoint("BOTTOMLEFT", inner, inner)
    foot:SetPoint("BOTTOMRIGHT", -inner, inner)
    foot:SetHeight(library.read_dialog_foot_height(dialog))
    local beside, middle = foot.money, read_foot_middle(foot)
    if foot.band then foot.band:SetColorTexture(FOOT_GROUND[1], FOOT_GROUND[2], FOOT_GROUND[3], library.read_dialog_ground()) end
    if foot.money then
        foot.money:ClearAllPoints()
        foot.money:SetPoint("RIGHT", foot, "TOPRIGHT", -draft(FOOT_SIDE), middle)
    end
    for index = #foot.buttons, 1, -1 do
        local button = foot.buttons[index]
        library.update_button(button)
        button:ClearAllPoints()
        if button:IsShown() then
            if beside then button:SetPoint("RIGHT", beside, "LEFT", -draft(FOOT_GAP), 0) else button:SetPoint("RIGHT", foot, "TOPRIGHT", -draft(FOOT_SIDE), middle) end
            beside = button
        end
    end
    if foot.status_note then update_status(foot) end
    foot.note:SetFontObject(library.read_font("figures_small"))
    foot.note:ClearAllPoints()
    foot.note:SetPoint("LEFT", foot, "TOPLEFT", draft(FOOT_SIDE), middle)
    if beside then foot.note:SetPoint("RIGHT", beside, "LEFT", -draft(FOOT_GAP), 0) end
end

function library.update_dialog_placed(dialog)
    if dialog:GetNumPoints() > 0 then return end
    dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
end

function library.read_figure_name()
    local name = UnitName and UnitName("npc")
    if not name or name == "" then name = UnitName and UnitName("target") end
    return name or ""
end

function library.read_figure_id()
    local guid = UnitGUID and (UnitGUID("npc") or UnitGUID("target"))
    if type(guid) ~= "string" or (issecretvalue and issecretvalue(guid)) then return nil end
    local kind, id = guid:match("^(%a+)%-[^-]+%-[^-]+%-[^-]+%-[^-]+%-([^-]+)")
    if kind ~= "Creature" and kind ~= "Vehicle" then return nil end
    return id
end

function library.read_figure_title(word)
    local name = library.read_figure_name()
    return name ~= "" and word .. " · " .. name or word
end

function library.update_dialog_closing(dialog, render)
    dialog:Hide()
    dialog:SetScript("OnHide", render)
end

function library.update_dialog_beside(dialog, frame, gap)
    dialog:ClearAllPoints()
    dialog:SetPoint("TOPLEFT", frame or UIParent, "TOPRIGHT", gap or 0, 0)
end

function library.read_dialog_frame_height(dialog)
    return library.read_size(4) + 1 + 2 * library.read_size(-4) + library.read_dialog_foot_height(dialog)
end

function library.create_dialog(name, title, foot)
    local dialog = CreateFrame("Frame", name, UIParent)
    dialog:SetFrameStrata("DIALOG")
    dialog:SetToplevel(true)
    dialog:HookScript("OnShow", update_raised)
    dialog:SetClampedToScreen(true)
    dialog:SetMovable(true)
    dialog:EnableMouse(true)
    dialog:RegisterForDrag("LeftButton")

    dialog.outline = library.create_surface(dialog, "BACKGROUND", 0)
    dialog.metal = library.create_surface(dialog, "BACKGROUND", 1)
    dialog.ground = library.create_surface(dialog, "BORDER", 0)
    dialog.head = dialog:CreateTexture(nil, "BORDER", nil, 1)
    dialog.head:SetColorTexture(1, 1, 1, 1)
    dialog.head_light = dialog:CreateTexture(nil, "BORDER", nil, 2)
    dialog.head_light:SetColorTexture(1, 1, 1, 0.08)
    dialog.head_line = dialog:CreateTexture(nil, "BORDER", nil, 2)
    dialog.head_line:SetColorTexture(0, 0, 0, 1)
    dialog.mark = dialog:CreateTexture(nil, "ARTWORK")
    dialog.mark:SetTexture(library.media .. "Mark")
    dialog.title = library.create_text(dialog, "title", colours.gold)
    dialog.title:SetText(title)
    dialog.close = create_close(dialog)
    create_pin(dialog)
    dialog.body = CreateFrame("Frame", nil, dialog)
    if foot then dialog.foot = create_foot(dialog, foot) end
    tinsert(UISpecialFrames, name)
    return dialog
end

function library.update_dialog(dialog)
    local inner, head, pad = library.read_size(-4), library.read_size(4), library.read_size(-2)
    local alpha = library.read_dialog_ground()
    library.update_surface(dialog.outline, -1, pad + 1, BLACK, BLACK, alpha)
    library.update_surface(dialog.metal, 0, pad, colours.metal_top, colours.metal_bottom, alpha)
    library.update_surface(dialog.ground, inner, inner, colours.ground, colours.ground, alpha)
    dialog.head:SetAlpha(alpha)
    dialog.head:ClearAllPoints()
    dialog.head:SetPoint("TOPLEFT", inner, -inner)
    dialog.head:SetPoint("TOPRIGHT", -inner, -inner)
    dialog.head:SetHeight(head)
    dialog.head:SetGradient("VERTICAL", library.create_colour(colours.head_bottom), library.create_colour(colours.head_top))
    dialog.head_light:ClearAllPoints()
    dialog.head_light:SetPoint("TOPLEFT", dialog.head, "TOPLEFT")
    dialog.head_light:SetPoint("TOPRIGHT", dialog.head, "TOPRIGHT")
    dialog.head_light:SetHeight(1)
    dialog.head_line:ClearAllPoints()
    dialog.head_line:SetPoint("TOPLEFT", dialog.head, "BOTTOMLEFT")
    dialog.head_line:SetPoint("TOPRIGHT", dialog.head, "BOTTOMRIGHT")
    dialog.head_line:SetHeight(1)
    local mark = library.read_size(2)
    dialog.mark:SetSize(mark, mark)
    dialog.mark:ClearAllPoints()
    dialog.mark:SetPoint("LEFT", dialog.head, "LEFT", pad, 0)
    dialog.title:SetFontObject(library.read_font("title"))
    dialog.title:ClearAllPoints()
    dialog.title:SetPoint("LEFT", dialog.mark, "RIGHT", pad, 0)
    update_close(dialog.close, mark)
    dialog.close:ClearAllPoints()
    dialog.close:SetPoint("RIGHT", dialog.head, "RIGHT", -pad, 0)
    local beside = dialog.close
    for _, button in ipairs(dialog.head_buttons or {}) do
        library.update_icon_button(button, mark)
        button:ClearAllPoints()
        button:SetPoint("RIGHT", beside, "LEFT", -library.read_size(-4), 0)
        beside = button
    end
    dialog.title:SetWordWrap(false)
    dialog.title:SetJustifyH("LEFT")
    dialog.title:SetPoint("RIGHT", beside, "LEFT", -library.read_size(-4), 0)
    if dialog.foot then update_foot(dialog, inner) end
    dialog.body:ClearAllPoints()
    dialog.body:SetPoint("TOPLEFT", dialog.head, "BOTTOMLEFT", 0, -1)
    dialog.body:SetPoint("BOTTOMRIGHT", -inner, inner + library.read_dialog_foot_height(dialog))
end

local function create_row_look(row, look)
    if look.note then
        row.note = library.create_text(row, "small", colours.quiet)
        row.note:SetText(look.note)
    end
    if look.stripe then
        row.stripe = row:CreateTexture(nil, "ARTWORK")
        row.stripe:SetColorTexture(look.stripe[1], look.stripe[2], look.stripe[3], 1)
    end
end

function library.create_row(parent, label, kind, look)
    local row = CreateFrame("Frame", nil, parent)
    row.kind = kind
    row.label = library.create_text(row, kind == "heading" and "small" or "body")
    row.label:SetText(kind == "heading" and library.read_capitals(label) or label)
    if kind == "heading" then
        row.fieldset = {}
        for _, name in ipairs(FIELDSET_LINES) do
            row.fieldset[name] = row:CreateTexture(nil, "BORDER")
            row.fieldset[name]:SetColorTexture(FIELDSET[1], FIELDSET[2], FIELDSET[3], 1)
        end
    end
    if look then create_row_look(row, look) end
    row.line = library.create_hairline(row)
    if kind ~= "heading" then row.tick = library.create_tick(row) end
    return row
end

function library.update_row_enabled(row, enabled)
    if not row.blocker then
        row.blocker = CreateFrame("Frame", nil, row)
        row.blocker:SetAllPoints()
        row.blocker:SetFrameLevel(row:GetFrameLevel() + 20)
        row.blocker:EnableMouse(true)
    end
    row:SetAlpha(enabled and 1 or 0.4)
    row.blocker:SetShown(not enabled)
end

function library.read_row_height(row)
    if row and row.kind == "heading" then return library.read_size(1) + library.read_size(-4) end
    if row and row.kind == "wide" then return library.read_size(0) * 4.4 + 2 * library.read_size(-2) end
    if row and row.note then return library.read_size(2) + library.read_size(-1) + 2 * library.read_size(-2) end
    return library.read_size(2) + 2 * library.read_size(-2)
end

local function read_control_width(control)
    if control.switch then return 0 end
    if control.popup then return library.read_popup_width(control) end
    if control.stops then return library.read_slider_width() end
    if control.buttons then return library.read_choice_width(control) end
    if control.pictures then return library.read_pictures_width(control) end
    if control.stepper then library.update_stepper(control) end
    return control:GetWidth()
end

function library.update_row_controls(rows)
    local column = 0
    for _, row in ipairs(rows) do
        if row.when then row:SetShown(row.when(row)) end
        if row.kind == "widget" then
            column = math.max(column, library.read_widget_row_width())
        elseif row.control and row.kind ~= "wide" then
            column = math.max(column, read_control_width(row.control))
        end
    end
    for _, row in ipairs(rows) do
        local control = row.kind ~= "widget" and row.control
        if control and control.stops then library.update_slider(control, column) end
        if control and control.buttons then library.update_choice(control, column) end
        if control and control.pictures then library.update_pictures(control) end
        if control and control.switch then library.update_switch(control) end
        if control and control.popup then library.update_popup(control) end
    end
    return column
end

local function read_group_gap()
    return math.floor(library.read_size(0) * 0.6 + 0.5)
end

function library.read_rows_height(rows)
    local height = 0
    for _, row in ipairs(library.read_shown_rows(rows)) do
        height = height + library.read_row_height(row) + (row.kind == "heading" and read_group_gap() or 0)
    end
    return height
end

local function check_member(members, row)
    for _, member in ipairs(members) do
        if member == row then return true end
    end
    return false
end

local function read_group_end(rows, start)
    local members, last = rows[start].members, start
    for index = start + 1, #rows do
        if rows[index].kind == "heading" then return last end
        if not members or check_member(members, rows[index]) then last = index end
    end
    return last
end

local function update_fieldset(heading, last, inset)
    local lines, gap = heading.fieldset, math.max(3, library.read_size(-6))
    for _, line in pairs(lines) do line:ClearAllPoints() end
    lines.top_left:SetPoint("LEFT", heading, "LEFT", inset, 0)
    lines.top_left:SetPoint("RIGHT", heading.label, "LEFT", -gap, 0)
    lines.top_right:SetPoint("LEFT", heading.label, "RIGHT", gap, 0)
    lines.top_right:SetPoint("RIGHT", heading, "RIGHT", -inset, 0)
    lines.left:SetPoint("TOPLEFT", heading, "LEFT", inset, 0)
    lines.left:SetPoint("BOTTOMLEFT", last, "BOTTOMLEFT", 0, 0)
    lines.right:SetPoint("TOPRIGHT", heading, "RIGHT", -inset, 0)
    lines.right:SetPoint("BOTTOMRIGHT", last, "BOTTOMRIGHT", 0, 0)
    lines.bottom:SetPoint("BOTTOMLEFT", last, "BOTTOMLEFT")
    lines.bottom:SetPoint("BOTTOMRIGHT", last, "BOTTOMRIGHT")
    lines.top_left:SetHeight(1)
    lines.top_right:SetHeight(1)
    lines.bottom:SetHeight(1)
    lines.left:SetWidth(1)
    lines.right:SetWidth(1)
end

local function read_stripe_room(row)
    if not row.stripe then return 0 end
    return library.read_draft_size(STRIPE[1]) + library.read_draft_size(STRIPE[2])
end

function library.read_row_label_width(row)
    local words = math.max(row.label:GetStringWidth(), row.note and row.note:GetStringWidth() or 0)
    return words + read_stripe_room(row)
end

function library.read_rows_width(rows, column)
    local label, wide = 0, 0
    for _, row in ipairs(rows) do
        label = math.max(label, library.read_row_label_width(row))
        if row.kind == "wide" and row.control then wide = math.max(wide, library.read_pictures_width(row.control) + 3 * library.read_size(0)) end
    end
    return math.max(math.ceil(label) + column + 3 * library.read_size(0), wide)
end

function library.read_shown_rows(rows)
    local shown = {}
    for _, row in ipairs(rows) do
        if row:IsShown() then shown[#shown + 1] = row end
    end
    return shown
end

local function update_row_tick(row, pad)
    if not row.tick then return 0 end
    library.update_tick(row.tick)
    row.tick:ClearAllPoints()
    row.tick:SetPoint("RIGHT", row, "RIGHT", -pad, 0)
    return library.read_tick_room() + library.read_draft_size(TICK_GAP)
end

local function update_row_control(row, parent, pad, inset, column, width)
    local tick = update_row_tick(row, pad)
    if row.kind == "widget" then
        library.update_widget_row(row, pad)
    elseif row.control and row.kind == "wide" then
        row.control:ClearAllPoints()
        row.control:SetPoint("LEFT", row, "LEFT", pad, 0)
        library.update_pictures(row.control, (width or parent:GetWidth()) > 0 and (width or parent:GetWidth()) - 2 * inset - 2 * pad or nil)
    elseif row.control then
        local control = row.control
        control:ClearAllPoints()
        if control.buttons or control.stops or control.pictures then
            control:SetPoint("LEFT", row, "RIGHT", -pad - tick - column + (control.reach or 0), 0)
        else
            control:SetPoint("RIGHT", row, "RIGHT", -pad - tick, 0)
        end
        if row.eye then
            library.update_eye_layout(row.eye)
            row.eye:ClearAllPoints()
            row.eye:SetPoint("RIGHT", control, "LEFT", -pad / 2, 0)
        end
    end
end

function library.create_row_mark(row)
    row.mark = library.create_active_mark(row, row.label)
    return row.mark
end

local function update_row_look(row, left)
    if row.stripe then
        row.stripe:SetSize(library.read_draft_size(STRIPE[1]), library.read_size(2))
        row.stripe:ClearAllPoints()
        row.stripe:SetPoint("LEFT", row, "LEFT", left, 0)
    end
    left = left + read_stripe_room(row)
    if not row.note then return left end
    row.note:SetFontObject(library.read_font("small"))
    row.note:ClearAllPoints()
    row.note:SetPoint("TOPLEFT", row, "LEFT", left, -1)
    return left
end

local function update_row_label(row, pad, inset)
    row.label:SetFontObject(library.read_font(row.kind == "heading" and "small" or "body"))
    if row.kind == "heading" then row.label:SetTextColor(unpack(colours.quiet)) end
    row.label:ClearAllPoints()
    local left = row.kind == "heading" and inset + pad - math.max(3, library.read_size(-6)) or update_row_look(row, pad)
    row.label:SetPoint(row.note and "BOTTOMLEFT" or "LEFT", row, "LEFT", left, row.note and 1 or 0)
    if row.mark then library.update_active_mark(row.mark, true) end
end

local function update_cards(parent, runs)
    parent.cards = parent.cards or {}
    for index, run in ipairs(runs) do
        local card = parent.cards[index]
        if not card then
            card = CreateFrame("Frame", nil, parent)
            card:SetFrameLevel(math.max(parent:GetFrameLevel() - 1, 0))
            card.face = library.create_surface(card, "BACKGROUND", -8)
            parent.cards[index] = card
        end
        card:ClearAllPoints()
        card:SetPoint("TOPLEFT", run[1], "TOPLEFT")
        card:SetPoint("BOTTOMRIGHT", run[2], "BOTTOMRIGHT")
        card:Show()
        library.update_surface(card.face, 0, library.read_size(-4), CARD, CARD, CARD_ALPHA)
    end
    for index = #runs + 1, #parent.cards do parent.cards[index]:Hide() end
end

function library.update_rows(rows, parent, top, column, width)
    local pad, below = library.read_size(0), top
    local half = math.floor(pad / 2 + 0.5)
    rows = library.read_shown_rows(rows)
    local group_end, runs = 0, {}
    for index, row in ipairs(rows) do
        local height = library.read_row_height(row)
        local inset = (index <= group_end and row.kind ~= "heading") and half or 0
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", inset, -below)
        row:SetPoint("RIGHT", parent, "RIGHT", -inset, 0)
        row:SetHeight(height)
        below = below + height
        if row.kind == "heading" then
            group_end = read_group_end(rows, index)
            update_fieldset(row, rows[group_end], half)
        end
        update_row_label(row, pad, half)
        update_row_control(row, parent, pad, inset, column, width)
        row.line:ClearAllPoints()
        row.line:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", pad, 0)
        row.line:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -pad, 0)
        row.line:SetHeight(1)
        row.line:SetShown(index < #rows and index ~= group_end and row.kind ~= "heading")
        if index == group_end then below = below + read_group_gap() end
        local plain = row.kind ~= "heading" and index > group_end
        local run = runs[#runs]
        if plain and run and run.open then run[2] = row elseif plain then runs[#runs + 1] = { row, row, open = true } elseif run then run.open = false end
    end
    update_cards(parent, runs)
    return below
end
