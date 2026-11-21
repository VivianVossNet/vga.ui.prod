-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.auctions' page Meine Auktionen as the accepted draft draws it (manual/view/vga-auctions.html, page »Meine Auktionen«, K0688): the player's own auctions asked of the game whenever the page is shown (C_AuctionHouse.QueryOwnedAuctions, answered by OWNED_AUCTIONS_UPDATED); in one of LibVGA's groups four figures - active, undercut in red, the value of the active ones, sold today from the ledger -; then the auctions in LibVGA's list under sortable heads, its columns by library.read_columns (K0686) - the item's picture and name in its quality's colour, the quantity, the price each, the state - undercut by how much as a red chip where a cheaper offer of the last reading stands below it, the cheapest as a green chip, sold and in the mailbox in quiet words -, the time left in hours, and one button: »Neu einstellen« where undercut, which withdraws it and opens Verkaufen with the item chosen once it is back in the bags, »Zurückziehen« where it is the cheapest, asking once as »Alles zurücksetzen« does; the game's deposit is lost on either; a note beneath as the draft's. The auctions are asked for at every opening too, three seconds after it and patient until the throttle is ready, and every answer counts the undercut ones for the sidebar's red count beside »Meine Auktionen«, as the draft shows it (K0689).

-- {K0688} {K0689}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local HEADS = { "item", "quantity", "price_each", "state", "time_left_short" }
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
    local page, size = mine_page, library.read_draft_size(26)
    local columns, x = page.columns, page.pad
    line.row = row
    line.icon:SetTexture(row.icon)
    line.icon:SetSize(size, size)
    line.icon:ClearAllPoints()
    line.icon:SetPoint("LEFT", line, "LEFT", x, 0)
    local colour = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[row.quality or 1]
    line.name:SetText(row.name)
    line.name:SetTextColor(colour and colour.r or 1, colour and colour.g or 1, colour and colour.b or 1, 1)
    line.name:ClearAllPoints()
    line.name:SetPoint("LEFT", line.icon, "RIGHT", library.read_size(-4), 0)
    line.name:SetWidth(math.max(1, columns.rights[1] - size - library.read_size(-4)))
    line.quantity:SetText(row.auction.quantity or 1)
    line.quantity:ClearAllPoints()
    line.quantity:SetPoint("LEFT", line, "LEFT", x + columns.lefts[2], 0)
    library.update_money(line.price, math.floor(row.each + 0.5))
    line.price:ClearAllPoints()
    line.price:SetPoint("RIGHT", line, "LEFT", x + columns.rights[3], 0)
    update_state(line, row)
    for _, shown in ipairs({ line.chip, line.sold }) do
        shown:ClearAllPoints()
        shown:SetPoint("LEFT", line, "LEFT", x + columns.lefts[4], 0)
    end
    line.left:SetText(read_hours(row.auction))
    line.left:ClearAllPoints()
    line.left:SetPoint("LEFT", line, "LEFT", x + columns.lefts[5], 0)
    update_action(line, row)
    line.action:ClearAllPoints()
    line.action:SetPoint("RIGHT", line, "LEFT", x + columns.rights[6], 0)
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
    local line = CreateFrame("Frame", nil, parent)
    line:EnableMouse(true)
    line.icon = line:CreateTexture(nil, "ARTWORK")
    line.name = library.create_text(line, "body", colours.ink)
    line.name:SetJustifyH("LEFT")
    line.name:SetWordWrap(false)
    line.quantity = library.create_text(line, "small", colours.ink)
    line.price = library.create_money(line, colours.ink)
    line.price.kind = "small"
    line.chip = library.create_chip(line)
    line.sold = library.create_text(line, "small", colours.quiet)
    line.sold:SetText(library.texts.sold_mailbox)
    line.left = library.create_text(line, "small", colours.quiet)
    line.action = library.create_button(line, library.texts.withdraw, "metal", render_action)
    line:SetScript("OnEnter", render_row_tip)
    line:SetScript("OnLeave", vga.update_item_tip_hidden)
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

function vga.create_mine_page(page)
    local texts = library.texts
    mine_page = page
    page.sums = library.create_group(page)
    page.figures = {}
    for index, key in ipairs({ "active", "undercut", "value_active", "sold_today" }) do
        local figure = { label = library.create_text(page.sums, "caption", colours.quiet) }
        figure.label:SetText(texts[key]:upper())
        figure.count = index <= 2 and library.create_text(page.sums, "title", index == 2 and RED or colours.ink) or nil
        figure.money = index > 2 and library.create_money(page.sums, colours.ink) or nil
        figure.rule = index > 1 and library.create_hairline(page.sums) or nil
        page.figures[index] = figure
    end
    page.group = library.create_group(page)
    page.list = library.create_list(page.group, create_mine_row, update_mine_row)
    page.list.sorters = { item = read_sort_name, quantity = read_sort_quantity, price_each = read_sort_each, state = read_sort_state, time_left_short = read_sort_left }
    page.list.on_sort = render_mine
    page.heads = {}
    for index, key in ipairs(HEADS) do page.heads[index] = library.create_sort_head(page.list, page.group, texts[key]:upper(), key) end
    page.empty = library.create_text(page.group, "small", colours.quiet)
    page.empty:SetText(texts.mine_empty)
    page.note = library.create_text(page, "small", colours.quiet)
    page.note:SetJustifyH("LEFT")
    page.note:SetText(texts.mine_note)
    page.probe_money = library.create_money(page, colours.ink)
    page.probe_money.kind = "small"
    page.probe_text = library.create_text(page, "small", colours.ink)
    page.probe_chip = library.create_chip(page)
    page.probe_chip:Hide()
    page.probe_button = library.create_button(page, texts.repost, "metal", render_mine)
    page.probe_button:Hide()
    page.lines = page.list.rows
end

local function read_sold_today()
    local _, sales = vga.read_holdings()
    local today = sales[math.floor(time() / 86400)]
    return today and today.proceeds or 0
end

local function update_sums(page, rows, width)
    local active, undercut, value = 0, 0, 0
    for _, row in ipairs(rows) do
        if row.state ~= "sold" then active, value = active + 1, value + (row.auction.buyoutAmount or 0) end
        if row.state == "undercut" then undercut = undercut + 1 end
    end
    page.figures[1].count:SetText(active)
    page.figures[2].count:SetText(undercut)
    library.update_money(page.figures[3].money, value)
    library.update_money(page.figures[4].money, read_sold_today())
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
        local shown = figure.count or figure.money
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

local function read_mine_columns(page)
    local texts = library.texts
    for index, heading in ipairs(page.heads) do library.update_sort_head(heading, index == 3) end
    local function read_room(index, least) return math.max(page.heads[index]:GetWidth(), least) end
    local state = math.max(library.read_widest_chip(page.probe_chip), library.read_widest_text(page.probe_text, texts.sold_mailbox), library.read_widest_text(page.probe_text, string.format(texts.undercut_by, 100)) + library.read_size(0))
    local widest = 0
    for _, word in ipairs({ texts.repost, texts.withdraw, texts.withdraw_sure }) do
        page.probe_button.text:SetText(word)
        library.update_button(page.probe_button)
        widest = math.max(widest, page.probe_button:GetWidth())
    end
    return library.read_columns(page.width, { false, read_room(2, library.read_widest_text(page.probe_text, "99999")), read_room(3, library.read_widest_money(page.probe_money)), read_room(4, state), read_room(5, library.read_widest_text(page.probe_text, string.format(texts.hours_count, 48))), widest })
end

function vga.update_mine_page(page, width)
    page.full_width, page.pad = width, library.read_draft_size(12)
    page.width = width - 2 * page.pad
    local rows = read_rows()
    local top = update_sums(page, rows, width)
    local head, row, note = library.read_draft_size(28), library.read_draft_size(40), library.read_draft_size(40)
    local height = math.max(page:GetHeight() - top - note, head + 3 * row)
    page.group:ClearAllPoints()
    page.group:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -top)
    page.group:SetSize(width, height)
    library.update_group(page.group)
    page.columns = read_mine_columns(page)
    local columns, icon = page.columns, library.read_draft_size(26) + library.read_size(-4)
    local places = { { "LEFT", columns.lefts[1] + icon }, { "LEFT", columns.lefts[2] }, { "RIGHT", columns.rights[3] }, { "LEFT", columns.lefts[4] }, { "LEFT", columns.lefts[5] } }
    for index, heading in ipairs(page.heads) do
        local place = places[index]
        heading:ClearAllPoints()
        heading:SetPoint(place[1], page.group, "TOPLEFT", page.pad + place[2], -head / 2)
    end
    page.list:ClearAllPoints()
    page.list:SetPoint("TOPLEFT", page.group, "TOPLEFT", 0, -head)
    library.update_list(page.list, rows, width, height - head, row)
    page.empty:SetShown(#rows == 0)
    page.empty:ClearAllPoints()
    page.empty:SetPoint("TOP", page.group, "TOP", 0, -(head + row))
    page.note:SetFontObject(library.read_font("small"))
    page.note:ClearAllPoints()
    page.note:SetPoint("TOPLEFT", page.group, "BOTTOMLEFT", library.read_draft_size(4), -library.read_draft_size(6))
    page.note:SetWidth(width - library.read_draft_size(8))
end

function vga.write_mine_query(patient)
    local house = C_AuctionHouse
    if not house.QueryOwnedAuctions then return end
    local price = Enum.AuctionHouseSortOrder and Enum.AuctionHouseSortOrder.Price or 0
    vga.write_auction_query(function() house.QueryOwnedAuctions({ { sortOrder = price, reverseSort = false } }) end, patient)
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
