-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.auctions' page Verlauf as the accepted draft draws it (manual/view/vga-auctions.html, page »Verlauf«, K0684): in one of LibVGA's groups four figures - sold in thirty days, bought in thirty days, the gain of the sales against the cost of their bought pieces, and that gain against the cost as a chip -; beneath, in a group of its own, LibVGA's day bars, one for each of the thirty days, the day's gain after the cut; then LibVGA's segmented choice - all, sales, purchases, expired - in place of the draft's pills, as everywhere since K0634; then the ledger's events of thirty days in LibVGA's list under sortable heads, the newest first - when, the item's picture and name in its quality's colour, the way, how many, the money or »zurück« for an expired auction, and for a sale its result against the cost as a chip, »Fund« where every piece was found -; the item's tooltip on hover; a note beneath as the draft's.

-- {K0684} {K0686}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local DAYS = 30
local DAY_SECONDS = 86400
local RED = { 0.886, 0.404, 0.353 }
local HEADS = { "when", "item", "kind", "quantity", "amount", "result" }
local FILTERS = { "all_events", "sales", "purchases", "expired" }
local BOUGHT = { merchant = true, auction = true, commodity = true }
local history_page

local function read_day(at)
    return math.floor(at / DAY_SECONDS)
end

local function read_when(at)
    local texts, today = library.texts, read_day(time())
    if read_day(at) == today then return texts.today .. " " .. date("%H:%M", at) end
    if read_day(at) == today - 1 then return texts.yesterday end
    return date("%d.%m.", at)
end

local function read_share(event)
    if event.way ~= "sale" then return nil end
    if (event.cost or 0) <= 0 then return event.found and event.found > 0 and math.huge or nil end
    return (event.money - event.cost) / event.cost
end

local function check_shown(event, filter)
    if filter == 2 then return event.way == "sale" end
    if filter == 3 then return BOUGHT[event.way] == true end
    if filter == 4 then return event.way == "expired" end
    return true
end

local function read_rows(filter)
    local rows, events = {}, vga.read_ledger_events()
    for index = #events, 1, -1 do
        local event = events[index]
        if check_shown(event, filter) then
            local name, _, quality, _, _, _, _, _, _, icon = C_Item.GetItemInfo(event.item)
            rows[#rows + 1] = { event = event, name = name or tostring(event.item), quality = quality, icon = icon or 134400 }
        end
    end
    return rows
end

local function read_sums()
    local _, sales = vga.read_holdings()
    local proceeds, cost, bought, days, today = 0, 0, 0, {}, read_day(time())
    for day, sold in pairs(sales) do
        proceeds, cost = proceeds + sold.proceeds, cost + sold.cost
        local back = today - day
        if back >= 0 and back < DAYS then days[DAYS - back] = sold.proceeds - sold.cost end
    end
    for _, event in ipairs(vga.read_ledger_events()) do
        if BOUGHT[event.way] then bought = bought + (event.money or 0) end
    end
    for index = 1, DAYS do days[index] = days[index] or 0 end
    return proceeds, bought, proceeds - cost, cost, days
end

local function update_signed_money(money, amount)
    local ink = amount < 0 and RED or colours.ink
    library.update_money(money, math.floor(math.abs(amount) + 0.5))
    for _, group in ipairs(money.groups) do group.text:SetTextColor(ink[1], ink[2], ink[3], 1) end
end

local function update_result_chip(chip, share)
    if share == math.huge then return library.update_chip(chip, "gold", "◆", library.texts.found) end
    if not share then return library.update_chip(chip, "grey", "≈", "–") end
    local percent = math.floor(math.abs(share) * 100 + 0.5)
    library.update_chip(chip, share >= 0 and "green" or "red", share >= 0 and "▲" or "▼", percent .. " %")
end

local function read_way_word(way)
    local texts = library.texts
    local words = { sale = texts.way_sale, expired = texts.way_expired, merchant = texts.way_merchant, auction = texts.way_auction, commodity = texts.way_commodity }
    return words[way] or ""
end

local function update_history_row(line, row)
    local page, event, size = history_page, row.event, library.read_draft_size(26)
    line.row = row
    line.when:SetText(read_when(event.at))
    line.when:ClearAllPoints()
    local columns, x = page.columns, page.pad
    line.when:SetPoint("LEFT", line, "LEFT", x + columns.lefts[1], 0)
    line.icon:SetTexture(row.icon)
    library.update_unusable(line.unusable, row.event.item)
    line.icon:SetSize(size, size)
    line.icon:ClearAllPoints()
    line.icon:SetPoint("LEFT", line, "LEFT", x + columns.lefts[2], 0)
    local colour = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[row.quality or 1]
    line.name:SetText(row.name)
    line.name:SetTextColor(colour and colour.r or 1, colour and colour.g or 1, colour and colour.b or 1, 1)
    line.name:ClearAllPoints()
    line.name:SetPoint("LEFT", line.icon, "RIGHT", library.read_size(-4), 0)
    line.name:SetWidth(math.max(1, columns.rights[2] - columns.lefts[2] - size - library.read_size(-4)))
    line.kind:SetText(read_way_word(event.way))
    local kind = event.way == "sale" and colours.ink or colours.quiet
    line.kind:SetTextColor(kind[1], kind[2], kind[3], 1)
    line.kind:ClearAllPoints()
    line.kind:SetPoint("LEFT", line, "LEFT", x + columns.lefts[3], 0)
    line.count:SetText(event.count or 1)
    line.count:ClearAllPoints()
    line.count:SetPoint("LEFT", line, "LEFT", x + columns.lefts[4], 0)
    local expired = event.way == "expired"
    line.money:SetShown(not expired)
    line.back:SetShown(expired)
    library.update_money(line.money, math.floor((event.money or 0) + 0.5))
    for _, shown in ipairs({ line.money, line.back }) do
        shown:ClearAllPoints()
        shown:SetPoint("RIGHT", line, "LEFT", x + columns.rights[5], 0)
    end
    local share = read_share(event)
    line.chip:SetShown(event.way == "sale")
    update_result_chip(line.chip, share)
    line.chip:ClearAllPoints()
    line.chip:SetPoint("LEFT", line, "LEFT", x + columns.lefts[6], 0)
end

local function render_row_tip(line)
    if line.row then vga.render_item_tip(line, { id = line.row.event.item }) end
end

local function create_history_row(parent)
    local line = CreateFrame("Frame", nil, parent)
    line:EnableMouse(true)
    line.when = library.create_text(line, "small", colours.quiet)
    line.icon = line:CreateTexture(nil, "ARTWORK")
    line.unusable = library.create_unusable(line, line.icon)
    line.name = library.create_text(line, "body", colours.ink)
    line.name:SetJustifyH("LEFT")
    line.name:SetWordWrap(false)
    line.kind = library.create_text(line, "small", colours.quiet)
    line.count = library.create_text(line, "small", colours.ink)
    line.money = library.create_money(line, colours.ink)
    line.money.kind = "small"
    line.back = library.create_text(line, "small", colours.quiet)
    line.back:SetText(library.texts.back)
    line.chip = library.create_chip(line)
    line:SetScript("OnEnter", render_row_tip)
    line:SetScript("OnLeave", vga.update_item_tip_hidden)
    return line
end

local function read_sort_when(row) return row.event.at end
local function read_sort_name(row) return row.name end
local function read_sort_kind(row) return read_way_word(row.event.way) end
local function read_sort_count(row) return row.event.count or 1 end
local function read_sort_amount(row) return row.event.money or 0 end
local function read_sort_result(row) return read_share(row.event) end

local function render_history()
    vga.update_history_page(history_page, history_page.full_width)
end

local function render_filter(index)
    history_page.filter = index
    render_history()
end

local function update_history_chips(list)
    local chips = {}
    for _, line in ipairs(library.read_list_rows_shown(list)) do chips[#chips + 1] = line.chip end
    library.update_chip_width(chips)
end

function vga.create_history_page(page)
    local texts = library.texts
    history_page, page.filter = page, 1
    page.sums = library.create_group(page)
    page.figures = {}
    for index, key in ipairs({ "sold_30", "bought_30", "gain", "to_cost" }) do
        local figure = { label = library.create_text(page.sums, "caption", colours.quiet) }
        figure.label:SetText(texts[key]:upper())
        figure.money = index <= 3 and library.create_money(page.sums, colours.ink) or nil
        figure.chip = index > 3 and library.create_chip(page.sums) or nil
        figure.rule = index > 1 and library.create_hairline(page.sums) or nil
        page.figures[index] = figure
    end
    page.days_group = library.create_group(page)
    page.days = library.create_day_bars(page.days_group)
    local labels = {}
    for index, key in ipairs(FILTERS) do labels[index] = texts[key] end
    page.choice = library.create_choice(page, labels, 1, render_filter)
    page.log = library.create_group(page)
    page.list = library.create_list(page.log, create_history_row, update_history_row)
    page.list.sorters = { when = read_sort_when, item = read_sort_name, kind = read_sort_kind, quantity = read_sort_count, amount = read_sort_amount, result = read_sort_result }
    page.list.on_sort = render_history
    page.list.on_rows = update_history_chips
    page.heads = {}
    for index, key in ipairs(HEADS) do page.heads[index] = library.create_sort_head(page.list, page.log, texts[key]:upper(), key, key == "result" and texts.head_tip_sale_result or nil) end
    page.empty = library.create_text(page.log, "small", colours.quiet)
    page.empty:SetText(texts.history_empty)
    page.note = library.create_text(page, "small", colours.quiet)
    page.note:SetJustifyH("LEFT")
    page.note:SetText(texts.history_note)
    page.probe_money = library.create_money(page, colours.ink)
    page.probe_money.kind = "small"
    page.probe_text = library.create_text(page, "small", colours.ink)
    page.probe_chip = library.create_chip(page)
    page.probe_chip:Hide()
    page.lines = page.list.rows
end

local function update_sums(page, width)
    local sold, bought, gain, cost, days = read_sums()
    library.update_money(page.figures[1].money, math.floor(sold + 0.5))
    library.update_money(page.figures[2].money, math.floor(bought + 0.5))
    update_signed_money(page.figures[3].money, gain)
    update_result_chip(page.figures[4].chip, cost > 0 and gain / cost or nil)
    local pad, height, cell = library.read_draft_size(12), library.read_draft_size(52), width / 4
    page.sums:ClearAllPoints()
    page.sums:SetPoint("TOPLEFT", page, "TOPLEFT")
    page.sums:SetSize(width, height)
    library.update_group(page.sums)
    for index, figure in ipairs(page.figures) do
        local x = (index - 1) * cell
        figure.label:SetFontObject(library.read_font("caption"))
        figure.label:ClearAllPoints()
        figure.label:SetPoint("TOPLEFT", page.sums, "TOPLEFT", x + pad, -library.read_draft_size(10))
        local shown = figure.money or figure.chip
        shown:ClearAllPoints()
        shown:SetPoint("TOPLEFT", figure.label, "BOTTOMLEFT", 0, -library.read_draft_size(4))
        if figure.rule then
            figure.rule:ClearAllPoints()
            figure.rule:SetPoint("TOPLEFT", page.sums, "TOPLEFT", x, -1)
            figure.rule:SetPoint("BOTTOMLEFT", page.sums, "BOTTOMLEFT", x, 1)
            figure.rule:SetWidth(1)
        end
    end
    return days
end

local function update_days(page, width, top, days)
    local height, inset, across = library.read_draft_size(70), library.read_draft_size(10), library.read_draft_size(12)
    page.days_group:ClearAllPoints()
    page.days_group:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -top)
    page.days_group:SetSize(width, height)
    library.update_group(page.days_group)
    library.update_day_bars(page.days, days, width - 2 * across, height - 2 * inset)
    page.days:ClearAllPoints()
    page.days:SetPoint("BOTTOMLEFT", page.days_group, "BOTTOMLEFT", across, inset)
    return top + height
end

local function read_widest_word(page, words)
    local widest = 0
    for _, word in ipairs(words) do widest = math.max(widest, library.read_widest_text(page.probe_text, word)) end
    return widest
end

local function read_history_columns(page)
    local texts = library.texts
    for index, heading in ipairs(page.heads) do library.update_sort_head(heading, index == 5) end
    local function read_room(index, least) return math.max(page.heads[index]:GetWidth(), least) end
    local when = read_widest_word(page, { texts.today .. " 00:00", texts.yesterday, "00.00." })
    local kind = read_widest_word(page, { texts.way_sale, texts.way_expired, texts.way_merchant, texts.way_auction, texts.way_commodity })
    local amount = math.max(library.read_widest_money(page.probe_money), library.read_widest_text(page.probe_text, texts.back))
    return library.read_columns(page.width, { read_room(1, when), false, read_room(3, kind), read_room(4, library.read_widest_text(page.probe_text, "99999")), read_room(5, amount), read_room(6, library.read_widest_chip(page.probe_chip)) })
end

function vga.update_history_page(page, width)
    page.full_width, page.pad = width, library.read_draft_size(12)
    page.width = width - 2 * page.pad
    local apart = library.read_draft_size(14)
    local days = update_sums(page, width)
    local top = update_days(page, width, library.read_draft_size(52) + apart, days) + apart
    page.choice.chosen = page.filter
    library.update_choice(page.choice)
    page.choice:ClearAllPoints()
    page.choice:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -top)
    top = top + page.choice:GetHeight() + apart
    local head, row, note = library.read_draft_size(28), library.read_draft_size(40), library.read_draft_size(40)
    local height = math.max(page:GetHeight() - top - note, head + 3 * row)
    page.log:ClearAllPoints()
    page.log:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -top)
    page.log:SetSize(width, height)
    library.update_group(page.log)
    page.columns = read_history_columns(page)
    local columns, icon = page.columns, library.read_draft_size(26) + library.read_size(-4)
    local places = { { "LEFT", columns.lefts[1] }, { "LEFT", columns.lefts[2] + icon }, { "LEFT", columns.lefts[3] }, { "LEFT", columns.lefts[4] }, { "RIGHT", columns.rights[5] }, { "LEFT", columns.lefts[6] } }
    for index, heading in ipairs(page.heads) do
        local place = places[index]
        heading:ClearAllPoints()
        heading:SetPoint(place[1], page.log, "TOPLEFT", page.pad + place[2], -head / 2)
    end
    local rows = read_rows(page.filter)
    page.list:ClearAllPoints()
    page.list:SetPoint("TOPLEFT", page.log, "TOPLEFT", 0, -head)
    library.update_list(page.list, rows, width, height - head, row)
    page.empty:SetShown(#rows == 0)
    page.empty:ClearAllPoints()
    page.empty:SetPoint("TOP", page.log, "TOP", 0, -(head + row))
    page.note:SetFontObject(library.read_font("small"))
    page.note:ClearAllPoints()
    page.note:SetPoint("TOPLEFT", page.log, "BOTTOMLEFT", library.read_draft_size(4), -library.read_draft_size(6))
    page.note:SetWidth(width - library.read_draft_size(8))
end
