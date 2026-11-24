-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.auctions' page Verkaufen as the accepted draft draws it (manual/view/vga-auctions.html »Seite Verkaufen«, K0603, K0617, K0619, K0632), every part in LibVGA's groups: at the left the bags' items the auction house takes in LibVGA's list (K0631) - picture, name in its quality's colour with the count and the required level beneath it (K0647), the market value at the right -, the chosen one ringed in gold on a faint gold ground; at the right the figures in LibVGA's figure strip (library.create_figure_strip, K0869) - market value, lowest now, the seven days as a chip, the quantity on offer -, the graph in its group with its legend - median, seven-day mean, lowest to median, on offer - and the range 7, 30 or 90 days, the item's current offers in LibVGA's list under their heads, each sorting them (K0655) - the rating against the market as a chip, the quantity, the price each, the player's own marked -, the posting row - the price each in LibVGA's money field, the quantity in its stepper, 12, 24 or 48 hours, the gold »Einstellen« -, the player's average cost and the result after the cut as a chip, and the note how the price is proposed and what the deposit is: one copper under the cheapest offer neither the player's own nor a bargain. Offers asked for as the game's own window asks (K0629), anew on every visit (K0625). The bags read for it are every bag the player carries, the reagent bag too, and the profession bags in the bag slots (K0738). The offers' list is LibVGA's item table (K0862); the bags' list stays LibVGA's plain list, having no sortable heads.

-- {K0869} {K0862} {K0802} {K0800} {K0798} {K0789} {K0785} {K0617} {K0619} {K0625} {K0628} {K0693} {K0629} {K0631} {K0632} {K0647} {K0648} {K0655} {K0738}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local CUT = 0.05
local DURATIONS = { 12, 24, 48 }
local RANGES = { 7, 30, 90 }
local BAND = { 0.894, 0.718, 0.314, 0.16 }
local BARS = { 0.227, 0.243, 0.275, 1 }
local MEAN = { 0.604, 0.588, 0.549, 1 }
local OFFERS = 4
local OFFER_HEAD = 28
local OFFER_ROW = 30
local OFFER_CHIP = 82
local BARGAIN, GOOD_DEAL, USUAL = -0.15, -0.03, 0.03
local sell_page
local update_offers
local render_search

local function read_bag_items()
    local found, order = {}, {}
    for bag = 0, vga.read_final_bag() do
        for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
            local content = C_Container.GetContainerItemInfo(bag, slot)
            local location = content and not content.isBound and ItemLocation:CreateFromBagAndSlot(bag, slot)
            if location and C_AuctionHouse.IsSellItemValid(location, false) then
                local entry = found[content.itemID]
                if not entry then
                    entry = { item = content.itemID, count = 0, location = location, icon = content.iconFileID, quality = content.quality, bag = bag, slot = slot }
                    found[content.itemID], order[#order + 1] = entry, entry
                end
                entry.count = entry.count + (content.stackCount or 1)
            end
        end
    end
    return order
end

local function read_mean(values, count)
    local means = {}
    for index = 1, count do
        local sum, seen = 0, 0
        for back = math.max(1, index - 6), index do
            if values[back] then sum, seen = sum + values[back], seen + 1 end
        end
        if seen > 0 then means[index] = sum / seen end
    end
    return means
end

local function read_name(item)
    return C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(item) or tostring(item)
end


local function read_known_days(values)
    local count = 0
    for _ in pairs(values) do count = count + 1 end
    return count
end

local function read_mean(values, count)
    local means = {}
    for index = 1, count do
        local sum, seen = 0, 0
        for back = math.max(1, index - 6), index do
            if values[back] then sum, seen = sum + values[back], seen + 1 end
        end
        if seen > 0 then means[index] = sum / seen end
    end
    return means
end

local function read_commodity(entry)
    return Enum.ItemCommodityStatus and C_AuctionHouse.GetItemCommodityStatus(entry.location) == Enum.ItemCommodityStatus.Commodity
end

local function read_deposit(page, entry)
    local duration, quantity = page.duration or 2, page.quantity or 1
    if read_commodity(entry) then
        return C_AuctionHouse.CalculateCommodityDeposit and C_AuctionHouse.CalculateCommodityDeposit(entry.item, duration, quantity)
    end
    return C_AuctionHouse.CalculateItemDeposit and C_AuctionHouse.CalculateItemDeposit(entry.location, duration, quantity)
end

local function update_note(page, entry)
    local deposit = read_deposit(page, entry)
    page.note:SetText(string.format(library.texts.sell_note, deposit and library.read_money_text(deposit) or "–"))
end

local function update_result(page, entry)
    local average, _, bought = vga.read_cost(entry.item)
    page.result_group:SetShown(average ~= nil)
    if not average then return end
    local holding = vga.read_holdings()[entry.item]
    local way = holding and holding.way and library.texts["way_" .. holding.way] or ""
    page.cost_text:SetText(library.texts.your_cost)
    library.update_money(page.cost_money, math.floor(average + 0.5))
    page.cost_more:SetText("· " .. string.format(library.texts.pieces, bought or 0) .. (way ~= "" and (", " .. way) or ""))
    local unit = library.read_money_field(page.price)
    local share = (unit * (1 - CUT) - average) / math.max(average, 1)
    library.update_chip(page.result, share >= 0 and "green" or "red", share >= 0 and "▲" or "▼", math.floor(math.abs(share) * 100 + 0.5) .. " %")
end

function vga.read_week_trend(item)
    local _, median = vga.read_days(item, 8)
    local share = median[8] and median[1] and (median[8] - median[1]) / math.max(median[1], 1)
    if not share then return "grey", "≈", "–" end
    return share >= 0 and "green" or "red", share >= 0 and "▲" or "▼", math.floor(math.abs(share) * 100 + 0.5) .. " %"
end

local function update_figures(page, entry)
    local market, lowest, quantity = vga.read_market(entry.item)
    local figures = page.facts.figures
    library.update_money(figures[1].value, math.floor((market or 0) + 0.5))
    library.update_money(figures[2].value, math.floor((lowest or 0) + 0.5))
    library.update_chip(figures[3].value, vga.read_week_trend(entry.item))
    figures[4].value:SetText(quantity or "–")
    return lowest
end

function vga.read_history_graph(item, days)
    local least, median, quantity = vga.read_days(item, days)
    return {
        count = days,
        bars = { values = quantity, colour = BARS },
        band = { low = least, high = median, colour = BAND },
        series = { { values = median, colour = colours.gold, thickness = 2 }, { values = read_mean(median, days), colour = MEAN, dashed = true } },
        note = read_known_days(median) < 2 and library.texts.graph_from_two_days or nil,
    }
end

local function update_graph(page, entry)
    library.update_graph(page.graph, vga.read_history_graph(entry.item, RANGES[page.range or 2]), page.graph_width, page.graph_height)
end

local function update_detail(page)
    local entry = page.chosen
    page.detail:SetShown(entry ~= nil)
    if not entry then return end
    local lowest = update_figures(page, entry)
    update_graph(page, entry)
    page.quantity = math.min(page.quantity or entry.count, entry.count)
    library.update_stepper(page.stepper, page.quantity)
    if page.proposed ~= entry.item then
        page.proposed = entry.item
        local market = vga.read_market(entry.item)
        library.update_money_field(page.price, math.max(1, math.floor((lowest and lowest - 1) or market or 1)))
    end
    update_result(page, entry)
    update_note(page, entry)
end

local function update_entry_line(line, entry)
    local page = sell_page
    local size = library.read_draft_size(26)
    local chosen = page.chosen == entry
    line.icon:SetTexture(entry.icon)
    library.update_unusable(line.unusable, entry.item)
    line.icon:SetSize(size, size)
    line.name:SetFontObject(library.read_font("body"))
    line.name:SetText(read_name(entry.item))
    local quality = library.read_quality_colour(entry.quality)
    line.name:SetTextColor(quality[1], quality[2], quality[3], 1)
    line.name:SetWidth(page.list_width * 0.55)
    line.count:SetFontObject(library.read_font("figures_small"))
    local level = vga.read_item_level(entry.item)
    line.count:SetText(string.format(library.texts.pieces, entry.count) .. ((level and level > 1) and (" · " .. library.texts.level .. " " .. vga.read_level_text(level)) or ""))
    library.update_money(line.money, math.floor((vga.read_market(entry.item) or 0) + 0.5))
    library.update_grid(line.grid, { { line.icon, { stack = { line.name, line.count } }, nil, line.money } }, page.list_width)
    library.update_item_hover(line, line.icon, line.name, size)
    library.update_item_row_chosen(line, chosen)
    line.rule:SetShown(line.index > 1 and not chosen)
end

local function update_lines(page)
    local height = library.read_draft_size(40)
    local room = page:GetHeight()
    page.list_group:ClearAllPoints()
    page.list_group:SetPoint("TOPLEFT", page, "TOPLEFT")
    page.list_group:SetSize(page.list_width, math.max(room, height))
    library.update_group(page.list_group)
    page.list:ClearAllPoints()
    page.list:SetPoint("TOPLEFT", page.list_group, "TOPLEFT")
    library.update_list(page.list, page.entries, page.list_width, math.max(room, height), height)
end

local function render_chosen(line)
    local page = sell_page
    page.chosen, page.quantity = page.entries[line.index], nil
    update_lines(page)
    update_detail(page)
    update_offers(page)
    render_search(page)
end

local function render_entry_tip(line)
    local entry = sell_page.entries[line.index]
    if entry then vga.render_item_tip(line, { bag = entry.bag, slot = entry.slot, id = entry.item }) end
end

local function create_entry_line(parent, index)
    local line = library.create_item_row(parent, { chosen = true, on_click = render_chosen, on_enter = render_entry_tip, on_leave = vga.update_item_tip_hidden })
    line.index = index
    line.count = library.create_text(line, "figures_small", colours.quiet)
    line.money = library.create_money(line, colours.ink)
    line.grid = library.create_grid(line, { columns = { 26, "auto", "rest", "auto" }, gaps = { 10, 0, 0 }, padding = { 0, 12, 0, 12 }, row = 40, x = { "left", "left", "left", "right" } })
    return line
end

local function render_step(stepper, step)
    local page = sell_page
    if not page.chosen then return end
    page.quantity = math.max(1, math.min(page.chosen.count, (page.quantity or 1) + step))
    library.update_stepper(stepper, page.quantity)
    update_note(page, page.chosen)
end

local function render_post()
    local page = sell_page
    local entry = page.chosen
    if not entry then return end
    local unit, duration = library.read_money_field(page.price), page.duration or 2
    local commodity = read_commodity(entry)
    if commodity then
        C_AuctionHouse.PostCommodity(entry.location, duration, page.quantity or 1, unit)
    else
        C_AuctionHouse.PostItem(entry.location, duration, page.quantity or 1, nil, unit)
    end
end

local function read_deal(unit, market)
    if not market or market <= 0 then return "grey", "≈", "–" end
    local share = (unit - market) / market
    local percent = math.floor(math.abs(share) * 100 + 0.5) .. " %"
    if share <= BARGAIN then return "gold", "▼", percent end
    if share <= GOOD_DEAL then return "green", "▼", percent end
    if share < USUAL then return "grey", "≈", percent end
    return "red", "▲", percent
end

vga.read_deal = read_deal

local function read_offers(entry)
    local offers = {}
    if entry.commodity then
        for index = 1, C_AuctionHouse.GetNumCommoditySearchResults(entry.item) do
            local found = C_AuctionHouse.GetCommoditySearchResultInfo(entry.item, index)
            if found then offers[#offers + 1] = { unit = found.unitPrice, quantity = found.quantity, own = found.containsOwnerItem } end
        end
    elseif entry.key then
        for index = 1, C_AuctionHouse.GetNumItemSearchResults(entry.key) do
            local found = C_AuctionHouse.GetItemSearchResultInfo(entry.key, index)
            if found and found.buyoutAmount then offers[#offers + 1] = { unit = found.buyoutAmount, quantity = found.quantity, own = found.containsOwnerItem } end
        end
    end
    return offers
end

local function update_offer_line(line, offer)
    local page = sell_page
    library.update_chip(line.chip, read_deal(offer.unit, page.market))
    line.quantity:SetText(offer.quantity)
    line.own:SetShown(offer.own == true)
    library.update_money(line.money, offer.unit)
    library.update_grid(line.grid, { { line.chip, line.quantity, line.own, nil, line.money } }, page.detail_width)
end

local function create_offer_line(parent)
    local line = CreateFrame("Frame", nil, parent)
    line.grid = library.create_grid(line, { columns = { 86, "auto", "auto", "rest", "auto" }, gaps = { 0, 8, 0, 0 }, padding = { 0, 12, 0, 12 }, row = 30, x = { "left", "left", "left", "left", "right" } })
    line.chip = library.create_chip(line)
    line.quantity = library.create_text(line, "figures_small", colours.ink)
    line.own = library.create_text(line, "caption", colours.gold)
    line.own:SetText(library.texts.yours)
    line.money = library.create_money(line, colours.ink)
    line.money.kind = "small"
    return line
end

local function read_offers_height()
    return library.read_draft_size(OFFER_HEAD) + OFFERS * (library.read_draft_size(OFFER_ROW) + 2)
end

local function update_offer_chips(list)
    local chips = {}
    for _, line in ipairs(library.read_list_rows_shown(list)) do chips[#chips + 1] = line.chip end
    library.update_chip_width(chips)
end

function update_offers(page)
    local entry = page.chosen
    local offers = entry and read_offers(entry) or {}
    page.market = entry and vga.read_market(entry.item)
    library.update_item_table(page.offers_group, offers, page.detail_width, read_offers_height())
    return offers
end

local function update_live_price(page, offers)
    if page.live_proposed == page.chosen.item then return end
    for _, offer in ipairs(offers) do
        if not offer.own and read_deal(offer.unit, page.market) ~= "gold" then
            page.live_proposed = page.chosen.item
            library.update_money_field(page.price, math.max(1, offer.unit - 1))
            update_result(page, page.chosen)
            return
        end
    end
end

local function write_offers_query(entry)
    local price = Enum.AuctionHouseSortOrder and Enum.AuctionHouseSortOrder.Price or 0
    local sorts = { { sortOrder = price, reverseSort = false } }
    local known = C_AuctionHouse.GetItemKeyInfo and C_AuctionHouse.GetItemKeyInfo(entry.key)
    if known and known.isEquipment then
        entry.key.itemLevel, entry.key.itemSuffix = 0, 0
        C_AuctionHouse.SendSellSearchQuery(entry.key, sorts, true)
    else
        C_AuctionHouse.SendSearchQuery(entry.key, sorts, true)
    end
end

function render_search(page)
    local entry = page.chosen
    if not (entry and C_AuctionHouse.SendSearchQuery and C_AuctionHouse.GetItemKeyFromItem) then return end
    entry.commodity = Enum.ItemCommodityStatus and C_AuctionHouse.GetItemCommodityStatus(entry.location) == Enum.ItemCommodityStatus.Commodity
    entry.key = C_AuctionHouse.GetItemKeyFromItem(entry.location)
    vga.write_auction_query(function() write_offers_query(entry) end)
end

local function create_figures(page, texts)
    local figures = { { word = texts.market_value, kind = "money" }, { word = texts.lowest_now, kind = "money" }, { word = texts.days_7, kind = "chip" }, { word = texts.offered, kind = "text", font = "bold" } }
    page.facts = library.create_figure_strip(page.detail, { figures = figures })
end

local function render_range(index)
    sell_page.range = index
    if sell_page.chosen then update_graph(sell_page, sell_page.chosen) end
end

local function create_chart(page, texts)
    page.chart = library.create_group(page.detail)
    page.legend = {}
    for index, entry in ipairs({ { "median", colours.gold }, { "mean_7", MEAN }, { "low_to_median", BAND }, { "offered", BARS } }) do
        local item = { mark = page.chart:CreateTexture(nil, "ARTWORK"), word = library.create_text(page.chart, "small", colours.quiet) }
        item.mark:SetColorTexture(entry[2][1], entry[2][2], entry[2][3], index == 3 and 0.5 or 1)
        item.word:SetText(texts[entry[1]])
        page.legend[index] = item
    end
    local labels = {}
    for index, days in ipairs(RANGES) do labels[index] = string.format(texts.days_short, days) end
    page.range = 2
    page.ranges = library.create_choice(page.chart, labels, 2, render_range)
    page.graph = library.create_graph(page.chart)
end

local function read_offer_share(offer) return sell_page.market and sell_page.market > 0 and offer.unit / sell_page.market or nil end
local function read_offer_quantity(offer) return offer.quantity end
local function read_offer_unit(offer) return offer.unit end

local function render_offers_sorted()
    update_offers(sell_page)
end

local function create_offers(page, texts)
    local columns = {
        { key = "to_market", word = texts.to_market, sort = read_offer_share, least = OFFER_CHIP },
        { key = "quantity", word = texts.quantity, sort = read_offer_quantity },
        { key = "price_each", word = texts.price_each, sort = read_offer_unit, least = "money_small", x = "right" },
    }
    page.offers_group = library.create_item_table(page.detail, { columns = columns, create_row = create_offer_line, update_row = update_offer_line, empty = texts.no_offers, on_sort = render_offers_sorted, on_rows = update_offer_chips, head = OFFER_HEAD, row = OFFER_ROW })
    page.offers, page.offer_heads, page.offers_none = page.offers_group.list, page.offers_group.heads, page.offers_group.empty
end

local function create_post_row(page, texts)
    page.post_group = library.create_group(page.detail)
    page.price_label = library.create_text(page.post_group, "small", colours.quiet)
    page.price_label:SetText(texts.price_each)
    page.price = library.create_money_field(page.post_group, function() if page.chosen then update_result(page, page.chosen) end end)
    page.stepper = library.create_stepper(page.post_group, render_step)
    local labels = {}
    for index, hours in ipairs(DURATIONS) do labels[index] = string.format(texts.hours_count, hours) end
    page.duration = 2
    page.durations = library.create_choice(page.post_group, labels, 2, function(index) page.duration = index if page.chosen then update_note(page, page.chosen) end end)
    page.post = library.create_button(page.post_group, texts.post, "gold", render_post)
    page.result_group = library.create_group(page.detail)
    page.cost_text = library.create_text(page.result_group, "small", colours.quiet)
    page.cost_money = library.create_money(page.result_group, colours.quiet)
    page.cost_money.kind = "small"
    page.cost_more = library.create_text(page.result_group, "small", colours.quiet)
    page.after_cut = library.create_text(page.result_group, "small", colours.quiet)
    page.after_cut:SetText(texts.after_cut)
    page.result = library.create_chip(page.result_group)
    page.note = library.create_text(page.detail, "small", colours.quiet)
    page.note:SetJustifyH("LEFT")
end

function vga.create_sell_page(page)
    local texts = library.texts
    sell_page = page
    page.list_group = library.create_group(page)
    page.list = library.create_list(page.list_group, create_entry_line, update_entry_line)
    page.lines = page.list.rows
    page.empty = library.create_text(page, "small", colours.quiet)
    page.empty:SetText(texts.nothing_to_post)
    page.empty:SetPoint("TOPLEFT")
    page.detail = CreateFrame("Frame", nil, page)
    page.detail_grid = library.create_grid(page.detail, { columns = { "rest" }, row = 0, row_gap = 14, y = "top" })
    create_figures(page, texts)
    create_chart(page, texts)
    create_offers(page, texts)
    create_post_row(page, texts)
end

local function update_facts_layout(page, top, gap)
    return top + library.update_figure_strip(page.facts, page.detail_width) + gap
end

local function update_chart_layout(page, top, gap, height)
    local pad = library.read_draft_size(12)
    page.chart:SetSize(page.detail_width, height)
    library.update_group(page.chart)
    library.update_choice(page.ranges)
    page.ranges:ClearAllPoints()
    page.ranges:SetPoint("TOPRIGHT", page.chart, "TOPRIGHT", -pad, -library.read_draft_size(8))
    local row, columns, gaps = {}, {}, {}
    for index, item in ipairs(page.legend) do
        item.mark:SetSize(library.read_draft_size(14), index <= 2 and 2 or library.read_draft_size(7))
        item.word:SetFontObject(library.read_font("small"))
        row[#row + 1], row[#row + 2] = item.mark, item.word
        columns[#columns + 1], columns[#columns + 2] = 14, "auto"
        gaps[#gaps + 1], gaps[#gaps + 2] = 5, 14
    end
    page.legend_grid = page.legend_grid or library.create_grid(page.chart, {})
    page.legend_grid.plan = { columns = columns, gaps = gaps, padding = { 8, 0, 0, { pixels = pad } }, row = { pixels = page.ranges:GetHeight() } }
    library.update_grid(page.legend_grid, { row })
    local graph_top = library.read_draft_size(16) + page.ranges:GetHeight()
    page.graph_width, page.graph_height = page.detail_width - 2 * pad, height - graph_top - library.read_draft_size(6)
    page.graph:ClearAllPoints()
    page.graph:SetPoint("TOPLEFT", page.chart, "TOPLEFT", pad, -graph_top)
    return top + height + gap
end

local function update_offers_layout(page, top, gap)
    update_offers(page)
    return top + read_offers_height() + gap
end

local function read_cells(row)
    local cells = {}
    for column, cell in ipairs(row) do cells[column] = cell or nil end
    return cells
end

local function update_post_layout(page, top, gap)
    local pad, height = library.read_draft_size(12), library.read_draft_size(50)
    page.post_group:SetSize(page.detail_width, height)
    library.update_group(page.post_group)
    page.price_label:SetFontObject(library.read_font("small"))
    library.update_money_field_layout(page.price)
    library.update_button(page.post)
    library.update_choice(page.durations)
    library.update_stepper(page.stepper)
    local needed = pad + math.ceil(page.price_label:GetStringWidth()) + library.read_draft_size(8) + page.price:GetWidth() + page.stepper:GetWidth() + page.durations:GetWidth() + page.post:GetWidth() + 4 * pad
    local fits = needed <= page.detail_width
    page.price_label:SetShown(fits)
    page.post_grid = page.post_grid or library.create_grid(page.post_group, {})
    local tail = { "auto", "auto", "auto" }
    page.post_grid.plan = { columns = fits and { "auto", "auto", "rest", unpack(tail) } or { "auto", "rest", unpack(tail) }, gaps = fits and { 8, 0, 0, 12, 12 } or { 0, 0, 12, 12 }, padding = { 0, 12, 0, 12 }, row = 50 }
    local row = fits and { page.price_label, page.price, false, page.stepper, page.durations, page.post } or { page.price, false, page.stepper, page.durations, page.post }
    library.update_grid(page.post_grid, { read_cells(row) }, page.detail_width)
    return top + height + gap
end

local function update_result_layout(page, top, gap)
    local pad, height = library.read_draft_size(12), library.read_draft_size(36)
    page.result_group:SetSize(page.detail_width, height)
    library.update_group(page.result_group)
    local near = library.read_draft_size(4)
    page.result_grid = page.result_grid or library.create_grid(page.result_group, { columns = { "auto", "auto", "auto", "auto", "auto" }, gaps = { 4, 4, 10, 10 }, padding = { 0, 0, 0, 12 }, row = 36 })
    library.update_grid(page.result_grid, { { page.cost_text, page.cost_money, page.cost_more, page.after_cut, page.result } })
    page.note:ClearAllPoints()
    page.note:SetPoint("TOPLEFT", page.result_group, "BOTTOMLEFT", near, -near)
    page.note:SetWidth(page.detail_width - 2 * near)
    return top + height + gap
end

local function update_detail_layout(page)
    local gap = library.read_draft_size(14)
    page.detail:ClearAllPoints()
    page.detail:SetPoint("TOPLEFT", page, "TOPLEFT", page.list_width + gap, 0)
    page.detail:SetPoint("BOTTOMRIGHT")
    local fixed = library.read_draft_size(52) + read_offers_height() + library.read_draft_size(50) + library.read_draft_size(36) + library.read_draft_size(34) + 5 * gap
    local top = update_facts_layout(page, 0, gap)
    top = update_chart_layout(page, top, gap, math.max(library.read_draft_size(140), page:GetHeight() - fixed))
    top = update_offers_layout(page, top, gap)
    top = update_post_layout(page, top, gap)
    update_result_layout(page, top, gap)
    library.update_grid(page.detail_grid, { { page.facts }, { page.chart }, { page.offers_group }, { page.post_group }, { page.result_group } }, page.detail_width)
end

function vga.update_sell_page(page, width)
    page.entries = read_bag_items()
    if page.chosen then
        local kept
        for _, entry in ipairs(page.entries) do if entry.item == page.chosen.item then kept = entry end end
        page.chosen = kept
    end
    page.chosen = page.chosen or page.entries[1]
    page.list_width = math.floor(width * 0.36)
    page.detail_width = width - page.list_width - library.read_draft_size(14)
    page.empty:SetShown(#page.entries == 0)
    update_lines(page)
    update_detail_layout(page)
    update_detail(page)
    update_offers(page)
    if page.chosen and page.searched ~= page.chosen.item then
        page.searched = page.chosen.item
        render_search(page)
    end
end

function vga.read_sellable_count()
    return #read_bag_items()
end

local function update_results()
    if not (sell_page and sell_page:IsVisible() and sell_page.chosen) then return end
    local offers = update_offers(sell_page)
    update_live_price(sell_page, offers)
end

local function update_visit()
    if not sell_page then return end
    sell_page.searched, sell_page.live_proposed = nil, nil
end

local events = CreateFrame("Frame")
for _, name in ipairs({ "COMMODITY_SEARCH_RESULTS_UPDATED", "ITEM_SEARCH_RESULTS_UPDATED", "AUCTION_HOUSE_SHOW" }) do pcall(events.RegisterEvent, events, name) end
events:SetScript("OnEvent", function(_, event)
    if event == "AUCTION_HOUSE_SHOW" then
        update_visit()
    else
        library.update_safely("auctions offers", update_results)
    end
end)

vga.read_sellable_items = read_bag_items
