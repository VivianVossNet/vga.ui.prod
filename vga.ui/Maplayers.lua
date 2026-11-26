-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: the world map's layers fed by what the game gives (K0805), drawn as LibVGA's map marks in the owner's signs (K0813, K0815), on the world map or, for the minimap, on the plane of the continent the player stands on (K0925); a figure's place kept as its zone and position there, turned into the plane's only when read (K0925); a quest giver from Questie marked only for a quest Questie still holds available and the figure did not refuse - its list by figure keeps quests it has let go -, its sign by its best quest: »QuestTake« in range, »QuestTakeLow« one the game shows grey, »QuestTakeHigh« one above the player's level (K0946): the player's sign turned by the facing; the party in their class colours; the quests of the zone in view - to hand in, in progress, to take where the game names a start -; the flight masters of the continent, learnt or not, the hostile ones left out, the faction in the card; own pins in orange, set by Ctrl and a click, taken off by a right click, the game's own waypoint beside them; townsfolk - vendors, repairers, barbers, the auction house, class and profession trainers - learnt by vga.ui itself whenever the player speaks with one, kept with the player's place in the account's saved variables (K0814). Each layer obeys its switch; the hatching covers everything outside the zone in view (K0812). Where Questie is installed and ready, its quest givers - the quests it holds available, by their figures' places in the zone in view - and its townsfolk - repairers, auctioneers, barbers, innkeepers, the player's class trainers, profession trainers and its vendors - are read at runtime, guarded, nothing copied, kept five seconds per map (K0814, K0822); every place at half the size of the quests in the quest view (library.read_map_mark_scale, K0822). VGA's own database comes once it is released.

-- {K0946} {K0925} {K0822} {K0815} {K0814} {K0813} {K0812} {K0805}

local _, vga = ...
local library = LibVGA
local texts = library.texts
local HOSTILE = { Alliance = 1, Horde = 2 }
local TOWNSFOLK = { vendor = "Vendor", repair = "Repair", barber = "Barber", auction = "Auction", class = "ClassTrainer", profession = "ProfessionTrainer" }
local TOWNSFOLK_WORDS = { vendor = "map_vendor", repair = "map_repair", barber = "map_barber", auction = "map_auction", class = "map_class_trainer", profession = "map_profession_trainer" }
local PARTY = 4
local QUESTIE_KINDS = { Repair = "Repair", Auctioneer = "Auction", Barber = "Barber", Innkeeper = "Inn" }
local QUESTIE_WORDS = { Repair = "map_repair", Auction = "map_auction", Barber = "map_barber", Inn = "map_inn", Vendor = "map_vendor", ClassTrainer = "map_class_trainer", ProfessionTrainer = "map_profession_trainer", QuestTake = "map_quest_take" }
local QUESTIE_KEEP = 5
local questie_kept = {}
local plane
local GREEN = 5

local function check_layer(key)
    return (LibVGASettings.map_layers or {})[key] ~= false
end

local function read_class_sign(unit)
    local _, class = UnitClass(unit)
    if not class then return "Party" end
    return "Party" .. class:sub(1, 1) .. class:sub(2):lower()
end

local function read_unit_item(unit, kind, facing)
    local map = C_Map.GetBestMapForUnit(unit)
    local spot = map and C_Map.GetPlayerMapPosition(map, unit)
    if not spot then return nil end
    local across, down = vga.read_map_world_point(map, spot.x, spot.y, plane)
    return across and { kind = kind, across = across, down = down, facing = facing, card = { UnitName(unit) } }
end

local function read_me()
    local item = read_unit_item("player", "Me", GetPlayerFacing and GetPlayerFacing() or 0)
    return { item }
end

local function read_party()
    local items = {}
    if not check_layer("party") then return items end
    for index = 1, PARTY do
        local unit = "party" .. index
        local item = UnitExists(unit) and read_unit_item(unit, read_class_sign(unit))
        if item then items[#items + 1] = item end
    end
    return items
end

local function read_quest_kind(found)
    if found.isQuestStart then return "QuestTake", texts.map_quest_take end
    if C_QuestLog.IsComplete and C_QuestLog.IsComplete(found.questID) then return "QuestTurn", texts.map_quest_turn end
    return "QuestOpen", texts.map_quest_open
end

local function read_quests(map)
    local items = {}
    if not (map and check_layer("quests") and C_QuestLog.GetQuestsOnMap) then return items end
    for _, found in ipairs(C_QuestLog.GetQuestsOnMap(map) or {}) do
        local across, down = vga.read_map_world_point(map, found.x, found.y, plane)
        local kind, word = read_quest_kind(found)
        local title = C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(found.questID)
        if across then items[#items + 1] = { kind = kind, across = across, down = down, card = { title or word, word } } end
    end
    return items
end

local function check_hostile(node)
    return node.faction == HOSTILE[UnitFactionGroup("player") or ""]
end

local function read_flight(continent)
    local items = {}
    if not (continent and check_layer("flight") and C_TaxiMap and C_TaxiMap.GetTaxiNodesForMap) then return items end
    for _, node in ipairs(C_TaxiMap.GetTaxiNodesForMap(continent) or {}) do
        local spot = node.position
        local across, down = spot and vga.read_map_world_point(continent, spot.x, spot.y, plane)
        if across and not check_hostile(node) then
            local kind = node.isUndiscovered and "FlightUnknown" or "Flight"
            items[#items + 1] = { kind = kind, across = across, down = down, card = { node.name, node.isUndiscovered and texts.map_unknown or texts.map_learnt } }
        end
    end
    return items
end

local function render_pin_clicked(item, button)
    if button ~= "RightButton" or not item.index then return end
    table.remove(LibVGAAccount.map_pins, item.index)
    vga.render_map_layers()
end

local function read_waypoint()
    local point = C_Map.GetUserWaypoint and C_Map.GetUserWaypoint()
    local spot = point and point.position
    local across, down = spot and vga.read_map_world_point(point.uiMapID, spot.x, spot.y, plane)
    return across and { kind = "Pin", across = across, down = down, card = { texts.map_waypoint } }
end

local function read_pins()
    local items = {}
    if not check_layer("pins") then return items end
    for index, pin in ipairs(LibVGAAccount.map_pins or {}) do
        items[#items + 1] = { kind = "Pin", across = pin.across, down = pin.down, index = index, on_click = render_pin_clicked, card = { texts.map_pin, pin.note, texts.map_pin_hint } }
    end
    items[#items + 1] = read_waypoint()
    return items
end

function vga.write_map_pin(across, down, note)
    LibVGAAccount.map_pins = LibVGAAccount.map_pins or {}
    table.insert(LibVGAAccount.map_pins, { across = across, down = down, note = note })
    vga.render_map_layers()
end

local function read_questie_modules()
    local loader = QuestieLoader
    if not (loader and Questie and Questie.API and Questie.API.isReady) then return nil end
    return { db = loader:ImportModule("QuestieDB"), zones = loader:ImportModule("ZoneDB"), available = loader:ImportModule("AvailableQuests"), folk = loader:ImportModule("Townsfolk"), lib = loader:ImportModule("QuestieLib") }
end

local function write_questie_npc(found, modules, npc_id, kind)
    local npc = modules.db:GetNPC(npc_id)
    if not (npc and npc.friendly ~= false and npc.spawns) then return end
    for area, spots in pairs(npc.spawns) do
        if modules.zones:GetUiMapIdByAreaId(area) == found.map then
            for _, spot in ipairs(spots) do
                local across, down = vga.read_map_world_point(found.map, spot[1] / 100, spot[2] / 100, plane)
                if across then found.items[#found.items + 1] = { kind = kind, across = across, down = down, card = { npc.name, texts[QUESTIE_WORDS[kind]] } } end
            end
        end
    end
end

local function write_questie_list(found, modules, list, kind)
    for _, npc_id in pairs(list or {}) do write_questie_npc(found, modules, npc_id, kind) end
end

local function write_questie_folk(found, modules)
    local folk = modules.folk
    for key, kind in pairs(QUESTIE_KINDS) do write_questie_list(found, modules, folk.townsfolk and folk.townsfolk[key], kind) end
    local _, class = UnitClass("player")
    local trainers = folk.classSpecificTownsfolk and folk.classSpecificTownsfolk[class]
    write_questie_list(found, modules, trainers and trainers["Class Trainer"], "ClassTrainer")
    for _, list in pairs(folk.professionTrainers or {}) do write_questie_list(found, modules, list, "ProfessionTrainer") end
    for _, list in pairs(Questie.db and Questie.db.char and Questie.db.char.vendorList or {}) do write_questie_list(found, modules, list, "Vendor") end
end

local function read_quest_rank(modules, quest_id, player)
    local level, needed = modules.lib.GetEffectiveQuestLevel(quest_id, player)
    if needed and needed > player then return 3, "QuestTakeHigh" end
    local green = GetQuestGreenRange and GetQuestGreenRange("player") or GREEN
    if level and level > 0 and level < player - green then return 2, "QuestTakeLow" end
    return 1, "QuestTake"
end

local function read_npc_quest_kind(modules, quests)
    local available, refused = modules.available.__availableQuests or {}, modules.available.__unavailableQuestsDeterminedByTalking or {}
    local player, best, kind = UnitLevel("player") or 1, nil, nil
    for quest_id in pairs(quests) do
        if available[quest_id] and not refused[quest_id] then
            local rank, named = read_quest_rank(modules, quest_id, player)
            if not best or rank < best then best, kind = rank, named end
        end
    end
    return kind
end

local function write_questie_places(found)
    local modules = read_questie_modules()
    if not modules then return end
    for npc_id, quests in pairs(modules.available.__availableQuestsByNpc or {}) do
        local kind = read_npc_quest_kind(modules, quests)
        if kind then write_questie_npc(found, modules, npc_id, kind) end
    end
    if check_layer("townsfolk") then write_questie_folk(found, modules) end
end

local function read_questie_places(map)
    local key = map .. ":" .. tostring(plane and plane.id)
    local kept = questie_kept[key]
    if kept and GetTime() - kept.at < QUESTIE_KEEP then return kept.items end
    local found = { map = map, items = {}, at = GetTime() }
    local ok = pcall(write_questie_places, found)
    questie_kept[key] = found
    return ok and found.items or {}
end

local function read_townsfolk()
    local items = {}
    if not check_layer("townsfolk") then return items end
    for _, figure in pairs(LibVGAAccount.townsfolk or {}) do
        local across, down = figure.across, figure.down
        if figure.x then across, down = vga.read_map_world_point(figure.map, figure.x, figure.y, plane) end
        if across then items[#items + 1] = { kind = TOWNSFOLK[figure.kind], across = across, down = down, card = { figure.name, texts[TOWNSFOLK_WORDS[figure.kind]] } } end
    end
    return items
end

local function write_townsfolk(kind)
    local map = C_Map.GetBestMapForUnit("player")
    local spot = map and C_Map.GetPlayerMapPosition(map, "player")
    local name = UnitName("npc")
    if not (spot and name) then return end
    LibVGAAccount.townsfolk = LibVGAAccount.townsfolk or {}
    LibVGAAccount.townsfolk[name .. ":" .. map] = { kind = kind, name = name, map = map, x = spot.x, y = spot.y }
end

local function read_merchant_kind()
    return CanMerchantRepair and CanMerchantRepair() and "repair" or "vendor"
end

local function read_trainer_kind()
    return IsTradeskillTrainer and IsTradeskillTrainer() and "profession" or "class"
end

local function read_barber_kind()
    return "barber"
end

local function read_auction_kind()
    return "auction"
end

local HEARD = { MERCHANT_SHOW = read_merchant_kind, BARBER_SHOP_OPEN = read_barber_kind, AUCTION_HOUSE_SHOW = read_auction_kind, TRAINER_SHOW = read_trainer_kind }

function vga.update_map_layers(canvas, tier, zone, given)
    plane = given
    local size = library.read_map_mark_size(tier)
    local map = zone and zone.id or C_Map.GetBestMapForUnit("player")
    local continent = zone and zone.parent
    library.update_map_marks(canvas, "me", read_me(), size)
    library.update_map_marks(canvas, "party", read_party(), size)
    library.update_map_marks(canvas, "quests", tier == "zone" and read_quests(map) or {}, size)
    library.update_map_marks(canvas, "flight", tier ~= "world" and read_flight(continent) or {}, size)
    library.update_map_marks(canvas, "pins", read_pins(), size)
    library.update_map_marks(canvas, "townsfolk", tier == "zone" and read_townsfolk() or {}, size)
    library.update_map_marks(canvas, "questie", tier == "zone" and map and read_questie_places(map) or {}, size)
end

local events = CreateFrame("Frame")
for event in pairs(HEARD) do events:RegisterEvent(event) end
events:SetScript("OnEvent", function(_, event) library.update_safely("map townsfolk", write_townsfolk, HEARD[event]()) end)
