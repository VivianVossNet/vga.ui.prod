-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.auctions' ledger, the second step (K0608, K0611): what each item the player holds has cost, per realm - loot at nothing, marked as found; a merchant's piece at his price over his stack; an auction bought outright at its bid; a bulk purchase at the total the game named for it -; the cost the weighted average of the bought pieces still held; a sale read from the mail's invoice, its proceeds after deposit and cut, its gain against that average, kept by day for thirty days; pieces gone otherwise - used, sold to a merchant, destroyed - taken out when bags and bank hold fewer than at the last look, bought pieces before found ones; pieces posted to the auction house are not counted as gone, and a rise - a purchase fetched from the mail - changes nothing. Every purchase, sale and expired auction is kept besides as one event of thirty days - when, the item, the way, how many, the money, and for a sale the cost of its bought pieces and how many were found -, the expired ones read from the mail whose subject is the game's AUCTION_EXPIRED_MAIL_SUBJECT, its item from the mail's first attachment (vga.read_ledger_events, K0684).

-- {K0608} {K0611} {K0684}

local _, vga = ...
local library = LibVGA
local KEEP_DAYS = 30
local pending = {}

local function read_ledger()
    local store = vga.read_auction_store()
    store.ledger = store.ledger or { holdings = {}, sales = {}, invoices = {} }
    store.ledger.events = store.ledger.events or {}
    return store.ledger
end

local function write_event(event)
    local events, oldest = read_ledger().events, time() - KEEP_DAYS * 86400
    event.at = time()
    events[#events + 1] = event
    while events[1] and events[1].at < oldest do table.remove(events, 1) end
end

function vga.read_ledger_events()
    return read_ledger().events
end

local function read_holding(item_id)
    local holdings = read_ledger().holdings
    holdings[item_id] = holdings[item_id] or { bought = 0, cost = 0, found = 0 }
    return holdings[item_id]
end

function vga.write_bought(item_id, count, total, way)
    if not item_id or not count or count <= 0 then return end
    local holding = read_holding(item_id)
    holding.bought, holding.cost, holding.way = holding.bought + count, holding.cost + (total or 0), way
    write_event({ item = item_id, way = way, count = count, money = total or 0 })
end

function vga.write_found(item_id, count)
    if not item_id or not count or count <= 0 then return end
    local holding = read_holding(item_id)
    holding.found = holding.found + count
end

local function update_taken(holding, count)
    local from_bought = math.min(holding.bought, count)
    local average = holding.bought > 0 and holding.cost / holding.bought or 0
    holding.bought, holding.cost = holding.bought - from_bought, holding.cost - average * from_bought
    holding.found = math.max(0, holding.found - (count - from_bought))
    return average, from_bought
end

function vga.read_holdings()
    return read_ledger().holdings, read_ledger().sales
end

function vga.read_cost(item_id)
    local holding = read_ledger().holdings[item_id]
    if not holding or holding.bought <= 0 then return nil, holding and holding.found or 0 end
    return holding.cost / holding.bought, holding.found, holding.bought
end

local function read_day()
    return math.floor(time() / 86400)
end

local function write_sale(item_id, count, proceeds)
    local holding = read_holding(item_id)
    local average, from_bought = update_taken(holding, count)
    local sales, today = read_ledger().sales, read_day()
    local day = sales[today] or { proceeds = 0, cost = 0, found = 0 }
    day.proceeds, day.cost = day.proceeds + proceeds, day.cost + average * from_bought
    day.found = day.found + (count - from_bought)
    sales[today] = day
    write_event({ item = item_id, way = "sale", count = count, money = proceeds, cost = average * from_bought, found = count - from_bought })
    for old in pairs(sales) do
        if old < today - KEEP_DAYS then sales[old] = nil end
    end
end

local function read_expired_pattern()
    local subject = AUCTION_EXPIRED_MAIL_SUBJECT
    return subject and ("^" .. subject:gsub("[%(%)%.%+%-%*%?%[%]%^%$]", "%%%0"):gsub("%%s", "(.+)") .. "$")
end

local function write_expired(index, subject, key)
    local pattern, invoices = read_expired_pattern(), read_ledger().invoices
    if not (pattern and subject and subject:match(pattern)) or invoices["expired|" .. key] then return end
    local _, item_id, _, count = GetInboxItem(index, 1)
    if not item_id then return end
    invoices["expired|" .. key] = read_day()
    write_event({ item = item_id, way = "expired", count = count or 1, money = 0 })
end

local function update_invoices()
    local invoices = read_ledger().invoices
    for index = 1, (GetInboxNumItems and GetInboxNumItems() or 0) do
        local kind, name, _, _, buyout, deposit, cut, _, _, _, count = GetInboxInvoiceInfo(index)
        local _, _, subject, money, _, days = GetInboxHeaderInfo(index)
        local key = tostring(subject) .. "|" .. tostring(money) .. "|" .. tostring(days and math.floor(days * 1440))
        local item_id = name and GetItemInfoInstant and GetItemInfoInstant(name)
        write_expired(index, subject, key)
        if kind == "seller" and item_id and not invoices[key] then
            invoices[key] = read_day()
            write_sale(item_id, count or 1, (buyout or 0) + (deposit or 0) - (cut or 0))
        end
    end
end

local function update_reconciled()
    local holdings = read_ledger().holdings
    for item_id, holding in pairs(holdings) do
        local held = GetItemCount(item_id, true)
        if holding.seen and held < holding.seen then update_taken(holding, holding.seen - held) end
        holding.seen = held
        if holding.bought + holding.found <= 0 then holdings[item_id] = nil end
    end
end

local function update_posted(location, quantity)
    local item_id = location and C_Item and C_Item.GetItemID and C_Item.GetItemID(location)
    local holding = item_id and read_ledger().holdings[item_id]
    if holding and holding.seen then holding.seen = holding.seen - (quantity or 1) end
end

local function update_loot(message)
    local link, count = message:match("(|Hitem:.-|h.-|h)x(%d+)")
    if not link then link = message:match("(|Hitem:.-|h.-|h)") end
    if not link or not LOOT_ITEM_SELF or not message:find(LOOT_ITEM_SELF:match("^([^%%]+)") or "\0", 1, true) then return end
    vga.write_found(GetItemInfoInstant(link), tonumber(count) or 1)
end

local function update_merchant_bought(index, quantity)
    local offer = C_MerchantFrame and C_MerchantFrame.GetItemInfo and C_MerchantFrame.GetItemInfo(index)
    local link = GetMerchantItemLink(index)
    if not (offer and link) then return end
    local stack = math.max(offer.stackCount or 1, 1)
    local count = quantity or stack
    vga.write_bought(GetItemInfoInstant(link), count, offer.price / stack * count, "merchant")
end

local function update_bid(auction_id, amount)
    local offer = C_AuctionHouse.GetAuctionInfoByID and C_AuctionHouse.GetAuctionInfoByID(auction_id)
    if offer and offer.buyoutAmount and amount >= offer.buyoutAmount then
        pending.item = { offer.itemKey and offer.itemKey.itemID, offer.quantity or 1, amount }
    end
end

local function update_commodity_start(item_id, quantity)
    pending.commodity = { item_id, quantity }
end

local function update_event(event, first, second)
    if event == "COMMODITY_PRICE_UPDATED" and pending.commodity then
        pending.commodity[3] = second
    elseif event == "COMMODITY_PURCHASE_SUCCEEDED" and pending.commodity and pending.commodity[3] then
        vga.write_bought(pending.commodity[1], pending.commodity[2], pending.commodity[3], "commodity")
        pending.commodity = nil
    elseif event == "ITEM_PURCHASED" and pending.item then
        vga.write_bought(pending.item[1] or first, pending.item[2], pending.item[3], "auction")
        pending.item = nil
    elseif event == "CHAT_MSG_LOOT" then
        update_loot(first or "")
    elseif event == "MAIL_INBOX_UPDATE" then
        update_invoices()
    elseif event == "BAG_UPDATE_DELAYED" then
        update_reconciled()
    end
end

local function create_hooks()
    if BuyMerchantItem then hooksecurefunc("BuyMerchantItem", function(index, quantity) library.update_safely("ledger merchant", update_merchant_bought, index, quantity) end) end
    if C_AuctionHouse and C_AuctionHouse.PlaceBid then hooksecurefunc(C_AuctionHouse, "PlaceBid", function(id, amount) library.update_safely("ledger bid", update_bid, id, amount) end) end
    if C_AuctionHouse and C_AuctionHouse.PostItem then hooksecurefunc(C_AuctionHouse, "PostItem", function(location, _, quantity) library.update_safely("ledger post", update_posted, location, quantity) end) end
    if C_AuctionHouse and C_AuctionHouse.PostCommodity then hooksecurefunc(C_AuctionHouse, "PostCommodity", function(location, _, quantity) library.update_safely("ledger post", update_posted, location, quantity) end) end
    if C_AuctionHouse and C_AuctionHouse.StartCommoditiesPurchase then hooksecurefunc(C_AuctionHouse, "StartCommoditiesPurchase", function(id, quantity) library.update_safely("ledger commodity", update_commodity_start, id, quantity) end) end
end

local events = CreateFrame("Frame")
for _, name in ipairs({ "PLAYER_LOGIN", "COMMODITY_PRICE_UPDATED", "COMMODITY_PURCHASE_SUCCEEDED", "ITEM_PURCHASED", "CHAT_MSG_LOOT", "MAIL_INBOX_UPDATE", "BAG_UPDATE_DELAYED" }) do
    pcall(events.RegisterEvent, events, name)
end
events:SetScript("OnEvent", function(_, event, first, second)
    if event == "PLAYER_LOGIN" then
        library.update_safely("ledger hooks", create_hooks)
    else
        library.update_safely("ledger " .. event, update_event, event, first, second)
    end
end)
