-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.auctions' data, the first step of the auction window (manual/view/vga-auctions.html, K0603, K0609): whenever the auction house opens, the game's whole list of auctions is asked for - a second after opening and only once the throttle is ready, so the game's own window's first search goes first instead of being cut off and leaving the house broken for the visit, as NaowhForever warns (K0663) - - at most once in fifteen minutes, as the game allows -, read in slices so the frame never stalls, and every item's day kept per realm - its name from GetRealmName, else the normalised name, else the player's full name, a list kept under an empty name moved to it (K0610) -: its lowest unit buyout, the median unit buyout over all pieces offered, and how many are offered; ninety days are kept; an item's market value is the median of its last seven daily medians. Bid-only auctions are left out. Every query of the window goes through vga.write_auction_query, which waits in line while the throttle is busy and sends in turn whenever any message of the throttle finds it ready, as Auctionator's queue does (K0656, K0693), one message at a time, and sends again at the next ready signal what the game dropped. An item's required level is read for every list of the window, loaded where the game does not know it yet, shown red above the player's level (vga.read_item_level, K0647). Every item in the window's lists shows the game's item tooltip on hover, compared with what the player wears (vga.render_item_tip, K0648), a little right of the cursor and following it (K0650). Watched items are kept per realm beside the days (vga.check_watched, vga.write_watched, vga.read_watched, K0655). The game's auction addon is loaded by the game at the opening, never earlier: loaded at login, its first-load bids query went out with no house open and left the first opening's throttle never ready (K0674, superseding K0668's preload). Every query - a search, the offers of an item chosen on Verkaufen, the player's auctions, the whole-house reading - waits in line while the throttle is busy and goes out in turn as it turns ready, one at a time, since the game drops an addon's query sent while busy without a word: an item chosen on Verkaufen right after another query showed »Gerade kein Angebot« until the page was laid anew (K0693). Every measuring line is gone for the release - the timeline, the messages heard, the throttle's counts, the realm's names; the count of offers read is kept in the store for the window's head, and what earlier versions measured is cleared from the saved variables at login (K0690). The workarounds laid while the cause of the empty first searches was sought - the poll, the calls written with their callers, the kick's favourite, the bids query skipped, the interaction timed - are gone again: the cause was vga.ui's own window closing the house at its first opening (K0681, K0682).

-- {K0787} {K0609} {K0610} {K0629} {K0638} {K0639} {K0641} {K0646} {K0647} {K0648} {K0649} {K0650} {K0652} {K0655} {K0656} {K0663} {K0668} {K0674} {K0682} {K0690} {K0693}

local _, vga = ...
local library = LibVGA
local SCAN_DELAY = 1
local SCAN_SECONDS = 15 * 60
local SLICE = 500
local KEEP_DAYS = 90
local MARKET_DAYS = 7
local DAY_SECONDS = 86400
local scan = { reading = false, done = 0, total = 0 }

local function read_day()
    return math.floor(time() / DAY_SECONDS)
end

local function read_realm()
    local named = GetRealmName and GetRealmName()
    if named and named ~= "" then return named end
    local normalised = GetNormalizedRealmName and GetNormalizedRealmName()
    if normalised and normalised ~= "" then return normalised end
    local _, own = UnitFullName("player")
    return (own and own ~= "") and own or "?"
end

local function read_store()
    VGAAuctions = VGAAuctions or {}
    local realm = read_realm()
    if VGAAuctions[""] and realm ~= "?" then
        VGAAuctions[realm], VGAAuctions[""] = VGAAuctions[realm] or VGAAuctions[""], nil
    end
    VGAAuctions[realm] = VGAAuctions[realm] or { items = {} }
    return VGAAuctions[realm]
end

local function check_cheaper(one, other)
    return one[1] < other[1]
end

local function read_day_figures(offers)
    table.sort(offers, check_cheaper)
    local quantity = 0
    for _, offer in ipairs(offers) do quantity = quantity + offer[2] end
    local half, counted = quantity / 2, 0
    for _, offer in ipairs(offers) do
        counted = counted + offer[2]
        if counted >= half then return offers[1][1], offer[1], quantity end
    end
    return offers[1][1], offers[1][1], quantity
end

local function update_old_days(item, today)
    for day in pairs(item) do
        if day < today - KEEP_DAYS then item[day] = nil end
    end
end

local function write_days(found)
    local store, today = read_store(), read_day()
    for item_id, offers in pairs(found) do
        local item = store.items[item_id] or {}
        local least, median, quantity = read_day_figures(offers)
        item[today] = { least, median, quantity }
        update_old_days(item, today)
        store.items[item_id] = item
    end
end

local function write_offers_read()
    read_store().offers = scan.total
end

local function update_slice()
    local last = math.min(scan.done + SLICE, scan.total)
    for index = scan.done, last - 1 do
        local _, _, count, _, _, _, _, _, _, buyout, _, _, _, _, _, _, item_id = C_AuctionHouse.GetReplicateItemInfo(index)
        if item_id and buyout and buyout > 0 and count and count > 0 then
            scan.found[item_id] = scan.found[item_id] or {}
            local offers = scan.found[item_id]
            offers[#offers + 1] = { buyout / count, count }
        end
    end
    scan.done = last
    if scan.done < scan.total then
        C_Timer.After(0, function() library.update_safely("auctions slice", update_slice) end)
        return
    end
    write_days(scan.found)
    scan.reading, scan.found = false, nil
    write_offers_read()
end

local function update_list()
    if not scan.asked or scan.reading then return end
    scan.asked, scan.reading = false, true
    scan.done, scan.total, scan.found = 0, C_AuctionHouse.GetNumReplicateItems(), {}
    update_slice()
end

local function write_replicate()
    local store = read_store()
    if (store.scanned and time() - store.scanned < SCAN_SECONDS) or scan.reading or not scan.open then return end
    store.scanned, scan.asked = time(), true
    C_AuctionHouse.ReplicateItems()
end

local function update_opened()
    scan.open = true
    C_Timer.After(SCAN_DELAY, function() vga.write_auction_query(write_replicate) end)
end

function vga.read_item_level(item_id)
    local level = select(5, C_Item.GetItemInfo(item_id))
    if level == nil and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(item_id) end
    return level
end

function vga.read_level_text(level)
    if not level or level < 1 then return "–" end
    local own = UnitLevel("player") or 1
    return level > own and ("|cffe2675a" .. level .. "|r") or tostring(level)
end

function vga.render_item_tip(owner, item)
    library.update_item_tip_owner(GameTooltip, owner)
    if item.bag then
        GameTooltip:SetBagItem(item.bag, item.slot)
    elseif item.key and GameTooltip.SetItemKey then
        GameTooltip:SetItemKey(item.key.itemID, item.key.itemLevel or 0, item.key.itemSuffix or 0)
    else
        GameTooltip:SetItemByID(item.id)
    end
    GameTooltip:Show()
    if GameTooltip_ShowCompareItem then GameTooltip_ShowCompareItem(GameTooltip) end
end

function vga.update_item_tip_hidden()
    GameTooltip:Hide()
end

local function read_watched_store()
    local store = read_store()
    store.watched = store.watched or {}
    return store.watched
end

function vga.check_watched(item_id)
    return read_watched_store()[item_id] == true
end

function vga.write_watched(item_id, on)
    read_watched_store()[item_id] = on or nil
end

function vga.read_watched()
    local found = {}
    for item_id in pairs(read_watched_store()) do found[#found + 1] = item_id end
    return found
end

local function check_lower(one, other)
    return one < other
end

function vga.read_market(item_id)
    local item = read_store().items[item_id]
    if not item then return nil end
    local days = {}
    for day in pairs(item) do days[#days + 1] = day end
    table.sort(days, check_lower)
    local medians = {}
    for index = math.max(1, #days - MARKET_DAYS + 1), #days do medians[#medians + 1] = item[days[index]][2] end
    table.sort(medians, check_lower)
    local latest = item[days[#days]]
    return medians[math.ceil(#medians / 2)], latest[1], latest[3]
end

function vga.read_days(item_id, count)
    local item, today = read_store().items[item_id] or {}, read_day()
    local least, median, quantity = {}, {}, {}
    for index = 1, count do
        local day = item[today - count + index]
        if day then least[index], median[index], quantity[index] = day[1], day[2], day[3] end
    end
    return least, median, quantity
end

vga.read_auction_store = read_store

function vga.read_next_scan()
    local scanned = read_store().scanned
    return scanned and scanned + SCAN_SECONDS
end

function vga.read_auction_scan()
    return scan.reading, scan.done, scan.total
end

local query = {}

local function check_query_ready()
    return not C_AuctionHouse.IsThrottledMessageSystemReady or C_AuctionHouse.IsThrottledMessageSystemReady()
end

function vga.write_auction_query(send)
    query.waiting = query.waiting or {}
    if not check_query_ready() then
        query.waiting[#query.waiting + 1] = send
        return
    end
    query.last = send
    send()
end

local function check_query_waiting()
    return (query.waiting and #query.waiting > 0) or query.dropped ~= nil
end

local function update_query_ready()
    local send = query.dropped or table.remove(query.waiting or {}, 1)
    query.dropped = nil
    if send then vga.write_auction_query(send) end
end

local function update_query_dropped()
    query.dropped = query.last
end

local THROTTLE_MESSAGES = { "AUCTION_HOUSE_THROTTLED_MESSAGE_QUEUED", "AUCTION_HOUSE_THROTTLED_MESSAGE_SENT", "AUCTION_HOUSE_THROTTLED_MESSAGE_RESPONSE_RECEIVED" }

local heard = CreateFrame("Frame")
for _, name in ipairs(THROTTLE_MESSAGES) do pcall(heard.RegisterEvent, heard, name) end
heard:SetScript("OnEvent", function()
    if check_query_waiting() and check_query_ready() then library.update_safely("auctions query ready", update_query_ready) end
end)

local function update_measures_cleared()
    local measures = LibVGASettings.measures or {}
    for key in pairs(measures) do
        if key:find("^auction_") or key:find("^ledger_") then measures[key] = nil end
    end
end

local events = CreateFrame("Frame")
for _, name in ipairs({ "PLAYER_LOGIN", "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED", "REPLICATE_ITEM_LIST_UPDATE", "AUCTION_HOUSE_THROTTLED_SYSTEM_READY", "AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED" }) do
    pcall(events.RegisterEvent, events, name)
end
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        library.update_safely("auctions measures cleared", update_measures_cleared)
    elseif event == "AUCTION_HOUSE_SHOW" then
        query.waiting, query.dropped = {}, nil
        library.update_safely("auctions opened", update_opened)
    elseif event == "AUCTION_HOUSE_CLOSED" then
        scan.open = false
    elseif event == "AUCTION_HOUSE_THROTTLED_SYSTEM_READY" then
        library.update_safely("auctions query ready", update_query_ready)
    elseif event == "AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED" then
        library.update_safely("auctions query dropped", update_query_dropped)
    else
        library.update_safely("auctions list", update_list)
    end
end)
