-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.auctions' page Kaufen, step 3c rethought and made calm (K0627: the gold »Suchen« beside the field, the path line always there, fine lines round the fields, a header over the results, »Suche läuft …« until the game answers) (manual/view/vga-auctions.html »Kaufen, neu gedacht« and »Die Ebenen, zu Ende gedacht«, K0603, K0621, K0622, K0624): one search field as Spotlight draws it - the lens, ✕ to empty it, ☆ to keep the search, gold when kept -, the kept searches, up to eight for the account, in the window's sidebar under their own heading as the draft draws them (K0632); then the path - »Alle« and every level chosen, each a way back - and the next choice as LibVGA's segmented choice, »Alle« first, the quality from which on, as the game names and colours it, and on the same line the level from and to (K0638) with »Alle Stufen« or »Passend für meine Stufe ±2« as a segmented choice too, no pills (K0634); the levels run to the end - weapons to their sorts, armour to the places on the body by the game's inventory types, the chest with the robe, jewellery to its places, trade goods, recipes and bags to the game's own subclasses -, a chosen last level staying on the path with its siblings beside it;  the game's own obsolete classes - named »…(OBSOLETE)« by the game, as Jewelry and Generic in Forever - left out at every level (K0667); every opening of the window starting afresh - text, path, quality and levels reset, the list empty (K0666), and the purchase too: no »Bestätigen«, no price, the quantity back at one; the watched items stay (K0683) -; nothing listed until »Suchen« or Enter is pressed - setting a filter only sets it, ✕ only empties the field (K0661) -; a search takes the filters as they stand and runs through the game's own auction window as its engine, as NaowhForever does - its Buy mode, the category our node names in the game's words, the text, the levels and the qualities set there and its own SendBrowseQuery called, once the throttle is ready; a node standing for several of the game's categories - Ausrüstung, Handwerk, bundles - searched once in each, one after another, the answers merged; a node with no counterpart searched without a category (K0664), a named path the game's tree does not hold skipped, never searched without a category (K0667) -; only the answers after our query are shown, cut to our finer levels where the game's categories are coarser; buying always at the live price (K0662); empty text meaning everything in the path, the qualities from the chosen one on asked for, all by default as the game's own window does; the search, the path, the choice and the levels in one of LibVGA's groups, the results in another under their heads (K0632), in LibVGA's list, scrolling, as many as the game sends (K0631) - picture, name in its quality's colour, the required level - red above the player's (K0647) -, quantity, lowest price, market value, the lowest price against it as a chip -, an eye at the row's end watching the item (K0655); every column title sorting the results, a second click the other way (K0655); the columns laid by library.read_columns, each as wide as its widest content, never running into each other (K0686); where the path runs through Handwerk, Behälter or Quest, whose items have no level, the level fields, the level choice and the level column are hidden, the name taking the column's room, the row keeping its height, and the search asks for every level (K0687); the chosen ringed in gold on a faint gold ground, known by its item key so a fresh reading of the results keeps it (K0642); beneath, the quantity and the gold »Kaufen«, which asks the game for the real price first and turns into »Bestätigen«, so nothing is bought by one click; »Kaufen« and »Bestätigen« shown off and taking no click while the player's money does not cover the price - the lowest price times the quantity, then the real price -, weighed again whenever the money changes (K0683); every query sent only when the game's throttle is ready, a refused one sent once more a second later (K0629).

-- {K0621} {K0622} {K0624} {K0627} {K0629} {K0631} {K0632} {K0634} {K0638} {K0642} {K0647} {K0648} {K0649} {K0655} {K0660} {K0661} {K0662} {K0664} {K0666} {K0667} {K0683} {K0686} {K0687}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local SAVED = 8
local LEVEL_NEAR = 2
local CRUMBS = 5
local LEVEL_CAP = 60
local FIELD_GROUND = { 0.031, 0.035, 0.043 }
local HEADS = { "item", "level", "quantity", "price_each", "market_value", "to_market" }
local QUALITIES = { "PoorQuality", "CommonQuality", "UncommonQuality", "RareQuality", "EpicQuality", "LegendaryQuality", "ArtifactQuality" }
local ARMOUR_SLOTS = { "IndexHeadType", "IndexShoulderType", "IndexChestType", "IndexWaistType", "IndexLegsType", "IndexFeetType", "IndexWristType", "IndexHandType" }
local CLOTH_SLOTS = { "IndexHeadType", "IndexShoulderType", "IndexChestType", "IndexWaistType", "IndexLegsType", "IndexFeetType", "IndexWristType", "IndexHandType", "IndexCloakType" }
local JEWELLERY_SLOTS = { "IndexNeckType", "IndexFingerType", "IndexTrinketType", "IndexHoldableType" }
local buy_page
local update_results
local write_next_chain
local filters

local function read_class(class) return function() return C_Item.GetItemClassInfo(class) or tostring(class) end end
local function read_sub(class, sub) return function() return C_Item.GetItemSubClassInfo(class, sub) or tostring(sub) end end
local function read_word(key) return function() return library.texts[key] end end

local function read_inventory_type(name)
    return Enum.InventoryType and Enum.InventoryType[name]
end

local function read_slot(name)
    return function() return C_Item.GetItemInventorySlotInfo and C_Item.GetItemInventorySlotInfo(read_inventory_type(name)) or name end
end

local function read_name(global) return function() return _G[global] end end

local function read_chain(prefix, step)
    local chain = {}
    for index, part in ipairs(prefix) do chain[index] = part end
    chain[#chain + 1] = step
    return chain
end

local WEAPONS, ARMOUR = read_name("AUCTION_CATEGORY_WEAPONS"), read_name("AUCTION_CATEGORY_ARMOR")
local ONE_HAND, TWO_HAND, RANGED = read_name("AUCTION_SUBCATEGORY_ONE_HANDED"), read_name("AUCTION_SUBCATEGORY_TWO_HANDED"), read_name("AUCTION_SUBCATEGORY_RANGED")
local CONSUMABLES, CONTAINERS = read_name("AUCTION_CATEGORY_CONSUMABLES"), read_name("AUCTION_CATEGORY_CONTAINERS")
local TRADE_GOODS, RECIPES, GEMS = read_name("AUCTION_CATEGORY_TRADE_GOODS"), read_name("AUCTION_CATEGORY_RECIPES"), read_name("AUCTION_CATEGORY_GEMS")
local ENHANCEMENT, QUEST, MISCELLANEOUS = read_name("AUCTION_CATEGORY_ITEM_ENHANCEMENT"), read_name("AUCTION_CATEGORY_QUEST_ITEMS"), read_name("AUCTION_CATEGORY_MISCELLANEOUS")
local WEAPON_PLACE = { [15] = ONE_HAND, [7] = ONE_HAND, [0] = ONE_HAND, [4] = ONE_HAND, [13] = ONE_HAND, [19] = ONE_HAND, [8] = TWO_HAND, [1] = TWO_HAND, [5] = TWO_HAND, [6] = TWO_HAND, [10] = TWO_HAND, [2] = RANGED, [18] = RANGED, [3] = RANGED, [16] = RANGED }

local function read_weapon_chain(sub)
    return { WEAPONS, WEAPON_PLACE[sub], read_sub(2, sub) }
end

local function create_slots(class, sub, names, prefix)
    local nodes = {}
    for _, name in ipairs(names) do
        local classes = { { class, sub, read_inventory_type(name) } }
        if name == "IndexChestType" then classes[2] = { class, sub, read_inventory_type("IndexRobeType") } end
        nodes[#nodes + 1] = { word = read_slot(name), classes = classes, blizzard = { read_chain(prefix, read_slot(name)) } }
    end
    return nodes
end

local function create_subs(class, subs, read_sub_chain)
    local nodes = {}
    for _, sub in ipairs(subs) do nodes[#nodes + 1] = { word = read_sub(class, sub), classes = { { class, sub } }, blizzard = { read_sub_chain(sub) } } end
    return nodes
end

local function create_armour(sub, names)
    local prefix = { ARMOUR, read_sub(4, sub) }
    return { word = read_sub(4, sub), classes = { { 4, sub } }, blizzard = { prefix }, children = create_slots(4, sub, names, prefix) }
end

local function create_group(word, class, subs, whole)
    local classes, chains = {}, {}
    for index, sub in ipairs(subs) do
        classes[index] = { class, sub }
        chains[index] = read_weapon_chain(sub)
    end
    return { word = word, classes = classes, blizzard = whole and { whole } or chains, children = create_subs(class, subs, read_weapon_chain) }
end

local function create_weapons()
    return { word = read_class(2), classes = { { 2 } }, blizzard = { { WEAPONS } }, children = {
        create_group(read_word("one_hand"), 2, { 15, 7, 0, 4, 13 }, { WEAPONS, ONE_HAND }),
        create_group(read_word("two_hand"), 2, { 8, 1, 5 }),
        create_group(read_word("poles_staves"), 2, { 6, 10 }),
        create_group(read_word("ranged"), 2, { 2, 18, 3, 19 }),
        { word = read_sub(2, 16), classes = { { 2, 16 } }, blizzard = { read_weapon_chain(16) } },
    } }
end

local function create_equipment()
    local jewellery = { ARMOUR, read_sub(4, 0) }
    return { word = read_word("equipment"), picture = "FilterArmour", classes = { { 2 }, { 4 } }, blizzard = { { WEAPONS }, { ARMOUR } }, children = {
        create_weapons(),
        { word = read_class(4), classes = { { 4, 1 }, { 4, 2 }, { 4, 3 }, { 4, 4 } }, blizzard = { { ARMOUR } }, children = {
            create_armour(1, CLOTH_SLOTS), create_armour(2, ARMOUR_SLOTS), create_armour(3, ARMOUR_SLOTS), create_armour(4, ARMOUR_SLOTS),
        } },
        { word = read_word("jewellery"), classes = { { 4, 0 } }, blizzard = { jewellery }, children = create_slots(4, 0, JEWELLERY_SLOTS, jewellery) },
        { word = read_sub(4, 6), classes = { { 4, 6 } }, blizzard = { read_chain(jewellery, read_sub(4, 6)) } },
    } }
end

local function read_consumable(sub)
    return { CONSUMABLES, read_sub(0, sub) }
end

local function create_filters()
    return {
        create_equipment(),
        { word = read_word("craft_level"), levelless = true, picture = "FilterHammer", classes = { { 7 }, { 9 }, { 5 }, { 3 }, { 8 } }, blizzard = { { TRADE_GOODS }, { RECIPES }, { GEMS }, { ENHANCEMENT } }, children = {
            { word = read_class(7), classes = { { 7 } }, sub_of = 7, blizzard = { { TRADE_GOODS } } }, { word = read_class(9), classes = { { 9 } }, sub_of = 9, blizzard = { { RECIPES } } },
            { word = read_class(5), classes = { { 5 } }, blizzard = { { MISCELLANEOUS, read_sub(15, 1) } } }, { word = read_class(3), classes = { { 3 } }, blizzard = { { GEMS } } },
            { word = read_class(8), classes = { { 8 } }, blizzard = { { ENHANCEMENT } } },
        } },
        { word = read_word("consumables"), picture = "FilterBottle", classes = { { 0 } }, blizzard = { { CONSUMABLES } }, children = {
            { word = read_sub(0, 1), classes = { { 0, 1 } }, blizzard = { read_consumable(1) } }, { word = read_word("elixirs"), classes = { { 0, 2 }, { 0, 3 } }, blizzard = { read_consumable(2), read_consumable(3) } },
            { word = read_sub(0, 5), classes = { { 0, 5 } }, blizzard = { read_consumable(5) } }, { word = read_sub(0, 7), classes = { { 0, 7 } }, blizzard = { read_consumable(7) } },
            { word = read_sub(0, 4), classes = { { 0, 4 } }, blizzard = { read_consumable(4) } }, { word = read_word("misc"), classes = { { 0, 0 }, { 0, 6 }, { 0, 8 } }, blizzard = { read_consumable(0), read_consumable(6), read_consumable(8) } },
        } },
        { word = read_word("containers"), levelless = true, picture = "TabBags", classes = { { 1 }, { 11 } }, blizzard = { { CONTAINERS }, {} }, children = {
            { word = read_word("bags_kind"), classes = { { 1 } }, sub_of = 1, blizzard = { { CONTAINERS } } }, { word = read_class(11), classes = { { 11 } }, blizzard = { {} } },
        } },
        { word = read_word("quest_items"), levelless = true, picture = "FilterQuest", classes = { { 12 } }, blizzard = { { QUEST } } },
        { word = read_word("misc"), picture = "FilterJunk", classes = { { 15 }, { 13 }, { 6 } }, blizzard = { { MISCELLANEOUS }, {} }, children = {
            { word = read_sub(15, 0), classes = { { 15, 0 } }, blizzard = { { MISCELLANEOUS, read_sub(15, 0) } } }, { word = read_sub(15, 1), classes = { { 15, 1 } }, blizzard = { { MISCELLANEOUS, read_sub(15, 1) } } },
            { word = read_sub(15, 2), classes = { { 15, 2 } }, blizzard = { { MISCELLANEOUS, read_sub(15, 2) } } }, { word = read_sub(15, 5), classes = { { 15, 5 } }, blizzard = { { MISCELLANEOUS, read_sub(15, 5) } } },
            { word = read_sub(15, 3), classes = { { 15, 3 } }, blizzard = { { MISCELLANEOUS, read_sub(15, 3) } } }, { word = read_class(13), classes = { { 13 } }, blizzard = { {} } },
            { word = read_class(6), classes = { { 6 } }, blizzard = { {} } }, { word = read_sub(15, 4), classes = { { 15, 4 } }, blizzard = { { MISCELLANEOUS, read_sub(15, 4) } } },
        } },
    }
end

local function read_filters()
    filters = filters or create_filters()
    return filters
end

local function read_children(node)
    if node.children == nil and node.sub_of then
        local subs = C_AuctionHouse.GetAuctionItemSubClasses and C_AuctionHouse.GetAuctionItemSubClasses(node.sub_of) or {}
        local prefix = node.blizzard[1]
        node.children = #subs > 1 and create_subs(node.sub_of, subs, function(sub) return read_chain(prefix, read_sub(node.sub_of, sub)) end) or false
    end
    return node.children or nil
end

local function read_saved()
    VGAAuctions = VGAAuctions or {}
    VGAAuctions.saved = VGAAuctions.saved or {}
    return VGAAuctions.saved
end

local function check_saved(text)
    for _, saved in ipairs(read_saved()) do
        if saved == text then return true end
    end
    return false
end

local function read_quality_colour(quality)
    local colour = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality or 1]
    return colour and { colour.r, colour.g, colour.b } or colours.ink
end

local function update_status(page, text, money)
    page.status:SetText(text or "")
    page.status_money:SetShown(money ~= nil)
    if money then library.update_money(page.status_money, money) end
end

local function read_buy_cost(page)
    if page.confirming and page.pending then return page.pending.price end
    return page.chosen and page.chosen.price and page.chosen.price * (page.quantity or 1)
end

local function update_buy_button(page, confirming)
    page.confirming = confirming
    page.buy.words = confirming and library.texts.confirm or library.texts.buy_now
    page.buy.text:SetText(page.buy.words)
    local cost = read_buy_cost(page)
    library.update_button_enabled(page.buy, cost ~= nil and cost <= GetMoney())
end

local function read_class_filters(page)
    local node = page.path[#page.path]
    local found = {}
    for _, class in ipairs(node and node.classes or {}) do found[#found + 1] = { classID = class[1], subClassID = class[2], inventoryType = class[3] } end
    return found
end

local function read_level_cap()
    return GetMaxPlayerLevel and GetMaxPlayerLevel() or LEVEL_CAP
end

local function read_level(field, fallback)
    return tonumber(field:GetText()) or fallback
end

local function check_class_match(item_id, classes)
    if #classes == 0 then return true end
    local _, _, _, _, _, class_id, sub_id = C_Item.GetItemInfoInstant(item_id)
    local slot = C_Item.GetItemInventoryTypeByID and C_Item.GetItemInventoryTypeByID(item_id)
    if not class_id then return true end
    for _, wanted in ipairs(classes) do
        if wanted.classID == class_id and (wanted.subClassID == nil or wanted.subClassID == sub_id) and (wanted.inventoryType == nil or wanted.inventoryType == slot) then return true end
    end
    return false
end

local function check_levelless(page)
    for _, node in ipairs(page.path or {}) do
        if node.levelless then return true end
    end
    return false
end

local function read_query(page)
    local node, levelless = page.path[#page.path], check_levelless(page)
    return { raw = page.search_text, classes = read_class_filters(page), quality = page.quality_least or 0, chains = node and node.blizzard or { {} },
        least = levelless and 1 or read_level(page.least, 1), most = levelless and read_level_cap() or read_level(page.most, read_level_cap()) }
end

local function read_quality_filters(query)
    local found = {}
    for quality, name in ipairs(QUALITIES) do
        local value = Enum.AuctionHouseFilter and Enum.AuctionHouseFilter[name]
        if value and quality - 1 >= query.quality then found[#found + 1] = value end
    end
    return found
end

local function read_chain_path(chain)
    local path, level = {}, AuctionCategories or {}
    for _, read in ipairs(chain) do
        local name, found = read(), nil
        for index, category in ipairs(level) do
            if name and category.name == name then found = index end
        end
        if not found then return nil end
        path[#path + 1] = found
        level = level[found].subCategories or {}
    end
    return path
end

local function read_engine()
    if not AuctionHouseFrame and C_AddOns and C_AddOns.LoadAddOn then C_AddOns.LoadAddOn("Blizzard_AuctionHouseUI") end
    return AuctionHouseFrame
end

local function write_engine_query(page, query, index)
    local house = read_engine()
    if not house then return end
    local path = read_chain_path(query.chains[index])
    if not path then return write_next_chain(page) end
    house:SetDisplayMode(AuctionHouseFrameDisplayMode.Buy)
    house:GetCategoriesList():SetSelectedCategory(path[1], path[2], path[3])
    if house.SearchBar and house.SearchBar.SetSearchText then house.SearchBar:SetSearchText(query.raw) end
    page.engine_sent = true
    house:SendBrowseQuery(query.raw, query.least > 1 and query.least or 0, query.most < read_level_cap() and query.most or 0, read_quality_filters(query))
end

function write_next_chain(page)
    local index, query = (page.chain_index or 0) + 1, page.query
    if index > #query.chains then
        page.answered = true
        return update_results(page)
    end
    page.chain_index = index
    vga.write_auction_query(function() write_engine_query(page, query, index) end)
end

local function render_search(page, text)
    page.search_text = text or page.input:GetText() or ""
    page.query, page.engine_sent, page.answered, page.collected, page.chain_index = read_query(page), false, false, {}, 0
    page.chosen, page.chosen_key = nil, nil
    page.none:SetText(library.texts.searching)
    update_buy_button(page, false)
    update_status(page)
    update_results(page)
    write_next_chain(page)
end

local function update_field(page)
    local text = page.input:GetText() or ""
    local saved = text ~= "" and check_saved(text)
    local star = saved and colours.gold or colours.quiet
    page.input.hint:SetShown(text == "")
    page.clear:SetShown(text ~= "")
    page.star.picture:SetTexture(library.media .. (saved and "StarFull" or "StarLine"))
    page.star.picture:SetVertexColor(star[1], star[2], star[3], 1)
end

local function render_save()
    local page = buy_page
    local text = page.input:GetText()
    if not text or text == "" then return end
    local saved = read_saved()
    for index = #saved, 1, -1 do
        if saved[index] == text then table.remove(saved, index) end
    end
    table.insert(saved, 1, text)
    while #saved > SAVED do table.remove(saved) end
    update_field(page)
    if vga.update_saved_searches then vga.update_saved_searches() end
end

local function render_clear()
    local page = buy_page
    page.input:SetText("")
    page.input:ClearFocus()
end

local function create_icon_button(page, picture, on_click)
    local button = CreateFrame("Button", nil, page.input)
    button.picture = button:CreateTexture(nil, "ARTWORK")
    button.picture:SetAllPoints()
    button.picture:SetTexture(library.media .. picture)
    button.picture:SetVertexColor(colours.quiet[1], colours.quiet[2], colours.quiet[3], 1)
    button:SetScript("OnClick", on_click)
    return button
end

local function create_input(page)
    local input = CreateFrame("EditBox", nil, page)
    input:SetAutoFocus(false)
    input:SetMaxLetters(60)
    input.edge = library.create_surface(input, "BACKGROUND", 0)
    input.ground = library.create_surface(input, "BACKGROUND", 1)
    input.lens = input:CreateTexture(nil, "ARTWORK")
    input.lens:SetTexture(library.media .. "Search")
    input.lens:SetVertexColor(colours.quiet[1], colours.quiet[2], colours.quiet[3], 1)
    input.hint = library.create_text(input, "small", colours.quiet)
    input.hint:SetText(library.texts.search_hint)
    input:SetScript("OnEscapePressed", input.ClearFocus)
    input:SetScript("OnTextChanged", function() update_field(page) end)
    input:SetScript("OnEnterPressed", function(field) field:ClearFocus() render_search(page) end)
    return input
end

local function read_key_text(key)
    return table.concat({ key.itemID or 0, key.itemLevel or 0, key.itemSuffix or 0, key.battlePetSpeciesID or 0 }, ":")
end

local function write_collected(page)
    page.collected = page.collected or {}
    for _, result in ipairs(C_AuctionHouse.GetBrowseResults and C_AuctionHouse.GetBrowseResults() or {}) do
        page.collected[read_key_text(result.itemKey)] = result
    end
end

local function read_result_rows()
    local page, rows = buy_page, {}
    if not page.query then return rows end
    for _, result in pairs(page.collected or {}) do
        local known = C_AuctionHouse.GetItemKeyInfo(result.itemKey)
        if known and check_class_match(known.itemID, page.query.classes) then
            rows[#rows + 1] = { key = result.itemKey, known = known, quantity = result.totalQuantity, price = result.minPrice }
        end
    end
    return rows
end

local function update_result_row(line, row)
    local page = buy_page
    local size = library.read_draft_size(26)
    local market = vga.read_market(row.known.itemID)
    line.icon:SetTexture(row.known.iconFileID)
    line.icon:SetSize(size, size)
    line.icon:SetPoint("LEFT", line, "LEFT", page.pad, 0)
    local quality = read_quality_colour(row.known.quality)
    line.name:SetText(row.known.itemName)
    line.name:SetTextColor(quality[1], quality[2], quality[3], 1)
    local columns, x = page.columns, page.pad
    line.name:SetPoint("LEFT", line.icon, "RIGHT", library.read_size(-4), 0)
    line.name:SetWidth(math.max(1, columns.rights[1] - size - library.read_size(-4)))
    line.level:SetText(vga.read_level_text(vga.read_item_level(row.known.itemID)))
    line.level:SetShown(not page.levelless)
    line.level:ClearAllPoints()
    line.level:SetPoint("LEFT", line, "LEFT", x + columns.lefts[2], 0)
    line.quantity:SetText(row.quantity)
    line.quantity:SetPoint("LEFT", line, "LEFT", x + columns.lefts[3], 0)
    library.update_money(line.price, row.price)
    line.price:SetPoint("RIGHT", line, "LEFT", x + columns.rights[4], 0)
    library.update_money(line.market, math.floor((market or 0) + 0.5))
    line.market:SetShown(market ~= nil)
    line.market:SetPoint("RIGHT", line, "LEFT", x + columns.rights[5], 0)
    library.update_chip(line.chip, vga.read_deal(row.price, market))
    line.chip:SetPoint("LEFT", line, "LEFT", x + columns.lefts[6], 0)
    library.update_eye_layout(line.eye)
    library.update_eye_shown(line.eye, vga.check_watched(row.known.itemID))
    line.eye:ClearAllPoints()
    line.eye:SetPoint("RIGHT", line, "LEFT", x + columns.rights[7], 0)
    line.item = { key = row.key, id = row.known.itemID }
    local chosen = page.chosen_key == read_key_text(row.key)
    library.update_surface(line.fill, 0, library.read_draft_size(8), colours.gold, colours.gold, chosen and 0.08 or 0)
    library.update_ring(line.ring, 1, colours.gold, chosen and 1 or 0)
end

local function update_chip_column(list)
    local chips = {}
    for _, line in ipairs(library.read_list_rows_shown(list)) do chips[#chips + 1] = line.chip end
    library.update_chip_width(chips)
end

local function read_sort_name(row) return row.known.itemName end
local function read_sort_level(row) return vga.read_item_level(row.known.itemID) end
local function read_sort_quantity(row) return row.quantity end
local function read_sort_price(row) return row.price end
local function read_sort_market(row) return vga.read_market(row.known.itemID) end

local function read_sort_deal(row)
    local market = vga.read_market(row.known.itemID)
    return market and market > 0 and row.price / market or nil
end

function update_results(page)
    page.rows = read_result_rows()
    for _, row in ipairs(page.rows) do
        if read_key_text(row.key) == page.chosen_key then page.chosen = row end
    end
    local height = library.read_draft_size(40)
    local room = page.results_group:GetHeight() - (page.head_height or 0)
    page.list:ClearAllPoints()
    page.list:SetPoint("TOPLEFT", page.results_group, "TOPLEFT", 0, -(page.head_height or 0))
    library.update_list(page.list, page.rows, page.results_group:GetWidth(), math.max(room, height), height)
    if page.answered then page.none:SetText(library.texts.no_results) end
    page.none:SetShown(page.query ~= nil and #page.rows == 0)
end

local function render_results_sorted()
    update_results(buy_page)
end

local function render_chosen(line)
    local page = buy_page
    page.chosen, page.quantity = page.list.items[line.index], 1
    page.buying = false
    page.chosen_key = page.chosen and read_key_text(page.chosen.key)
    library.update_stepper(page.stepper, 1)
    update_buy_button(page, false)
    update_status(page)
    update_results(page)
end

local function render_step(stepper, step)
    local page = buy_page
    if not page.chosen then return end
    local most = page.chosen.known.isCommodity and page.chosen.quantity or 1
    page.quantity = math.max(1, math.min(most, (page.quantity or 1) + step))
    library.update_stepper(stepper, page.quantity)
    update_buy_button(page, false)
end

local function render_buy()
    local page, row = buy_page, buy_page.chosen
    if not row then return end
    local item = row.known.itemID
    if page.confirming and page.pending then
        if row.known.isCommodity then
            C_AuctionHouse.ConfirmCommoditiesPurchase(item, page.quantity or 1)
        else
            C_AuctionHouse.PlaceBid(page.pending.auction, page.pending.price)
        end
        page.pending = nil
        update_buy_button(page, false)
        return
    end
    if row.known.isCommodity == nil then
        local known = C_AuctionHouse.GetItemKeyInfo(row.key)
        row.known.isCommodity = known and known.isCommodity
    end
    if row.known.isCommodity then
        C_AuctionHouse.StartCommoditiesPurchase(item, page.quantity or 1)
    else
        page.buying = true
        local price = Enum.AuctionHouseSortOrder and Enum.AuctionHouseSortOrder.Price or 0
        C_AuctionHouse.SendSearchQuery(row.key, { { sortOrder = price, reverseSort = false } }, true)
    end
end

local function update_commodity_price(total)
    local page = buy_page
    if not (page and page.chosen and page.chosen.known.isCommodity) then return end
    page.pending = { price = total }
    update_status(page, library.texts.total, total)
    update_buy_button(page, true)
end

local function update_item_offer()
    local page = buy_page
    if not (page and page.chosen and not page.chosen.known.isCommodity) then return end
    for index = 1, C_AuctionHouse.GetNumItemSearchResults(page.chosen.key) do
        local found = C_AuctionHouse.GetItemSearchResultInfo(page.chosen.key, index)
        if found and found.buyoutAmount and not found.containsOwnerItem then
            page.pending = { auction = found.auctionID, price = found.buyoutAmount }
            update_status(page, library.texts.cheapest, found.buyoutAmount)
            update_buy_button(page, true)
            return
        end
    end
end

local function update_bought()
    local page = buy_page
    if not page then return end
    update_status(page, library.texts.bought)
    update_results(page)
end

local function read_current(nodes)
    local current = {}
    for _, node in ipairs(nodes) do
        if not tostring(node.word()):upper():find("OBSOLETE", 1, true) then current[#current + 1] = node end
    end
    return current
end

local function read_choice(page)
    local depth = #page.path
    if depth == 0 then return read_current(read_filters()), 1 end
    local below = read_children(page.path[depth])
    if below then return read_current(below), depth + 1 end
    local parent = page.path[depth - 1]
    return read_current(parent and read_children(parent) or read_filters()), depth
end

local function update_choice(page, top)
    local nodes, level = read_choice(page)
    local labels, chosen = { library.texts.all_kinds }, 1
    for index, node in ipairs(nodes) do
        labels[index + 1] = node.word()
        if page.path[level] == node then chosen = index + 1 end
    end
    page.kind_nodes, page.kind_level = nodes, level
    library.update_choice_labels(page.kind_choice, labels, chosen)
    page.kind_choice.most = page.width
    library.update_choice(page.kind_choice)
    page.kind_choice:ClearAllPoints()
    page.kind_choice:SetPoint("TOPLEFT", page.area, "TOPLEFT", 0, -top)
    return page.kind_choice:GetHeight()
end

local function update_crumbs(page, top)
    local x, gap, height = 0, library.read_size(-4), library.read_size(1) + library.read_size(-4)
    for index, crumb in ipairs(page.crumbs) do
        local node = page.path[index - 1]
        local shown = index == 1 or node ~= nil
        crumb:SetShown(shown)
        crumb.mark:SetShown(shown and index > 1)
        if shown then
            local ink = index == 1 and colours.label or colours.gold
            crumb.word:SetFontObject(library.read_font("small"))
            crumb.word:SetTextColor(ink[1], ink[2], ink[3], 1)
            crumb.word:SetText(index == 1 and library.texts.all_kinds or node.word())
            crumb.mark:SetFontObject(library.read_font("small"))
            if index > 1 then
                crumb.mark:ClearAllPoints()
                crumb.mark:SetPoint("LEFT", page.area, "TOPLEFT", x, -(top + height / 2))
                x = x + math.ceil(crumb.mark:GetStringWidth()) + gap
            end
            local width = math.ceil(crumb.word:GetStringWidth())
            crumb:SetSize(width, height)
            crumb:ClearAllPoints()
            crumb:SetPoint("TOPLEFT", page.area, "TOPLEFT", x, -top)
            x = x + width + gap
        end
    end
    return height
end

local function render_crumb(crumb)
    local page = buy_page
    for level = #page.path, crumb.index, -1 do page.path[level] = nil end
    vga.update_buy_page(page, page.full_width)
end

local function render_kind(index)
    local page = buy_page
    for level = #page.path, page.kind_level, -1 do page.path[level] = nil end
    if index > 1 then page.path[page.kind_level] = page.kind_nodes[index - 1] end
    vga.update_buy_page(page, page.full_width)
end

local function render_quality(index)
    local page = buy_page
    page.quality_least = index - 1
    vga.update_buy_page(page, page.full_width)
end

local function render_level()
    local page = buy_page
    local least, most = read_level(page.least, 1), read_level(page.most, read_level_cap())
    if page.levels_sent == least .. "-" .. most then return end
    page.levels_sent = least .. "-" .. most
    vga.update_buy_page(page, page.full_width)
end

local function read_level_range()
    local cap, own = read_level_cap(), UnitLevel("player") or 1
    return math.max(1, own - LEVEL_NEAR), math.min(cap, own + LEVEL_NEAR)
end

local function render_level_choice(index)
    local page = buy_page
    local least, most = read_level_range()
    page.least:SetText(tostring(index == 2 and least or 1))
    page.most:SetText(tostring(index == 2 and most or read_level_cap()))
    render_level()
end

local function create_level_field(page)
    local field = CreateFrame("EditBox", nil, page)
    field:SetAutoFocus(false)
    field:SetNumeric(true)
    field:SetMaxLetters(2)
    field:SetJustifyH("CENTER")
    field.edge = library.create_surface(field, "BACKGROUND", 0)
    field.ground = library.create_surface(field, "BACKGROUND", 1)
    field:SetScript("OnEscapePressed", field.ClearFocus)
    field:SetScript("OnEnterPressed", field.ClearFocus)
    field:SetScript("OnEditFocusLost", render_level)
    return field
end

local function read_quality_labels(texts)
    local labels = { texts.all_kinds }
    for quality = 1, 4 do
        local colour = read_quality_colour(quality)
        labels[#labels + 1] = string.format("|cff%02x%02x%02x%s|r", math.floor(colour[1] * 255), math.floor(colour[2] * 255), math.floor(colour[3] * 255), _G["ITEM_QUALITY" .. quality .. "_DESC"] or tostring(quality))
    end
    return labels
end

local function create_filters_row(page, texts)
    page.path, page.crumbs = {}, {}
    page.kind_choice = library.create_choice(page, { texts.all_kinds }, 1, render_kind)
    page.kind_choice.natural = true
    for index = 1, CRUMBS do
        local crumb = CreateFrame("Button", nil, page)
        crumb.index = index
        crumb.word = library.create_text(crumb, "small", colours.gold)
        crumb.word:SetPoint("LEFT")
        crumb.mark = library.create_text(page.area, "small", colours.quiet)
        crumb.mark:SetText("›")
        crumb:SetScript("OnClick", render_crumb)
        page.crumbs[index] = crumb
    end
    page.quality_word = library.create_text(page.area, "small", colours.label)
    page.quality_word:SetText(texts.quality_from)
    page.quality_least = 0
    page.quality_choice = library.create_choice(page, read_quality_labels(texts), 1, render_quality)
    page.quality_choice.natural = true
    page.level_word = library.create_text(page.area, "small", colours.label)
    page.level_word:SetText(texts.level)
    page.level_to = library.create_text(page.area, "small", colours.label)
    page.level_to:SetText(texts.level_to)
    page.least, page.most = create_level_field(page), create_level_field(page)
    page.least:SetText("1")
    page.level_choice = library.create_choice(page, { texts.levels_all, texts.levels_near }, 1, render_level_choice)
    page.level_choice.natural = true
end

local function update_field_ground(field)
    local radius = library.read_size(-6)
    library.update_surface(field.edge, -1, radius + 1, colours.edge, colours.edge)
    library.update_surface(field.ground, 0, radius, FIELD_GROUND, FIELD_GROUND)
end

local function update_level_field(field, height)
    field:SetFontObject(library.read_font("body"))
    field:SetSize(library.read_size(4), height)
    update_field_ground(field)
end

local function read_level_chosen(page)
    local least, most = read_level_range()
    return read_level(page.least, 1) == least and read_level(page.most, read_level_cap()) == most and 2 or 1
end

local function update_quality_row(page, top)
    page.quality_word:SetFontObject(library.read_font("small"))
    page.quality_choice.chosen = page.quality_least + 1
    page.quality_choice.most = page.width / 2
    library.update_choice(page.quality_choice)
    page.quality_choice:ClearAllPoints()
    page.quality_choice:SetPoint("LEFT", page.quality_word, "RIGHT", library.read_size(-4), 0)
    page.quality_word:ClearAllPoints()
    page.quality_word:SetPoint("LEFT", page.area, "TOPLEFT", 0, -(top + library.read_size(2) / 2))
    return page.quality_choice:GetHeight()
end

local function update_levels(page, top)
    local gap, cap = library.read_size(-4), read_level_cap()
    local height = library.read_size(2)
    if page.most:GetText() == "" then page.most:SetText(tostring(cap)) end
    page.level_word:SetFontObject(library.read_font("small"))
    page.level_to:SetFontObject(library.read_font("small"))
    update_level_field(page.least, height)
    update_level_field(page.most, height)
    page.level_word:ClearAllPoints()
    page.level_word:SetPoint("LEFT", page.quality_choice, "RIGHT", library.read_draft_size(24), 0)
    page.least:ClearAllPoints()
    page.least:SetPoint("LEFT", page.level_word, "RIGHT", gap, 0)
    page.level_to:ClearAllPoints()
    page.level_to:SetPoint("LEFT", page.least, "RIGHT", gap, 0)
    page.most:ClearAllPoints()
    page.most:SetPoint("LEFT", page.level_to, "RIGHT", gap, 0)
    page.level_choice.chosen = read_level_chosen(page)
    library.update_choice(page.level_choice)
    page.level_choice:ClearAllPoints()
    page.level_choice:SetPoint("LEFT", page.most, "RIGHT", 2 * gap, 0)
    local shown = not check_levelless(page)
    for _, part in ipairs({ page.level_word, page.least, page.level_to, page.most, page.level_choice }) do part:SetShown(shown) end
    return height
end

local function render_line_tip(line)
    if line.item then vga.render_item_tip(line, line.item) end
end

local function create_line(parent, index)
    local line = CreateFrame("Button", nil, parent)
    line.index = index
    line.fill = library.create_surface(line, "BACKGROUND", 0)
    line.ring = library.create_ring(line, "OVERLAY", 0)
    line.icon = line:CreateTexture(nil, "ARTWORK")
    line.name = library.create_text(line, "body", colours.ink)
    line.name:SetJustifyH("LEFT")
    line.name:SetWordWrap(false)
    line.quantity = library.create_text(line, "small", colours.quiet)
    line.level = library.create_text(line, "small", colours.label)
    line.price = library.create_money(line, colours.ink)
    line.market = library.create_money(line, colours.quiet)
    line.chip = library.create_chip(line)
    line.eye = library.create_eye(line, function(on) if line.item then vga.write_watched(line.item.id, on) end end, { library.texts.watch_on, library.texts.watch_off })
    line:SetScript("OnClick", render_chosen)
    line:SetScript("OnEnter", render_line_tip)
    line:SetScript("OnLeave", vga.update_item_tip_hidden)
    return line
end

local function create_buy_row(page, texts)
    page.probe_money = library.create_money(page, colours.ink)
    page.probe_text = library.create_text(page, "small", colours.ink)
    page.probe_chip = library.create_chip(page)
    page.probe_chip:Hide()
    page.stepper = library.create_stepper(page, render_step)
    page.buy = library.create_button(page, texts.buy_now, "gold", render_buy)
    page.status = library.create_text(page, "small", colours.quiet)
    page.status_money = library.create_money(page, colours.ink)
end

function vga.update_buy_visit()
    local page = buy_page
    if not page then return end
    page.query, page.search_text, page.engine_sent, page.answered, page.collected = nil, nil, false, false, nil
    page.chosen, page.chosen_key, page.rows = nil, nil, {}
    page.pending, page.buying, page.quantity = nil, false, 1
    page.path, page.quality_least, page.levels_sent = {}, 0, nil
    library.update_stepper(page.stepper, 1)
    update_buy_button(page, false)
    update_status(page)
    page.input:SetText("")
    page.least:SetText("1")
    page.most:SetText(tostring(read_level_cap()))
end

function vga.read_buy_text()
    return buy_page and buy_page.input:GetText()
end

function vga.read_saved_searches()
    return read_saved()
end

function vga.render_saved_search(text)
    local page = buy_page
    page.input:SetText(text)
    render_search(page, text)
end

function vga.create_buy_page(page)
    local texts = library.texts
    buy_page = page
    page.top_group = library.create_group(page)
    page.area = CreateFrame("Frame", nil, page)
    page.input = create_input(page)
    page.clear = create_icon_button(page, "Clear", render_clear)
    page.star = create_icon_button(page, "StarLine", render_save)
    page.search_button = library.create_button(page, texts.search, "gold", function() page.input:ClearFocus() render_search(page) end)
    create_filters_row(page, texts)
    page.results_group = library.create_group(page)
    page.list = library.create_list(page.results_group, create_line, update_result_row)
    page.list.sorters = { item = read_sort_name, level = read_sort_level, quantity = read_sort_quantity, price_each = read_sort_price, market_value = read_sort_market, to_market = read_sort_deal }
    page.list.on_sort = render_results_sorted
    page.heads = {}
    for index, key in ipairs(HEADS) do page.heads[index] = library.create_sort_head(page.list, page.results_group, texts[key]:upper(), key) end
    page.list.on_rows = update_chip_column
    page.lines = page.list.rows
    page.none = library.create_text(page.results_group, "small", colours.quiet)
    page.none:SetText(texts.no_results)
    create_buy_row(page, texts)
    page.rows = {}
end

local function update_search_field(page)
    local pad, height, mark = library.read_size(-2), library.read_size(2), library.read_size(0)
    page.input:SetFontObject(library.read_font("body"))
    page.input:SetTextInsets(pad + mark + library.read_size(-4), 2 * (mark + pad), 0, 0)
    page.input:ClearAllPoints()
    library.update_button(page.search_button)
    page.search_button:ClearAllPoints()
    page.search_button:SetPoint("TOPRIGHT", page.area, "TOPLEFT", page.width, 0)
    page.input:SetPoint("TOPLEFT", page.area, "TOPLEFT")
    page.input:SetPoint("RIGHT", page.search_button, "LEFT", -pad, 0)
    page.input:SetHeight(height)
    update_field_ground(page.input)
    page.input.lens:SetSize(mark, mark)
    page.input.lens:ClearAllPoints()
    page.input.lens:SetPoint("LEFT", page.input, "LEFT", pad, 0)
    page.input.hint:SetFontObject(library.read_font("small"))
    page.input.hint:ClearAllPoints()
    page.input.hint:SetPoint("LEFT", page.input.lens, "RIGHT", library.read_size(-4), 0)
    page.star:SetSize(mark, mark)
    page.star:ClearAllPoints()
    page.star:SetPoint("RIGHT", page.input, "RIGHT", -pad, 0)
    page.clear:SetSize(mark * 0.8, mark * 0.8)
    page.clear:ClearAllPoints()
    page.clear:SetPoint("RIGHT", page.star, "LEFT", -pad, 0)
    update_field(page)
    return height
end

local function read_buy_columns(page)
    for index, head in ipairs(page.heads) do library.update_sort_head(head, index == 4 or index == 5) end
    local money = library.read_widest_money(page.probe_money)
    local chip = library.read_widest_chip(page.probe_chip)
    local function read_room(index, least) return math.max(page.heads[index]:GetWidth(), least) end
    page.levelless = check_levelless(page)
    page.heads[2]:SetShown(not page.levelless)
    return library.read_columns(page.width, { false, page.levelless and 0 or read_room(2, library.read_widest_text(page.probe_text, "60")), read_room(3, library.read_widest_text(page.probe_text, "99999")), read_room(4, money), read_room(5, money), read_room(6, chip), library.read_size(2) })
end

local function update_heads(page)
    local height, icon = library.read_draft_size(28), library.read_draft_size(26) + library.read_size(-4)
    page.columns = read_buy_columns(page)
    local columns = page.columns
    local places = { { "LEFT", columns.lefts[1] + icon }, { "LEFT", columns.lefts[2] }, { "LEFT", columns.lefts[3] }, { "RIGHT", columns.rights[4] }, { "RIGHT", columns.rights[5] }, { "LEFT", columns.lefts[6] } }
    for index, head in ipairs(page.heads) do
        local place = places[index]
        head:ClearAllPoints()
        head:SetPoint(place[1], page.results_group, "TOPLEFT", page.pad + place[2], -height / 2)
    end
    page.head_height = height
end

local function update_top(page, width)
    local gap, inset, apart = library.read_size(-4), library.read_draft_size(10), library.read_draft_size(14)
    page.area:ClearAllPoints()
    page.area:SetPoint("TOPLEFT", page, "TOPLEFT", page.pad, -inset)
    page.area:SetSize(page.width, 1)
    local top = update_search_field(page) + gap
    top = top + update_crumbs(page, top) + gap
    top = top + update_choice(page, top) + gap
    page.level_word:SetFontObject(library.read_font("small"))
    page.quality_word:SetFontObject(library.read_font("small"))
    update_quality_row(page, top)
    top = top + update_levels(page, top)
    page.top_group:ClearAllPoints()
    page.top_group:SetPoint("TOPLEFT", page, "TOPLEFT")
    page.top_group:SetSize(width, top + 2 * inset)
    library.update_group(page.top_group)
    local below = top + 2 * inset + apart
    page.results_group:ClearAllPoints()
    page.results_group:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -below)
    page.results_group:SetSize(width, math.max(page:GetHeight() - below - page.buy:GetHeight() - apart, library.read_draft_size(120)))
    library.update_group(page.results_group)
    update_heads(page)
end

function vga.update_buy_page(page, width)
    page.full_width = width
    page.pad = library.read_draft_size(12)
    page.width = width - 2 * page.pad
    local pad = library.read_size(-2)
    library.update_button(page.buy)
    update_top(page, width)
    page.none:ClearAllPoints()
    page.none:SetFontObject(library.read_font("body"))
    page.none:SetPoint("TOP", page.results_group, "TOP", 0, -(page.head_height + library.read_draft_size(40)))

    library.update_button(page.buy)
    page.buy:ClearAllPoints()
    page.buy:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT")
    library.update_stepper(page.stepper, page.quantity or 1)
    page.stepper:ClearAllPoints()
    page.stepper:SetPoint("RIGHT", page.buy, "LEFT", -pad, 0)
    page.status:ClearAllPoints()
    page.status:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 0, library.read_size(-4))
    page.status_money:ClearAllPoints()
    page.status_money:SetPoint("LEFT", page.status, "RIGHT", library.read_size(-4), 0)
    update_results(page)
end

local events = CreateFrame("Frame")
for _, name in ipairs({ "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", "COMMODITY_PRICE_UPDATED", "ITEM_SEARCH_RESULTS_UPDATED", "COMMODITY_PURCHASE_SUCCEEDED", "ITEM_PURCHASED", "PLAYER_MONEY" }) do
    pcall(events.RegisterEvent, events, name)
end
events:SetScript("OnEvent", function(_, event, first, second)
    if not (buy_page and buy_page:IsVisible()) then return end
    if event == "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED" then
        if not buy_page.engine_sent then return end
        buy_page.engine_sent = false
        write_collected(buy_page)
        library.update_safely("auctions results", update_results, buy_page)
        library.update_safely("auctions next search", write_next_chain, buy_page)
    elseif event == "COMMODITY_PRICE_UPDATED" then
        library.update_safely("auctions price", update_commodity_price, second)
    elseif event == "ITEM_SEARCH_RESULTS_UPDATED" then
        library.update_safely("auctions item offer", update_item_offer)
    elseif event == "PLAYER_MONEY" then
        library.update_safely("auctions money", update_buy_button, buy_page, buy_page.confirming)
    else
        library.update_safely("auctions bought", update_bought)
    end
end)
