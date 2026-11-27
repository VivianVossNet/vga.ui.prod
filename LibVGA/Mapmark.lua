-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's map mark, a sign on LibVGA's map canvas as the owner's own pictures draw them (LibVGA/Media/Map, K0813) and the cartographer's draft sizes them (manual/view/vga-map-signs.html, K0809): 18 draft pixels at the world's zoom, 24 at a continent's, 32 at a zone's, scaled by the chosen size; a hit area of at least 24 draft pixels around it; a card in LibVGA's tooltip look on hover - its first line the title in gold, the others beneath -; a click handed to its item; the player's sign turned by the facing; places - quests to take, flight masters, vendors, repair, barbers, the auction house, inns, class and profession trainers - at three quarters of that size (K0825; before half, K0822), the quests in the quest view keeping it whole (library.read_map_mark_scale, K0822); marks given way by their layer when they crowd - the player above the party, the party above quests, quests above the rest. A layer of marks is laid by library.update_map_marks from its owner's items - kind, place in the plane, card, facing, what a click does -, its marks pooled, the unused hidden (K0815). Every sign is drawn from the owner's vaulted Grok set (LibVGA/Media/Sign, K0923, K0924) - the gold »!« to take a quest, the silver one for a low one, the gold and silver »?«, the gryphon gold or silver, the hearthstone, the coins, the anvil, the new barber, auction, dungeon, raid, boat, zeppelin, the pin tinted VGA's orange (K0812); the party a flat white circle with a gently vaulted edge, tinted in its member's class colour, at 0.85 of the other signs' size (K0962, K0964); the quests all in gold, the places - merchant, repair, inn, barber, auction, trainers under the book - in silver, so the quests stand out, flight masters and boats green, a flight master not yet learnt silver (K0928); a quest the game shows grey, far below the player, gold at half strength, one above the player's level grey at half strength, so it reads as not yet to be had (K0946); the merchant in a light gold and the trainers in a light blue, a little stronger than at first (K0930, K0931), the repair's anvil a light copper as a forge's fire; the bank the temple, mailbox, stable and battle master the owner's own signs, reagents and food and drink the merchant's coins (K0952); the inn always above a merchant, beneath the quests (K0955) -, the player as the orange arrow; a kind the set lacks still from LibVGA/Media/Map. It is LibVGA's layer of map signs for both maps (K0925): a surface places a sign through its own reckoning of a point (library.create_map_sign_surface, the minimap's), the world map's canvas through its view (library.read_map_mark_point), and either shows a sign only while its picture lies wholly inside (K0915); a surface may name which kinds it shows at all (read_kind_shown) - the minimap by the game's own tracking filters (K0951). The player's corpse is the owner's tombstone in dark grey with its cross glowing gold, untinted (K0978), above every sign but the party's and the player's (Corpse, K0977).

-- {K0978} {K0977} {K0964} {K0962} {K0955} {K0952} {K0951} {K0946} {K0931} {K0930} {K0928} {K0925} {K0924} {K0923} {K0825} {K0822} {K0815} {K0813} {K0809}

local library = LibVGA
local colours = library.colours
local SIZES = { world = 18, continent = 24, zone = 32 }
local HIT = 24
local LEVELS = { me = 10, party = 8, corpse = 7, quests = 6 }
local REST = 4
local KIND_LEVELS = { Inn = 5 }
local PLACE = 0.75
local SIGNS = {
    QuestTake = "OfferGold", QuestTakeLow = "OfferGold", QuestTakeHigh = "OfferSilver", QuestTurn = "QuestionGold", QuestOpen = "QuestionGold",
    Flight = "GryphonGold", FlightUnknown = "GryphonSilver", Inn = "HearthstoneSilver", Vendor = "CoinsSilver", Repair = "AnvilSilver",
    Barber = "BarberSilver", Auction = "AuctionSilver", ClassTrainer = "BookSilver", ProfessionTrainer = "BookSilver",
    Dungeon = "DungeonGold", Raid = "RaidGold", Boat = "BoatGold", Zeppelin = "ZeppelinGold", Pin = "PinGold", Bank = "TempleGold", Mail = "MailGold", Stable = "StableGold", Battle = "BattleGold", Reagents = "CoinsGold", Food = "CoinsGold", Me = "PlayerOrange", Party = "PartyWhite", Corpse = "TombstoneGrey",
}
local PALE_GOLD = { 1, 0.86, 0.55 }
local PALE_BLUE = { 0.62, 0.8, 1 }
local COPPER = { 1, 0.66, 0.5 }
local FAINT = { QuestTakeLow = 0.5, QuestTakeHigh = 0.5 }
local GREY = { 0.78, 0.78, 0.78 }
local TINTS = { QuestTakeHigh = GREY, Pin = colours.orange, Flight = colours.green, Boat = colours.green, Vendor = PALE_GOLD, Repair = COPPER, ClassTrainer = PALE_BLUE, ProfessionTrainer = PALE_BLUE }
local PARTY = "Party"
local PARTY_SCALE = 0.85
local CLASSES = { Druid = "DRUID", Hunter = "HUNTER", Mage = "MAGE", Paladin = "PALADIN", Priest = "PRIEST", Rogue = "ROGUE", Shaman = "SHAMAN", Warlock = "WARLOCK", Warrior = "WARRIOR" }
local PLACES = { QuestTake = true, QuestTakeLow = true, QuestTakeHigh = true, Flight = true, FlightUnknown = true, Vendor = true, Repair = true, Barber = true, Auction = true, ClassTrainer = true, ProfessionTrainer = true, Inn = true }

function library.read_map_mark_scale(kind)
    if kind:sub(1, #PARTY) == PARTY then return PARTY_SCALE end
    if PLACES[kind] then return PLACE end
    return 1
end

function library.read_map_mark_size(tier)
    return library.read_draft_size(SIZES[tier] or SIZES.zone)
end

local function render_mark_entered(mark)
    local card = mark.item and mark.item.card
    if not card then return end
    GameTooltip:SetOwner(mark, "ANCHOR_RIGHT")
    GameTooltip:AddLine(card[1], colours.gold[1], colours.gold[2], colours.gold[3])
    for index = 2, #card do GameTooltip:AddLine(card[index], colours.ink[1], colours.ink[2], colours.ink[3], true) end
    GameTooltip:Show()
end

local function render_mark_left()
    GameTooltip:Hide()
end

local function render_mark_clicked(mark, button)
    local item = mark.item
    if item and item.on_click then item.on_click(item, button) end
end

function library.create_map_mark(canvas, kind)
    local mark = CreateFrame("Button", nil, canvas.marks)
    mark:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    mark.picture = mark:CreateTexture(nil, "ARTWORK")
    mark.picture:SetPoint("CENTER")
    mark:SetScript("OnEnter", render_mark_entered)
    mark:SetScript("OnLeave", render_mark_left)
    mark:SetScript("OnClick", function(self, button) library.update_safely("map mark click", render_mark_clicked, self, button) end)
    library.update_map_mark_look(mark, kind, library.read_map_mark_size("zone"))
    return mark
end

local function read_tint(kind)
    return TINTS[kind]
end

function library.read_map_mark_picture(kind)
    local sign = SIGNS[kind]
    return library.media .. (sign and "Sign\\" .. sign or "Map\\" .. kind), read_tint(kind), FAINT[kind]
end

local function read_class_colour(kind)
    local class = CLASSES[kind:sub(#PARTY + 1)]
    local colour = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if not colour then return nil end
    return { colour.r, colour.g, colour.b }
end

local function update_mark_picture(picture, kind)
    local party = kind:sub(1, #PARTY) == PARTY
    local sign = SIGNS[party and PARTY or kind]
    picture:SetTexture(library.media .. (sign and "Sign\\" .. sign or "Map\\" .. kind))
    local colour = party and read_class_colour(kind) or read_tint(kind)
    picture:SetDesaturated(colour ~= nil)
    if colour then picture:SetVertexColor(colour[1], colour[2], colour[3], 1) else picture:SetVertexColor(1, 1, 1, 1) end
    picture:SetAlpha(FAINT[kind] or 1)
end

function library.update_map_mark_look(mark, kind, size, facing)
    update_mark_picture(mark.picture, kind)
    mark.picture:SetSize(size, size)
    mark.picture:SetRotation(facing or 0)
    local hit = math.max(size, library.read_draft_size(HIT))
    mark:SetSize(hit, hit)
end

local function update_mark_placed(canvas, mark, across, down, size)
    local read_point = canvas.read_mark_point or library.read_map_mark_point
    local x, y
    if across and down then x, y = read_point(canvas, across, down) end
    local half, width, height = size / 2, canvas:GetWidth(), canvas:GetHeight()
    local inside = x and x - half >= 0 and x + half <= width and y - half >= 0 and y + half <= height
    mark:SetShown(inside and true or false)
    if not inside then return end
    mark:ClearAllPoints()
    mark:SetPoint("CENTER", canvas, "TOPLEFT", x, -y)
end

function library.update_map_marks_placed(canvas)
    for _, pool in pairs(canvas.mark_layers or {}) do
        for _, mark in ipairs(pool) do
            if mark.item then update_mark_placed(canvas, mark, mark.item.across, mark.item.down, mark.sized) end
        end
    end
end

function library.create_map_sign_surface(parent, plan)
    local surface = CreateFrame("Frame", nil, parent)
    surface.marks = CreateFrame("Frame", nil, surface)
    surface.marks:SetAllPoints()
    surface.read_mark_point, surface.read_mark_size, surface.read_kind_shown = plan.read_point, plan.read_size, plan.read_kind_shown
    return surface
end

local function read_items_shown(canvas, items)
    if not canvas.read_kind_shown then return items end
    local shown = {}
    for _, item in ipairs(items) do
        if canvas.read_kind_shown(item.kind) then shown[#shown + 1] = item end
    end
    return shown
end

function library.update_map_marks(canvas, layer, items, size)
    items = read_items_shown(canvas, items)
    canvas.mark_layers = canvas.mark_layers or {}
    local pool = canvas.mark_layers[layer] or {}
    canvas.mark_layers[layer] = pool
    for index, item in ipairs(items) do
        pool[index] = pool[index] or library.create_map_mark(canvas, item.kind)
        local mark = pool[index]
        mark.item = item
        local sized = canvas.read_mark_size and canvas.read_mark_size(layer, item.kind) or size * library.read_map_mark_scale(item.kind)
        library.update_map_mark_look(mark, item.kind, sized, item.facing)
        mark:SetFrameLevel(canvas.marks:GetFrameLevel() + (KIND_LEVELS[item.kind] or LEVELS[layer] or REST))
        mark.sized = sized
        update_mark_placed(canvas, mark, item.across, item.down, sized)
    end
    for index = #items + 1, #pool do
        pool[index].item = nil
        pool[index]:Hide()
    end
end
