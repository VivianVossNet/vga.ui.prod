-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's debug row, one entry of the debug console as the accepted draft draws it (manual/view/vga-debug.html B, K0919): a button thirty draft pixels high on a faint ground of its kind - red for an error, a muted gold for a blocked action, none for a message -, a chevron pointing right, down when open, a small disc of its kind with »!« or »i«, the text in a light shade of its kind ended in »…«, its source quiet beside it, the counter as LibVGA's chip of its kind and the time last seen; a gold stroke at its left while it is new. Open, beneath it, the whole text and its stack in a field of its own in LibVGA's input skin, laid above the detail's ground so its frame shows (K0920), that can be read and marked but not changed, the first and last time beneath and »Markieren«, which marks the field for Ctrl+C. Its owner gives it the entry and the width and hears a click; it gives back its height. One task: show one entry.

-- {K0920} {K0919}

local library = LibVGA
local colours = library.colours
local ROW, DISC, CHEVRON, STROKE = 30, 14, 10, 2
local SIDE, GAP, FIELD_PAD, INDENT = 12, 8, 10, 44
local KINDS = {
    error = { chip = "red", ground = { 0.886, 0.404, 0.353, 0.06 }, ink = { 0.941, 0.702, 0.667 }, sign = "!" },
    blocked = { chip = "gold", ground = { 0.894, 0.718, 0.314, 0.05 }, ink = { 0.918, 0.831, 0.604 }, sign = "!" },
    test = { chip = "blue", ink = { 0.788, 0.773, 0.737 }, sign = "i" },
}

local function update_field_kept(field, by_user)
    if by_user then field:SetText(field.words or "") end
end

local function render_marked(button)
    local field = button:GetParent().field
    field:SetFocus()
    field:HighlightText()
end

local function create_detail(row)
    local detail = CreateFrame("Frame", nil, row:GetParent())
    detail.ground = detail:CreateTexture(nil, "BACKGROUND")
    detail.ground:SetAllPoints()
    detail.ground:SetColorTexture(0.031, 0.035, 0.043, 1)
    detail.field = CreateFrame("EditBox", nil, detail)
    detail.field:SetMultiLine(true)
    detail.field:SetAutoFocus(false)
    detail.field:SetFrameLevel(detail:GetFrameLevel() + 2)
    detail.field:SetTextInsets(library.read_draft_size(FIELD_PAD), library.read_draft_size(FIELD_PAD), library.read_draft_size(FIELD_PAD), library.read_draft_size(FIELD_PAD))
    library.create_input_skin(detail.field)
    detail.field:SetScript("OnEscapePressed", detail.field.ClearFocus)
    detail.field:SetScript("OnTextChanged", function(self, by_user) library.update_safely("debug field kept", update_field_kept, self, by_user) end)
    detail.measure = library.create_text(detail, "small", colours.ink)
    detail.measure:SetWordWrap(true)
    detail.measure:Hide()
    detail.times = library.create_text(detail, "small", colours.quiet)
    detail.mark = library.create_button(detail, library.texts.debug_mark_one, "plain", render_marked)
    return detail
end

function library.create_debug_row(parent, on_click)
    local row = CreateFrame("Button", nil, parent)
    row.ground = row:CreateTexture(nil, "BACKGROUND")
    row.ground:SetAllPoints()
    row.stroke = row:CreateTexture(nil, "ARTWORK")
    row.stroke:SetColorTexture(colours.gold[1], colours.gold[2], colours.gold[3], 1)
    row.chevron = row:CreateTexture(nil, "ARTWORK")
    row.chevron:SetTexture(library.media .. "NaviChevron")
    row.chevron:SetTexCoord(0, 1, 0.25, 0.75)
    row.chevron:SetVertexColor(colours.quiet[1], colours.quiet[2], colours.quiet[3], 1)
    row.disc = row:CreateTexture(nil, "ARTWORK")
    row.disc:SetTexture(library.media .. "Disc")
    row.sign = library.create_text(row, "small", colours.ground)
    row.text = library.create_text(row, "small", colours.ink)
    row.text:SetWordWrap(false)
    row.text:SetJustifyH("LEFT")
    row.source = library.create_text(row, "small", colours.quiet)
    row.count = library.create_chip(row)
    row.time = library.create_text(row, "small", colours.quiet)
    row.line = library.create_hairline(row)
    row.detail = create_detail(row)
    row:SetScript("OnClick", on_click)
    return row
end

local function update_look(row, entry, look)
    local ground = look.ground or { 0, 0, 0, 0 }
    row.ground:SetColorTexture(ground[1], ground[2], ground[3], ground[4])
    row.stroke:SetShown(entry.new == true)
    local disc = library.read_chip_colour(look.chip)
    row.disc:SetVertexColor(disc[1], disc[2], disc[3], 1)
    row.sign:SetText(look.sign)
    row.text:SetText(entry.text:match("^[^\n]*"))
    row.text:SetTextColor(look.ink[1], look.ink[2], look.ink[3], 1)
    row.source:SetText(entry.source or "")
    library.update_chip(row.count, look.chip, nil, tostring(entry.count))
    row.time:SetText(entry.last or "")
    row.chevron:SetRotation(row.open and math.pi or -math.pi / 2)
end

local function update_parts(row, width)
    local draft, height = library.read_draft_size, library.read_draft_size(ROW)
    local side, gap, disc, chevron = draft(SIDE), draft(GAP), draft(DISC), draft(CHEVRON)
    row:SetSize(width, height)
    row.stroke:ClearAllPoints()
    row.stroke:SetPoint("TOPLEFT")
    row.stroke:SetPoint("BOTTOMLEFT")
    row.stroke:SetWidth(draft(STROKE))
    row.chevron:SetSize(chevron, math.floor(chevron / 2 + 0.5))
    row.chevron:ClearAllPoints()
    row.chevron:SetPoint("LEFT", row, "LEFT", side, 0)
    row.disc:SetSize(disc, disc)
    row.disc:ClearAllPoints()
    row.disc:SetPoint("LEFT", row.chevron, "RIGHT", gap, 0)
    row.sign:SetPoint("CENTER", row.disc, "CENTER", 0, 0)
    row.time:ClearAllPoints()
    row.time:SetPoint("RIGHT", row, "RIGHT", -side, 0)
    row.count:ClearAllPoints()
    row.count:SetPoint("RIGHT", row.time, "LEFT", -gap, 0)
    row.source:ClearAllPoints()
    row.source:SetPoint("RIGHT", row.count, "LEFT", -gap, 0)
    row.text:ClearAllPoints()
    row.text:SetPoint("LEFT", row.disc, "RIGHT", gap, 0)
    row.text:SetPoint("RIGHT", row.source, "LEFT", -gap, 0)
    row.line:ClearAllPoints()
    row.line:SetPoint("BOTTOMLEFT")
    row.line:SetPoint("BOTTOMRIGHT")
    row.line:SetHeight(1)
end

local function update_detail(row, entry, width)
    local detail, draft = row.detail, library.read_draft_size
    detail:SetShown(row.open == true)
    if not row.open then return 0 end
    local inner, pad, gap = width - draft(INDENT) - draft(SIDE), draft(FIELD_PAD), draft(GAP)
    detail.measure:SetFontObject(library.read_font("small"))
    detail.measure:SetWidth(inner - 2 * pad)
    detail.measure:SetText(entry.detail)
    local field = math.ceil(library.read_string_height(detail.measure)) + 2 * pad
    detail.field:SetFontObject(library.read_font("small"))
    detail.field.words = entry.detail
    detail.field:SetText(entry.detail)
    detail.field:SetSize(inner, field)
    library.update_input_skin(detail.field)
    detail.field:ClearAllPoints()
    detail.field:SetPoint("TOPLEFT", detail, "TOPLEFT", draft(INDENT), -gap)
    library.update_button(detail.mark)
    detail.mark:ClearAllPoints()
    detail.mark:SetPoint("TOPRIGHT", detail.field, "BOTTOMRIGHT", 0, -gap)
    detail.times:SetText(string.format(library.texts.debug_times, entry.first, entry.last))
    detail.times:ClearAllPoints()
    detail.times:SetPoint("LEFT", detail.field, "BOTTOMLEFT", 0, -gap - detail.mark:GetHeight() / 2)
    local height = gap + field + gap + detail.mark:GetHeight() + gap
    detail:SetSize(width, height)
    return height
end

function library.update_debug_row(row, entry, width)
    row.entry = entry
    local look = KINDS[entry.kind] or KINDS.test
    update_parts(row, width)
    update_look(row, entry, look)
    return row:GetHeight(), update_detail(row, entry, width)
end
