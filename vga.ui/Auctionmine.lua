-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.auctions' page Meine Auktionen as the accepted draft draws it (manual/view/vga-auctions.html, page »Meine Auktionen«, K0688): the player's own auctions asked of the game whenever the page is shown (C_AuctionHouse.QueryOwnedAuctions, answered by OWNED_AUCTIONS_UPDATED); in one of LibVGA's groups four figures - active, undercut in red, the value of the active ones, sold today from the ledger -; then the auctions in LibVGA's list under sortable heads, its columns by library.read_columns (K0686) - the item's picture and name in its quality's colour, the quantity, the price each, the state - undercut by how much as a red chip where a cheaper offer of the last reading stands below it, the cheapest as a green chip, sold and in the mailbox in quiet words -, the time left in hours, and one button: »Neu einstellen« where undercut, which withdraws it and opens Verkaufen with the item chosen once it is back in the bags, »Zurückziehen« where it is the cheapest, asking once as »Alles zurücksetzen« does; the game's deposit is lost on either; a note beneath as the draft's. The page fills LibVGA's ledger page (library.create_ledger_page, K0870): its figure strip (K0869) with the four figures, its item table (K0862) with the auctions, its note. The auctions are asked for at every opening too, three seconds after it and patient until the throttle is ready, and every answer counts the undercut ones for the sidebar's red count beside »Meine Auktionen«, as the draft shows it (K0689).

-- {K0870} {K0869} {K0862} {K0802} {K0798} {K0789} {K0785} {K0688} {K0689}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local SOLD = 1
local HOUR = 3600
local RED = { 0.886, 0.404, 0.353 }
local mine_page

local function read_state(auction, lowest)
    if auction.status == SOLD then return "sold" end
    local each = (auction.buyoutAmount or 0) / math.max(auction.quantity or 1, 1)
    if lowest and each > 0 and lowest < each then return "undercut", (each - lowest) / each end
    return "cheapest"
end

local function read_rows()
    local rows, house = {}, C_AuctionHouse
    local owned = house.GetOwnedAuctions and house.GetOwnedAuctions() or {}
    for _, auction in ipairs(owned) do
        local item = auction.itemKey and auction.itemKey.itemID
        local name, _, quality, _, _, _, _, _, _, icon = C_Item.GetItemInfo(item or 0)
        local _, lowest = vga.read_market(item)
        local state, share = read_state(auction, lowest)
        rows[#rows + 1] = { auction = auction, item = item, name = name or tostring(item), quality = quality, icon = icon or 134400, each = (auction.buyoutAmount or 0) / math.max(auction.quantity or 1, 1), state = state, share = share }
    end
    return rows
end

local function read_hours(auction)
    if auction.status == SOLD or not auction.timeLeftSeconds then return "–" end
    return string.format(library.texts.hours_count, math.ceil(auction.timeLeftSeconds / HOUR))
end

local function update_state(line, row)
    local texts = library.texts
    line.chip:SetShown(row.state ~= "sold")
    line.sold:SetShown(row.state == "sold")
    if row.state == "undercut" then
        library.update_chip(line.chip, "red", "▼", string.format(texts.undercut_by, math.floor(row.share * 100 + 0.5)))
    elseif row.state == "cheapest" then
        library.update_chip(line.chip, "green", "◆", texts.cheapest_own)
    end
end

local function update_action(line, row)
    local texts = library.texts
    line.action:SetShown(row.state ~= "sold")
    line.action.words = row.state == "undercut" and texts.repost or texts.withdraw
    line.action.ask = row.state == "cheapest" and texts.withdraw_sure or nil
    line.action.text:SetText(line.action.words)
    library.update_button(line.action)
end

local function update_mine_row(line, row)
    local page = mine_page
    local columns, x = page.ledger.table.columns, page.ledger.table.pad
    line.row = row
    library.update_item_row(line, { icon = row.icon, id = row.item, name = row.name, quality = row.quality }, x, x + columns.rights[1])
    line.quantity:SetText(row.auction.quantity or 1)
    library.update_money(line.price, math.floor(row.each + 0.5))
    update_state(line, row)
    line.left:SetText(read_hours(row.auction))
    update_action(line, row)
    library.update_grid_columns(line, columns, x, { { line.quantity, 2 }, { line.price, 3, "right" }, { line.chip, 4 }, { line.sold, 4 }, { line.left, 5 }, { line.action, 6, "right" } })
end

local function render_action(button)
    local row = button:GetParent().row
    if not (row and C_AuctionHouse.CancelAuction) then return end
    C_AuctionHouse.CancelAuction(row.auction.auctionID)
    if row.state == "undercut" and vga.render_auction_page then vga.render_auction_page("sell", row.item) end
end

local function render_row_tip(line)
    if line.row then vga.render_item_tip(line, { id = line.row.item }) end
end

local function create_mine_row(parent)
    local line = library.create_item_row(parent, { on_enter = render_row_tip, on_leave = vga.update_item_tip_hidden })
    line.quantity = library.create_text(line, "figures_small", colours.ink)
    line.price = library.create_money(line, colours.ink)
    line.price.kind = "small"
    line.chip = library.create_chip(line)
    line.sold = library.create_text(line, "small", colours.quiet)
    line.sold:SetText(library.texts.sold_mailbox)
    line.left = library.create_text(line, "figures_small", colours.quiet)
    line.action = library.create_button(line, library.texts.withdraw, "metal", render_action)
    return line
end

local function read_sort_name(row) return row.name end
local function read_sort_quantity(row) return row.auction.quantity or 1 end
local function read_sort_each(row) return row.each end
local function read_sort_state(row) return row.state == "undercut" and 1 + row.share or (row.state == "cheapest" and 0.5 or 0) end
local function read_sort_left(row) return row.auction.timeLeftSeconds or 0 end

local function render_mine()
    vga.update_mine_page(mine_page, mine_page.full_width)
end

local function read_state_room(sheet)
    local texts = library.texts
    return math.max(library.read_widest_chip(sheet.probe_chip), library.read_item_table_text(sheet, texts.sold_mailbox), library.read_item_table_text(sheet, string.format(texts.undercut_by, 100)) + library.read_size(0))
end

local function read_left_room(sheet)
    return library.read_item_table_text(sheet, string.format(library.texts.hours_count, 48))
end

local function read_action_room()
    local texts, probe, widest = library.texts, mine_page.probe_button, 0
    for _, word in ipairs({ texts.repost, texts.withdraw, texts.withdraw_sure }) do
        probe.text:SetText(word)
        library.update_button(probe)
        widest = math.max(widest, probe:GetWidth())
    end
    return widest
end

local function read_auctions_plan(texts)
    local columns = {
        { key = "item", word = texts.item, sort = read_sort_name, inset = "icon" },
        { key = "quantity", word = texts.quantity, sort = read_sort_quantity, least = "99999" },
        { key = "price_each", word = texts.price_each, sort = read_sort_each, least = "money_small", x = "right" },
        { key = "state", word = texts.state, sort = read_sort_state, least = read_state_room },
        { key = "time_left_short", word = texts.time_left_short, sort = read_sort_left, least = read_left_room },
        { key = "action", least = read_action_room },
    }
    return { columns = columns, create_row = create_mine_row, update_row = update_mine_row, empty = texts.mine_empty, on_sort = render_mine }
end

local function read_strip_plan(texts)
    return { figures = { { word = texts.active, kind = "text", font = "title" }, { word = texts.undercut, kind = "text", font = "title", colour = RED }, { word = texts.value_active, kind = "money" }, { word = texts.sold_today, kind = "money" } } }
end

function vga.create_mine_page(page)
    local texts = library.texts
    mine_page = page
    page.ledger = library.create_ledger_page(page, { strip = read_strip_plan(texts), table = read_auctions_plan(texts), note = texts.mine_note })
    page.probe_button = library.create_button(page, texts.repost, "metal", render_mine)
    page.probe_button:Hide()
    page.list = page.ledger.table.list
    page.lines = page.list.rows
end

local function read_sold_today()
    local _, sales = vga.read_holdings()
    local today = sales[math.floor(time() / 86400)]
    return today and today.proceeds or 0
end

local function update_sums(page, rows)
    local active, undercut, value = 0, 0, 0
    for _, row in ipairs(rows) do
        if row.state ~= "sold" then active, value = active + 1, value + (row.auction.buyoutAmount or 0) end
        if row.state == "undercut" then undercut = undercut + 1 end
    end
    local figures = page.ledger.strip.figures
    figures[1].value:SetText(active)
    figures[2].value:SetText(undercut)
    library.update_money(figures[3].value, value)
    library.update_money(figures[4].value, read_sold_today())
end

function vga.update_mine_page(page, width)
    page.full_width = width
    local rows = read_rows()
    update_sums(page, rows)
    library.update_ledger_page(page.ledger, rows, width, page:GetHeight())
end

function vga.write_mine_query()
    local house = C_AuctionHouse
    if not house.QueryOwnedAuctions then return end
    local price = Enum.AuctionHouseSortOrder and Enum.AuctionHouseSortOrder.Price or 0
    vga.write_auction_query(function() house.QueryOwnedAuctions({ { sortOrder = price, reverseSort = false } }) end)
end

local function update_undercut_count()
    local undercut = 0
    for _, row in ipairs(read_rows()) do
        if row.state == "undercut" then undercut = undercut + 1 end
    end
    if vga.update_own_count then vga.update_own_count(undercut) end
end

local events = CreateFrame("Frame")
for _, name in ipairs({ "OWNED_AUCTIONS_UPDATED", "AUCTION_CANCELED" }) do pcall(events.RegisterEvent, events, name) end
events:SetScript("OnEvent", function(_, event)
    if event == "OWNED_AUCTIONS_UPDATED" then library.update_safely("auctions own count", update_undercut_count) end
    if not (mine_page and mine_page:IsVisible()) then return end
    if event == "AUCTION_CANCELED" then return library.update_safely("auctions own query", vga.write_mine_query) end
    library.update_safely("auctions own", vga.update_mine_page, mine_page, mine_page.full_width)
end)
