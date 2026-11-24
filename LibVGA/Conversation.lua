-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's conversation, as the accepted draft draws it (manual/view/vga-npc-chat.html, K0840): the course of a talk in a scroll, written from the top as a real dialogue and following the newest once it is longer than its room. The figure speaks at the left in LibVGA's bubbles with its round portrait ringed in silver, the player at the right in gold with the player's ringed in gold, each ring two draft pixels inside a black line, as the draft draws .face (library.update_portrait_cell, K0858); long words are cut at their sentences into bubbles of at most three lines, only the first of them beside the portrait. A card - a quest's - never stands in the course: it belongs with the answers beneath the line, where its owner lays it (K0859, before in the course, K0856). A done thing, as »Quest angenommen«, stands with the green tick in a green bubble of its own without a tail, across the course from side to side, its words centred (K0859). Its owner writes, clears and lays it; the conversation keeps the entries and draws them anew at each laying, so a change of size lays every bubble again. Paced, where its owner asks for immersion, the figure sends its bubbles one by one - a paragraph always a bubble of its own -, each next one after the last has been read at twenty-five letters a second, typing dots in a small parchment bubble meanwhile, the player's words and the ticks at once; a click in the course shows everything; read_conversation_done tells its owner when all is shown, so the answers may follow (K0844).

-- {K0859} {K0858} {K0856} {K0844} {K0840}

local library = LibVGA
local colours = library.colours
local FACE = 28
local FACE_GAP = 8
local GAP = 8
local FOLLOW_GAP = 4
local SIDE = 16
local TOP = 12
local MOST = 320
local MOST_PLAYER = 300
local TICK_ABOVE = 6
local TICK_GAP = 6
local LINES = 3
local UNITS = { left = "npc", right = "player" }
local PACE = 25
local SHORTEST_WAIT = 0.4
local TYPING_WIDTH = 56
local DOT = 6
local DOT_GAP = 5
local DOT_SPEED = 7.5
local DOT_LAG = 0.6
local DOT_FAINT = 0.35

function library.create_conversation(parent)
    local conversation = { entries = {}, bubbles = {}, faces = {}, ticks = {} }
    conversation.scroll = library.create_scroll(parent)
    conversation.probe = library.create_text(conversation.scroll.content, "body")
    conversation.probe:Hide()
    conversation.probe:SetWordWrap(true)
    conversation.scroll:EnableMouse(true)
    conversation.scroll:SetScript("OnMouseDown", function() library.update_safely("conversation shown whole", library.render_conversation_whole, conversation) end)
    conversation.laid = 0
    return conversation
end

function library.update_conversation_cleared(conversation)
    conversation.entries = {}
    conversation.laid, conversation.visible, conversation.waiting = 0, nil, nil
end

function library.update_conversation_paced(conversation, paced)
    conversation.paced = paced
end

function library.read_conversation_done(conversation)
    return not conversation.more
end

function library.render_conversation_whole(conversation)
    if not conversation.more then return end
    conversation.visible, conversation.waiting = nil, nil
    if conversation.on_change then conversation.on_change() end
end

function library.write_conversation_words(conversation, side, words)
    if not words or words == "" then return end
    if conversation.paced and side == "left" and not conversation.visible then conversation.visible = conversation.laid end
    conversation.entries[#conversation.entries + 1] = { side = side, words = words }
end

function library.write_conversation_tick(conversation, words)
    conversation.entries[#conversation.entries + 1] = { tick = words }
end

local function read_paragraphs(words)
    local paragraphs = {}
    for paragraph in (words:gsub("\r", "") .. "\n"):gmatch("(.-)\n") do
        local sentences = {}
        local marked = paragraph:gsub("([%.!%?])%s+", "%1\1")
        for sentence in (marked .. "\1"):gmatch("(.-)\1") do
            if sentence:find("%S") then sentences[#sentences + 1] = sentence end
        end
        if #sentences > 0 then paragraphs[#paragraphs + 1] = sentences end
    end
    return paragraphs
end

local function read_lines_high(conversation, words, inside)
    local probe = conversation.probe
    probe:SetFontObject(library.read_font("body"))
    probe:SetWidth(inside)
    probe:SetText(words)
    return library.read_string_height(probe)
end

local function read_pieces(conversation, words, most)
    local inside = library.read_bubble_text_width(most)
    local most_high = LINES * library.read_sample_height(library.read_font("body"), "Ag") + 1
    local pieces = {}
    for _, sentences in ipairs(read_paragraphs(words)) do
        local held
        for _, sentence in ipairs(sentences) do
            local joined = held and held .. " " .. sentence or sentence
            if held and read_lines_high(conversation, joined, inside) > most_high then
                pieces[#pieces + 1] = held
                held = sentence
            else
                held = joined
            end
        end
        pieces[#pieces + 1] = held
    end
    return pieces
end

local function create_face(parent)
    return library.create_cell(parent, { kind = "round", frame = "Frame", portrait = true })
end

local function create_tick_line(parent)
    local line = CreateFrame("Frame", nil, parent)
    line.bubble = library.create_bubble(line)
    line.bubble:SetAllPoints()
    line.tick = library.create_tick(line.bubble)
    line.words = line.bubble.words
    return line
end

local function read_pool(pool, index, make, parent)
    pool[index] = pool[index] or make(parent)
    pool[index]:Show()
    return pool[index]
end

local function update_face(face, side)
    local size = library.read_draft_size(FACE)
    face:SetSize(size, size)
    library.update_portrait_cell(face, side == "right")
    face.unit = UNITS[side]
    if SetPortraitTexture then SetPortraitTexture(face.icon, face.unit) end
end

function library.update_conversation_faces(conversation)
    for _, face in ipairs(conversation.faces) do
        if face:IsShown() and face.unit and SetPortraitTexture then SetPortraitTexture(face.icon, face.unit) end
    end
end

local function read_letters(words)
    return #(words:gsub("[\128-\191]", ""))
end

local function check_room(conversation, used, waits)
    local limit = conversation.visible
    if not limit or used.items < limit then return true end
    if waits and used.said then return false end
    conversation.visible = limit + 1
    return true
end

local function update_revealed(conversation, token)
    if conversation.waiting ~= token then return end
    conversation.waiting = nil
    if conversation.visible then conversation.visible = conversation.visible + 1 end
    if conversation.on_change then conversation.on_change() end
end

local function update_waiting(conversation, said)
    if conversation.waiting then return end
    conversation.token = (conversation.token or 0) + 1
    local token = conversation.token
    conversation.waiting = token
    local wait = math.max(SHORTEST_WAIT, read_letters(said) / PACE)
    C_Timer.After(wait, function() library.update_safely("conversation paced", update_revealed, conversation, token) end)
end

local function update_dots(typing, elapsed)
    typing.time = (typing.time or 0) + elapsed
    for index, dot in ipairs(typing.dots) do
        local wave = 0.5 + 0.5 * math.sin(typing.time * DOT_SPEED - index * DOT_LAG)
        dot:SetAlpha(DOT_FAINT + (1 - DOT_FAINT) * wave)
    end
end

local function create_typing(parent)
    local typing = library.create_bubble(parent)
    typing.dots = {}
    for index = 1, 3 do
        local dot = CreateFrame("Frame", nil, typing)
        dot.face = library.create_surface(dot, "ARTWORK", 0)
        typing.dots[index] = dot
    end
    typing:SetScript("OnUpdate", update_dots)
    return typing
end

local function write_typing(conversation, width, top)
    conversation.typing = conversation.typing or create_typing(conversation.scroll.content)
    local typing = conversation.typing
    local face_room = library.read_draft_size(FACE) + library.read_draft_size(FACE_GAP)
    local _, height = library.update_bubble(typing, "", "left", library.read_draft_size(TYPING_WIDTH))
    typing:SetWidth(library.read_draft_size(TYPING_WIDTH))
    local size, gap = library.read_draft_size(DOT), library.read_draft_size(DOT_GAP)
    local start = (library.read_draft_size(TYPING_WIDTH) - 3 * size - 2 * gap) / 2
    for index, dot in ipairs(typing.dots) do
        dot:SetSize(size, size)
        library.update_surface(dot.face, 0, size / 2, { 0.165, 0.118, 0.055 }, { 0.165, 0.118, 0.055 })
        dot:ClearAllPoints()
        dot:SetPoint("LEFT", typing, "LEFT", start + (index - 1) * (size + gap), 0)
    end
    typing:ClearAllPoints()
    typing:SetPoint("TOPLEFT", conversation.scroll.content, "TOPLEFT", library.read_draft_size(SIDE) + face_room, -top)
    typing:Show()
    return top + height
end

local function write_words(conversation, entry, width, top, used)
    local content, right = conversation.scroll.content, entry.side == "right"
    local face_room = library.read_draft_size(FACE) + library.read_draft_size(FACE_GAP)
    local most = math.min(library.read_draft_size(right and MOST_PLAYER or MOST), width - 2 * library.read_draft_size(SIDE) - face_room)
    for index, piece in ipairs(read_pieces(conversation, entry.words, most)) do
        if not check_room(conversation, used, not right) then
            used.stopped = true
            return top - library.read_draft_size(FOLLOW_GAP) * (index > 1 and 1 or 0), index > 1
        end
        used.items = used.items + 1
        used.said = not right and piece or nil
        used.bubbles = used.bubbles + 1
        local bubble = read_pool(conversation.bubbles, used.bubbles, library.create_bubble, content)
        local bubble_width, bubble_height = library.update_bubble(bubble, piece, entry.side, most)
        local x = right and width - library.read_draft_size(SIDE) - face_room - bubble_width or library.read_draft_size(SIDE) + face_room
        bubble:ClearAllPoints()
        bubble:SetPoint("TOPLEFT", content, "TOPLEFT", x, -top)
        if index == 1 then
            used.faces = used.faces + 1
            local face = read_pool(conversation.faces, used.faces, create_face, content)
            update_face(face, entry.side)
            face:ClearAllPoints()
            local face_x = right and width - library.read_draft_size(SIDE) - library.read_draft_size(FACE) or library.read_draft_size(SIDE)
            face:SetPoint("BOTTOMLEFT", content, "TOPLEFT", face_x, -top - bubble_height)
        end
        top = top + bubble_height + library.read_draft_size(FOLLOW_GAP)
    end
    return top - library.read_draft_size(FOLLOW_GAP), true
end

local function write_tick(conversation, entry, width, top, used)
    check_room(conversation, used, false)
    used.items, used.said = used.items + 1, nil
    used.ticks = used.ticks + 1
    local content = conversation.scroll.content
    local line = read_pool(conversation.ticks, used.ticks, create_tick_line, content)
    library.update_tick(line.tick)
    library.update_tick_kept(line.tick, colours.dark_green)
    line.words:SetFontObject(library.read_font("caption"))
    line.words:SetTextColor(colours.dark_green[1], colours.dark_green[2], colours.dark_green[3], 1)
    line.words:SetWidth(0)
    line.words:SetText(entry.tick)
    local room, gap, side = library.read_tick_room(), library.read_draft_size(TICK_GAP), library.read_draft_size(SIDE)
    local across = width - 2 * side
    local wide = math.min(room + gap + math.ceil(library.read_string_width(line.words)), across)
    local height = math.max(room, math.ceil(library.read_string_height(line.words))) + 2 * library.read_draft_size(TICK_ABOVE)
    line:SetSize(across, height)
    library.update_bubble_ground(line.bubble, across, height, nil, colours.parchment_green)
    line.tick:ClearAllPoints()
    line.tick:SetPoint("LEFT", line.bubble, "LEFT", math.floor((across - wide) / 2), 0)
    line.words:SetWidth(wide - room - gap)
    line.words:ClearAllPoints()
    line.words:SetPoint("LEFT", line.tick, "RIGHT", gap, 0)
    line:ClearAllPoints()
    line:SetPoint("TOPLEFT", content, "TOPLEFT", side, -top)
    return top + height, true
end

local function update_unused(pool, used)
    for index = used + 1, #pool do pool[index]:Hide() end
end

local function write_entries(conversation, width, used)
    local top = library.read_draft_size(TOP)
    for index, entry in ipairs(conversation.entries) do
        local gap = index > 1 and library.read_draft_size(GAP) or 0
        local placed
        if entry.tick then top, placed = write_tick(conversation, entry, width, top + gap, used)
        else top, placed = write_words(conversation, entry, width, top + gap, used) end
        if not placed then top = top - gap end
        if used.stopped then return top, placed and library.read_draft_size(FOLLOW_GAP) or gap end
    end
    return top, 0
end

function library.update_conversation(conversation, width, room)
    local used = { bubbles = 0, faces = 0, ticks = 0, items = 0 }
    local top, gap = write_entries(conversation, width, used)
    conversation.more = used.stopped
    if used.stopped then
        top = write_typing(conversation, width, top + gap)
        update_waiting(conversation, used.said or "")
    else
        conversation.laid = used.items
        if conversation.typing then conversation.typing:Hide() end
    end
    update_unused(conversation.bubbles, used.bubbles)
    update_unused(conversation.faces, used.faces)
    update_unused(conversation.ticks, used.ticks)
    local length = top + library.read_draft_size(TOP)
    library.update_scroll(conversation.scroll, width, room, length)
    library.update_scrolled(conversation.scroll, length)
end
