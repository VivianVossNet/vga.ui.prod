-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: The settings' tab »Taschen«: the bags' size - small, normal, large -, and the order the bags show their items in: as they lie - the game's own places, the default -; by value, rising or falling, a stack counted at what it sells for; or by type, the type worth most in all first, within it the dearest first; the empty slots always last when sorted. Only the view is sorted; no item is moved in the bags. Beneath the loot's size the game's own fast looting is switched, »Schnell plündern« (autoLootDefault), out of combat, as the game's settings do (K0705).

-- {K0705} {K0414} {K0415}

local _, vga = ...
local library = LibVGA
local ORDERS = { "laid", "value_up", "value_down", "kind" }
local SIZES = { "small", "normal", "large" }

local function read_value(item)
    if not item then return 0 end
    local price = select(11, C_Item.GetItemInfo(item.itemID)) or 0
    return price * (item.stackCount or 1)
end

local function read_kind(item)
    local _, _, _, _, _, class = C_Item.GetItemInfoInstant(item.itemID)
    return class or -1
end

local function read_kind_worth(entries)
    local worth = {}
    for _, entry in ipairs(entries) do
        if entry.item then worth[entry.kind] = (worth[entry.kind] or 0) + entry.value end
    end
    return worth
end

local function check_laid_before(one, other)
    if one.bag ~= other.bag then return one.bag < other.bag end
    return one.slot < other.slot
end

local function read_sorter(order, worth)
    local function check_before(one, other)
        if (one.item == nil) ~= (other.item == nil) then return one.item ~= nil end
        if one.item and order == "kind" and one.kind ~= other.kind then
            if worth[one.kind] ~= worth[other.kind] then return worth[one.kind] > worth[other.kind] end
            return one.kind < other.kind
        end
        if one.item and one.value ~= other.value then
            if order == "value_up" then return one.value < other.value end
            return one.value > other.value
        end
        return check_laid_before(one, other)
    end
    return check_before
end

function vga.read_bag_order()
    return LibVGASettings.bag_order or "laid"
end

function vga.update_bag_order(entries)
    local order = vga.read_bag_order()
    if order == "laid" then return entries end
    for _, entry in ipairs(entries) do
        entry.value = read_value(entry.item)
        entry.kind = entry.item and read_kind(entry.item) or -1
    end
    table.sort(entries, read_sorter(order, read_kind_worth(entries)))
    return entries
end

local function write_order(index)
    LibVGASettings.bag_order = ORDERS[index]
    library.update_elements()
end

local function write_size(index)
    LibVGASettings.sizes.bags = SIZES[index]
    library.update_elements()
end

local function write_loot_size(index)
    LibVGASettings.sizes.loot = SIZES[index]
    library.update_elements()
end

local function write_auto_loot(index)
    if InCombatLockdown() then return end
    SetCVar("autoLootDefault", index == 1 and "1" or "0")
end

local function read_place(list, wanted)
    for index, value in ipairs(list) do
        if value == wanted then return index end
    end
    return 1
end

function vga.create_bags_page(page)
    local texts = library.texts
    local _, size = library.read_size_step("bags")
    local _, loot_size = library.read_size_step("loot")
    page.rows = {
        library.create_choice_row(page, texts.size, { texts.small, texts.medium, texts.large }, read_place(SIZES, size), write_size),
        library.create_choice_row(page, texts.loot, { texts.small, texts.medium, texts.large }, read_place(SIZES, loot_size), write_loot_size),
        library.create_choice_row(page, texts.auto_loot, { texts.on, texts.off }, GetCVarBool("autoLootDefault") and 1 or 2, write_auto_loot),
        library.create_choice_row(page, texts.sorting, { texts.as_laid, texts.value_up, texts.value_down, texts.by_kind }, read_place(ORDERS, vga.read_bag_order()), write_order),
    }
end
