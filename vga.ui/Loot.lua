-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: the loot as a dialog in the bags' look, as the accepted draft draws variant B (manual/view/vga-loot.html, K0700): LibVGA's dialog with the bags' head - the mark, the title naming what is looted, else »Beute« - and a foot with the bag slots still free; beneath the head every loot slot as one row of LibVGA's list - the item's picture in a slot with the bags' edge in its quality's colour, a quest item's in gold, its count in the slot, beside it the name in its quality's colour, rare and epic in the brighter colours vga.auctions uses so they read on the dark ground, and below it what it is - its kind and sort, »Geld«, or »Questgegenstand« in gold -; the whole row the click that takes it, a modified click linking it as everywhere, the game's tooltip of the slot on hover, the row lit as the template's rows are; a slot taken keeps its place, greyed, so nothing moves under the pointer; the dialog one size for six rows, more scrolling, compact since K0704 - each row one line, the picture small, the name beside it and its kind at the right, both in the bags' small face, the title in the bold face of the body, not the large one of a full dialog, a long name ending in »…« before the close button (K0707) - and as large as the bags' tab chooses for it, Klein, Mittel or Groß; opened with its first row under the pointer and closed with the loot. The game's own loot frame hears nothing.

-- {K0802} {K0793} {K0789} {K0786} {K0785} {K0784} {K0783} {K0700} {K0704} {K0707}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local ROWS = 6
local ROW = 40
local WIDTH = 240
local PAD = 12
local ICON = 26
local MONEY = 2
local loot

local function read_kind(entry, link)
    local texts = library.texts
    if entry.coin then return texts.money_kind end
    if entry.quest then return texts.quest_item, colours.gold end
    local kind, sort = link and select(6, C_Item.GetItemInfo(link))
    if not kind then return "" end
    return sort and sort ~= kind and (kind .. " · " .. sort) or kind
end

local function read_copper(slot)
    if not GetLootSourceInfo then return nil end
    local sources, copper = { GetLootSourceInfo(slot) }, 0
    for index = 2, #sources, 2 do copper = copper + (sources[index] or 0) end
    return copper > 0 and copper or nil
end

local function read_entries()
    local entries = {}
    for slot = 1, GetNumLootItems() do
        local icon, name, count, _, quality, _, quest = GetLootSlotInfo(slot)
        if icon then
            local coin = GetLootSlotType(slot) == MONEY
            entries[#entries + 1] = { slot = slot, icon = icon, name = name or "", count = count or 0, quality = quality, quest = quest, coin = coin, copper = coin and read_copper(slot) or nil }
        end
    end
    return entries
end

local function read_item(entry)
    local link = not entry.coin and GetLootSlotLink and GetLootSlotLink(entry.slot)
    local sub, ink = read_kind(entry, link)
    return { icon = entry.icon, id = link and C_Item.GetItemInfoInstant(link), name = entry.name, quality = entry.quality, count = entry.count, sub = sub, sub_colour = ink, quest = entry.quest == true, taken = entry.taken == true, money = entry.copper }
end

local function update_loot_row(row, entry)
    row.entry = entry
    library.update_item_row(row, read_item(entry), library.read_draft_size(PAD), library.read_draft_size(WIDTH - PAD))
end

local function render_loot_tip(row)
    if not (row.entry and not row.entry.taken) then return end
    library.update_item_tip_owner(GameTooltip, row)
    GameTooltip:SetLootItem(row.entry.slot)
    GameTooltip:Show()
end

local function update_loot_tip_hidden()
    GameTooltip:Hide()
end

local function render_taken(row)
    local entry = row.entry
    if not entry or entry.taken then return end
    if IsModifiedClick() and GetLootSlotLink and HandleModifiedItemClick(GetLootSlotLink(entry.slot)) then return end
    LootSlot(entry.slot)
end

local function create_loot_row(parent)
    local row = library.create_item_row(parent, { cell = true, lit = true, on_click = render_taken, on_enter = render_loot_tip, on_leave = update_loot_tip_hidden })
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    return row
end

local function read_free_slots()
    local free = 0
    for bag = 0, NUM_BAG_SLOTS or 4 do free = free + (C_Container.GetContainerNumFreeSlots(bag) or 0) end
    return free
end

local function update_loot_layout()
    loot:SetScale(library.read_size_step("loot"))
    library.update_dialog(loot)
    loot.title:SetFontObject(library.read_font("bold"))
    loot.title:SetWordWrap(false)
    loot.title:SetPoint("RIGHT", loot.close, "LEFT", -library.read_size(-4), 0)
    local inner, row = library.read_size(-4), library.read_draft_size(ROW)
    local width = library.read_draft_size(WIDTH)
    loot:SetSize(width + 2 * inner, library.read_dialog_frame_height(loot) + ROWS * row)
    loot.list:ClearAllPoints()
    loot.list:SetPoint("TOPLEFT", loot.body, "TOPLEFT")
    library.update_list(loot.list, loot.entries or {}, width, ROWS * row, row)
    library.update_dialog_foot(loot, string.format(library.texts.slots_free, read_free_slots()))
end

local function update_loot_place()
    local scale = loot:GetEffectiveScale()
    local x, y = GetCursorPosition()
    local inner, head = library.read_size(-4), library.read_size(4)
    loot:ClearAllPoints()
    loot:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale - inner - library.read_draft_size(PAD + ICON / 2), y / scale + inner + head + library.read_draft_size(ROW) / 2)
end

local function create_loot()
    loot = library.create_dialog("VGALootWindow", library.texts.loot, {})
    loot.list = library.create_list(loot.body, create_loot_row, update_loot_row)
    loot:SetScript("OnHide", function() if CloseLoot then CloseLoot() end end)
    loot:Hide()
    if LootFrame then LootFrame:UnregisterAllEvents() end
end

local function update_loot_opened()
    if not loot then create_loot() end
    loot.entries = read_entries()
    local unit = UnitExists("target") and UnitIsDead("target") and UnitName("target")
    loot.title:SetText(unit or library.texts.loot)
    update_loot_layout()
    update_loot_place()
    loot:Show()
end

local function update_slot_taken(slot)
    if not (loot and loot.entries) then return end
    for _, entry in ipairs(loot.entries) do
        if entry.slot == slot then entry.taken = true end
    end
    update_loot_layout()
end

local function update_loot_closed()
    if loot then loot:Hide() end
end

local events = CreateFrame("Frame")
for _, name in ipairs({ "PLAYER_LOGIN", "LOOT_OPENED", "LOOT_SLOT_CLEARED", "LOOT_CLOSED" }) do pcall(events.RegisterEvent, events, name) end
events:SetScript("OnEvent", function(_, event, first)
    if event == "PLAYER_LOGIN" then
        library.update_safely("loot", create_loot)
    elseif event == "LOOT_OPENED" then
        library.update_safely("loot opened", update_loot_opened)
    elseif event == "LOOT_SLOT_CLEARED" then
        library.update_safely("loot taken", update_slot_taken, first)
    else
        library.update_safely("loot closed", update_loot_closed)
    end
end)
