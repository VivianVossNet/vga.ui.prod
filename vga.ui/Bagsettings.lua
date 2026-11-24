-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: The settings' tab »Taschen«: the bags' size - small, normal, large -, and the order the bags show their items in: as they lie - the game's own places, the default -; by value, rising or falling, a stack counted at what it sells for; or by type, the type worth most in all first, within it the dearest first; the empty slots always last when sorted. The loot's moment after a quick loot, 0, 1 or 2 seconds, one by default (K0906). Only the view is sorted; no item is moved in the bags. Whatever the order, the fixed items stand at its end, after the empty slots - or, chosen on the page Komfort, at its start (LibVGASettings.bag_pins_place) -: the player's own pins first, in the order pinned (LibVGAAccount.bag_pins, by item number), then the tools of the professions as Forever knows them (measured, K0898), the hearthstone the very last - mirrored at the start, the hearthstone the very first. The hearthstone and the tools are always fixed; the player adds or removes only items of their own (vga.write_bag_pin).

-- {K0906} {K0898} {K0414} {K0415}

local _, vga = ...
local library = LibVGA
local ORDERS = { "laid", "value_up", "value_down", "kind" }
local FIXED = { 2901, 778, 756, 1959, 7005, 5956, 6256, 6365, 6366, 6367, 12225, 19022, 19970, 4471, 6219, 10498, 6218, 6339, 11130, 11145, 16207, 9149, 5060, 6948 }
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

local function read_pin_ranks()
    local ranks, own = {}, LibVGAAccount.bag_pins or {}
    for index, id in ipairs(own) do ranks[id] = index end
    for index, id in ipairs(FIXED) do ranks[id] = #own + index end
    return ranks
end

function vga.check_bag_pinned(item)
    return item ~= nil and read_pin_ranks()[item.itemID] ~= nil
end

function vga.check_bag_pin_fixed(id)
    for _, fixed in ipairs(FIXED) do
        if fixed == id then return true end
    end
    return false
end

function vga.write_bag_pin(id)
    if vga.check_bag_pin_fixed(id) then return end
    LibVGAAccount.bag_pins = LibVGAAccount.bag_pins or {}
    local own = LibVGAAccount.bag_pins
    for index, pinned in ipairs(own) do
        if pinned == id then return table.remove(own, index) end
    end
    own[#own + 1] = id
end

local function read_sorted(entries)
    local order = vga.read_bag_order()
    if order == "laid" then return entries end
    for _, entry in ipairs(entries) do
        entry.value = read_value(entry.item)
        entry.kind = entry.item and read_kind(entry.item) or -1
    end
    table.sort(entries, read_sorter(order, read_kind_worth(entries)))
    return entries
end

local function check_pin_before(one, other)
    if one.rank ~= other.rank then return one.rank < other.rank end
    return check_laid_before(one, other)
end

function vga.update_bag_order(entries)
    local ranks, rest, pinned = read_pin_ranks(), {}, {}
    for _, entry in ipairs(read_sorted(entries)) do
        entry.rank = entry.item and ranks[entry.item.itemID]
        local list = entry.rank and pinned or rest
        list[#list + 1] = entry
    end
    table.sort(pinned, check_pin_before)
    local start = LibVGASettings.bag_pins_place == "start"
    local ordered = start and {} or rest
    for index = start and #pinned or 1, start and 1 or #pinned, start and -1 or 1 do ordered[#ordered + 1] = pinned[index] end
    if start then for _, entry in ipairs(rest) do ordered[#ordered + 1] = entry end end
    return ordered
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

local function read_place(list, wanted)
    for index, value in ipairs(list) do
        if value == wanted then return index end
    end
    return 1
end

local function read_linger_labels()
    local labels = {}
    for index, seconds in ipairs(library.loot_linger_stops) do labels[index] = string.format(library.texts.seconds_short, seconds) end
    return labels
end

local function write_loot_linger(index)
    LibVGASettings.loot_linger = library.loot_linger_stops[index]
end

function vga.create_bags_page(page)
    local texts = library.texts
    local _, size = library.read_size_step("bags")
    local _, loot_size = library.read_size_step("loot")
    page.rows = {
        library.create_choice_row(page, texts.size, { texts.small, texts.medium, texts.large }, read_place(SIZES, size), write_size),
        library.create_choice_row(page, texts.loot, { texts.small, texts.medium, texts.large }, read_place(SIZES, loot_size), write_loot_size),
        library.create_choice_row(page, texts.loot_linger, read_linger_labels(), read_place(library.loot_linger_stops, LibVGASettings.loot_linger or library.loot_linger_default), write_loot_linger),
        library.create_choice_row(page, texts.sorting, { texts.as_laid, texts.value_up, texts.value_down, texts.by_kind }, read_place(ORDERS, vga.read_bag_order()), write_order),
    }
end
