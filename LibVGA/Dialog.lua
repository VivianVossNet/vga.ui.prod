-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's dialog as the accepted drafts draw it (manual/view/vga-scale.html .dlg, vga-template.css .vt): the metal frame, the head with the mark, the gold title and the close button, further buttons of the same make with an icon to its left where a dialog asks for them, its rows divided by hairlines; always free to move, its ground down to a floor. Rows that stand together outside a fieldset stand on one rounded, faintly lighter card, in the way of the macOS System Settings (K0565). A stepper in a row is measured as it is laid (K0721). The dialog opened or clicked last stands in front of every other, whole, so no two dialogs interleave (K0737). A row may carry a mark before its label - the elite's chevron turned to point right at the label, four draft pixels before it, in a colour of the library's -, standing in the row's inset so the label never moves; the profiles mark the active one so in orange (K0729).

-- {K0256} {K0296} {K0299} {K0324} {K0330} {K0337} {K0415} {K0565} {K0721} {K0729} {K0737}

local library = LibVGA
local CARD = { 1, 1, 1 }
local CARD_ALPHA = 0.04
local colours = library.colours
local BLACK = { 0, 0, 0 }
local CLOSE_TOP = { 0.227, 0.239, 0.267 }
local CLOSE_BOTTOM = { 0.118, 0.125, 0.145 }
local HAIRLINE = { 0.137, 0.149, 0.173 }
local FIELDSET = { 0.235, 0.247, 0.282 }
local FIELDSET_LINES = { "top_left", "top_right", "left", "right", "bottom" }

local function create_head_button(dialog, on_click)
    local button = CreateFrame("Button", nil, dialog)
    button.ring = library.create_surface(button, "BACKGROUND", 0)
    button.face = library.create_surface(button, "BACKGROUND", 1)
    button.light = button:CreateTexture(nil, "BORDER")
    button.light:SetColorTexture(1, 1, 1, 0.12)
    button:SetScript("OnClick", on_click)
    return button
end

local function update_head_button(button, size)
    button:SetSize(size, size)
    local radius = library.read_size(-6)
    library.update_surface(button.ring, -1, radius + 1, BLACK, BLACK)
    library.update_surface(button.face, 0, radius, CLOSE_TOP, CLOSE_BOTTOM)
    button.light:ClearAllPoints()
    button.light:SetPoint("TOPLEFT", radius, 0)
    button.light:SetPoint("TOPRIGHT", -radius, 0)
    button.light:SetHeight(1)
    if button.icon then
        button.icon:SetSize(math.floor(size * 0.7 + 0.5), math.floor(size * 0.7 + 0.5))
        button.icon:SetPoint("CENTER")
    end
end

local function create_close(dialog)
    local close = create_head_button(dialog, function() dialog:Hide() end)
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
    local button = create_head_button(dialog, on_click)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetTexture(library.media .. icon)
    dialog.head_buttons = dialog.head_buttons or {}
    dialog.head_buttons[#dialog.head_buttons + 1] = button
    return button
end

local function update_close(close, size)
    update_head_button(close, size)
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

function library.create_dialog(name, title)
    local dialog = CreateFrame("Frame", name, UIParent)
    dialog:SetFrameStrata("DIALOG")
    dialog:SetToplevel(true)
    dialog:HookScript("OnShow", update_raised)
    dialog:SetClampedToScreen(true)
    dialog:SetMovable(true)
    dialog:EnableMouse(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", dialog.StartMoving)
    dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
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
    dialog.body = CreateFrame("Frame", nil, dialog)
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
        update_head_button(button, mark)
        button:ClearAllPoints()
        button:SetPoint("RIGHT", beside, "LEFT", -library.read_size(-4), 0)
        beside = button
    end
    dialog.body:ClearAllPoints()
    dialog.body:SetPoint("TOPLEFT", dialog.head, "BOTTOMLEFT", 0, -1)
    dialog.body:SetPoint("BOTTOMRIGHT", -inner, inner)
end

function library.create_row(parent, label, kind)
    local row = CreateFrame("Frame", nil, parent)
    row.kind = kind
    row.label = library.create_text(row, kind == "heading" and "small" or "body")
    row.label:SetText(kind == "heading" and label:upper() or label)
    if kind == "heading" then
        row.fieldset = {}
        for _, name in ipairs(FIELDSET_LINES) do
            row.fieldset[name] = row:CreateTexture(nil, "BORDER")
            row.fieldset[name]:SetColorTexture(FIELDSET[1], FIELDSET[2], FIELDSET[3], 1)
        end
    end
    row.line = row:CreateTexture(nil, "BACKGROUND")
    row.line:SetColorTexture(HAIRLINE[1], HAIRLINE[2], HAIRLINE[3], 1)
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

function library.read_rows_width(rows, column)
    local label, wide = 0, 0
    for _, row in ipairs(rows) do
        label = math.max(label, row.label:GetStringWidth())
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

local function update_row_control(row, parent, pad, inset, column, width)
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
            control:SetPoint("LEFT", row, "RIGHT", -pad - column + (control.reach or 0), 0)
        else
            control:SetPoint("RIGHT", row, "RIGHT", -pad, 0)
        end
        if row.eye then
            library.update_eye_layout(row.eye)
            row.eye:ClearAllPoints()
            row.eye:SetPoint("RIGHT", control, "LEFT", -pad / 2, 0)
        end
    end
end

function library.create_row_mark(row, colour)
    row.mark = row:CreateTexture(nil, "ARTWORK")
    row.mark:SetTexture(library.media .. "Chevron")
    row.mark:SetRotation(-math.pi / 2)
    row.mark:SetVertexColor(colours[colour][1], colours[colour][2], colours[colour][3], 1)
    return row.mark
end

local function update_row_mark(row)
    local size = library.read_size(-4)
    row.mark:SetSize(size, size)
    row.mark:ClearAllPoints()
    row.mark:SetPoint("RIGHT", row.label, "LEFT", -library.read_draft_size(4), 0)
end

local function update_row_label(row, pad, inset)
    row.label:SetFontObject(library.read_font(row.kind == "heading" and "small" or "body"))
    if row.kind == "heading" then row.label:SetTextColor(unpack(colours.quiet)) end
    row.label:ClearAllPoints()
    row.label:SetPoint("LEFT", row, "LEFT", row.kind == "heading" and inset + pad - math.max(3, library.read_size(-6)) or pad, 0)
    if row.mark then update_row_mark(row) end
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
