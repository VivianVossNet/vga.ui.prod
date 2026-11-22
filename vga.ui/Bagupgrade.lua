-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: whether an item in the bags is an upgrade, by formula B of the draft (manual/view/vga-upgrade.html, K0723): its stats weighted and added - the main stat of the player's specialisation times 1.2, a main stat foreign to it times 0, stamina and every other stat times 1, a weapon's damage per second times 1 for strength and agility, the armour value and sockets not at all - and compared with what is worn in its place; for two places, rings, trinkets and one-handers, with the weaker of the two; a two-hander with both hands together; an empty place taking any item with points; only what the player can use. Forever has no answer of its own.

-- {K0723}

local _, vga = ...
local MAIN_WEIGHT = 1.2
local PRIMARY = { ITEM_MOD_STRENGTH_SHORT = 1, ITEM_MOD_AGILITY_SHORT = 2, ITEM_MOD_INTELLECT_SHORT = 4 }
local DAMAGE = "ITEM_MOD_DAMAGE_PER_SECOND_SHORT"
local INTELLECT = 4
local LEFT_OUT = { RESISTANCE0_NAME = true }
local CLASS_MAIN = {
    WARRIOR = 1, PALADIN = 1, DEATHKNIGHT = 1, HUNTER = 2, ROGUE = 2, DEMONHUNTER = 2, MONK = 2, DRUID = 2,
    SHAMAN = 4, MAGE = 4, PRIEST = 4, WARLOCK = 4, EVOKER = 4,
}
local PLACES = {
    INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 }, INVTYPE_CHEST = { 5 }, INVTYPE_ROBE = { 5 },
    INVTYPE_WAIST = { 6 }, INVTYPE_LEGS = { 7 }, INVTYPE_FEET = { 8 }, INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 },
    INVTYPE_FINGER = { 11, 12 }, INVTYPE_TRINKET = { 13, 14 }, INVTYPE_CLOAK = { 15 },
    INVTYPE_WEAPON = { 16, 17 }, INVTYPE_WEAPONMAINHAND = { 16 }, INVTYPE_WEAPONOFFHAND = { 17 }, INVTYPE_SHIELD = { 17 },
    INVTYPE_HOLDABLE = { 17 }, INVTYPE_RANGED = { 16 }, INVTYPE_RANGEDRIGHT = { 16 },
}
local TWO_HANDS = { INVTYPE_2HWEAPON = { 16, 17 } }

local function read_main_stat()
    local specs = C_SpecializationInfo
    local chosen = specs and specs.GetSpecialization and specs.GetSpecialization()
    local primary = chosen and select(6, specs.GetSpecializationInfo(chosen))
    if primary then return primary end
    local _, class = UnitClass("player")
    return CLASS_MAIN[class] or INTELLECT
end

local function read_weight(key, main)
    if LEFT_OUT[key] or key:find("^EMPTY_SOCKET") then return 0 end
    if PRIMARY[key] then return PRIMARY[key] == main and MAIN_WEIGHT or 0 end
    if key == DAMAGE then return main ~= INTELLECT and 1 or 0 end
    return 1
end

function vga.read_item_score(link, main)
    local stats = link and C_Item.GetItemStats(link)
    if not stats then return 0 end
    local score = 0
    for key, value in pairs(stats) do score = score + value * read_weight(key, main) end
    return score
end

local function read_worn_score(places, main, together)
    local scores = {}
    for index, place in ipairs(places) do scores[index] = vga.read_item_score(GetInventoryItemLink("player", place), main) end
    if together then return scores[1] + (scores[2] or 0) end
    return math.min(unpack(scores))
end

function vga.check_item_upgrade(link)
    if not link or link == "" then return false end
    local itemID, _, _, slot = C_Item.GetItemInfoInstant(link)
    local places, together = PLACES[slot], TWO_HANDS[slot] ~= nil
    places = places or TWO_HANDS[slot]
    if not places or (C_PlayerInfo and type(itemID) == "number" and not C_PlayerInfo.CanUseItem(itemID)) then return false end
    local main = read_main_stat()
    local score = vga.read_item_score(link, main)
    return score > 0 and score > read_worn_score(places, main, together)
end
