-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: what disenchanting an item yields, after the accepted draft manual/view/vga-disenchant.html (K0752): weapons and armour of uncommon, rare and epic quality, by Forever's own item level bands (read from the game's data, build 1.60.1.71037) and, for what a band gives, the known table of Classic, unconfirmed for Forever - uncommon armour mostly dust, an uncommon weapon mostly essence, rare a shard, epic shards or a Nexus Crystal; each material with its amount and chance. vga.ui learns along: whenever the player disenchants, what came out is kept per band, account-wide, and from ten disenchantings of a band on, what was learned stands instead of the rule. The expected value is the materials' market values by amount and chance, none where a material has none. Shown only to a player who knows Enchanting (K0636).

-- {K0752} {K0636} {K0603}

local _, vga = ...
local SPELL = 13262
local LEARNED_FROM = 10
local WEAPON, ARMOUR = 2, 4
local UNCOMMON_QUALITY, RARE_QUALITY, EPIC_QUALITY = 2, 3, 4
local AFTER_CAST = 5
local MATERIAL = {
    strange = 10940, soul = 11083, vision = 11137, dream = 11176, illusion = 16204,
    lmagic = 10938, gmagic = 10939, lastral = 10998, gastral = 11082, lmystic = 11134, gmystic = 11135,
    lnether = 11174, gnether = 11175, leternal = 16202, geternal = 16203,
    sglim = 10978, lglim = 11084, sglow = 11138, lglow = 11139, srad = 11177, lrad = 11178, sbril = 14343, lbril = 14344, nexus = 20725,
}
local UNCOMMON = {
    { 5, 15, { MATERIAL.strange, 1, 2 }, { MATERIAL.lmagic, 1, 2 }, false, { 80, 20, 0 } },
    { 16, 20, { MATERIAL.strange, 2, 3 }, { MATERIAL.gmagic, 1, 2 }, { MATERIAL.sglim, 1, 1 } },
    { 21, 25, { MATERIAL.strange, 4, 6 }, { MATERIAL.lastral, 1, 2 }, { MATERIAL.sglim, 1, 1 }, { 75, 15, 10 } },
    { 26, 30, { MATERIAL.soul, 1, 2 }, { MATERIAL.gastral, 1, 2 }, { MATERIAL.lglim, 1, 1 } },
    { 31, 35, { MATERIAL.soul, 2, 5 }, { MATERIAL.lmystic, 1, 2 }, { MATERIAL.sglow, 1, 1 } },
    { 36, 40, { MATERIAL.vision, 1, 2 }, { MATERIAL.gmystic, 1, 2 }, { MATERIAL.lglow, 1, 1 } },
    { 41, 45, { MATERIAL.vision, 2, 5 }, { MATERIAL.lnether, 1, 2 }, { MATERIAL.srad, 1, 1 } },
    { 46, 50, { MATERIAL.dream, 1, 2 }, { MATERIAL.gnether, 1, 2 }, { MATERIAL.lrad, 1, 1 } },
    { 51, 55, { MATERIAL.dream, 2, 5 }, { MATERIAL.leternal, 1, 2 }, { MATERIAL.sbril, 1, 1 } },
    { 56, 60, { MATERIAL.illusion, 1, 2 }, { MATERIAL.geternal, 1, 2 }, { MATERIAL.lbril, 1, 1 } },
    { 61, 99, { MATERIAL.illusion, 2, 5 }, { MATERIAL.geternal, 2, 3 }, { MATERIAL.lbril, 1, 1 } },
}
local RARE = {
    { 5, 15, { { MATERIAL.sglim, 1, 1, 100 } } }, { 16, 20, { { MATERIAL.sglim, 1, 1, 100 } } }, { 21, 25, { { MATERIAL.sglim, 1, 1, 100 } } },
    { 26, 30, { { MATERIAL.lglim, 1, 1, 100 } } }, { 31, 35, { { MATERIAL.sglow, 1, 1, 100 } } }, { 36, 40, { { MATERIAL.lglow, 1, 1, 100 } } },
    { 41, 45, { { MATERIAL.srad, 1, 1, 100 } } }, { 46, 50, { { MATERIAL.lrad, 1, 1, 100 } } }, { 51, 55, { { MATERIAL.sbril, 1, 1, 100 } } },
    { 56, 99, { { MATERIAL.lbril, 1, 1, 99.5 }, { MATERIAL.nexus, 1, 1, 0.5 } } },
}
local EPIC = {
    { 40, 45, { { MATERIAL.srad, 2, 4, 100 } } }, { 46, 50, { { MATERIAL.lrad, 2, 4, 100 } } }, { 51, 55, { { MATERIAL.sbril, 2, 4, 100 } } },
    { 56, 60, { { MATERIAL.nexus, 1, 1, 100 } } }, { 61, 99, { { MATERIAL.nexus, 1, 2, 100 } } },
}
local TABLES = { [UNCOMMON_QUALITY] = UNCOMMON, [RARE_QUALITY] = RARE, [EPIC_QUALITY] = EPIC }

local function read_uncommon_yields(row, weapon)
    local shares = row[6] or { 75, 20, 5 }
    local dust, essence, shard = shares[1], shares[2], shares[3]
    if weapon and row[1] >= 51 then
        dust, essence, shard = 22, 75, 3
    elseif weapon then
        dust, essence = essence, dust
    end
    local yields = { { row[3][1], row[3][2], row[3][3], dust }, { row[4][1], row[4][2], row[4][3], essence } }
    if row[5] and shard > 0 then yields[3] = { row[5][1], row[5][2], row[5][3], shard } end
    return yields
end

local function read_row(quality, level)
    for _, row in ipairs(TABLES[quality] or {}) do
        if level >= row[1] and level <= row[2] then return row end
    end
end

local function read_store()
    LibVGAAccount = LibVGAAccount or {}
    LibVGAAccount.disenchants = LibVGAAccount.disenchants or {}
    return LibVGAAccount.disenchants
end

local function read_learned_yields(key)
    local band = read_store()[key]
    if not (band and band.casts >= LEARNED_FROM) then return nil end
    local yields = {}
    for item, seen in pairs(band.items) do yields[#yields + 1] = { item, seen.least, seen.most, seen.times / band.casts * 100 } end
    table.sort(yields, function(one, other) return one[4] > other[4] end)
    return yields, band.casts
end

local function read_band(link)
    local _, _, quality, level, _, _, _, _, _, _, _, class = C_Item.GetItemInfo(link)
    if not (quality and level) or (class ~= WEAPON and class ~= ARMOUR) then return nil end
    local row = read_row(quality, level)
    if not row then return nil end
    local weapon = class == WEAPON
    local kind = quality == UNCOMMON_QUALITY and (weapon and "weapon" or "armour") or "any"
    return row, quality, weapon, quality .. ":" .. kind .. ":" .. row[1]
end

function vga.read_disenchant(link)
    local row, quality, weapon, key = read_band(link)
    if not row then return nil end
    local learned, casts = read_learned_yields(key)
    local rule = quality == UNCOMMON_QUALITY and read_uncommon_yields(row, weapon) or row[3]
    return { yields = learned or rule, learned = casts, band = { row[1], row[2] } }
end

function vga.read_disenchant_value(found)
    local value = 0
    for _, yield in ipairs(found.yields) do
        local market = vga.read_market(yield[1])
        if not market then return nil end
        value = value + market * (yield[2] + yield[3]) / 2 * yield[4] / 100
    end
    return value
end

function vga.check_enchanter()
    if IsPlayerSpell and IsPlayerSpell(SPELL) then return true end
    return C_SpellBook ~= nil and C_SpellBook.ContainsAnyDisenchantSpell ~= nil and C_SpellBook.ContainsAnyDisenchantSpell() == true
end

function vga.update_disenchant_learned(link, loot)
    local _, _, _, key = read_band(link)
    if not key then return end
    local store = read_store()
    store[key] = store[key] or { casts = 0, items = {} }
    local band = store[key]
    band.casts = band.casts + 1
    for _, got in ipairs(loot) do
        local seen = band.items[got[1]] or { times = 0, least = got[2], most = got[2] }
        seen.times, seen.least, seen.most = seen.times + 1, math.min(seen.least, got[2]), math.max(seen.most, got[2])
        band.items[got[1]] = seen
    end
end

local pending = {}

local function update_target(bag, slot)
    if SpellIsTargeting and SpellIsTargeting() then pending.link = C_Container.GetContainerItemLink(bag, slot) end
end

local function read_loot()
    local loot = {}
    for slot = 1, GetNumLootItems() do
        local link = GetLootSlotLink(slot)
        local item = link and C_Item.GetItemInfoInstant(link)
        local _, _, amount = GetLootSlotInfo(slot)
        if item then loot[#loot + 1] = { item, amount or 1 } end
    end
    return loot
end

local function update_event(event, unit, _, spell)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        if unit == "player" and spell == SPELL and pending.link then pending.cast, pending.since = pending.link, GetTime() end
        return
    end
    if not (pending.cast and GetTime() - pending.since < AFTER_CAST) then return end
    vga.update_disenchant_learned(pending.cast, read_loot())
    pending.cast, pending.link = nil, nil
end

if C_Container and C_Container.UseContainerItem then hooksecurefunc(C_Container, "UseContainerItem", update_target) end

local events = CreateFrame("Frame")
for _, name in ipairs({ "UNIT_SPELLCAST_SUCCEEDED", "LOOT_READY" }) do pcall(events.RegisterEvent, events, name) end
events:SetScript("OnEvent", function(_, event, ...)
    LibVGA.update_safely("disenchant " .. event, update_event, event, ...)
end)
