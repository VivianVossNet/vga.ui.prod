-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.auctions' window, step 3a (manual/view/vga-auctions.html, K0603, K0612): a dialog of the template with a sidebar - Kaufen, Verkaufen, Meine Auktionen, Depot, Verlauf, Beobachtet (vga.ui/Auctionwatch.lua, K0655) -, Verlauf built by vga.ui/Auctionhistory.lua (K0684), Meine Auktionen by vga.ui/Auctionmine.lua, which may turn the window to Verkaufen with an item chosen (vga.render_auction_page, K0688); the undercut auctions counted in red beside it in the sidebar, asked for three seconds after every opening (vga.update_own_count, K0689), the page's title, and in the head the reading's progress - how many offers were read and how long ago, the last count kept across restarts, and when the next reading may come, »neu ab 23:34« within the fifteen minutes and »neu beim nächsten Öffnen« after them (K0691), or that the house is being read -; it opens instead of the game's auction house, always on Kaufen (K0624) - the game's own window opened by the game's player interaction manager as ever - in Forever not UIParent, so K0651's silencing of UIParent did nothing and is gone (K0659) - and veiled; the bags opened by us too; the head button loads and shows the game's window on the owner's wish, and should it stand, it is veiled; when the house closes the game's window only takes back its look and place, never shown, since a window shown on a closed house sends its own queries into nothing and leaves the throttle stuck for the next visit (K0665) - invisible, shrunk and laid off the screen (K0645) -; veiled again once its addon has loaded and a frame after opening -, whose window is made invisible and out of reach while it stays open, and a button in the head brings the game's window back for this visit, the search text carried over into its search box (K0639); closing ours closes the auction house - heard only once the new window has first been hidden, since that first hiding, at the very first opening after a load, closed the house the moment it opened and left the visit without any answer (K0681). The page Kaufen is vga.ui/Auctionbuy.lua's (K0621), the page Verkaufen vga.ui/Auctionsell.lua's (K0617), refreshed when the bags change. The page Depot is built: on top the value today, the cost, the book gain and what was sold in thirty days, then every holding - item, stock, origin, average cost, market value, the result as a chip, the gain in gold -, the most valuable first; the other pages say they come in the next step.

-- {K0603} {K0608} {K0612} {K0617} {K0621} {K0624} {K0631} {K0632} {K0643} {K0645} {K0647} {K0648} {K0651} {K0655} {K0659} {K0665} {K0681} {K0684} {K0688} {K0689} {K0691}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local PAGES = {
    { key = "buy", icon = "CoinCopper" }, { key = "sell", icon = "CoinGold" }, { key = "own_auctions", icon = "TabProfiles" },
    { key = "depot", icon = "TabBars" }, { key = "history", icon = "TabExperience" }, { key = "watched", icon = "EyeOpen" },
}
local WIDTH, HEIGHT = 82, 54
local SAVED = 8
local OFF_SCREEN = 4000
local CUT = 0.05
local OWN_DELAY = 3
local window
local update_depot

local function read_texts()
    return library.texts
end

local function read_grouped(number)
    local text = tostring(number)
    local grouped = text:reverse():gsub("(%d%d%d)", "%1 "):reverse()
    return (grouped:gsub("^ ", ""))
end

local function read_scan_line()
    local reading, done, total = vga.read_auction_scan()
    if reading then return read_texts().reading .. " " .. math.floor(done / math.max(total, 1) * 100) .. " %", done / math.max(total, 1) end
    local count = vga.read_auction_store().offers
    if not count then return "", 0 end
    local scanned = vga.read_auction_store().scanned
    local minutes = scanned and math.floor((time() - scanned) / 60)
    local ago = minutes and (minutes < 1 and read_texts().just_now or string.format(read_texts().minutes_ago, minutes))
    local next_scan = vga.read_next_scan()
    local again = next_scan and (next_scan > time() and string.format(read_texts().next_read_at, date("%H:%M", next_scan)) or read_texts().next_read_open)
    return string.format(read_texts().offers_read, read_grouped(count)) .. (ago and (" · " .. ago) or "") .. (again and (" · " .. again) or ""), 1
end

local function read_ways()
    local texts = read_texts()
    return { merchant = texts.way_merchant, auction = texts.way_auction, commodity = texts.way_commodity }
end

local function read_depot_rows()
    local holdings, rows = vga.read_holdings(), {}
    for item_id, holding in pairs(holdings) do
        local market = vga.read_market(item_id)
        local pieces = holding.bought + holding.found
        if pieces > 0 then
            rows[#rows + 1] = { item = item_id, holding = holding, market = market, value = (market or 0) * pieces }
        end
    end
    table.sort(rows, function(one, other) return one.value > other.value end)
    return rows
end

local function read_result(holding, market)
    if holding.bought <= 0 or not market then return nil end
    local average = holding.cost / holding.bought
    return (market * (1 - CUT) - average) / math.max(average, 1), (market * (1 - CUT) - average) * holding.bought
end

local function update_chip_for(chip, share, found)
    if found then return library.update_chip(chip, "gold", "◆", read_texts().found) end
    if not share then return library.update_chip(chip, "grey", "≈", "–") end
    local percent = math.floor(math.abs(share) * 100 + 0.5)
    library.update_chip(chip, share >= 0 and "green" or "red", share >= 0 and "▲" or "▼", percent .. " %")
end

local function render_holding_tip(line)
    if line.item_id then vga.render_item_tip(line, { id = line.item_id }) end
end

local function create_line(parent)
    local line = CreateFrame("Frame", nil, parent)
    line:EnableMouse(true)
    line:SetScript("OnEnter", render_holding_tip)
    line:SetScript("OnLeave", vga.update_item_tip_hidden)
    line.icon = line:CreateTexture(nil, "ARTWORK")
    line.unusable = library.create_unusable(line, line.icon)
    line.name = library.create_text(line, "body", colours.ink)
    line.name:SetJustifyH("LEFT")
    line.name:SetWordWrap(false)
    line.stock = library.create_text(line, "small", colours.ink)
    line.level = library.create_text(line, "small", colours.label)
    line.origin = library.create_text(line, "small", colours.quiet)
    line.cost = library.create_money(line, colours.ink)
    line.market = library.create_money(line, colours.ink)
    line.chip = library.create_chip(line)
    line.minus = library.create_text(line, "small", colours.ink)
    line.minus:SetText("−")
    line.gain = library.create_money(line, colours.ink)
    for _, money in ipairs({ line.cost, line.market, line.gain }) do money.kind = "small" end
    return line
end

local function read_columns(width)
    local pad, apart = library.read_draft_size(12), library.read_draft_size(10)
    local fixed = { 26, 44, 56, 96, 90, 90, 72, 92 }
    local sizes = {}
    for index, pixels in ipairs(fixed) do sizes[index] = library.read_draft_size(pixels) end
    local fixed_sum = 0
    for _, size in ipairs(sizes) do fixed_sum = fixed_sum + size end
    local name = width - 2 * pad - 8 * apart - fixed_sum
    local level = pad + sizes[1] + apart + name + apart
    local stock = level + sizes[2] + apart
    local origin = stock + sizes[3] + apart
    local cost = origin + sizes[4] + apart + sizes[5]
    local market = cost + apart + sizes[6]
    return { icon = pad, name = pad + sizes[1] + apart, name_width = name, level = level, stock = stock, origin = origin, cost = cost, market = market, result = market + apart, gain = width - pad }
end

local function update_line(line, row)
    local page = window.pages.depot
    local columns, ways = page.columns, page.ways
    local size, item, holding = library.read_draft_size(26), row.item, row.holding
    line.item_id = item
    local items = C_Item or {}
    line.icon:SetSize(size, size)
    line.icon:ClearAllPoints()
    line.icon:SetPoint("LEFT", line, "LEFT", columns.icon, 0)
    line.icon:SetTexture(items.GetItemIconByID and items.GetItemIconByID(item) or 134400)
    library.update_unusable(line.unusable, item)
    line.name:SetText(items.GetItemNameByID and items.GetItemNameByID(item) or tostring(item))
    line.name:ClearAllPoints()
    line.name:SetPoint("LEFT", line, "LEFT", columns.name, 0)
    line.name:SetWidth(columns.name_width)
    line.stock:SetText(holding.bought + holding.found)
    line.level:SetText(vga.read_level_text(vga.read_item_level(item)))
    local found = holding.bought <= 0
    line.origin:SetText(found and read_texts().found or (ways[holding.way] or ""))
    local origin = found and colours.gold or colours.quiet
    line.origin:SetTextColor(origin[1], origin[2], origin[3], 1)
    local average = holding.bought > 0 and holding.cost / holding.bought or nil
    library.update_money(line.cost, average and math.floor(average + 0.5) or 0)
    line.cost:SetShown(average ~= nil)
    library.update_money(line.market, row.market and math.floor(row.market + 0.5) or 0)
    line.market:SetShown(row.market ~= nil)
    local share, gain = read_result(holding, row.market)
    update_chip_for(line.chip, share, found)
    local amount = gain or (row.market or 0) * holding.found
    local ink = amount < 0 and { 0.886, 0.404, 0.353 } or colours.ink
    library.update_money(line.gain, math.floor(math.abs(amount) + 0.5))
    for _, group in ipairs(line.gain.groups) do group.text:SetTextColor(ink[1], ink[2], ink[3], 1) end
    line.minus:SetShown(amount < 0)
    line.minus:SetTextColor(ink[1], ink[2], ink[3], 1)
    for _, placed in ipairs({ { line.level, "LEFT", columns.level }, { line.stock, "LEFT", columns.stock }, { line.origin, "LEFT", columns.origin }, { line.cost, "RIGHT", columns.cost }, { line.market, "RIGHT", columns.market }, { line.chip, "LEFT", columns.result }, { line.gain, "RIGHT", columns.gain } }) do
        placed[1]:ClearAllPoints()
        placed[1]:SetPoint(placed[2], line, "LEFT", placed[3], 0)
    end
    line.minus:ClearAllPoints()
    line.minus:SetPoint("RIGHT", line.gain, "LEFT", -1, 0)
end

local function update_depot_chips(list)
    local chips = {}
    for _, line in ipairs(library.read_list_rows_shown(list)) do chips[#chips + 1] = line.chip end
    library.update_chip_width(chips)
end

local function read_holding_name(row) return C_Item.GetItemNameByID and C_Item.GetItemNameByID(row.item) or tostring(row.item) end
local function read_holding_level(row) return vga.read_item_level(row.item) end
local function read_holding_stock(row) return row.holding.bought + row.holding.found end
local function read_holding_origin(row) return row.holding.bought > 0 and (row.holding.way or "") or "" end
local function read_holding_cost(row) return row.holding.bought > 0 and row.holding.cost / row.holding.bought or nil end
local function read_holding_market(row) return row.market end

local function read_holding_result(row)
    local share = read_result(row.holding, row.market)
    return share
end

local function read_holding_gain(row)
    local _, gain = read_result(row.holding, row.market)
    return gain or (row.market or 0) * row.holding.found
end

local function render_depot_sorted()
    update_depot(window.pages.depot, window.page_width)
end

local function create_depot(page)
    local texts = read_texts()
    page.sums = library.create_group(page)
    page.figures = {}
    for index, key in ipairs({ "value_today", "cost", "book_gain", "sold_30" }) do
        local figure = { label = library.create_text(page.sums, "caption", colours.quiet) }
        figure.label:SetText(texts[key]:upper())
        figure.money = index <= 2 and library.create_money(page.sums, colours.ink) or nil
        figure.chip = index > 2 and library.create_chip(page.sums) or nil
        figure.rule = index > 1 and library.create_hairline(page.sums) or nil
        page.figures[index] = figure
    end
    page.holdings = library.create_group(page)
    page.list = library.create_list(page.holdings, create_line, update_line)
    page.list.sorters = { item = read_holding_name, level = read_holding_level, stock = read_holding_stock, origin = read_holding_origin, average_cost = read_holding_cost, market_value = read_holding_market, result = read_holding_result, in_gold = read_holding_gain }
    page.list.on_sort = render_depot_sorted
    page.heads = {}
    for index, key in ipairs({ "item", "level", "stock", "origin", "average_cost", "market_value", "result", "in_gold" }) do
        page.heads[index] = library.create_sort_head(page.list, page.holdings, texts[key]:upper(), key)
    end
    page.list.on_rows = update_depot_chips
    page.lines = page.list.rows
    page.empty = library.create_text(page.holdings, "small", colours.quiet)
    page.empty:SetText(texts.depot_empty)
    page.note = library.create_text(page, "small", colours.quiet)
    page.note:SetJustifyH("LEFT")
    page.note:SetText(texts.depot_note)
end

local function update_figures(page, rows, width)
    local value, cost, gain_cost = 0, 0, 0
    for _, row in ipairs(rows) do
        value = value + (row.market or 0) * (row.holding.bought + row.holding.found)
        cost = cost + row.holding.cost
        gain_cost = gain_cost + (row.market or 0) * (1 - CUT) * row.holding.bought
    end
    local _, sales = vga.read_holdings()
    local proceeds, sold_cost = 0, 0
    for _, day in pairs(sales) do proceeds, sold_cost = proceeds + day.proceeds, sold_cost + day.cost end
    library.update_money(page.figures[1].money, math.floor(value + 0.5))
    library.update_money(page.figures[2].money, math.floor(cost + 0.5))
    update_chip_for(page.figures[3].chip, cost > 0 and (gain_cost - cost) / cost or nil)
    update_chip_for(page.figures[4].chip, sold_cost > 0 and (proceeds - sold_cost) / sold_cost or nil)
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
    return height + library.read_draft_size(14)
end

function update_depot(page, width)
    local rows = read_depot_rows()
    local top = update_figures(page, rows, width)
    local columns = read_columns(width)
    local head, row, note = library.read_draft_size(28), library.read_draft_size(40), library.read_draft_size(40)
    local height = math.max(page:GetHeight() - top - note, head + 3 * row)
    page.holdings:ClearAllPoints()
    page.holdings:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -top)
    page.holdings:SetSize(width, height)
    library.update_group(page.holdings)
    local places = { { "LEFT", columns.name }, { "LEFT", columns.level }, { "LEFT", columns.stock }, { "LEFT", columns.origin }, { "RIGHT", columns.cost }, { "RIGHT", columns.market }, { "LEFT", columns.result }, { "RIGHT", columns.gain } }
    for index, heading in ipairs(page.heads) do
        library.update_sort_head(heading, places[index][1] == "RIGHT")
        heading:ClearAllPoints()
        heading:SetPoint(places[index][1], page.holdings, "TOPLEFT", places[index][2], -head / 2)
    end
    page.columns, page.ways = columns, read_ways()
    page.list:ClearAllPoints()
    page.list:SetPoint("TOPLEFT", page.holdings, "TOPLEFT", 0, -head)
    library.update_list(page.list, rows, width, height - head, row)
    page.empty:SetShown(#rows == 0)
    page.empty:ClearAllPoints()
    page.empty:SetPoint("TOP", page.holdings, "TOP", 0, -(head + row))
    page.note:SetFontObject(library.read_font("small"))
    page.note:ClearAllPoints()
    page.note:SetPoint("TOPLEFT", page.holdings, "BOTTOMLEFT", library.read_draft_size(4), -library.read_draft_size(6))
    page.note:SetWidth(width - library.read_draft_size(8))
end

local function update_page(key)
    local saved = tonumber(tostring(key):match("^saved(%d+)$"))
    if saved then
        update_page("buy")
        vga.render_saved_search(vga.read_saved_searches()[saved])
        return
    end
    window.chosen = key
    window.heading:SetText(read_texts()[key])
    for name, page in pairs(window.pages) do page:SetShown(name == key) end
    library.update_sidebar(window.sidebar, key)
    if key == "depot" then update_depot(window.pages.depot, window.page_width) end
    if key == "sell" then vga.update_sell_page(window.pages.sell, window.page_width) end
    if key == "buy" then vga.update_buy_page(window.pages.buy, window.page_width) end
    if key == "watched" then vga.update_watch_page(window.pages.watched, window.page_width) end
    if key == "history" then vga.update_history_page(window.pages.history, window.page_width) end
    if key == "own_auctions" then
        vga.update_mine_page(window.pages.own_auctions, window.page_width)
        vga.write_mine_query()
    end
end

function vga.update_own_count(undercut)
    if window then library.update_sidebar_count(window.sidebar, "own_auctions", undercut > 0 and undercut or nil, true) end
end

function vga.render_auction_page(key, item)
    if key == "sell" and item then window.pages.sell.chosen = { item = item } end
    update_page(key)
end

local function update_sidebar_entries()
    local searches = vga.read_saved_searches and vga.read_saved_searches() or {}
    for index = 1, SAVED do library.update_sidebar_entry(window.sidebar, "saved" .. index, searches[index], searches[index] ~= nil) end
    local sellable = vga.read_sellable_count and vga.read_sellable_count()
    library.update_sidebar_count(window.sidebar, "sell", sellable and sellable > 0 and sellable or nil)
end

local function update_scan_line()
    if not (window and window:IsShown()) then return end
    local line, share = read_scan_line()
    window.scan:SetText(line)
    library.update_progress(window.progress, share, library.read_draft_size(160))
end

local function update_window()
    if not window then return end
    library.update_dialog(window)
    local scale = library.read_base() / 13
    local width, height = math.floor(WIDTH * 13 * scale), math.floor(HEIGHT * 13 * scale)
    window:SetSize(width, height)
    local side, gap, inner = library.read_sidebar_width(window.sidebar), library.read_size(0), library.read_size(-4)
    update_sidebar_entries()
    library.update_sidebar(window.sidebar, window.chosen)
    window.sidebar:ClearAllPoints()
    window.sidebar:SetPoint("TOPLEFT", window.body, "TOPLEFT")
    window.sidebar:SetPoint("BOTTOMLEFT", window.body, "BOTTOMLEFT")
    window.sidebar:SetWidth(side)
    window.heading:SetFontObject(library.read_font("title"))
    window.heading:ClearAllPoints()
    window.heading:SetPoint("TOPLEFT", window.body, "TOPLEFT", side + gap, -library.read_size(-2))
    window.scan:SetFontObject(library.read_font("small"))
    window.scan:ClearAllPoints()
    window.progress:ClearAllPoints()
    window.progress:SetPoint("RIGHT", window.game_button, "LEFT", -library.read_size(-2), 0)
    window.scan:SetPoint("RIGHT", window.progress, "LEFT", -library.read_draft_size(8), 0)
    window.page_width = width - side - gap - 2 * inner - gap
    for _, page in pairs(window.pages) do
        page:ClearAllPoints()
        page:SetPoint("TOPLEFT", window.body, "TOPLEFT", side + gap, -(library.read_size(4) + library.read_size(-2)))
        page:SetPoint("BOTTOMRIGHT", window.body, "BOTTOMRIGHT", -gap, gap)
        if page.note then page.note:SetFontObject(library.read_font("small")) end
    end
    update_scan_line()
    update_page(window.chosen or "depot")
end

function vga.update_saved_searches()
    if window and window:IsShown() then update_window() end
end

local function read_game_window()
    return AuctionHouseFrame or AuctionFrame
end

local function update_game_look(game, shown)
    game:SetAlpha(shown and 1 or 0)
    game:SetScale(shown and 1 or 0.01)
    if not shown then
        game:ClearAllPoints()
        game:SetPoint("TOPLEFT", UIParent, "BOTTOMRIGHT", OFF_SCREEN, -OFF_SCREEN)
    elseif UpdateUIPanelPositions then
        UpdateUIPanelPositions(game)
    end
end

local function update_game_window(shown)
    if shown and not read_game_window() and C_AddOns and C_AddOns.LoadAddOn then C_AddOns.LoadAddOn("Blizzard_AuctionHouseUI") end
    local game = read_game_window()
    if not game or (not shown and not game:IsShown()) then return end
    if shown and not game:IsShown() and ShowUIPanel then ShowUIPanel(game) end
    update_game_look(game, shown)
end

local function update_game_restored()
    local game = read_game_window()
    if not game then return end
    update_game_look(game, true)
end

local function write_search_over()
    local box = AuctionHouseFrame and AuctionHouseFrame.SearchBar and AuctionHouseFrame.SearchBar.SearchBox
    local text = vga.read_buy_text and vga.read_buy_text()
    if box and text then box:SetText(text) end
end

local function render_game_window()
    window.keep_house = true
    window:Hide()
    update_game_window(true)
    write_search_over()
end

local function update_closed_window()
    if not window.keep_house and C_AuctionHouse.CloseAuctionHouse then C_AuctionHouse.CloseAuctionHouse() end
end

local function create_window()
    local texts = read_texts()
    window = library.create_dialog("VGAAuctionWindow", "vga.auctions")
    window:SetPoint("TOPLEFT", UIParent, "TOPLEFT", library.read_size(4), -library.read_size(8))
    window.game_button = library.create_dialog_button(window, "Sort", render_game_window)
    window.progress = library.create_progress(window)
    window.game_button:SetScript("OnEnter", function(button) GameTooltip:SetOwner(button, "ANCHOR_BOTTOM") GameTooltip:SetText(texts.game_window) GameTooltip:Show() end)
    window.game_button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    window.scan = library.create_text(window, "small", colours.quiet)
    window.heading = library.create_text(window.body, "title", colours.ink)
    local entries = {}
    for _, entry in ipairs(PAGES) do entries[#entries + 1] = { key = entry.key, title = texts[entry.key], icon = entry.icon } end
    local saved = {}
    for index = 1, SAVED do saved[index] = { key = "saved" .. index, title = "", icon = "Search", free = true } end
    window.sidebar = library.create_sidebar(window.body, { { title = texts.auctions, entries = entries }, { title = texts.saved_searches, entries = saved } }, update_page)
    window.pages = {}
    for _, entry in ipairs(PAGES) do
        local page = CreateFrame("Frame", nil, window.body)
        if entry.key == "depot" then
            create_depot(page)
        elseif entry.key == "sell" then
            vga.create_sell_page(page)
        elseif entry.key == "buy" then
            vga.create_buy_page(page)
        elseif entry.key == "watched" then
            vga.create_watch_page(page)
        elseif entry.key == "history" then
            vga.create_history_page(page)
        elseif entry.key == "own_auctions" then
            vga.create_mine_page(page)
        else
            page.note = library.create_text(page, "small", colours.quiet)
            page.note:SetText(texts.next_step)
            page.note:SetPoint("TOPLEFT")
        end
        window.pages[entry.key] = page
    end
    window:Hide()
    window:SetScript("OnHide", function() library.update_safely("auctions window closed", update_closed_window) end)
    library.create_element("auctions", { update = update_window })
end

local function update_veiled()
    if window and window:IsShown() then update_game_window(false) end
end

local function update_opened()
    if not window then create_window() end
    if OpenAllBags then OpenAllBags() end
    window.keep_house = false
    window.chosen = "buy"
    vga.update_buy_visit()
    window:Show()
    update_window()
    update_veiled()
    C_Timer.After(0, function() library.update_safely("auctions game veiled", update_veiled) end)
    C_Timer.After(OWN_DELAY, function() library.update_safely("auctions own query", vga.write_mine_query) end)
end

local function update_house_closed()
    update_game_restored()
    if window then
        window.keep_house = true
        window:Hide()
    end
end

vga.update_auction_scan_line = update_scan_line

local events = CreateFrame("Frame")
pcall(events.RegisterEvent, events, "AUCTION_HOUSE_SHOW")
pcall(events.RegisterEvent, events, "ADDON_LOADED")
pcall(events.RegisterEvent, events, "GET_ITEM_INFO_RECEIVED")
pcall(events.RegisterEvent, events, "AUCTION_HOUSE_CLOSED")
pcall(events.RegisterEvent, events, "BAG_UPDATE_DELAYED")
events:SetScript("OnEvent", function(_, event, first)
    if event == "GET_ITEM_INFO_RECEIVED" then
        if window and window:IsShown() and not window.known_soon then
            window.known_soon = true
            C_Timer.After(0.3, function()
                window.known_soon = nil
                library.update_safely("auctions page", update_page, window.chosen)
            end)
        end
    elseif event == "ADDON_LOADED" then
        if tostring(first):find("Auction") then library.update_safely("auctions game veiled", update_veiled) end
    elseif event == "AUCTION_HOUSE_SHOW" then
        library.update_safely("auctions window", update_opened)
    elseif event == "BAG_UPDATE_DELAYED" then
        if window and window:IsShown() then library.update_safely("auctions page", update_page, window.chosen) end
    else
        library.update_safely("auctions window closed", update_house_closed)
    end
end)
C_Timer.NewTicker(1, function() library.update_safely("auctions scan line", update_scan_line) end)
