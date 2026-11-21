-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: the bags' »Aufräumen« (K0644): every item pushed together from the top left - in the general bags as one run, in each special bag on its own -, the last item moved into the first gap, one move at a time, each waiting until the game has unlocked both places and the cursor is free; nothing is sorted, nothing merged, nothing moved in a fight.

-- {K0644}

local _, vga = ...
local library = LibVGA
local STEP_SECONDS = 0.1
local MOST_STEPS = 400
local tidy = {}

function vga.read_tidy_moves(slots, check_filled)
    local taken, moves = {}, {}
    for index, place in ipairs(slots) do taken[index] = check_filled(place) end
    local first, last = 1, #slots
    while true do
        while first <= #slots and taken[first] do first = first + 1 end
        while last >= 1 and not taken[last] do last = last - 1 end
        if first >= last then break end
        moves[#moves + 1] = { from = slots[last], to = slots[first] }
        taken[first], taken[last] = true, false
    end
    return moves
end

local function check_filled(place)
    return C_Container.GetContainerItemInfo(place.bag, place.slot) ~= nil
end

local function check_locked(place)
    local found = C_Container.GetContainerItemInfo(place.bag, place.slot)
    return found and found.isLocked
end

local function update_stopped()
    if tidy.ticker then tidy.ticker:Cancel() end
    tidy.ticker, tidy.moves = nil, nil
end

local function update_step()
    if InCombatLockdown() or tidy.steps > MOST_STEPS or #tidy.moves == 0 then return update_stopped() end
    if GetCursorInfo() then return end
    local move = tidy.moves[1]
    if check_locked(move.from) or check_locked(move.to) then return end
    table.remove(tidy.moves, 1)
    tidy.steps = tidy.steps + 1
    C_Container.PickupContainerItem(move.from.bag, move.from.slot)
    C_Container.PickupContainerItem(move.to.bag, move.to.slot)
end

local function update_step_safely()
    library.update_safely("bag tidy", update_step)
end

function vga.render_bag_tidy(groups)
    if InCombatLockdown() or tidy.ticker then return end
    tidy.moves, tidy.steps = {}, 0
    for _, group in ipairs(groups) do
        local slots = {}
        for _, bag in ipairs(group) do
            for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do slots[#slots + 1] = { bag = bag, slot = slot } end
        end
        for _, move in ipairs(vga.read_tidy_moves(slots, check_filled)) do tidy.moves[#tidy.moves + 1] = move end
    end
    tidy.ticker = C_Timer.NewTicker(STEP_SECONDS, update_step_safely)
end
