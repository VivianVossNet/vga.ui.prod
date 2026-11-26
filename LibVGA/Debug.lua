-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's debug console, a meta-object (K0860) as the accepted draft draws it (manual/view/vga-debug.html B, K0919), grown from the debug dialog (K0917): LibVGA's dialog the size of the talk, 460 by 600 draft pixels, headed »Debug-Protokoll«, in the middle of the screen in front of everything; opened only by the red counter on the VGA badge or by a test writing into it (library.render_debug), never on its own. Its areas are objects of their own: a segmented choice Alle, Fehler, Blockiert, Tests with their counts and, at the right, how many are new; beneath, scrolling, LibVGA's debug rows (library.create_debug_row) for what the debug log gathered (LibVGA/Debuglog.lua), the last seen first, each opening on a click to its copyable field; its room reckoned from the dialog's own size, never asked of a frame not yet laid (K0918). The foot notes the entries and messages and carries »Leeren« and the gold »Alles markieren«, which shows every entry of the filter in one field, marked for Ctrl+C, until a filter is chosen or the field left by Escape. Opening it ends the badge's counter; closing it ends the gold strokes of the new. Test output goes here, never into the chat (K0917). One task: show the debug log.

-- {K0919} {K0918} {K0917} {K0860}

local library = LibVGA
local colours = library.colours
local WIDTH, HEIGHT = 460, 600
local SIDE, TOOLS = 12, 42
local FILTERS = { false, "error", "blocked", "test" }
local dialog, render_toggled

local function read_room()
    return library.read_draft_size(HEIGHT) - library.read_dialog_frame_height(dialog) - library.read_draft_size(TOOLS)
end

local function read_labels()
    local texts = library.texts
    local labels = { texts.debug_all }
    for index, name in ipairs({ texts.debug_errors, texts.debug_blocked, texts.debug_tests }) do
        labels[index + 1] = name .. " " .. #library.read_debug_entries(FILTERS[index + 1])
    end
    return labels
end

local function read_all_words(entries)
    local lines = {}
    for _, entry in ipairs(entries) do lines[#lines + 1] = string.format("[%s ×%d %s] %s", entry.last, entry.count, entry.source or "", entry.detail) end
    return table.concat(lines, "\n\n")
end

local function update_all_field(width, room)
    local field = dialog.all
    field:SetShown(dialog.marking == true)
    if not dialog.marking then return end
    field.words = read_all_words(dialog.shown)
    dialog.measure:SetFontObject(library.read_font("small"))
    dialog.measure:SetWidth(width)
    dialog.measure:SetText(field.words)
    field:SetFontObject(library.read_font("small"))
    field:SetText(field.words)
    field:SetSize(width, math.max(room, math.ceil(library.read_string_height(dialog.measure))))
    library.update_scroll(dialog.scroll, width, room, field:GetHeight())
    field:SetFocus()
    field:HighlightText()
end

local function update_rows(width, room)
    local laid, length = {}, 0
    for index, entry in ipairs(dialog.marking and {} or dialog.shown) do
        local row = dialog.rows[index] or library.create_debug_row(dialog.scroll.content, function(self) library.update_safely("debug opened", render_toggled, self) end)
        dialog.rows[index] = row
        row.open = dialog.opened[entry] == true
        local high, deep = library.update_debug_row(row, entry, width)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", dialog.scroll.content, "TOPLEFT", 0, -length)
        row.detail:ClearAllPoints()
        row.detail:SetPoint("TOPLEFT", row, "BOTTOMLEFT")
        row:Show()
        length = length + high + deep
        laid[#laid + 1] = row
    end
    for index = #laid + 1, #dialog.rows do
        dialog.rows[index]:Hide()
        dialog.rows[index].detail:Hide()
    end
    if not dialog.marking then library.update_scroll(dialog.scroll, width, room, length) end
end

local function update_tools(width)
    local side = library.read_draft_size(SIDE)
    library.update_choice_labels(dialog.choice, read_labels(), dialog.choice.chosen or 1)
    library.update_choice(dialog.choice)
    dialog.choice:ClearAllPoints()
    dialog.choice:SetPoint("LEFT", dialog.body, "TOPLEFT", side, -library.read_draft_size(TOOLS) / 2)
    local new = library.read_debug_new()
    dialog.new_note:SetText(string.format(library.texts.debug_new, new))
    dialog.new_note:SetShown(new > 0)
    dialog.new_note:ClearAllPoints()
    dialog.new_note:SetPoint("RIGHT", dialog.body, "TOPRIGHT", -side, -library.read_draft_size(TOOLS) / 2)
    dialog.tools_line:ClearAllPoints()
    dialog.tools_line:SetPoint("TOPLEFT", dialog.body, "TOPLEFT", 0, -library.read_draft_size(TOOLS))
    dialog.tools_line:SetSize(width, 1)
end

local function update_note()
    local messages = 0
    for _, entry in ipairs(library.read_debug_entries()) do messages = messages + entry.count end
    library.update_dialog_foot(dialog, string.format(library.texts.debug_note, #library.read_debug_entries(), messages))
end

local function update_console()
    if not (dialog and dialog:IsShown()) then return end
    local width, room = library.read_draft_size(WIDTH) - 2 * library.read_size(-4), read_room()
    dialog:SetSize(library.read_draft_size(WIDTH), library.read_draft_size(HEIGHT))
    library.update_dialog(dialog)
    dialog.shown = library.read_debug_entries(FILTERS[dialog.choice.chosen or 1] or nil)
    update_tools(width)
    dialog.scroll:ClearAllPoints()
    dialog.scroll:SetPoint("TOPLEFT", dialog.body, "TOPLEFT", 0, -library.read_draft_size(TOOLS) - 1)
    update_rows(width, room)
    update_all_field(width, room)
    update_note()
end

function render_toggled(row)
    dialog.opened[row.entry] = not dialog.opened[row.entry]
    update_console()
end

local function render_filtered(index)
    dialog.choice.chosen, dialog.marking = index, false
    update_console()
end

local function render_marked()
    dialog.marking = true
    update_console()
end

local function render_emptied()
    dialog.marking, dialog.opened = false, {}
    library.write_debug_cleared()
end

local function update_all_left(field, by_user)
    if by_user then field:SetText(field.words or "") end
end

local function render_all_ended()
    dialog.marking = false
    update_console()
end

local function create_all_field(parent)
    local field = CreateFrame("EditBox", nil, parent)
    field:SetMultiLine(true)
    field:SetAutoFocus(false)
    field:SetTextColor(colours.ink[1], colours.ink[2], colours.ink[3], 1)
    field:SetPoint("TOPLEFT", parent, "TOPLEFT")
    field:SetScript("OnEscapePressed", function() library.update_safely("debug all ended", render_all_ended) end)
    field:SetScript("OnTextChanged", function(self, by_user) library.update_safely("debug all kept", update_all_left, self, by_user) end)
    field:Hide()
    return field
end

local function create_console()
    local texts = library.texts
    dialog = library.create_dialog("VGADebug", texts.debug_title, { buttons = { { texts.debug_clear, "plain", render_emptied }, { texts.debug_mark, "gold", render_marked } } })
    dialog.rows, dialog.opened, dialog.shown = {}, {}, {}
    dialog.choice = library.create_choice(dialog.body, { texts.debug_all }, 1, function(index) library.update_safely("debug filter", render_filtered, index) end)
    dialog.choice.natural = true
    dialog.new_note = library.create_text(dialog.body, "small", colours.quiet)
    dialog.tools_line = library.create_hairline(dialog.body)
    dialog.scroll = library.create_scroll(dialog.body)
    dialog.all = create_all_field(dialog.scroll.content)
    dialog.measure = library.create_text(dialog.body, "small", colours.ink)
    dialog.measure:SetWordWrap(true)
    dialog.measure:Hide()
    dialog:HookScript("OnHide", function() library.update_safely("debug seen", library.update_debug_seen) end)
    dialog:Hide()
    library.create_debug_listener(update_console)
end

function library.render_debug_opened()
    if not dialog then create_console() end
    if not dialog:IsShown() then
        dialog:ClearAllPoints()
        dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    dialog:Show()
    dialog:Raise()
    library.update_debug_opened()
    update_console()
end

function library.render_debug(message)
    library.write_debug("test", library.texts.debug_test, message, tostring(message))
    library.render_debug_opened()
end

function library.read_debug()
    return dialog
end
