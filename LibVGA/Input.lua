-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's one input, as the accepted catalogue draws it (manual/view/vga-catalogue.html, K0775) after the auctions' search bar and field (manual/view/vga-auctions.html .sbar, .input; K0740): a dark ground rounded 7 draft pixels inside a fine line of the same width at rest and while typed into, gold then (rule 29), 22 draft pixels high like every box of a row (K0774); its text in the body face, set in from the edges; a gold caret blinking where the game's own cursor stands, as the game tells it on every move, so with a long entry, which the game scrolls, it stays inside (K0739); a quiet hint while empty, a picture at its left where one is named, a clear button at its right where one is asked for, once there is text; at most so many letters, digits only where asked, centred where asked; Escape ends the typing, Enter hands the text to its owner and ends it, and the owner hears when the typing ends. The owner fills it - hint, picture, what a change or Enter does - and lays it by library.update_input with its width. An input the game makes itself, the chat's, wears the same skin and caret (library.create_input_skin).

-- {K0777} {K0740} {K0739} {K0774} {K0775}

local library = LibVGA
local colours = library.colours
local GROUND = { 0.031, 0.035, 0.043 }
local HEIGHT = 22
local RADIUS = 7
local PAD = 10
local PICTURE = 14
local GAP = 6
local BLINK = 0.5

local function update_look(input)
    local skin, typing = input.skin, input:HasFocus()
    local line, radius = typing and colours.gold or colours.edge, library.read_draft_size(RADIUS)
    library.update_surface(skin.ring, -1, radius + 1, line, line)
    library.update_surface(skin.ground, 0, radius, GROUND, GROUND)
    skin.caret.time = 0
    skin.caret:SetShown(typing)
end

local function read_caret_x(input, skin)
    if skin.cursor_x then return skin.cursor_x end
    skin.measure:SetText((input:GetText() or ""):sub(1, input:GetCursorPosition()))
    return library.read_string_width(skin.measure) + 1
end

local function update_caret(input, elapsed)
    local skin = input.skin
    if not input:HasFocus() then return end
    local caret = skin.caret
    caret.time = (caret.time or 0) + elapsed
    caret:SetAlpha(math.floor(caret.time / BLINK) % 2 == 0 and 1 or 0)
    local face, size = input:GetFont()
    if not face then return end
    skin.measure:SetFont(face, size, "")
    local left, right = input:GetTextInsets()
    local width = math.max(2, math.floor(size / 8 + 0.5))
    local most = input:GetWidth() - (right or 0) - width
    caret:SetSize(width, size)
    caret:ClearAllPoints()
    caret:SetPoint("LEFT", input, "LEFT", math.max(left or 0, math.min((left or 0) + read_caret_x(input, skin), most)), 0)
end

local function write_cursor(input, x)
    input.skin.cursor_x = x
end

function library.create_input_skin(input)
    local skin = CreateFrame("Frame", nil, input)
    skin:SetAllPoints()
    skin:SetFrameLevel(math.max(input:GetFrameLevel() - 1, 0))
    skin.ring = library.create_surface(skin, "BACKGROUND", 0)
    skin.ground = library.create_surface(skin, "BACKGROUND", 1)
    skin.caret = skin:CreateTexture(nil, "OVERLAY")
    skin.caret:SetColorTexture(colours.gold[1], colours.gold[2], colours.gold[3], 1)
    skin.caret:Hide()
    skin.measure = library.create_text(skin, "body")
    skin.measure:Hide()
    input.skin = skin
    input:HookScript("OnCursorChanged", write_cursor)
    input:HookScript("OnEditFocusGained", update_look)
    input:HookScript("OnEditFocusLost", update_look)
    skin:SetScript("OnUpdate", function(_, elapsed) library.update_safely("input caret", update_caret, input, elapsed) end)
    return skin
end

function library.update_input_skin(input)
    update_look(input)
end

local function update_shown(input)
    local empty = (input:GetText() or "") == ""
    input.hint:SetShown(empty)
    input.clear:SetShown(input.plan.clear and not empty or false)
end

local function render_changed(input, by_user)
    update_shown(input)
    if input.plan.on_change then input.plan.on_change(input, by_user) end
end

local function render_leave(input)
    if input.plan and input.plan.on_leave then input.plan.on_leave(input) end
end

local function render_enter(input)
    if input.plan.on_enter then input.plan.on_enter(input) end
    input:ClearFocus()
end

local function render_clear(button)
    local input = button:GetParent()
    input:SetText("")
    render_changed(input, true)
    input:ClearFocus()
end

local function create_clear(input)
    local clear = CreateFrame("Button", nil, input)
    clear.picture = clear:CreateTexture(nil, "ARTWORK")
    clear.picture:SetAllPoints()
    clear.picture:SetTexture(library.media .. "Clear")
    clear.picture:SetVertexColor(colours.quiet[1], colours.quiet[2], colours.quiet[3], 1)
    clear:SetScript("OnClick", render_clear)
    return clear
end

local function create_box(parent, plan)
    local input = CreateFrame("EditBox", nil, parent)
    input:SetAutoFocus(false)
    input:SetMaxLetters(plan.most or 0)
    input:SetNumeric(plan.numeric or false)
    input:SetJustifyH(plan.centred and "CENTER" or "LEFT")
    return input
end

function library.create_input(parent, plan)
    local input = create_box(parent, plan)
    input.plan = plan
    library.create_input_skin(input)
    input.picture = input:CreateTexture(nil, "ARTWORK")
    input.picture:SetVertexColor(colours.quiet[1], colours.quiet[2], colours.quiet[3], 1)
    input.hint = library.create_text(input, "small", colours.quiet)
    input.hint:SetWordWrap(false)
    input.hint:SetJustifyH("LEFT")
    input.clear = create_clear(input)
    input:SetScript("OnEscapePressed", input.ClearFocus)
    input:SetScript("OnEnterPressed", render_enter)
    input:HookScript("OnEditFocusLost", render_leave)
    input:SetScript("OnTextChanged", function(self, by_user) library.update_safely("input changed", render_changed, self, by_user) end)
    return input
end

local function read_insets(input, pad, picture, gap)
    local plan = input.plan
    local left = pad + (plan.picture and picture + gap or 0)
    local right = pad + (plan.clear and picture + gap or 0) + (input.room or 0)
    return left, right
end

local function update_parts(input, pad, picture, left, right)
    local plan = input.plan
    input.picture:SetShown(plan.picture ~= nil)
    input.picture:SetTexture(plan.picture and library.media .. plan.picture or nil)
    input.picture:SetSize(picture, picture)
    input.picture:ClearAllPoints()
    input.picture:SetPoint("LEFT", input, "LEFT", pad, 0)
    input.clear:SetSize(picture, picture)
    input.clear:ClearAllPoints()
    input.clear:SetPoint("RIGHT", input, "RIGHT", -(pad + (input.room or 0)), 0)
    input.hint:SetFontObject(library.read_font("small"))
    input.hint:SetText(plan.hint or "")
    input.hint:SetWidth(math.max(0, input:GetWidth() - left - right))
    input.hint:ClearAllPoints()
    input.hint:SetPoint("LEFT", input, "LEFT", left, 0)
end

function library.update_input(input, width)
    local draft = library.read_draft_size
    local pad, picture = draft(PAD), draft(PICTURE)
    input:SetFontObject(library.read_font("body"))
    input:SetSize(width, draft(HEIGHT))
    local left, right = read_insets(input, pad, picture, draft(GAP))
    input:SetTextInsets(left, right, 0, 0)
    update_parts(input, pad, picture, left, right)
    update_look(input)
    update_shown(input)
end
