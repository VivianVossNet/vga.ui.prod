-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: the place toast (K1044), LibVGA's toast of the kind »place«, white rimmed with the book ornament above and beneath, bare and centred - no head word, no picture, its words in the middle and twice as large (plan.centred, K1046) -, as manual/view/vga-toast-colours.html draws it: entering an area, the area above, »Westhain«, the place within it beneath, »Brückenhof« (GetZoneText, GetSubZoneText; ZONE_CHANGED_NEW_AREA, ZONE_CHANGED, ZONE_CHANGED_INDOORS); a new place in the same area counts the same toast on in its place (key »place«), and a discovery turns it gold there (vga.ui/Discoverytoast.lua). The place is read a fifth of a second after the game's message, when the game knows it, never at the message itself. Only at login and at a reload of the interface is the first reading only noted; after any other loading screen - a hearthstone, a portal, an instance - the place is told (PLAYER_ENTERING_WORLD's isInitialLogin and isReloadingUi). A place just discovered (vga.discovered, kept five seconds) is not told again, so the gold discovery stays gold (K1050). While »Orte« is on, the game's own great place names in the screen's middle are faded - their texts, ZoneTextString and SubZoneTextString, the game's PvP line beneath them left shown (K1050), since the game sets its frames' own alpha as it fades them; never hidden (manual/16 R1.1) -, and shown again the moment »Orte« is switched off (library.write_notice, hooked).

-- {K1050} {K1046} {K1044} {K1037} {K1035}

local _, vga = ...
local library = LibVGA
local NAMES = { "ZoneTextString", "SubZoneTextString" }
local SETTLE = 0.2
local KEPT = 5
local last

local function update_game_names()
    local alpha = library.read_notice_on("place") and 0 or 1
    for _, name in ipairs(NAMES) do
        if _G[name] then _G[name]:SetAlpha(alpha) end
    end
end

local function read_place()
    local zone, place = GetZoneText and GetZoneText() or "", GetSubZoneText and GetSubZoneText() or ""
    if place == zone then place = "" end
    return zone, place
end

local function check_discovered(zone, place)
    local found = vga.discovered
    return found ~= nil and GetTime() - found.at < KEPT and (found.area == zone or found.area == place)
end

local function render_place()
    update_game_names()
    local zone, place = read_place()
    local now = zone .. "|" .. place
    if not last or now == last or zone == "" then
        last = now
        return
    end
    last = now
    if check_discovered(zone, place) then return end
    library.render_toast({ line = zone, second = place ~= "" and place or nil, kind = "place", key = "place", ornate = true, centred = true })
end

local function render_settled()
    C_Timer.After(SETTLE, function() library.update_safely("place toast", render_place) end)
end

local function update_entered(login, reload)
    update_game_names()
    if login or reload then
        last = table.concat({ read_place() }, "|")
        return
    end
    render_settled()
end

hooksecurefunc(library, "write_notice", function() library.update_safely("place names", update_game_names) end)

local HEARD = { PLAYER_ENTERING_WORLD = update_entered, ZONE_CHANGED_NEW_AREA = render_settled, ZONE_CHANGED = render_settled, ZONE_CHANGED_INDOORS = render_settled }

local events = CreateFrame("Frame")
library.update_events(events, { "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS" })
events:SetScript("OnEvent", function(_, event, first, second) library.update_safely("place toast " .. event, HEARD[event], first, second) end)
