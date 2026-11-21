-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.ui's party frame as the accepted draft draws .party and .pm (manual/view/vga-probe.html): one widget with one gold corner for the whole group; a row per member divided by hairlines - the level in gold, the class's dot, the name, a thin health bar -, the whole row in grey while the member is offline, an OFFLINE in capitals, four pixels below the small face, beneath the bar where the pet's bar would stand, a pet being gone with its owner, a pet as a second, shorter bar inside its owner's row, without name or level, there for the healer to click; every row and pet bar a secure button that targets on click; Blizzard's own party frame hidden; ours stands left-aligned 120 pixels above the player frame, as tall as the group, its members stacked upward from the first; a protected pet bar is anchored to its protected row, never to a plain region. The group's leader carries a small filled gold crown right after the name (K0614). Shown and sized by a secure state driver on how many party units exist, so a group formed in a fight appears at once, not after it (K0630).

-- {K0277} {K0278} {K0279} {K0354} {K0379} {K0614} {K0630}

local library = LibVGA
local colours = library.colours
local MEMBERS = 4
local GAP_ABOVE_PLAYER = 120
local LEVEL_TEXT = { 0.945, 0.812, 0.431 }
local HAIRLINE = { 1, 1, 1, 0.063 }
local OFFLINE = { 0.5, 0.5, 0.52 }
local OFFLINE_SMALLER = 4
local MEMBERS_SHOWN = "[group:raid] 0; [@party4,exists] 4; [@party3,exists] 3; [@party2,exists] 2; [@party1,exists] 1; 0"
local RESIZE_PARTY = [[
    local party = self:GetFrameRef("party")
    local count = tonumber(newstate) or 0
    if count == 0 then
        party:Hide()
        return
    end
    party:SetHeight(2 * self:GetAttribute("pad") + count * self:GetAttribute("row"))
    party:Show()
]]
local party

local function create_secure(name, parent, unit)
    local button = CreateFrame("Button", name, parent, "SecureUnitButtonTemplate")
    button:SetAttribute("unit", unit)
    button:SetAttribute("*type1", "target")
    button:SetAttribute("*type2", "togglemenu")
    button:RegisterForClicks("AnyUp")
    RegisterUnitWatch(button)
    return button
end

local function create_member(index)
    local row = create_secure("VGAPartyMember" .. index, party, "party" .. index)
    row.unit = "party" .. index
    row.level = library.create_text(row, "caption", LEVEL_TEXT)
    row.level:SetJustifyH("RIGHT")
    row.spot = CreateFrame("Frame", nil, row)
    row.dot = library.create_surface(row.spot, "ARTWORK", 0)
    row.name = library.create_text(row, "bold")
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
    row.crown = row:CreateTexture(nil, "OVERLAY")
    row.crown:SetTexture(library.media .. "Crown")
    row.crown:SetVertexColor(colours.gold[1], colours.gold[2], colours.gold[3], 1)
    row.crown:Hide()
    row.health = library.create_bar(row, "health")
    row.offline = library.create_text(row, "small", OFFLINE)
    row.offline:SetText(string.upper(PLAYER_OFFLINE or "Offline"))
    row.line = row:CreateTexture(nil, "BACKGROUND")
    row.line:SetColorTexture(unpack(HAIRLINE))
    row.pet = create_secure("VGAPartyPet" .. index, row, "partypet" .. index)
    row.pet.health = library.create_bar(row.pet, "health")
    row.pet.health:SetAllPoints()
    row.pet.health:SetAlpha(0.85)
    return row
end

local function update_member_layout(row, index)
    local base, pad = library.read_base(), library.read_size(-2)
    local width, height = library.read_size(6) * 4, library.read_size(4) + 2 * pad
    local bar, dot = math.max(4, library.read_size(-4)), math.floor(base * 0.77 + 0.5)
    local level = math.floor(base * 1.3 + 0.5)
    row:ClearAllPoints()
    row:SetSize(width, height)
    row:SetPoint("BOTTOMLEFT", party, "BOTTOMLEFT", 0, pad + (index - 1) * height)
    row.level:SetFontObject(library.read_font("caption"))
    row.level:ClearAllPoints()
    row.level:SetPoint("LEFT", row, "LEFT", pad, 0)
    row.level:SetWidth(level)
    row.spot:ClearAllPoints()
    row.spot:SetPoint("LEFT", row, "LEFT", 2 * pad + level, 0)
    row.spot:SetSize(dot, dot)
    row.name:SetFontObject(library.read_frame_font("bold"))
    row.name:ClearAllPoints()
    row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 2 * pad + level + dot + pad, -pad)
    row.name:SetPoint("RIGHT", row, "RIGHT", -library.read_size(1), 0)
    row.health:ClearAllPoints()
    row.health:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -library.read_size(-6))
    row.health:SetPoint("RIGHT", row, "RIGHT", -library.read_size(1), 0)
    row.health:SetHeight(bar)
    local face, size, flags = library.read_font("small"):GetFont()
    row.offline:SetFont(face, math.max(size - OFFLINE_SMALLER, 6), flags or "")
    row.offline:SetTextColor(unpack(OFFLINE))
    row.offline:ClearAllPoints()
    row.offline:SetPoint("TOPLEFT", row.health, "BOTTOMLEFT", 0, -library.read_size(-6))
    library.update_bar_shape(row.health, library.read_size(-6))
    local left = 2 * pad + level + dot + pad
    local below = pad + library.read_size(1) + library.read_size(-6) + bar + library.read_size(-4)
    row.pet:ClearAllPoints()
    row.pet:SetPoint("TOPLEFT", row, "TOPLEFT", left, -below)
    row.pet:SetSize(math.floor((width - left - library.read_size(1)) * 0.6 + 0.5), bar + 1)
    library.update_bar_shape(row.pet.health, library.read_size(-6))
    row.line:ClearAllPoints()
    row.line:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    row.line:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
    row.line:SetHeight(1)
    row.line:SetShown(index > 1)
end

local function update_dot(row, colour)
    local size = math.floor(library.read_base() * 0.77 + 0.5)
    library.update_surface(row.dot, 0, size / 2, colour, colour)
end

local function read_class_colour(unit)
    local _, class = UnitClass(unit)
    local colour = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if colour then return { colour.r, colour.g, colour.b } end
    return colours.quiet
end

local function update_member(row)
    local unit = row.unit
    if not UnitExists(unit) then return end
    local level = UnitLevel(unit)
    local online = UnitIsConnected(unit)
    row.level:SetText(level and level > 0 and level or "??")
    row.level:SetTextColor(unpack(online and LEVEL_TEXT or OFFLINE))
    row.name:SetText(library.read_unit_name(unit))
    local crown = library.read_size(0)
    row.crown:SetSize(crown, crown)
    row.crown:ClearAllPoints()
    row.crown:SetPoint("LEFT", row.name, "LEFT", math.ceil(row.name:GetStringWidth()) + library.read_size(-4), 0)
    row.crown:SetShown(UnitIsGroupLeader(unit) == true)
    row.name:SetTextColor(unpack(online and colours.ink or OFFLINE))
    update_dot(row, online and read_class_colour(unit) or OFFLINE)
    library.update_bar_kind(row.health, online and "health" or "tapped")
    row.offline:SetShown(not online)
    library.update_bar_value(row.health, UnitHealth(unit), UnitHealthMax(unit))
    local pet = row.pet.unit or ("partypet" .. unit:match("%d"))
    row.pet.unit = pet
    if UnitExists(pet) then library.update_bar_value(row.pet.health, UnitHealth(pet), UnitHealthMax(pet)) end
end

local function update_party_layout()
    if InCombatLockdown() then return end
    library.update_frame(party)
    for index, row in ipairs(party.rows) do update_member_layout(row, index) end
    local pad = library.read_size(-2)
    local row = library.read_size(4) + 2 * pad
    party.driver:SetAttribute("pad", pad)
    party.driver:SetAttribute("row", row)
    local count = math.max(1, math.min(MEMBERS, GetNumSubgroupMembers and GetNumSubgroupMembers() or MEMBERS))
    party:SetSize(library.read_size(6) * 4, 2 * pad + count * row)
    party:SetShown(IsInGroup() and not IsInRaid())
end

local function update_party()
    update_party_layout()
    for _, row in ipairs(party.rows) do update_member(row) end
end

local function delete_blizzard_party()
    for _, blizzard in ipairs({ PartyFrame, CompactPartyFrame }) do
        if blizzard then
            blizzard:UnregisterAllEvents()
            blizzard:Hide()
            blizzard:SetAlpha(0)
        end
    end
end

local function create_party_driver()
    local driver = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
    driver:SetFrameRef("party", party)
    driver:SetAttribute("_onstate-members", RESIZE_PARTY)
    RegisterStateDriver(driver, "members", MEMBERS_SHOWN)
    return driver
end

local function create_party()
    party = library.create_frame("VGAPartyFrame", UIParent)
    party.corner:SetScript("OnClick", function(corner) library.update_safely("options", library.render_widget, corner, "party") end)
    party.rows = {}
    for index = 1, MEMBERS do party.rows[index] = create_member(index) end
    party.driver = create_party_driver()
    library.create_place(party, "party", "BOTTOMLEFT", VGAUnitFrame_player or UIParent, 0, GAP_ABOVE_PLAYER, "TOPLEFT")
    delete_blizzard_party()
    library.create_element("party", { title = PARTY or "Party", update = update_party })
end

local function update_event(event, unit)
    if event == "PLAYER_LOGIN" then
        create_party()
    elseif not party then
        return
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        for _, row in ipairs(party.rows) do
            if row.unit == unit or row.pet.unit == unit then update_member(row) end
        end
    else
        update_party()
    end
end

local events = CreateFrame("Frame")
for _, name in ipairs({ "PLAYER_LOGIN", "GROUP_ROSTER_UPDATE", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED", "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_PET", "UNIT_LEVEL", "UNIT_NAME_UPDATE", "UNIT_CONNECTION", "PARTY_MEMBER_ENABLE", "PARTY_MEMBER_DISABLE", "PARTY_LEADER_CHANGED" }) do
    pcall(events.RegisterEvent, events, name)
end
events:SetScript("OnEvent", function(_, event, unit)
    library.update_safely("party " .. event, update_event, event, unit)
end)
