-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.ui's flight master list, as the accepted draft draws it (manual/view/vga-npc-windows.html, K0830, K0831): the game's own flight map stays as the game shows it, and beside it LibVGA's list dialog (library.create_list_dialog, K0871) lists every destination the player can fly to now, its name and its cost in our coins, the place where the player stands named first and quiet; hovering a destination draws its route on the game's map, white, from flight point to flight point at each one's exact place - the game's place, its centre rounded to a whole pixel, never an approximate one -, the chosen one gold; a click takes the flight (K0835). Drawn as the draft draws it (K0836): the title names the flight master, the heads Ziel, Dauer, Preis stand over the list in its group, each destination in its cell with its zone beneath, the duration in the figure face - »–« until flight times are measured -; a click chooses the destination into the foot, »Fliegen« takes it, »Schließen« closes, and the player's gold stands in the status line. The window is at least 300 draft pixels wide and grows with its longest destination or zone, so every name can be read whole (K0968); its destination column at least as wide as »Steinkrallengipfel« needs, at the owner's word; its price column is only as wide as its dearest flight, so duration and price stand close at the right and the destination takes the room (K0969).

-- {K0969} {K0968} {K0909} {K0871} {K0839} {K0838} {K0836} {K0835} {K0830} {K0831}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local WIDTH, HEIGHT = 300, 470
local ICON = 26
local FIT_SAMPLE = "Steinkrallengipfel"
local NO_TIME = "–"
local GAP = 8
local window

local function read_map()
    return TaxiRouteMap or TaxiMap or TaxiFrame
end

local function read_destinations()
    local destinations = {}
    for index = 1, (NumTaxiNodes and NumTaxiNodes() or 0) do
        if TaxiNodeGetType(index) == "REACHABLE" then
            local name, zone = TaxiNodeName(index):match("^([^,]+),%s*(.+)$")
            destinations[#destinations + 1] = { index = index, name = name or TaxiNodeName(index), zone = zone, cost = TaxiNodeCost and TaxiNodeCost(index) or 0 }
        end
    end
    return destinations
end

local function read_route_places(index)
    local places = {}
    for hop = 1, (GetNumRoutes and GetNumRoutes(index) or 0) do
        if hop == 1 then places[1] = { TaxiNodePosition(TaxiGetNodeSlot(index, hop, true)) } end
        places[#places + 1] = { TaxiNodePosition(TaxiGetNodeSlot(index, hop, false)) }
    end
    return places
end

local function render_route(row)
    if not (row and row.item) then return end
    library.update_route_line(window.route, read_map(), read_route_places(row.item.index), false)
end

local function render_route_gone()
    library.update_route_line(window.route, read_map(), {}, false)
end

local function render_chosen(row)
    if not row.item then return end
    window.chosen = row.item
    library.update_route_line(window.route, read_map(), read_route_places(row.item.index), true)
    vga.update_taxi()
end

local function render_taken()
    if window.chosen and TakeTaxiNode then TakeTaxiNode(window.chosen.index) end
end

local function render_route_kept()
    if window.chosen then library.update_route_line(window.route, read_map(), read_route_places(window.chosen.index), true) else render_route_gone() end
end

local function create_row(parent)
    local row = library.create_item_row(parent, { chosen = true, cell = true, on_click = render_chosen, on_enter = render_route, on_leave = render_route_kept })
    row.duration = library.create_text(row, "figures_small", colours.ink)
    row.money = library.create_money(row, colours.ink)
    row.money.kind = "small"
    return row
end

local function update_row(row, item)
    local sheet = window.listing.table
    row.item = item
    library.update_item_row(row, { icon = library.media .. "GossipFlight", name = item.name, sub = item.zone, quality = 1 }, sheet.pad, sheet.pad + sheet.columns.rights[1])
    library.update_item_row_chosen(row, window.chosen and window.chosen.index == item.index)
    row.duration:SetText(NO_TIME)
    library.update_money(row.money, item.cost)
    library.update_grid_columns(row, sheet.columns, sheet.pad, { { row.duration, 2, "right" }, { row.money, 3, "right" } })
end

local function read_price_room(sheet)
    local dearest = 0
    for _, item in ipairs(window.items or {}) do dearest = math.max(dearest, item.cost or 0) end
    return library.read_widest_money(sheet.probe_small, dearest)
end

local function read_wanted_width()
    local sheet = window.listing.table
    local room = (sheet.columns and sheet.columns.rights[1] or 0) - library.read_draft_size(ICON) - library.read_size(-4)
    local widest = library.read_sample_width(library.read_font("bold"), FIT_SAMPLE)
    for _, item in ipairs(window.items or {}) do
        widest = math.max(widest, library.read_sample_width(library.read_font("bold"), item.name or ""), library.read_sample_width(library.read_font("small"), item.zone or ""))
    end
    local short = math.ceil(widest - room)
    if short <= 0 then return window.plan.width end
    return window.plan.width + math.ceil(short / (library.read_draft_size(100) / 100))
end

local function update_window()
    window.items = read_destinations()
    window.plan.width = WIDTH
    library.update_list_dialog(window, window.items, window.chosen and window.chosen.name or "")
    local wanted = read_wanted_width()
    if wanted == window.plan.width then return end
    window.plan.width = wanted
    library.update_list_dialog(window, window.items, window.chosen and window.chosen.name or "")
end

vga.update_taxi = update_window

local function render_closing()
    window:Hide()
end

local function render_closed()
    render_route_gone()
    if CloseTaxiMap then CloseTaxiMap() end
end

local function read_name_sort(item)
    return (item.name or ""):lower()
end

local function read_duration_sort(item)
    return item.duration
end

local function read_cost_sort(item)
    return item.cost or 0
end

local function create_window()
    local texts = library.texts
    local columns = { { key = "head_destination_taxi", word = texts.head_destination, sort = read_name_sort }, { key = "head_duration_taxi", word = texts.head_duration, least = 44, x = "right", sort = read_duration_sort }, { key = "price_taxi", word = texts.price, least = read_price_room, x = "right", sort = read_cost_sort } }
    local buttons = { { texts.close, "plain", render_closing }, { texts.fly, "gold", render_taken } }
    window = library.create_list_dialog("VGATaxiWindow", { title = texts.flight_master, buttons = buttons, width = WIDTH, height = HEIGHT, table = { columns = columns, create_row = create_row, update_row = update_row } })
    window.route = library.create_route_line(read_map())
    library.update_dialog_closing(window, function() library.update_safely("taxi closed", render_closed) end)
end

local function update_opened()
    if not window then create_window() end
    window.chosen = nil
    window.title:SetText(library.read_figure_title(library.texts.flight_master))
    library.update_dialog_beside(window, TaxiFrame, library.read_draft_size(GAP))
    window:Show()
    update_window()
end

local function update_closed()
    if window and window:IsShown() then window:Hide() end
end

local HEARD = { TAXIMAP_OPENED = update_opened, TAXIMAP_CLOSED = update_closed }

local events = CreateFrame("Frame")
library.update_events(events, { "TAXIMAP_OPENED", "TAXIMAP_CLOSED" })
events:SetScript("OnEvent", function(_, event) library.update_safely("taxi " .. event, HEARD[event]) end)
