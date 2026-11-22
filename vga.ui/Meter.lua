-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.ui's damage meter as the accepted draft draws variant A (manual/view/vga-meter.html, K0721): one widget in the quest tracker's look - its ground, its gold corner, a head with the mark, the chosen type in the tracker's gold and at the right the fight with its time -, beneath it a row per player as a bar in the class's colour, the raid cell's gradient darkened to 55 and 45 per cent, rank, name, amount and, quieter, the second figure; the own row with the gold edge at the left and its rank in gold; alone, the player's own spells beneath the own row; more players than rows, the own row added with its real rank behind a dotted line, the wheel scrolling, a foot naming how many and the total. The figures come from the game's own meter, C_DamageMeter: plain they are written short - whole below 10 000, three places with k or M above -, secret in an instance's fight they are handed to the game as they come. No menu of its own: the head's words and the gold corner open the meter's page of the one settings dialog - type and fight as pop-up menus, rows, the second figure, what it does out of combat, its widget row, and »Alle Kämpfe löschen …«. It starts in the screen's top left corner, 8 draft pixels from the top and from the left. The game's own meter window is hidden and kept hidden whenever the game shows it again; its data still come (K0722).

-- {K0721} {K0722}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local WIDTH = 220
local ROW = 18
local SPELL_ROW = 16
local ROW_GAP = 2
local SIDE = 6
local RANK = 14
local SECOND = 34
local CELL_GAP = 6
local ICON = 12
local EDGE = 2
local MARK = 16
local CORNER_GAP = 8
local ROWS_DEFAULT, ROWS_LEAST, ROWS_MOST = 8, 3, 15
local BAR_LEFT, BAR_RIGHT = 0.55, 0.45
local SPELL_LEFT, SPELL_RIGHT = 0.38, 0.30
local FAINT = 0.5
local REFRESH = 0.5
local TITLE = { 0.945, 0.812, 0.431 }
local GOLD_RANK = { 0.945, 0.812, 0.431 }
local SECOND_INK = { 0.839, 0.824, 0.792 }
local ROW_GROUND = { 0.031, 0.035, 0.043 }
local CUT = { 1, 1, 1, 0.19 }
local SESSIONS = { current = 1, overall = 0 }
local TYPES = {
    { key = "damage", enum = "DamageDone" }, { key = "healing", enum = "HealingDone" }, { key = "absorbs", enum = "Absorbs" },
    { key = "taken", enum = "DamageTaken" }, { key = "avoidable", enum = "AvoidableDamageTaken" }, { key = "deaths", enum = "Deaths" },
    { key = "interrupts", enum = "Interrupts" }, { key = "dispels", enum = "Dispels" }, { key = "enemy", enum = "EnemyDamageTaken" },
}
local NO_PER_SECOND = { deaths = true, interrupts = true, dispels = true }
local meter

local function read_type_entry()
    for _, entry in ipairs(TYPES) do
        if entry.key == (LibVGASettings.meter_type or "damage") then return entry end
    end
    return TYPES[1]
end

local function read_type_number(entry)
    local kinds = Enum and Enum.DamageMeterType
    return kinds and kinds[entry.enum] or 0
end

local function read_rows_wanted()
    return math.max(ROWS_LEAST, math.min(ROWS_MOST, LibVGASettings.meter_rows or ROWS_DEFAULT))
end

local function check_secret(value)
    return issecretvalue ~= nil and issecretvalue(value)
end

local function read_clock(seconds)
    if type(seconds) ~= "number" or check_secret(seconds) then return "" end
    local whole = math.floor(seconds + 0.5)
    return string.format("%d:%02d", math.floor(whole / 60), whole % 60)
end

local function render_decimal(format, value)
    return (string.format(format, value):gsub("%.", DECIMAL_SEPERATOR or "."))
end

function vga.render_meter_amount(value)
    if value < 10000 then
        local text = tostring(math.floor(value + 0.5))
        return (text:reverse():gsub("(%d%d%d)", "%1 "):reverse():gsub("^ ", ""))
    end
    if value < 1000000 then
        local thousands = value / 1000
        return (thousands < 100 and render_decimal("%.1f", thousands) or tostring(math.floor(thousands + 0.5))) .. " k"
    end
    local millions = value / 1000000
    if millions < 10 then return render_decimal("%.2f", millions) .. " M" end
    return (millions < 100 and render_decimal("%.1f", millions) or tostring(math.floor(millions + 0.5))) .. " M"
end

local function update_secret_text(text, value)
    if AbbreviateNumbers and pcall(text.SetFormattedText, text, "%s", AbbreviateNumbers(value)) then return end
    if not pcall(text.SetFormattedText, text, "%s", value) then text:SetText("") end
end

local function update_amount_text(text, value)
    if check_secret(value) then return update_secret_text(text, value) end
    text:SetText(vga.render_meter_amount(value or 0))
end

local function read_available()
    return C_DamageMeter.GetAvailableCombatSessions and C_DamageMeter.GetAvailableCombatSessions() or {}
end

local function read_chosen_session()
    local chosen = LibVGASettings.meter_fight or "current"
    if type(chosen) ~= "number" then return nil, chosen end
    for _, session in ipairs(read_available()) do
        if session.sessionID == chosen then return session, chosen end
    end
    return nil, "current"
end

local function read_session()
    local kind = read_type_number(read_type_entry())
    local held, chosen = read_chosen_session()
    if held then return C_DamageMeter.GetCombatSessionFromID(held.sessionID, kind), held end
    return C_DamageMeter.GetCombatSessionFromType(SESSIONS[chosen] or SESSIONS.current, kind), nil
end

local function read_fight_word(held)
    local texts = library.texts
    if held then return held.name .. " " .. read_clock(held.durationSeconds) end
    local chosen = LibVGASettings.meter_fight
    local sessions = Enum and Enum.DamageMeterSessionType
    if chosen == "overall" then
        return texts.meter_overall .. " " .. read_clock(C_DamageMeter.GetSessionDurationSeconds(sessions and sessions.Overall or SESSIONS.overall))
    end
    return texts.meter_current .. " " .. read_clock(C_DamageMeter.GetSessionDurationSeconds(sessions and sessions.Current or SESSIONS.current))
end

local function read_class_colour(class)
    local colour = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if colour then return { colour.r, colour.g, colour.b } end
    return colours.quiet
end

local function create_meter_row(parent)
    local row = CreateFrame("Frame", nil, parent)
    row.ground = row:CreateTexture(nil, "BACKGROUND")
    row.ground:SetAllPoints()
    row.ground:SetColorTexture(ROW_GROUND[1], ROW_GROUND[2], ROW_GROUND[3], 0.6)
    row.bar = library.create_bar(row, "tapped")
    row.bar:SetAllPoints()
    row.edge = row:CreateTexture(nil, "OVERLAY", nil, 2)
    row.edge:SetColorTexture(colours.gold[1], colours.gold[2], colours.gold[3], 1)
    row.icon = row.bar:CreateTexture(nil, "OVERLAY")
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.rank = library.create_text(row.bar, "small", colours.quiet)
    row.rank:SetJustifyH("RIGHT")
    row.name = library.create_text(row.bar, "caption", colours.ink)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
    row.amount = library.create_text(row.bar, "caption", colours.ink)
    row.amount:SetJustifyH("RIGHT")
    row.second = library.create_text(row.bar, "small", SECOND_INK)
    row.second:SetJustifyH("RIGHT")
    for _, text in ipairs({ row.rank, row.name, row.amount, row.second }) do text:SetDrawLayer("OVERLAY", 7) end
    return row
end

local function read_row(index)
    meter.rows[index] = meter.rows[index] or create_meter_row(meter.list)
    return meter.rows[index]
end

local function update_row_layout(row, spell)
    local draft = library.read_draft_size
    local height = draft(spell and SPELL_ROW or ROW)
    row:SetSize(draft(WIDTH - 2 * SIDE), height)
    library.update_bar_shape(row.bar, draft(3))
    row.rank:SetFontObject(library.read_frame_font("small"))
    row.name:SetFontObject(library.read_frame_font("caption"))
    row.amount:SetFontObject(library.read_frame_font("caption"))
    row.second:SetFontObject(library.read_frame_font("small"))
    row.name:SetTextColor(unpack(colours.ink))
    row.amount:SetTextColor(unpack(colours.ink))
    row.second:SetTextColor(unpack(SECOND_INK))
    row.rank:ClearAllPoints()
    row.rank:SetPoint("LEFT", row, "LEFT", draft(4), 0)
    row.rank:SetWidth(draft(RANK))
    row.icon:ClearAllPoints()
    row.icon:SetPoint("RIGHT", row, "LEFT", draft(4 + RANK), 0)
    row.icon:SetSize(draft(ICON), draft(ICON))
    row.second:ClearAllPoints()
    row.second:SetPoint("RIGHT", row, "RIGHT", -draft(SIDE), 0)
    row.second:SetWidth(draft(SECOND))
    row.amount:ClearAllPoints()
    row.amount:SetPoint("RIGHT", row.second, "LEFT", -draft(CELL_GAP), 0)
    row.name:ClearAllPoints()
    row.name:SetPoint("LEFT", row, "LEFT", draft(4 + RANK + CELL_GAP), 0)
    row.name:SetPoint("RIGHT", row.amount, "LEFT", -draft(CELL_GAP), 0)
    row.edge:ClearAllPoints()
    row.edge:SetPoint("TOPLEFT")
    row.edge:SetPoint("BOTTOMLEFT")
    row.edge:SetWidth(draft(EDGE))
    return height
end

local function update_second_text(row, entry, board)
    local chosen, kind = LibVGASettings.meter_second or "per_second", read_type_entry().key
    if chosen == "none" or (chosen == "per_second" and NO_PER_SECOND[kind]) then return row.second:SetText("") end
    if chosen == "per_second" then return update_amount_text(row.second, entry.amountPerSecond) end
    if board.secret or not (board.total and board.total > 0) then return row.second:SetText("") end
    row.second:SetText(math.floor(entry.totalAmount / board.total * 100 + 0.5) .. " %")
end

local function update_row_values(row, entry, board)
    row.bar:SetMinMaxValues(0, board.secret and board.most or math.max(board.most or 0, 1))
    row.bar:SetValue(entry.totalAmount)
    update_amount_text(row.amount, entry.totalAmount)
    update_second_text(row, entry, board)
end

local function update_source_row(row, entry, rank, board)
    update_row_layout(row, false)
    local colour = read_class_colour(entry.classFilename)
    library.update_bar_shade(row.bar, colour, BAR_LEFT, BAR_RIGHT)
    row.icon:Hide()
    row.rank:Show()
    row.rank:SetText(rank)
    row.rank:SetTextColor(unpack(entry.isLocalPlayer and GOLD_RANK or colours.quiet))
    row.edge:SetShown(entry.isLocalPlayer == true)
    row.name:SetText(entry.name or "")
    update_row_values(row, entry, board)
end

local function update_spell_row(row, spell, board, colour)
    update_row_layout(row, true)
    library.update_bar_shade(row.bar, colour, SPELL_LEFT, SPELL_RIGHT)
    row.rank:Hide()
    row.edge:Hide()
    row.icon:SetTexture(C_Spell.GetSpellTexture(spell.spellID))
    row.icon:Show()
    row.name:SetText(C_Spell.GetSpellName(spell.spellID) or "")
    update_row_values(row, spell, board)
end

local function read_own_index(sources)
    for index, entry in ipairs(sources) do
        if entry.isLocalPlayer then return index end
    end
    return nil
end

local function read_board()
    local session, held = read_session()
    local sources = session and session.combatSources or {}
    local board = { sources = sources, most = session and session.maxAmount, total = session and session.totalAmount, held = held }
    board.secret = check_secret(board.total) or check_secret(board.most)
    board.own = read_own_index(sources)
    return board
end

local function read_spells(board)
    if board.secret or #board.sources ~= 1 or board.own ~= 1 then return {} end
    local kind = read_type_number(read_type_entry())
    local guid = UnitGUID and UnitGUID("player")
    local found
    if board.held then
        found = C_DamageMeter.GetCombatSessionSourceFromID(board.held.sessionID, kind, guid)
    else
        found = C_DamageMeter.GetCombatSessionSourceFromType(SESSIONS[LibVGASettings.meter_fight or "current"] or SESSIONS.current, kind, guid)
    end
    return found and found.combatSpells or {}
end

local function update_placed(laid, part, height)
    part:ClearAllPoints()
    part:SetPoint("TOPLEFT", meter.list, "TOPLEFT", 0, -laid.top)
    part:Show()
    laid.top = laid.top + height + laid.gap
end

local function read_next_row(laid)
    laid.shown = laid.shown + 1
    return read_row(laid.shown)
end

local function update_spell_rows(laid, board, wanted)
    local spells, first = read_spells(board), board.sources[1]
    if #spells == 0 then return end
    local colour, own = read_class_colour(first.classFilename), { most = first.totalAmount, total = first.totalAmount }
    for index = 1, math.min(#spells, wanted - 1) do
        local row = read_next_row(laid)
        update_spell_row(row, spells[index], own, colour)
        update_placed(laid, row, row:GetHeight())
    end
end

local function update_own_pinned(laid, board, wanted)
    local own = board.own
    local outside = own ~= nil and (own <= meter.offset or own > meter.offset + wanted)
    meter.cut:SetShown(outside)
    if not outside then return end
    meter.cut:SetSize(library.read_draft_size(WIDTH - 2 * SIDE), 1)
    update_placed(laid, meter.cut, 1)
    local row = read_next_row(laid)
    update_source_row(row, board.sources[own], own, board)
    update_placed(laid, row, row:GetHeight())
end

local function update_list_rows(board)
    local wanted, sources = read_rows_wanted(), board.sources
    meter.offset = math.max(0, math.min(meter.offset or 0, #sources - wanted))
    local laid = { shown = 0, top = 0, gap = library.read_draft_size(ROW_GAP) }
    for index = meter.offset + 1, math.min(#sources, meter.offset + wanted) do
        local row = read_next_row(laid)
        update_source_row(row, sources[index], index, board)
        update_placed(laid, row, row:GetHeight())
    end
    update_spell_rows(laid, board, wanted)
    update_own_pinned(laid, board, wanted)
    for index = laid.shown + 1, #meter.rows do meter.rows[index]:Hide() end
    return math.max(0, laid.top - laid.gap)
end

local function update_cut_line()
    local dots = meter.cut.dots
    local step, width = 5, library.read_draft_size(WIDTH - 2 * SIDE)
    for index = 1, math.floor(width / step) do
        dots[index] = dots[index] or meter.cut:CreateTexture(nil, "ARTWORK")
        dots[index]:SetColorTexture(unpack(CUT))
        dots[index]:SetSize(2, 1)
        dots[index]:ClearAllPoints()
        dots[index]:SetPoint("LEFT", meter.cut, "LEFT", (index - 1) * step, 0)
    end
end

local function update_head()
    local draft = library.read_draft_size
    meter.mark:SetSize(draft(MARK), draft(MARK))
    meter.mark:ClearAllPoints()
    meter.mark:SetPoint("TOPLEFT", meter, "TOPLEFT", draft(12), -draft(8))
    meter.head:SetFontObject(library.read_font("bold"))
    meter.head:SetTextColor(unpack(TITLE))
    meter.head:SetText(library.texts["meter_" .. read_type_entry().key])
    meter.head:ClearAllPoints()
    meter.head:SetPoint("LEFT", meter.mark, "RIGHT", draft(CORNER_GAP), 0)
    meter.fight:SetFontObject(library.read_font("small"))
    meter.fight:SetTextColor(unpack(colours.quiet))
    meter.fight:ClearAllPoints()
    meter.fight:SetPoint("RIGHT", meter, "TOPRIGHT", -draft(12), 0)
    meter.fight:SetPoint("TOP", meter.mark, "TOP")
    meter.fight:SetPoint("BOTTOM", meter.mark, "BOTTOM")
    meter.fight:SetPoint("LEFT", meter.head, "RIGHT", draft(CORNER_GAP), 0)
    meter.opener:ClearAllPoints()
    meter.opener:SetPoint("TOPLEFT", meter.mark, "TOPLEFT")
    meter.opener:SetPoint("BOTTOMRIGHT", meter.fight, "BOTTOMRIGHT")
    return draft(8) + math.max(draft(MARK), math.ceil(meter.head:GetStringHeight())) + draft(6)
end

local function update_foot(board)
    local wanted = read_rows_wanted()
    local shown = #board.sources > wanted
    meter.foot:SetShown(shown)
    meter.total:SetShown(shown)
    if not shown then return 0 end
    local draft = library.read_draft_size
    meter.foot:SetFontObject(library.read_font("small"))
    meter.total:SetFontObject(library.read_font("small"))
    meter.foot:SetText(string.format(library.texts.meter_players, #board.sources))
    update_amount_text(meter.total, board.total)
    meter.foot:ClearAllPoints()
    meter.foot:SetPoint("BOTTOMLEFT", meter, "BOTTOMLEFT", draft(12), draft(8))
    meter.total:ClearAllPoints()
    meter.total:SetPoint("BOTTOMRIGHT", meter, "BOTTOMRIGHT", -draft(12), draft(8))
    return draft(6) + math.ceil(meter.foot:GetStringHeight())
end

local function update_shown()
    local idle = LibVGASettings.meter_idle or "show"
    local fighting = InCombatLockdown() or (UnitAffectingCombat and UnitAffectingCombat("player"))
    meter:SetShown(fighting or idle ~= "hide")
    meter:SetAlpha((fighting or idle ~= "faint") and 1 or FAINT)
end

local function update_meter()
    if not meter then return end
    meter:SetScale(library.read_size_step("meter"))
    library.update_frame(meter)
    update_shown()
    local board = read_board()
    meter.fight:SetText(read_fight_word(board.held))
    local head = update_head()
    local draft = library.read_draft_size
    meter.list:ClearAllPoints()
    meter.list:SetPoint("TOPLEFT", meter, "TOPLEFT", draft(SIDE), -head)
    meter.list:SetSize(draft(WIDTH - 2 * SIDE), 1)
    update_cut_line()
    local list = update_list_rows(board)
    local foot = update_foot(board)
    meter:SetSize(draft(WIDTH), head + list + foot + draft(8))
    meter.dirty = false
end

local function update_wheel(_, delta)
    meter.offset = (meter.offset or 0) - delta
    update_meter()
end

local function render_meter_page()
    library.update_safely("options", library.render_widget, meter.corner, "meter")
end

local function write_rows(stepper, step)
    LibVGASettings.meter_rows = math.max(ROWS_LEAST, math.min(ROWS_MOST, read_rows_wanted() + step))
    library.update_stepper(stepper, LibVGASettings.meter_rows)
    update_meter()
end

local function read_type_items(keys)
    local items = {}
    for index, key in ipairs(keys) do items[index] = { key, library.texts["meter_" .. key] } end
    return items
end

local function read_type_sections()
    local texts = library.texts
    return {
        { title = texts.meter_performance, items = read_type_items({ "damage", "healing", "absorbs" }) },
        { title = texts.meter_survival, items = read_type_items({ "taken", "avoidable", "deaths" }) },
        { title = texts.meter_support, items = read_type_items({ "interrupts", "dispels" }) },
        { title = texts.meter_enemies, items = read_type_items({ "enemy" }) },
    }
end

local function read_fight_sections()
    local texts = library.texts
    local recent = {}
    for _, session in ipairs(read_available()) do
        recent[#recent + 1] = { session.sessionID, session.name .. " · " .. read_clock(session.durationSeconds) }
    end
    local sections = { { items = { { "current", texts.meter_current }, { "overall", texts.meter_overall } } } }
    if #recent > 0 then sections[2] = { title = texts.meter_recent, items = recent } end
    return sections
end

local function update_fight_choices(page)
    local held, chosen = read_chosen_session()
    library.update_popup_sections(page.fight.control, read_fight_sections(), held and held.sessionID or chosen)
    library.update_popup(page.fight.control)
end

local function update_fights_cleared()
    C_DamageMeter.ResetAllCombatSessions()
    LibVGASettings.meter_fight = "current"
    update_meter()
end

local function write_meter_setting(key)
    return function(value)
        LibVGASettings[key] = value
        meter.offset = 0
        update_meter()
    end
end

local function create_index_row(page, word, key, values, labels)
    local chosen = 1
    for index, value in ipairs(values) do
        if value == (LibVGASettings[key] or values[1]) then chosen = index end
    end
    local write = write_meter_setting(key)
    return library.create_choice_row(page, word, labels, chosen, function(index) write(values[index]) end)
end

local function create_meter_page(page)
    local texts = library.texts
    local kind = library.create_row(page, texts.meter_type)
    kind.control = library.create_popup(kind, read_type_sections(), LibVGASettings.meter_type or "damage", write_meter_setting("meter_type"))
    page.fight = library.create_row(page, texts.meter_fight)
    page.fight.control = library.create_popup(page.fight, read_fight_sections(), LibVGASettings.meter_fight or "current", write_meter_setting("meter_fight"))
    local rows = library.create_row(page, texts.meter_rows)
    rows.control = library.create_stepper(rows, write_rows)
    library.update_stepper(rows.control, read_rows_wanted())
    page.rows = {
        kind, page.fight, rows,
        create_index_row(page, texts.meter_second, "meter_second", { "per_second", "share", "none" }, { texts.meter_per_second, texts.meter_share, texts.meter_none }),
        create_index_row(page, texts.meter_idle, "meter_idle", { "show", "faint", "hide" }, { texts.meter_show, texts.meter_faint, texts.meter_hide }),
    }
    for _, row in ipairs(library.create_widget_rows(page, "meter", { { key = "meter", title = texts.meter, sized = true } })) do page.rows[#page.rows + 1] = row end
    local clear = library.create_button(page, texts.meter_clear, "alarm", update_fights_cleared)
    clear.ask = texts.meter_clear_sure
    page.foot = { clear }
    page:SetScript("OnShow", update_fight_choices)
end

local function update_marked()
    if meter then meter.dirty = true end
end

local function update_ticked()
    if not meter then return end
    if meter.dirty or InCombatLockdown() then update_meter() end
end

local function update_game_meter_hidden(frame)
    frame:Hide()
end

local function delete_game_meter()
    if not DamageMeter then return end
    DamageMeter:UnregisterAllEvents()
    DamageMeter:Hide()
    hooksecurefunc(DamageMeter, "Show", update_game_meter_hidden)
    hooksecurefunc(DamageMeter, "SetShown", update_game_meter_hidden)
end

local function create_meter()
    if not C_DamageMeter then return end
    delete_game_meter()
    meter = library.create_frame("VGADamageMeter", UIParent)
    meter.corner:SetScript("OnClick", render_meter_page)
    meter.mark = meter:CreateTexture(nil, "OVERLAY")
    meter.mark:SetTexture(library.media .. "Mark")
    meter.head = library.create_text(meter, "bold", TITLE)
    meter.fight = library.create_text(meter, "small", colours.quiet)
    meter.fight:SetJustifyH("RIGHT")
    meter.fight:SetWordWrap(false)
    meter.opener = CreateFrame("Button", nil, meter)
    meter.opener:SetScript("OnClick", render_meter_page)
    meter.list = CreateFrame("Frame", nil, meter)
    meter.cut = CreateFrame("Frame", nil, meter.list)
    meter.cut.dots = {}
    meter.foot = library.create_text(meter, "small", colours.quiet)
    meter.total = library.create_text(meter, "small", colours.quiet)
    meter.rows, meter.offset = {}, 0
    meter:EnableMouseWheel(true)
    meter:SetScript("OnMouseWheel", update_wheel)
    library.create_place(meter, "meter", "TOPLEFT", UIParent, library.read_draft_size(8), -library.read_draft_size(8))
    library.create_element("meter", { title = library.texts.meter, icon = "TabMeter", update = update_meter, tab = create_meter_page })
    C_Timer.NewTicker(REFRESH, function() library.update_safely("meter tick", update_ticked) end)
end

local events = CreateFrame("Frame")
for _, name in ipairs({ "PLAYER_LOGIN", "DAMAGE_METER_COMBAT_SESSION_UPDATED", "DAMAGE_METER_CURRENT_SESSION_UPDATED", "DAMAGE_METER_RESET", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "GROUP_ROSTER_UPDATE" }) do
    pcall(events.RegisterEvent, events, name)
end
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then return library.update_safely("meter", create_meter) end
    if event == "DAMAGE_METER_COMBAT_SESSION_UPDATED" or event == "DAMAGE_METER_CURRENT_SESSION_UPDATED" then return update_marked() end
    library.update_safely("meter " .. event, update_meter)
end)
