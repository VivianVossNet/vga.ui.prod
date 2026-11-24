-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.auctions' page Verlauf as the accepted draft draws it (manual/view/vga-auctions.html, page »Verlauf«, K0684): in one of LibVGA's groups four figures - sold in thirty days, bought in thirty days, the gain of the sales against the cost of their bought pieces, and that gain against the cost as a chip -; beneath, in a group of its own, LibVGA's day bars, one for each of the thirty days, the day's gain after the cut; then LibVGA's segmented choice - all, sales, purchases, expired - in place of the draft's pills, as everywhere since K0634; then the ledger's events of thirty days in LibVGA's list under sortable heads, the newest first - when, the item's picture and name in its quality's colour, the way, how many, the money or »zurück« for an expired auction, and for a sale its result against the cost as a chip, »Fund« where every piece was found -; the item's tooltip on hover; a note beneath as the draft's. The page fills LibVGA's ledger page (library.create_ledger_page, K0870): its figure strip (K0869) with the four figures, its item table (K0862) with the events, its note; the day bars and the choice stand between the strip and the table.

-- {K0870} {K0869} {K0862} {K0802} {K0798} {K0789} {K0785} {K0684} {K0686}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local DAYS = 30
local DAY_SECONDS = 86400
local RED = { 0.886, 0.404, 0.353 }
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
    local page, event = history_page, row.event
    line.row = row
    line.when:SetText(read_when(event.at))
    local columns, x = page.ledger.table.columns, page.ledger.table.pad
    library.update_item_row(line, { icon = row.icon, id = row.event.item, name = row.name, quality = row.quality }, x + columns.lefts[2], x + columns.rights[2])
    line.kind:SetText(read_way_word(event.way))
    local kind = event.way == "sale" and colours.ink or colours.quiet
    line.kind:SetTextColor(kind[1], kind[2], kind[3], 1)
    line.count:SetText(event.count or 1)
    local expired = event.way == "expired"
    line.money:SetShown(not expired)
    line.back:SetShown(expired)
    library.update_money(line.money, math.floor((event.money or 0) + 0.5))
    local share = read_share(event)
    line.chip:SetShown(event.way == "sale")
    update_result_chip(line.chip, share)
    library.update_grid_columns(line, columns, x, { { line.when, 1 }, { line.kind, 3 }, { line.count, 4 }, { line.money, 5, "right" }, { line.back, 5, "right" }, { line.chip, 6 } })
end

local function render_row_tip(line)
    if line.row then vga.render_item_tip(line, { id = line.row.event.item }) end
end

local function create_history_row(parent)
    local line = library.create_item_row(parent, { on_enter = render_row_tip, on_leave = vga.update_item_tip_hidden })
    line.when = library.create_text(line, "figures_small", colours.quiet)
    line.kind = library.create_text(line, "small", colours.quiet)
    line.count = library.create_text(line, "figures_small", colours.ink)
    line.money = library.create_money(line, colours.ink)
    line.money.kind = "small"
    line.back = library.create_text(line, "small", colours.quiet)
    line.back:SetText(library.texts.back)
    line.chip = library.create_chip(line)
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

local function read_widest_word(sheet, words)
    local widest = 0
    for _, word in ipairs(words) do widest = math.max(widest, library.read_item_table_text(sheet, word)) end
    return widest
end

local function read_when_room(sheet)
    local texts = library.texts
    return read_widest_word(sheet, { texts.today .. " 00:00", texts.yesterday, "00.00." })
end

local function read_kind_room(sheet)
    local texts = library.texts
    return read_widest_word(sheet, { texts.way_sale, texts.way_expired, texts.way_merchant, texts.way_auction, texts.way_commodity })
end

local function read_amount_room(sheet)
    return math.max(library.read_widest_money(sheet.probe_small), library.read_item_table_text(sheet, library.texts.back))
end

local function read_log_plan(texts)
    local columns = {
        { key = "when", word = texts.when, sort = read_sort_when, least = read_when_room },
        { key = "item", word = texts.item, sort = read_sort_name, inset = "icon" },
        { key = "kind", word = texts.kind, sort = read_sort_kind, least = read_kind_room },
        { key = "quantity", word = texts.quantity, sort = read_sort_count, least = "99999" },
        { key = "amount", word = texts.amount, sort = read_sort_amount, least = read_amount_room, x = "right" },
        { key = "result", word = texts.result, sort = read_sort_result, least = "chip", tip = texts.head_tip_sale_result },
    }
    return { columns = columns, create_row = create_history_row, update_row = update_history_row, empty = texts.history_empty, on_sort = render_history, on_rows = update_history_chips }
end

local function read_strip_plan(texts)
    return { figures = { { word = texts.sold_30, kind = "money" }, { word = texts.bought_30, kind = "money" }, { word = texts.gain, kind = "money" }, { word = texts.to_cost, kind = "chip" } } }
end

local function create_days(page)
    page.days_group = library.create_group(page)
    page.days = library.create_day_bars(page.days_group)
end

function vga.create_history_page(page)
    local texts = library.texts
    history_page, page.filter = page, 1
    page.ledger = library.create_ledger_page(page, { strip = read_strip_plan(texts), table = read_log_plan(texts), note = texts.history_note })
    create_days(page)
    local labels = {}
    for index, key in ipairs(FILTERS) do labels[index] = texts[key] end
    page.choice = library.create_choice(page, labels, 1, render_filter)
    page.list = page.ledger.table.list
    page.lines = page.list.rows
end

local function update_sums(page)
    local sold, bought, gain, cost, days = read_sums()
    local figures = page.ledger.strip.figures
    library.update_money(figures[1].value, math.floor(sold + 0.5))
    library.update_money(figures[2].value, math.floor(bought + 0.5))
    update_signed_money(figures[3].value, gain)
    update_result_chip(figures[4].value, cost > 0 and gain / cost or nil)
    return days
end

local function update_days(page, width, days)
    local height, inset, across = library.read_draft_size(70), library.read_draft_size(10), library.read_draft_size(12)
    page.days_group:SetSize(width, height)
    library.update_group(page.days_group)
    library.update_day_bars(page.days, days, width - 2 * across, height - 2 * inset)
    page.days:ClearAllPoints()
    page.days:SetPoint("BOTTOMLEFT", page.days_group, "BOTTOMLEFT", across, inset)
end

function vga.update_history_page(page, width)
    page.full_width = width
    update_days(page, width, update_sums(page))
    page.choice.chosen = page.filter
    library.update_choice(page.choice)
    library.update_ledger_page(page.ledger, read_rows(page.filter), width, page:GetHeight(), { page.days_group, page.choice })
end
