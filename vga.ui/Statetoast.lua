-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: the state toasts (K1031), by the house rule of the toast (K1018): a change of the player's state that is easily missed is told by LibVGA's toast, its rim saying its kind as manual/view/vga-toast-colours.html draws it (K1034): the searches and the rest area blue, PvP copper, damaged gear wine red. A search switched on or off - only the searches, the game's tracking of type »spell«, never the town's figures the map filters switch (C_Minimap.GetTrackingInfo, MINIMAP_UPDATE_TRACKING) -, »Mineraliensuche an« or »… aus« with the search's picture; the player's PvP flag (UnitIsPVP, PLAYER_FLAGS_CHANGED, UNIT_FACTION), »PvP an« or »PvP aus«, with the faction's banner; a rest area (IsResting, PLAYER_UPDATE_RESTING), »Erholungsgebiet betreten« or »… verlassen«; a piece of gear the game marks damaged or broken - its own judgement, as its durability figure reads it (GetInventoryAlertStatus, UPDATE_INVENTORY_ALERTS, the eleven places of Forever's DurabilityFrame) -, »Brust beschädigt« or »… kaputt«, with the item's picture and the place's name as the game writes it; mended, nothing. The first reading of each only takes note, so logging in tells nothing. New mail come (HasNewMail, UPDATE_PENDING_MAIL), »Neue Post«, and the bags become full, no slot free in the five bags (BAG_UPDATE_DELAYED), »Taschen voll«, each told once until it ends (K1040). Each is a kind of LibVGA's toast - »map«, »pvp«, »rest«, »gear«, »mail«, »bags« -, switched on or off on the settings' tab »Hinweise« (K1035), on unless the player turns it off; the comfort page's one switch is gone.

-- {K1040} {K1035} {K1034} {K1031} {K1018}

local library = LibVGA
local SEARCH = "spell"
local REST_PICTURE = "Interface\\Icons\\Spell_Nature_Sleep"
local BANNERS = { Horde = "Interface\\Icons\\INV_BannerPVP_01", Alliance = "Interface\\Icons\\INV_BannerPVP_02" }
local PLACES = { { 1, "HEADSLOT" }, { 3, "SHOULDERSLOT" }, { 5, "CHESTSLOT" }, { 6, "WAISTSLOT" }, { 7, "LEGSSLOT" }, { 8, "FEETSLOT" }, { 9, "WRISTSLOT" }, { 10, "HANDSSLOT" }, { 16, "MAINHANDSLOT" }, { 17, "SECONDARYHANDSLOT" }, { 18, "RANGEDSLOT" } }
local GEAR = { "gear_damaged", "gear_broken" }
local MAIL_PICTURE = "Interface\\Icons\\INV_Letter_15"
local BAGS_PICTURE = "Interface\\Icons\\INV_Misc_Bag_08"
local BAGS = 4
local last = {}

local function render(head, line, picture, kind)
    library.render_toast({ head = head, line = line, picture = picture, kind = kind })
end

local function check_changed(key, now)
    local before = last[key]
    last[key] = now
    return before ~= nil and before ~= now
end

local function update_searches()
    if not (C_Minimap and C_Minimap.GetNumTrackingTypes and C_Minimap.GetTrackingInfo) then return end
    local texts = library.texts
    for index = 1, C_Minimap.GetNumTrackingTypes() do
        local tracking = C_Minimap.GetTrackingInfo(index)
        if tracking and tracking.type == SEARCH and check_changed("search:" .. tostring(tracking.name), tracking.active == true) then
            render(texts.toast_search, string.format(tracking.active and texts.toast_on or texts.toast_off, tracking.name), tracking.texture, "map")
        end
    end
end

local function update_pvp(unit)
    if unit and unit ~= "player" then return end
    local flagged = UnitIsPVP and UnitIsPVP("player")
    if issecretvalue and issecretvalue(flagged) then return end
    flagged = flagged == true
    if not check_changed("pvp", flagged) then return end
    local texts = library.texts
    render(texts.toast_pvp, flagged and texts.pvp_on or texts.pvp_off, BANNERS[UnitFactionGroup and UnitFactionGroup("player") or ""], "pvp")
end

local function update_rest()
    local resting = IsResting and IsResting() == true
    if not check_changed("rest", resting) then return end
    local texts = library.texts
    render(texts.toast_rest, resting and texts.rest_in or texts.rest_out, REST_PICTURE, "rest")
end

local function update_gear_place(index, place)
    local status = GetInventoryAlertStatus(index) or 0
    local before = last["gear:" .. index]
    last["gear:" .. index] = status
    if before == nil or status <= before or not GEAR[status] then return end
    local texts = library.texts
    local picture = GetInventoryItemTexture and GetInventoryItemTexture("player", place[1])
    render(texts.toast_gear, string.format(texts[GEAR[status]], _G[place[2]] or place[2]), picture, "gear")
end

local function update_gear()
    if not GetInventoryAlertStatus then return end
    for index, place in ipairs(PLACES) do update_gear_place(index, place) end
end

local function update_mail()
    local waiting = HasNewMail and HasNewMail() == true
    if check_changed("mail", waiting) and waiting then render(library.texts.toast_mail, library.texts.mail_new, MAIL_PICTURE, "mail") end
end

local function read_free()
    local free = 0
    for bag = 0, BAGS do free = free + (C_Container.GetContainerNumFreeSlots(bag) or 0) end
    return free
end

local function update_bags()
    local full = read_free() == 0
    if check_changed("bags", full) and full then render(library.texts.toast_bags, library.texts.bags_full, BAGS_PICTURE, "bags") end
end

local function update_all()
    update_searches()
    update_pvp()
    update_rest()
    update_gear()
    update_mail()
    update_bags()
end

local HEARD = { PLAYER_ENTERING_WORLD = update_all, MINIMAP_UPDATE_TRACKING = update_searches, PLAYER_FLAGS_CHANGED = update_pvp, UNIT_FACTION = update_pvp, PLAYER_UPDATE_RESTING = update_rest, UPDATE_INVENTORY_ALERTS = update_gear, UPDATE_PENDING_MAIL = update_mail, BAG_UPDATE_DELAYED = update_bags }

local events = CreateFrame("Frame")
library.update_events(events, { "PLAYER_ENTERING_WORLD", "MINIMAP_UPDATE_TRACKING", "PLAYER_FLAGS_CHANGED", "UNIT_FACTION", "PLAYER_UPDATE_RESTING", "UPDATE_INVENTORY_ALERTS", "UPDATE_PENDING_MAIL", "BAG_UPDATE_DELAYED" })
events:SetScript("OnEvent", function(_, event, unit) library.update_safely("state toast " .. event, HEARD[event], unit) end)
