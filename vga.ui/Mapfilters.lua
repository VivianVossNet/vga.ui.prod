-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: the minimap's filters, as the accepted draft draws them (manual/view/vga-minimap-filters.html B, K0952): the magnifier opens our list - LibVGA's list of switches on the widgets' frame and head, »Verfolgen« (K0954), its ground at three quarters (K0956), each row with its sign - instead of the game's menu, holding what the game's menu holds, each tracking known by its picture's number, not its name (K0951): the searches of a race or a class - every tracking of the kind »spell« the player has - first, under »Suchen«, in a round cell with the game's own picture; then »Reisen«, »Dienste«, »Lehrer und Quests«. What vga.ui draws itself - flight masters, inns, auction, repair, trainers, the low quests - is switched in our own state (LibVGASettings.map_filters, its first value the game's) and kept off in the game; bank, mailbox, stable and battle masters are ours too, from Questie (K0957); the searches switch the game's own tracking, and while one of them is on the game's signs are shown on the minimap, so the finds of a search appear as the game's yellow points, the game's arrow beneath ours. vga.check_minimap_kind_shown answers the minimap's signs - never a quest under way, whose »?« the game sets in the middle of its area and would read as a place to hand it in; a quest's »?« stands only where it is handed in (K0967) -; vga.read_game_signs_shown the scale of the game's signs.

-- {K0967} {K0957} {K0956} {K0954} {K0952} {K0951}

local _, vga = ...
local library = LibVGA
local texts = library.texts
local SEARCHES = "spell"
local OURS = {
    [136456] = { "Flight", "FlightUnknown" }, [136458] = { "Inn" }, [136452] = { "Auction" }, [136465] = { "Repair" },
    [136455] = { "ClassTrainer" }, [136463] = { "ProfessionTrainer" }, [237607] = { "QuestTakeLow" },
    [136453] = { "Bank" }, [136459] = { "Mail" }, [136466] = { "Stable" }, [136454] = { "Battle" },
}
local GROUPS = {
    { key = "map_filter_travel", rows = { { 136456, "Flight" }, { 136466, "Stable" } } },
    { key = "map_filter_services", rows = { { 136458, "Inn" }, { 136453, "Bank" }, { 136459, "Mail" }, { 136452, "Auction" }, { 136465, "Repair" }, { 136454, "Battle" } } },
    { key = "map_filter_teachers", rows = { { 136455, "ClassTrainer" }, { 136463, "ProfessionTrainer" }, { 237607, "QuestTakeLow" } } },
}
local GROUND = 0.75
local NEVER = { QuestOpen = true }
local list

local function read_trackings()
    local found = {}
    if not (C_Minimap.GetNumTrackingTypes and C_Minimap.GetTrackingInfo) then return found end
    for index = 1, C_Minimap.GetNumTrackingTypes() do
        local tracking = C_Minimap.GetTrackingInfo(index)
        if tracking and not found[tracking.texture] then found[tracking.texture] = { index = index, name = tracking.name, active = tracking.active, search = tracking.type == SEARCHES } end
    end
    return found
end

local function read_own(texture, tracking)
    LibVGASettings.map_filters = LibVGASettings.map_filters or {}
    local own = LibVGASettings.map_filters[texture]
    if own == nil then own = tracking.active == true end
    LibVGASettings.map_filters[texture] = own
    return own
end

local function write_game_ours_off(trackings)
    for texture, tracking in pairs(trackings) do
        if OURS[texture] then
            read_own(texture, tracking)
            if tracking.active and C_Minimap.SetTracking then C_Minimap.SetTracking(tracking.index, false) end
        end
    end
end

function vga.check_minimap_kind_shown(kind)
    if NEVER[kind] then return false end
    for texture, kinds in pairs(OURS) do
        for _, named in ipairs(kinds) do
            if named == kind then return LibVGASettings.map_filters == nil or LibVGASettings.map_filters[texture] ~= false end
        end
    end
    return true
end

function vga.read_game_signs_shown()
    for texture, tracking in pairs(read_trackings()) do
        if tracking.active and tracking.search then return true end
    end
    return false
end

function vga.update_map_filters_kept()
    write_game_ours_off(read_trackings())
end

local function write_filter(texture, on)
    local tracking = read_trackings()[texture]
    if not tracking then return end
    if OURS[texture] then
        LibVGASettings.map_filters = LibVGASettings.map_filters or {}
        LibVGASettings.map_filters[texture] = on
        return
    end
    if C_Minimap.SetTracking then C_Minimap.SetTracking(tracking.index, on) end
end

local function read_row(texture, kind, tracking)
    local row = { key = texture, word = tracking.name, on = OURS[texture] and read_own(texture, tracking) or tracking.active }
    row.picture, row.tint, row.faint = library.read_map_mark_picture(kind)
    return row
end

local function read_groups(trackings)
    local searches = { heading = texts.map_filter_searches, rows = {} }
    for texture, tracking in pairs(trackings) do
        if tracking.search then searches.rows[#searches.rows + 1] = { key = texture, word = tracking.name, on = tracking.active, picture = texture, round = true } end
    end
    table.sort(searches.rows, function(one, other) return one.word < other.word end)
    local groups = { searches }
    for _, group in ipairs(GROUPS) do
        local made = { heading = texts[group.key], rows = {} }
        for _, entry in ipairs(group.rows) do
            if trackings[entry[1]] then made.rows[#made.rows + 1] = read_row(entry[1], entry[2], trackings[entry[1]]) end
        end
        if #made.rows > 0 then groups[#groups + 1] = made end
    end
    return groups
end

local function render_filter_changed(texture, on)
    library.update_safely("map filter", write_filter, texture, on)
end

function vga.render_map_filters(anchor)
    if list and list:IsShown() then return list:Hide() end
    local trackings = read_trackings()
    write_game_ours_off(trackings)
    list = list or library.create_switch_list(UIParent, read_groups(trackings), render_filter_changed, { title = texts.map_filters, ground = GROUND })
    list:SetFrameStrata("DIALOG")
    list:ClearAllPoints()
    list:SetPoint("TOPRIGHT", anchor, "BOTTOMLEFT", 0, 0)
    library.update_switch_list(list)
    list:Show()
end

function vga.read_map_filters()
    return list
end
