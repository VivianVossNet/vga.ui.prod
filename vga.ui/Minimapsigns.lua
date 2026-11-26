-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: the minimap's signs, all our own (K0922), as the accepted draft draws them (manual/view/vga-minimap-signs.html B, K0923, K0924): the game's own signs put away by Minimap:SetIconScale(0), which takes the player's arrow too (K0921); over the visible map LibVGA's layer of map signs (library.create_map_sign_surface, K0925) fed with the world map's layers (vga.update_map_layers) on the plane of the continent the player stands on, read twice a second, every sign placed anew at every frame so it sits fast on the map and moves with it, never jerking behind it (K0929); each sign placed by its offset from the player in yards - its plane position less the player's, times the plane's size by C_Map.GetMapWorldSize - against C_Minimap.GetViewRadius, which the minimap's half side stands for (K0926), and shown only while it lies wholly inside the visible map (K0915); the player's arrow, the orange sign, 30 draft pixels - a third smaller than the draft's 40 at the owner's word (K0927), then a little larger so it hides the game's arrow beneath it while a search shows the game's signs (K0957) -, held in the minimap's middle and turned with the facing at every frame, lying exactly over the game's own beneath it - the setting »Positionspfeil« of K0945 is gone, having no effect left (K0958, K0959, K0960); the party 19 - a quarter smaller than 22, then a little larger again (K0962, K0964) -, each member's place read anew at every frame so it never trails (K0965), the quests' »!« and »?« 22.5 - a quarter larger at the owner's word (K0931) -, every other sign 18. Our filters (vga.ui/Mapfilters.lua) govern which of our signs are shown, and whether the game's own signs are shown too - while a search or a tracking we do not draw is on (K0951, K0952). Indoors is not measured yet.

-- {K0965} {K0964} {K0962} {K0960} {K0959} {K0958} {K0957} {K0951} {K0949} {K0945} {K0931} {K0929} {K0927} {K0926} {K0925} {K0924} {K0923} {K0922}

local _, vga = ...
local library = LibVGA
local EVERY = 0.5
local SIZES = { me = 30, party = 19 }
local QUESTS = { QuestTake = true, QuestTakeLow = true, QuestTurn = true, QuestOpen = true }
local QUEST = 22.5
local REST = 18
local CONTINENT = Enum and Enum.UIMapType and Enum.UIMapType.Continent or 2
local surface

local function read_continent(map)
    local entry = map and C_Map.GetMapInfo(map)
    while entry and entry.mapType ~= CONTINENT and entry.parentMapID and entry.parentMapID > 0 do
        entry = C_Map.GetMapInfo(entry.parentMapID)
    end
    return entry and entry.mapType == CONTINENT and entry.mapID or nil
end

local function read_mark_size(layer, kind)
    if QUESTS[kind] then return library.read_draft_size(QUEST) end
    return library.read_draft_size(SIZES[layer] or REST)
end

local function read_mark_point(view, across, down)
    local radius = C_Minimap.GetViewRadius()
    local half = view:GetWidth() / 2
    local x = half + (across - view.me[1]) * view.plane_size[1] / radius * half
    local y = view:GetHeight() / 2 + (down - view.me[2]) * view.plane_size[2] / radius * half
    return x, y
end

local function read_player()
    local map = C_Map.GetBestMapForUnit("player")
    local continent = read_continent(map)
    local spot = map and C_Map.GetPlayerMapPosition(map, "player")
    if not (spot and continent) then return nil end
    local plane = { id = continent }
    local width, height = C_Map.GetMapWorldSize(continent)
    local across, down = vga.read_map_world_point(map, spot.x, spot.y, plane)
    if not (across and (width or 0) > 0) then return nil end
    return { map = map, plane = plane, me = { across, down }, size = { width, height } }
end

local function update_arrow(player)
    local arrow = ((surface.mark_layers or {}).me or {})[1]
    if not (arrow and arrow.item) then return end
    arrow.item.across, arrow.item.down = player.me[1], player.me[2]
    arrow.picture:SetRotation(GetPlayerFacing and GetPlayerFacing() or 0)
end

local function update_party(player)
    for _, mark in ipairs((surface.mark_layers or {}).party or {}) do
        local unit = mark.item and mark.item.unit
        local map = unit and C_Map.GetBestMapForUnit(unit)
        local spot = map and C_Map.GetPlayerMapPosition(map, unit)
        if spot then
            local across, down = vga.read_map_world_point(map, spot.x, spot.y, player.plane)
            if across then mark.item.across, mark.item.down = across, down end
        end
    end
end

local function update_signs(read_layers)
    if Minimap.SetIconScale then Minimap:SetIconScale(vga.read_game_signs_shown() and 1 or 0) end
    local player = read_player()
    surface:SetShown(player ~= nil)
    if not player then return end
    surface.me, surface.plane_size = player.me, player.size
    if read_layers then vga.update_map_filters_kept() end
    if read_layers then return vga.update_map_layers(surface, "zone", { id = player.map, parent = player.plane.id }, player.plane) end
    update_arrow(player)
    update_party(player)
    library.update_map_marks_placed(surface)
end

local function update_signs_safely(_, elapsed)
    surface.since = (surface.since or 0) + elapsed
    local read_layers = surface.since >= EVERY
    if read_layers then surface.since = 0 end
    library.update_safely("minimap signs", update_signs, read_layers)
end

function vga.create_minimap_signs(view)
    surface = library.create_map_sign_surface(view, { read_point = read_mark_point, read_size = read_mark_size, read_kind_shown = vga.check_minimap_kind_shown })
    surface:SetAllPoints(view)
    surface:SetFrameStrata(Minimap:GetFrameStrata())
    surface:SetFrameLevel(Minimap:GetFrameLevel() + 5)
    surface:SetScript("OnUpdate", update_signs_safely)
    return surface
end

function vga.read_minimap_signs()
    return surface
end
