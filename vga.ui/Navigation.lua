-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: The navigation arrow centred between the player frame and the target frame: three gold chevrons, the foremost strongest and each behind it fainter, laid on the ground as if they lay on the way, each tilted back on its own, with room between them, the farther a little smaller - turned towards the nearest open quest's target as the player sees it - the quest set as the game's tracked one, so the game's own navigation tells where its target stands on the screen, and the arrow points from the screen's middle there, turning with the camera however it is turned, behind the camera pointing back; the addon never sets a map marker of its own, markers are the player's alone (K0749) - one an earlier version left, remembered in LibVGASettings.navigation_waypoint, is cleared on entering the world -; the game's report is read only half a second after the target changes, when it has caught up (K0746); while a marker the player set stands, it is the arrow's target instead of any quest, tracked by the game, every quest's arrow in the tracker grey, until a click on one of them takes it off the map and makes that quest the target (K0748); only where the game gives no place on the screen, by the character's facing - and tilted back (K0545) -, its distance beneath it; shown whenever the tracker has such a target, in a fight too, gone without one.

-- {K0789} {K0370} {K0372} {K0398} {K0399} {K0545} {K0728} {K0746} {K0748} {K0749}

local _, vga = ...
local library = LibVGA
local atan2 = math.atan2 or math.atan
local colours = library.colours
local TILT = 0.5
local CHEVRONS = { { ahead = 1, alpha = 1 }, { ahead = 0, alpha = 0.6 }, { ahead = -1, alpha = 0.25 } }
local SPACING = 0.3
local CHEVRON = 0.5
local NEARER = 0.15
local OVERHANG = 0.05
local navigation

local function create_navigation()
    navigation = CreateFrame("Frame", "VGANavigation", UIParent)
    navigation.lying = CreateFrame("Frame", nil, navigation)
    navigation.lying:SetPoint("CENTER")
    navigation.chevrons = {}
    for index, chevron in ipairs(CHEVRONS) do
        local texture = navigation.lying:CreateTexture(nil, "ARTWORK")
        texture:SetTexture(library.media .. "NaviChevron", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        texture:SetVertexColor(colours.gold[1], colours.gold[2], colours.gold[3], chevron.alpha)
        texture.ahead = chevron.ahead
        navigation.chevrons[index] = texture
    end
    navigation.distance = library.create_text(navigation, "figures_figure", colours.ink)
    navigation:Hide()
end

local function read_ground_corner(x, y, turn)
    local cosine, sine = math.cos(turn), math.sin(turn)
    local ground = y / TILT
    return x * cosine - ground * sine + 0.5, x * sine + ground * cosine + 0.5
end

local function update_lying(texture, turn)
    local left_top_x, left_top_y = read_ground_corner(-0.5, -0.5 * TILT, turn)
    local left_bottom_x, left_bottom_y = read_ground_corner(-0.5, 0.5 * TILT, turn)
    local right_top_x, right_top_y = read_ground_corner(0.5, -0.5 * TILT, turn)
    local right_bottom_x, right_bottom_y = read_ground_corner(0.5, 0.5 * TILT, turn)
    texture:SetTexCoord(left_top_x, left_top_y, left_bottom_x, left_bottom_y, right_top_x, right_top_y, right_bottom_x, right_bottom_y)
end

local function update_chevrons(heading)
    local width = navigation.lying:GetWidth()
    for _, texture in ipairs(navigation.chevrons) do
        local ahead = texture.ahead * SPACING * width
        local rise = math.cos(heading) * ahead * TILT
        local size = width * CHEVRON * (1 - NEARER * rise / (SPACING * width * TILT))
        texture:ClearAllPoints()
        texture:SetPoint("CENTER", navigation.lying, "CENTER", -math.sin(heading) * ahead, rise)
        texture:SetSize(size, size * TILT)
        update_lying(texture, heading)
    end
end

local function update_place()
    local player, target = VGAUnitFrame_player, VGAUnitFrame_target
    if not (player and target) then return false end
    local width = library.read_size(8)
    navigation:ClearAllPoints()
    navigation:SetPoint("TOPLEFT", player, "TOPRIGHT")
    navigation:SetPoint("BOTTOMRIGHT", target, "BOTTOMLEFT")
    navigation.lying:SetSize(width, math.floor(width * TILT + 0.5))
    navigation.distance:SetFontObject(library.read_font("figures_figure"))
    navigation.distance:ClearAllPoints()
    navigation.distance:SetPoint("TOP", navigation.lying, "BOTTOM", 0, -library.read_size(-6) - math.floor(width * OVERHANG + 0.5))
    return true
end

local navigation_way
local SAME_SPOT = 0.0001
local SETTLE = 0.5
local chosen = {}

local function update_tracked(aim)
    if not (aim.id and C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID) then return end
    if C_SuperTrack.GetSuperTrackedQuestID() ~= aim.id then C_SuperTrack.SetSuperTrackedQuestID(aim.id) end
end

local function check_screen_place()
    return C_Navigation and C_Navigation.GetFrame and C_Navigation.GetFrame() and C_Navigation.HasValidScreenPosition and C_Navigation.HasValidScreenPosition()
end

local function read_map_waypoint()
    if not (C_Map.HasUserWaypoint and C_Map.HasUserWaypoint() and C_Map.GetUserWaypoint) then return nil end
    return C_Map.GetUserWaypoint()
end

local function check_spot(point, map, x, y)
    local spot = point and point.position
    return spot ~= nil and point.uiMapID == map and math.abs(spot.x - x) < SAME_SPOT and math.abs(spot.y - y) < SAME_SPOT
end

local function check_waypoint_ours(point)
    local own = LibVGASettings.navigation_waypoint
    return own ~= nil and check_spot(point, own[1], own[2], own[3])
end

local function update_waypoint_cleared()
    if not LibVGASettings.navigation_waypoint then return end
    if check_waypoint_ours(read_map_waypoint()) and C_Map.ClearUserWaypoint then C_Map.ClearUserWaypoint() end
    LibVGASettings.navigation_waypoint = nil
end

local function read_player_point(point, map)
    if point.uiMapID == map then return { point.position.x, point.position.y } end
    if not (C_Map.GetWorldPosFromMapPos and C_Map.GetMapPosFromWorldPos) then return nil end
    local continent, world = C_Map.GetWorldPosFromMapPos(point.uiMapID, point.position)
    local _, spot = C_Map.GetMapPosFromWorldPos(continent, world, map)
    return spot and { spot.x, spot.y }
end

local function read_marker_distance(map, point)
    local spot = C_Map.GetPlayerMapPosition(map, "player")
    if not (spot and CreateVector2D) then return nil end
    local _, here = C_Map.GetWorldPosFromMapPos(map, CreateVector2D(spot.x, spot.y))
    local _, there = C_Map.GetWorldPosFromMapPos(map, CreateVector2D(point[1], point[2]))
    if not (here and there) then return nil end
    return math.sqrt((there.x - here.x) ^ 2 + (there.y - here.y) ^ 2)
end

function vga.read_marker_aim()
    local point = read_map_waypoint()
    local map = C_Map.GetBestMapForUnit("player")
    if not (point and point.position and map) or check_waypoint_ours(point) then return nil end
    local spot = read_player_point(point, map)
    return spot and { marker = true, point = spot, distance = read_marker_distance(map, spot) }
end

function vga.update_marker_cleared()
    if vga.read_marker_aim() and C_Map.ClearUserWaypoint then C_Map.ClearUserWaypoint() end
end

local function update_marker_tracked()
    if not (C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint) then return end
    if not (C_SuperTrack.IsSuperTrackingUserWaypoint and C_SuperTrack.IsSuperTrackingUserWaypoint()) then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
end

local function write_way(way)
    if navigation_way == way then return end
    navigation_way = way
    LibVGASettings.measures = LibVGASettings.measures or {}
    LibVGASettings.measures.navigation = way
end

local function read_aim_key(aim)
    return tostring(aim.id) .. ":" .. aim.point[1] .. ":" .. aim.point[2]
end

local function update_way_chosen(aim)
    local key = read_aim_key(aim)
    if chosen.key == key then return end
    chosen.key, chosen.since = key, GetTime()
    if aim.marker then update_marker_tracked() else update_tracked(aim) end
end

local function update_way_forgotten()
    chosen.key = nil
end

local function update_left_marker_cleared()
    update_waypoint_cleared()
    update_way_forgotten()
end

function vga.read_screen_heading(aim)
    update_way_chosen(aim)
    if GetTime() - chosen.since < SETTLE or not check_screen_place() then
        write_way(GetTime() - chosen.since < SETTLE and "settling" or "none")
        return nil
    end
    write_way(aim.marker and "marker" or "quest")
    local marker = C_Navigation.GetFrame()
    local marker_x, marker_y = marker:GetCenter()
    local middle_x, middle_y = WorldFrame:GetCenter()
    if not (marker_x and middle_x) then return nil end
    return atan2(middle_x - marker_x, marker_y - middle_y)
end

local function update_navigation()
    local aim = vga.quest_aim
    if not (aim and aim.point) then update_way_forgotten() end
    local heading = aim and aim.point and (vga.read_screen_heading(aim) or vga.read_heading(aim.point))
    navigation:SetShown(heading ~= nil and update_place())
    if not heading then return end
    update_chevrons(heading)
    navigation.distance:SetText(vga.render_distance(aim.distance))
end

local function update_navigation_safely(_, elapsed)
    navigation.since = (navigation.since or 0) + elapsed
    if navigation.since < 0.05 then return end
    navigation.since = 0
    library.update_safely("navigation", update_navigation)
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_ENTERING_WORLD" then return library.update_safely("navigation waypoint", update_left_marker_cleared) end
    library.update_safely("navigation login", create_navigation)
    events:SetScript("OnUpdate", update_navigation_safely)
end)
