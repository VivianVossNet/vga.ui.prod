-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: since when each item has been carried in the bags (K0943): at login and after every change of the bags, every item link held is given the time it was first seen, kept in LibVGASettings.bag_held, and a link no longer held is let go; what the bags held when this began counts as the oldest, its time 0. vga.read_held_since(link) gives it - the merchant's sell page lists the newest first by it.

-- {K0943}

local _, vga = ...
local library = LibVGA

local function write_held()
    local fresh = LibVGASettings.bag_held == nil
    LibVGASettings.bag_held = LibVGASettings.bag_held or {}
    local held, now, present = LibVGASettings.bag_held, time(), {}
    for bag = 0, NUM_BAG_SLOTS or 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local found = C_Container.GetContainerItemInfo(bag, slot)
            local link = found and found.hyperlink
            if link then
                present[link] = true
                held[link] = held[link] or (fresh and 0 or now)
            end
        end
    end
    for link in pairs(held) do
        if not present[link] then held[link] = nil end
    end
end

function vga.read_held_since(link)
    return link and LibVGASettings.bag_held and LibVGASettings.bag_held[link] or 0
end

local events = CreateFrame("Frame")
library.update_events(events, { "PLAYER_LOGIN", "BAG_UPDATE_DELAYED" })
events:SetScript("OnEvent", function() library.update_safely("bag held", write_held) end)
