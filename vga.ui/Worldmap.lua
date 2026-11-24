-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.ui's world map, a window of its own as the accepted draft draws it (manual/view/vga-map.html, K0804-K0811): LibVGA's dialog »Weltkarte«, fixed by the chosen size - 900 by 680 draft pixels at Mittel -, with its pin and close, a head button that centres on the player, and its status line with the pointer's coordinates in the zone in the figure face and the zone's name; over LibVGA's map canvas the controls float - zoom in and out, centre and the layers at the upper right, at the lower left a switch between the continents, LibVGA's pop-up, and the zone in view beside it -; one view per continent, Kalimdor or the Eastern Kingdoms, never the world as one map, the map cut cleanly at the view's edge, every zone's map fully revealed - its base art and every one of its overlay pieces, explored or not, from vga.ui's table of the game's WorldMapOverlay (Data/Overlays.lua, K0826) - and a city within a zone, Undercity, laid over it as its detail view at close zoom, fading in and kept above the minimap tiles (K0822); every level - continent, zone maps, cities, minimap tiles - fades in by its transparency over wide, overlapping bands of the zoom, the lower ones staying underneath (K0825), the view's rim LibVGA's notches rounding its corners in the dialog's ground with a fine ring and a faint inner shade (K0821); the layers panel holds three groups, Welt, Reisen, Ich und Gruppe, each layer kept in the settings and greyed while it has nothing to show yet. The world is the game's own: each view the plane of its continent's own map, at its art's proportions, its zones placed by the game's rectangles on the continent; far out the continent's own map art, closer in the game's minimap tiles, loaded from the game by their file IDs through vga.ui's table (Data/Minimap.lua) and only those in view (K0807, K0808). Its layers - the player, party, quests, flight masters, own pins and the waypoint, townsfolk - are the owner's signs as LibVGA's map marks (Maplayers.lua, K0815), laid anew five times a second while it shows; the hatching outside the zone (K0812) is off for now (K0821); a Ctrl-click sets an own pin. The game's map key M and its map button open this map instead of the game's, whose map the setting »Karte des Spiels« brings back (K0810).

-- {K0826} {K0825} {K0824} {K0823} {K0822} {K0821} {K0819} {K0816} {K0815} {K0811} {K0804} {K0805} {K0806} {K0807} {K0808} {K0809} {K0810}

local _, vga = ...
local library = LibVGA
vga.world_map_parked = true
local colours = library.colours
local WIDTH, HEIGHT = 900, 680
local WORLD = 947
local TILE = 1600 / 3
local CHUNKS = 16
local FADES = { zone = { 0.2, 1.6 }, city = { 1.2, 2.5 }, tiles = { 1.4, 2.9 } }
local PIECE = 256
local SMALLEST_FILE = 16
local MOST_ZOOM = 96
local TILES_AT_ONCE = 160
local CONTROL = 26
local INSTANCES = { [0] = 1415, [1] = 1414 }
local INSTANCES_BY_MAP = { [1415] = 0, [1414] = 1 }
local PATH_INSET = 10
local LAYERS = {
    { heading = "map_group_world", keys = { "unexplored", "levels", "roads" } },
    { heading = "map_group_travel", keys = { "flight", "routes", "boats" } },
    { heading = "map_group_me", keys = { "party", "quests", "pins", "townsfolk", "dungeons" } },
}
local READY = { flight = true, party = true, quests = true, pins = true, townsfolk = true }
local TICK = 0.2
local window, world
local tile_rects = {}

local function read_rect(id)
    local left, right, top, bottom = C_Map.GetMapRectOnMap(id, WORLD)
    if left then return { left, right, top, bottom } end
end

local function check_inside(inner, outer)
    return inner[1] >= outer[1] and inner[2] <= outer[2] and inner[3] >= outer[3] and inner[4] <= outer[4]
end

local function check_city(zone)
    for _, other in ipairs(world.zones) do
        if other ~= zone and other.parent == zone.parent and check_inside(zone.rect, other.rect) then return true end
    end
    return false
end

local function read_world()
    if world then return world end
    world = { continents = {}, zones = {}, by_id = { [WORLD] = { id = WORLD, rect = { 0, 1, 0, 1 } } } }
    for _, map in ipairs(C_Map.GetMapChildrenInfo(WORLD, nil, true) or {}) do
        local rect = read_rect(map.mapID)
        local entry = rect and { id = map.mapID, name = map.name, kind = map.mapType, rect = rect, parent = map.parentMapID }
        if entry and map.mapType == 2 then world.continents[#world.continents + 1] = entry end
        if entry and map.mapType == 3 then world.zones[#world.zones + 1] = entry end
        if entry then world.by_id[map.mapID] = entry end
    end
    for _, zone in ipairs(world.zones) do zone.city = check_city(zone) end
    return world
end

local function read_plane_rect(map)
    local plane = window and window.continent
    if not plane or map.id == plane.id then return { 0, 1, 0, 1 } end
    map.plane_rects = map.plane_rects or {}
    if map.plane_rects[plane.id] == nil then
        local left, right, top, bottom = C_Map.GetMapRectOnMap(map.id, plane.id)
        map.plane_rects[plane.id] = left and { left, right, top, bottom } or false
    end
    return map.plane_rects[plane.id] or nil
end

local function check_meets(rect, left, top, right, bottom)
    return rect[1] < right and rect[2] > left and rect[3] < bottom and rect[4] > top
end

local function read_art_layer(id)
    local layers = C_Map.GetMapArtLayers and C_Map.GetMapArtLayers(id)
    return layers and layers[1]
end

local function read_smooth(fade, depth)
    local share = math.max(0, math.min(1, (depth - fade[1]) / (fade[2] - fade[1])))
    return share * share * (3 - 2 * share)
end

local function read_alphas(depth)
    return { continent = 1, zone = read_smooth(FADES.zone, depth), city = read_smooth(FADES.city, depth), tiles = read_smooth(FADES.tiles, depth) }
end

local function read_crop(whole, step, index)
    return math.min(1, (whole - index * step) / step)
end

local function write_art(map, pictures, look)
    local layer = read_art_layer(map.id)
    if not layer or look.alpha <= 0 then return end
    local columns = math.ceil(layer.layerWidth / layer.tileWidth)
    local rect = read_plane_rect(map)
    if not rect then return end
    local across = (rect[2] - rect[1]) * layer.tileWidth / layer.layerWidth
    local down = (rect[4] - rect[3]) * layer.tileHeight / layer.layerHeight
    for index, file in ipairs(C_Map.GetMapArtLayerTextures(map.id, 1) or {}) do
        local column, row = (index - 1) % columns, math.floor((index - 1) / columns)
        local s1, t1 = read_crop(layer.layerWidth, layer.tileWidth, column), read_crop(layer.layerHeight, layer.tileHeight, row)
        local left, top = rect[1] + column * across, rect[3] + row * down
        pictures[#pictures + 1] = { file = file, u0 = left, v0 = top, u1 = left + across * s1, v1 = top + down * t1, s1 = s1, t1 = t1, level = look.level, alpha = look.alpha, kind = look.kind, mask = look.mask, map = map.id }
    end
end

local function read_file_size(pixels)
    local size = SMALLEST_FILE
    while size < pixels do size = size * 2 end
    return size
end

local function write_piece(piece, place, pictures, look)
    local layer, rect = place.layer, place.rect
    local across, down = (rect[2] - rect[1]) / layer.layerWidth, (rect[4] - rect[3]) / layer.layerHeight
    local wide, tall = piece[5], math.ceil(piece[4] / PIECE)
    local width = place.column == wide and piece[3] - (wide - 1) * PIECE or PIECE
    local height = place.row == tall and piece[4] - (tall - 1) * PIECE or PIECE
    local file = piece[5 + (place.row - 1) * wide + place.column]
    if not file or file == 0 then return end
    local left = rect[1] + (piece[1] + PIECE * (place.column - 1)) * across
    local top = rect[3] + (piece[2] + PIECE * (place.row - 1)) * down
    pictures[#pictures + 1] = { file = file, u0 = left, v0 = top, u1 = left + width * across, v1 = top + height * down, s1 = width / read_file_size(width), t1 = height / read_file_size(height), level = look.level, alpha = look.alpha, kind = look.kind, mask = look.mask, map = look.map }
end

local function read_overlays(id)
    local art = C_Map.GetMapArtID and C_Map.GetMapArtID(id)
    return art and vga.map_overlays and vga.map_overlays[art] or {}
end

local function write_overlays(zone, pictures, look)
    local layer, rect = read_art_layer(zone.id), read_plane_rect(zone)
    if not (layer and rect and look.alpha > 0) then return end
    for _, piece in ipairs(read_overlays(zone.id)) do
        for row = 1, math.ceil(piece[4] / PIECE) do
            for column = 1, piece[5] do write_piece(piece, { layer = layer, rect = rect, row = row, column = column }, pictures, look) end
        end
    end
end

local function write_revealed_whole(zone, pictures, look)
    write_art(zone, pictures, look)
    write_overlays(zone, pictures, look)
end

local function read_world_point(instance, north, west)
    local continent = read_world().by_id[INSTANCES[instance]]
    if not continent then return end
    local _, spot = C_Map.GetMapPosFromWorldPos(instance, CreateVector2D(north, west), continent.id)
    if not spot then return end
    return spot.x, spot.y
end

local function read_tile_rect(instance, key)
    tile_rects[instance] = tile_rects[instance] or {}
    local kept = tile_rects[instance][key]
    if kept ~= nil then return kept end
    local x, y = math.floor(key / 64), key % 64
    local u0, v0 = read_world_point(instance, (32 - y) * TILE, (32 - x) * TILE)
    local u1, v1 = read_world_point(instance, (31 - y) * TILE, (31 - x) * TILE)
    tile_rects[instance][key] = u0 and u1 and { math.min(u0, u1), math.max(u0, u1), math.min(v0, v1), math.max(v0, v1) } or false
    return tile_rects[instance][key]
end

local function write_tiles(instance, pictures, view, alpha)
    for key, file in pairs(vga.minimap_tiles[instance] or {}) do
        local rect = read_tile_rect(instance, key)
        if rect and check_meets(rect, view[1], view[2], view[3], view[4]) and #pictures < TILES_AT_ONCE then
            pictures[#pictures + 1] = { file = file, u0 = rect[1], v0 = rect[3], u1 = rect[2], v1 = rect[4], level = 3, alpha = alpha, kind = "tile" }
        end
    end
end

local function read_mask_rect(instance, mask)
    local u0, v0 = read_world_point(instance, (32 - mask[3] / CHUNKS) * TILE, (32 - mask[2] / CHUNKS) * TILE)
    local u1, v1 = read_world_point(instance, (32 - mask[5] / CHUNKS) * TILE, (32 - mask[4] / CHUNKS) * TILE)
    if not (u0 and u1) then return nil end
    return { file = mask[1], u0 = math.min(u0, u1), v0 = math.min(v0, v1), u1 = math.max(u0, u1), v1 = math.max(v0, v1) }
end

local function write_zone_masks()
    local named = {}
    for _, zone in ipairs(read_world().zones) do named[zone.name] = zone end
    for instance, masks in pairs(vga.zone_masks or {}) do
        for area, mask in pairs(masks) do
            local zone = named[C_Map.GetAreaInfo and C_Map.GetAreaInfo(area) or ""]
            if zone then zone.mask = read_mask_rect(instance, mask) end
        end
    end
    world.masked = true
end

local function write_city(zone, pictures, alpha)
    write_revealed_whole(zone, pictures, { level = 4, alpha = alpha, kind = "city", map = zone.id })
end

local function write_zones(pictures, view, alphas)
    if not world.masked then write_zone_masks() end
    for _, zone in ipairs(world.zones) do
        local rect = zone.parent == window.continent.id and read_plane_rect(zone)
        if rect and check_meets(rect, view[1], view[2], view[3], view[4]) then
            if zone.city then write_city(zone, pictures, alphas.city) else write_revealed_whole(zone, pictures, { level = 2, alpha = alphas.zone, kind = "zone", mask = zone.mask, map = zone.id }) end
        end
    end
end

local function read_pictures(canvas)
    local pictures, view = {}, { library.read_map_view(canvas) }
    local alphas = read_alphas(library.read_map_depth(canvas))
    write_art(window.continent, pictures, { level = 1, alpha = alphas.continent, kind = "continent" })
    write_zones(pictures, view, alphas)
    if alphas.tiles <= 0 then return pictures end
    for instance, continent in pairs(INSTANCES) do
        if continent == window.continent.id then write_tiles(instance, pictures, view, alphas.tiles) end
    end
    return pictures
end

local function read_place_at(across, down)
    local found, smallest
    for _, map in ipairs(read_world().zones) do
        local rect = map.parent == (window and window.continent and window.continent.id) and read_plane_rect(map)
        local size = rect and (rect[2] - rect[1]) * (rect[4] - rect[3])
        if rect and across >= rect[1] and across <= rect[2] and down >= rect[3] and down <= rect[4] and (not smallest or size < smallest) then found, smallest = map, size end
    end
    return found
end

local function read_figure(value)
    return (string.format("%.1f", value):gsub("%.", library.texts.decimal_mark))
end

local function render_pointer(_, across, down)
    local zone = read_place_at(across, down)
    local rect = zone and read_plane_rect(zone)
    if not rect then return library.update_dialog_foot(window, "") end
    local x, y = (across - rect[1]) / (rect[2] - rect[1]) * 100, (down - rect[3]) / (rect[4] - rect[3]) * 100
    library.update_dialog_foot(window, read_figure(x) .. " · " .. read_figure(y) .. "   " .. zone.name)
end

local function read_path(canvas)
    local words, maps = {}, {}
    local zone = read_place_at(canvas.u, canvas.v)
    if zone and library.read_map_depth(canvas) >= FADES.zone[1] then words[1], maps[1] = zone.name, zone end
    return words, maps
end

function vga.read_map_world_point(map, across, down)
    local entry = map and across and (read_world().by_id[map] or { id = map })
    local rect = entry and read_plane_rect(entry)
    if not rect then return end
    return rect[1] + across * (rect[2] - rect[1]), rect[3] + down * (rect[4] - rect[3])
end

local function read_player_point()
    local map = C_Map.GetBestMapForUnit("player")
    local spot = map and C_Map.GetPlayerMapPosition(map, "player")
    if not spot then return end
    return vga.read_map_world_point(map, spot.x, spot.y)
end

local function read_tier(canvas)
    return library.read_map_depth(canvas) >= FADES.zone[2] and "zone" or "continent"
end

local function update_path(canvas)
    local words, maps = read_path(canvas)
    window.path_maps = maps
    local size, gap = library.read_draft_size(CONTROL), library.read_draft_size(6)
    library.update_popup(window.switch)
    local switch_width = library.read_popup_width(window.switch)
    local _, height = library.update_grid(window.path.grid, { { window.switch } }, switch_width + 2 * library.read_draft_size(PATH_INSET))
    window.crumbs.inset = library.read_draft_size(PATH_INSET) + switch_width + gap
    library.update_crumbs(window.crumbs, words, (size - library.read_size(1) - library.read_size(-4)) / 2)
    window.path:SetSize(math.max(size, #words > 0 and window.crumbs.width or switch_width + 2 * library.read_draft_size(PATH_INSET)), math.max(size, height))
end

local function update_layers(canvas)
    local tier = read_tier(canvas)
    local zone = read_place_at(canvas.u, canvas.v)
    library.update_map_fog(window.fog, nil)
    vga.update_map_layers(canvas, tier, tier == "zone" and zone or nil)
end

local function render_view(canvas)
    library.update_map_pictures(canvas, read_pictures(canvas))
    update_layers(canvas)
    update_path(canvas)
end

function vga.render_map_layers()
    if window and window:IsShown() then update_layers(window.canvas) end
end

local function render_canvas_click(canvas, button, across, down)
    if button ~= "LeftButton" or not IsControlKeyDown() then return end
    local zone = read_place_at(across, down)
    vga.write_map_pin(across, down, zone and zone.name or "")
end

local function update_tick(_, elapsed)
    window.tick = (window.tick or 0) + elapsed
    if window.tick < TICK then return end
    window.tick = 0
    update_layers(window.canvas)
end

local function render_continent(continent)
    window.continent = continent
    window.switch.value = continent.id
    local layer = read_art_layer(continent.id)
    library.update_map_aspect(window.canvas, layer and layer.layerWidth / layer.layerHeight or 1)
    library.update_map_bounds(window.canvas, { 0, 1, 0, 1 })
end

local function render_fit(map)
    if map.kind == 2 then render_continent(map) end
    local canvas, rect = window.canvas, read_plane_rect(map)
    if not rect then return end
    local zoom = math.min(canvas:GetWidth() / ((rect[2] - rect[1]) * canvas.aspect), canvas:GetHeight() / (rect[4] - rect[3])) * 0.95
    library.update_map_view(canvas, (rect[1] + rect[2]) / 2, (rect[3] + rect[4]) / 2, zoom)
end

local function render_path_chosen(crumb)
    local map = window.path_maps and window.path_maps[crumb.index]
    if map then render_fit(map) end
end

local function render_centre()
    local across, down = read_player_point()
    local zone = across and read_place_at(across, down)
    if zone then render_fit(zone) end
    if across then library.update_map_view(window.canvas, across, down) end
end

local function render_zoom_in()
    library.update_map_view(window.canvas, nil, nil, window.canvas.zoom * 1.5)
end

local function render_zoom_out()
    library.update_map_view(window.canvas, nil, nil, window.canvas.zoom / 1.5)
end

local function render_layers_shown()
    window.layers:SetShown(not window.layers:IsShown())
end

local function write_layer(key, on)
    LibVGASettings.map_layers = LibVGASettings.map_layers or {}
    LibVGASettings.map_layers[key] = on and nil or false
    vga.render_map_layers()
end

local function read_layer_groups()
    local texts, kept, groups = library.texts, LibVGASettings.map_layers or {}, {}
    for _, group in ipairs(LAYERS) do
        local rows = {}
        for _, key in ipairs(group.keys) do rows[#rows + 1] = { key = key, word = texts["layer_" .. key], on = kept[key] ~= false, enabled = READY[key] or false } end
        groups[#groups + 1] = { heading = texts[group.heading], rows = rows }
    end
    return groups
end

local function create_controls()
    local controls = CreateFrame("Frame", nil, window.canvas)
    controls:SetFrameLevel(window.canvas:GetFrameLevel() + 4)
    controls.buttons = {}
    for _, made in ipairs({ { "Plus", render_zoom_in }, { "Minus", render_zoom_out }, { "Centre", render_centre }, { "Layers", render_layers_shown } }) do
        controls.buttons[#controls.buttons + 1] = { library.create_icon_button(controls, made[1], made[2], { kind = "head" }) }
    end
    controls.grid = library.create_grid(controls, { columns = { CONTROL }, row = CONTROL, row_gap = 6 })
    return controls
end

local function read_continent_sections()
    local items = {}
    for _, continent in ipairs(read_world().continents) do
        if vga.minimap_tiles and INSTANCES_BY_MAP[continent.id] then items[#items + 1] = { continent.id, continent.name } end
    end
    return { { items = items } }
end

local function render_continent_chosen(id)
    local continent = read_world().by_id[id]
    if continent then render_fit(continent) end
end

local function create_path()
    local area = CreateFrame("Frame", nil, window.canvas)
    area:SetFrameLevel(window.canvas:GetFrameLevel() + 4)
    area.ground = library.create_surface(area, "BACKGROUND", 0)
    window.switch = library.create_popup(area, read_continent_sections(), nil, render_continent_chosen)
    area.grid = library.create_grid(area, { columns = { "auto" }, padding = { 0, PATH_INSET, 0, PATH_INSET }, row = CONTROL })
    window.crumbs = library.create_crumbs(area, area, 3, render_path_chosen)
    return area
end

local function create_rim()
    local rim = CreateFrame("Frame", nil, window.canvas)
    rim:SetAllPoints()
    rim:SetFrameLevel(window.canvas:GetFrameLevel() + 3)
    rim.corners = library.create_notches(rim, "OVERLAY", 0)
    rim.line = library.create_ring(rim, "OVERLAY", 1)
    rim.shade = library.create_ring(rim, "ARTWORK", 0)
    return rim
end

local function update_rim()
    local rim, round = window.rim, library.read_size(-4)
    library.update_notches(rim.corners, rim, round, colours.ground)
    library.update_ring(rim.line, 1, colours.metal_bottom, 1)
    library.update_ring(rim.shade, library.read_draft_size(4), { 0, 0, 0 }, 0.25)
end

local function create_window()
    local texts = library.texts
    window = library.create_dialog("VGAWorldMap", texts.world_map, {})
    window.centre = library.create_dialog_button(window, "Centre", render_centre)
    window.canvas = library.create_map_canvas(window.body, { on_view = render_view, on_pointer = render_pointer, on_click = render_canvas_click })
    window.canvas:SetAllPoints(window.body)
    window.fog = library.create_map_fog(window.canvas)
    window.rim = create_rim()
    window:SetScript("OnUpdate", function(self, elapsed) library.update_safely("world map tick", update_tick, self, elapsed) end)
    window.controls = create_controls()
    window.path = create_path()
    window.layers = library.create_switch_list(window.canvas, read_layer_groups(), write_layer)
    window.layers:SetFrameLevel(window.canvas:GetFrameLevel() + 6)
    window.layers:Hide()
    window:Hide()
end

local function update_floating()
    local pad, size = library.read_draft_size(12), library.read_draft_size(CONTROL)
    for _, cell in ipairs(window.controls.buttons) do library.update_icon_button(cell[1], size) end
    local width, height = library.update_grid(window.controls.grid, window.controls.buttons)
    window.controls:SetSize(width, height)
    window.controls:ClearAllPoints()
    window.controls:SetPoint("TOPRIGHT", window.canvas, "TOPRIGHT", -pad, -pad)
    library.update_switch_list(window.layers)
    window.layers:ClearAllPoints()
    window.layers:SetPoint("TOPRIGHT", window.controls, "TOPLEFT", -pad, 0)
    update_rim()
    library.update_surface(window.path.ground, 0, library.read_size(-4), colours.metal_bottom, colours.metal_bottom, 0.9)
    window.path:ClearAllPoints()
    window.path:SetPoint("BOTTOMLEFT", window.canvas, "BOTTOMLEFT", pad, pad)
end

local function update_window()
    library.update_dialog(window)
    window:SetSize(library.read_draft_size(WIDTH), library.read_draft_size(HEIGHT))
    library.update_dialog(window)
    update_floating()
    window.canvas.most = math.min(window.canvas:GetWidth(), window.canvas:GetHeight()) * MOST_ZOOM
end

local function read_player_continent()
    local map = C_Map.GetBestMapForUnit("player")
    local entry = map and C_Map.GetMapInfo(map)
    while entry and entry.mapType and entry.mapType > 2 do entry = C_Map.GetMapInfo(entry.parentMapID) end
    return entry and read_world().by_id[entry.mapID]
end

local function render_opened()
    update_window()
    local continent = read_player_continent() or read_world().by_id[INSTANCES[0]] or read_world().continents[1]
    if continent then render_fit(continent) end
end

function vga.render_world_map()
    if not window then create_window() end
    if window:IsShown() then return window:Hide() end
    library.update_dialog_placed(window)
    window:Show()
    library.update_safely("world map opened", render_opened)
end

local function render_game_toggle()
    if LibVGASettings.game_map then return end
    if WorldMapFrame and WorldMapFrame:IsShown() then WorldMapFrame:Hide() end
    vga.render_world_map()
end

local function create_on_login()
    if vga.world_map_parked then return end
    if ToggleWorldMap then hooksecurefunc("ToggleWorldMap", function() library.update_safely("world map key", render_game_toggle) end) end
end

local HEARD = { PLAYER_LOGIN = create_on_login }

local events = CreateFrame("Frame")
library.update_events(events, { "PLAYER_LOGIN" })
events:SetScript("OnEvent", function(_, event) library.update_safely("world map " .. event, HEARD[event]) end)
