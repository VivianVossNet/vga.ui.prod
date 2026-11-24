-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.ui's party frame as the accepted draft draws .party and .pm (manual/view/vga-probe.html): one widget with one gold corner for the whole group, a row per member divided by hairlines, each row LibVGA's unit frame in its tertiary tier, left-aligned, with its pet (library.create_unit_frame, K0864) - the level in gold, the class's dot, the name with the leader's crown after it (K0614, K0724), a thin health bar, the row grey with an OFFLINE beneath while the member is offline, the pet's shorter bar inside its owner's row, every row and pet bar a secure button that targets on click. What is the place's stays here: the rows stacked upward from the first, ours left-aligned 120 pixels above the player frame, as tall as the group, the hairlines between the rows, Blizzard's own party frame hidden, the events that fill the rows, and the secure state driver that shows and sizes the frame on how many party units exist, so a group formed in a fight appears at once, not after it (K0630).

-- {K0864} {K0789} {K0783} {K0755} {K0277} {K0278} {K0279} {K0354} {K0379} {K0614} {K0724} {K0630} {K0698} {K0717}

local library = LibVGA
local MEMBERS = 4
local GAP_ABOVE_PLAYER = 120
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

local function create_member(index)
    local pet = { name = "VGAPartyPet" .. index, unit = "partypet" .. index }
    local row = library.create_unit_frame("VGAPartyMember" .. index, "party" .. index, { tier = "tertiary", side = "left", parent = party, pet = pet })
    row.line = library.create_hairline(row, "light")
    return row
end

local function update_member_layout(row, index)
    local _, height = library.read_unit_frame_size("tertiary")
    row:ClearAllPoints()
    row:SetPoint("BOTTOMLEFT", party, "BOTTOMLEFT", 0, library.read_size(-2) + (index - 1) * height)
    library.update_unit_frame_layout(row)
    row.line:ClearAllPoints()
    row.line:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    row.line:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
    row.line:SetHeight(1)
    row.line:SetShown(index > 1)
end

local function update_party_layout()
    if InCombatLockdown() then return end
    library.update_frame(party)
    for index, row in ipairs(party.rows) do update_member_layout(row, index) end
    local pad = library.read_size(-2)
    local width, row = library.read_unit_frame_size("tertiary")
    party.driver:SetAttribute("pad", pad)
    party.driver:SetAttribute("row", row)
    local count = math.max(1, math.min(MEMBERS, GetNumSubgroupMembers and GetNumSubgroupMembers() or MEMBERS))
    party:SetSize(width, 2 * pad + count * row)
    party:SetShown(IsInGroup() and not IsInRaid())
end

local function update_party()
    update_party_layout()
    for _, row in ipairs(party.rows) do library.update_unit_frame(row) end
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
            if row.unit == unit or row.pet.unit == unit then library.update_unit_frame(row) end
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
