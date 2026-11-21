-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: The quest tracker's zones as manual/view/vga-questzones.html draws B (K0547): with »Zonen: Alle« on the tab Quests the watched quests are grouped by their zone, each group under a label of its own - a thin line above it, a chevron, the zone's name in small capitals and the count of its quests at the right, all in VGA's orange -; the zone the player stands in first, open, its name followed by a quiet »· hier«, a click closing and opening it (K0557); the others by name, closed, a click on one opening it and closing the one opened before, a second click closing it again. The label is LibVGA's accordion (LibVGA/Accordion.lua, K0633). With »Aktuelle«, the default, the tracker shows the player's zone alone, as before. Quests.lua lays the groups.

-- {K0547} {K0557} {K0633}

local _, vga = ...
local library = LibVGA
local QUIET = "|cff9a968c"
local open_zone, here_closed

function vga.check_all_zones()
    return LibVGASettings.quest_zones == "all"
end

local function check_group_before(one, other)
    if one.here ~= other.here then return one.here end
    return one.name < other.name
end

function vga.read_zone_groups(quests, here_name)
    local groups, by_name = {}, {}
    for _, quest in ipairs(quests) do
        local name = quest.here and here_name or quest.zone or library.texts.other_zone
        local group = by_name[name]
        if not group then
            group = { name = name, here = quest.here and true or false, quests = {} }
            by_name[name] = group
            groups[#groups + 1] = group
        end
        group.here = group.here or (quest.here and true or false)
        group.quests[#group.quests + 1] = quest
    end
    table.sort(groups, check_group_before)
    return groups
end

function vga.check_zone_open(group)
    if group.here then return not here_closed end
    return group.name == open_zone
end

local function render_toggle(label)
    if label.here then
        here_closed = not here_closed
    else
        open_zone = open_zone ~= label.zone and label.zone or nil
    end
    if vga.update_quest_tracker then vga.update_quest_tracker() end
end

local function render_toggle_safely(label)
    library.update_safely("quest zone", render_toggle, label)
end

function vga.create_zone_label(parent)
    local label = library.create_accordion(parent)
    label:SetScript("OnClick", render_toggle_safely)
    return label
end

function vga.update_zone_label(label, group, top, width)
    label:ClearAllPoints()
    label:SetPoint("TOPLEFT", label:GetParent(), "TOPLEFT", 0, -(top - (label:GetParent().top or 0)))
    label:Show()
    label.zone, label.here = group.name, group.here
    local word = library.read_capitals(group.name) .. (group.here and (QUIET .. " · " .. library.texts.here_zone .. "|r") or "")
    return library.update_accordion(label, word, vga.check_zone_open(group), width, #group.quests)
end
