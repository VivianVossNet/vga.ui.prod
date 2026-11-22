-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: the loot as a dialog in the bags' look, as the accepted draft draws variant B (manual/view/vga-loot.html, K0700): LibVGA's dialog with the bags' head - the mark, the title naming what is looted, else »Beute« - and a foot with the bag slots still free; beneath the head every loot slot as one row of LibVGA's list - the item's picture in a slot with the bags' edge in its quality's colour, a quest item's in gold, its count in the slot, beside it the name in its quality's colour, rare and epic in the brighter colours vga.auctions uses so they read on the dark ground, and below it what it is - its kind and sort, »Geld«, or »Questgegenstand« in gold -; the whole row the click that takes it, a modified click linking it as everywhere, the game's tooltip of the slot on hover, the row lit as the template's rows are; a slot taken keeps its place, greyed, so nothing moves under the pointer; the dialog one size for six rows, more scrolling, compact since K0704 - each row one line, the picture small, the name beside it and its kind at the right, both in the bags' small face, the title in the bold face of the body, not the large one of a full dialog, a long name ending in »…« before the close button (K0707) - and as large as the bags' tab chooses for it, Klein, Mittel or Groß; opened with its first row under the pointer and closed with the loot. The game's own loot frame hears nothing.

-- {K0700} {K0704} {K0707}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local ROWS = 6
local ROW = 26
local WIDTH = 240
local CELL = 22
local EDGE = 2
local MONEY = 2
local KIND_MOST = 90
local TAKEN = { 0.29, 0.29, 0.29 }
local BRIGHT = { [3] = { 0.31, 0.56, 0.91 }, [4] = { 0.69, 0.36, 0.91 } }
local loot

local function read_quality_colour(quality)
    if BRIGHT[quality] then return BRIGHT[quality] end
    local colour = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality or 1]
    return colour and { colour.r, colour.g, colour.b } or colours.ink
end

local function read_edge_colour(entry)
    if entry.quest then return colours.gold end
    if (entry.quality or 0) >= 2 then return read_quality_colour(entry.quality) end
    return colours.metal_top
end

local function read_kind(entry)
    local texts = library.texts
    if entry.money then return texts.money_kind, colours.quiet end
    if entry.quest then return texts.quest_item, colours.gold end
    local link = GetLootSlotLink and GetLootSlotLink(entry.slot)
    local kind, sort = link and select(6, C_Item.GetItemInfo(link))
    if not kind then return "", colours.quiet end
    return sort and sort ~= kind and (kind .. " · " .. sort) or kind, colours.quiet
end

local function read_entries()
    local entries = {}
    for slot = 1, GetNumLootItems() do
        local icon, name, count, _, quality, _, quest = GetLootSlotInfo(slot)
        if icon then
            entries[#entries + 1] = { slot = slot, icon = icon, name = name or "", count = count or 0, quality = quality, quest = quest, money = GetLootSlotType(slot) == MONEY }
        end
    end
    return entries
end

local function update_loot_row(row, entry)
    local size, gap = library.read_draft_size(CELL), library.read_draft_size(6)
    row.entry = entry
    row.cell:SetSize(size, size)
    row.cell:ClearAllPoints()
    row.cell:SetPoint("LEFT", row, "LEFT", library.read_draft_size(8), 0)
    row.icon:SetTexture(entry.icon)
    row.icon:SetDesaturated(entry.taken == true)
    local link = not entry.money and GetLootSlotLink and GetLootSlotLink(entry.slot)
    library.update_unusable(row.unusable, link and C_Item.GetItemInfoInstant(link))
    library.update_cell_picture(row.icon, row.cell, library.read_draft_size(EDGE))
    library.update_ring(row.edge, library.read_draft_size(EDGE), entry.taken and TAKEN or read_edge_colour(entry), 1)
    row.count:SetText(entry.count > 1 and entry.count or "")
    local colour = entry.taken and TAKEN or read_quality_colour(entry.quality)
    row.name:SetText(entry.name)
    row.name:SetTextColor(colour[1], colour[2], colour[3], 1)
    row.name:ClearAllPoints()
    row.name:SetPoint("LEFT", row.cell, "RIGHT", gap, 0)
    row.name:SetPoint("RIGHT", row.kind, "LEFT", -gap, 0)
    local kind, ink = read_kind(entry)
    ink = entry.taken and TAKEN or ink
    row.kind:SetText(kind)
    row.kind:SetTextColor(ink[1], ink[2], ink[3], 1)
    row.kind:ClearAllPoints()
    row.kind:SetPoint("RIGHT", row, "RIGHT", -library.read_draft_size(8), 0)
    row.kind:SetWidth(math.min(math.ceil(row.kind:GetStringWidth()), library.read_draft_size(KIND_MOST)))
end

local function render_loot_tip(row)
    row.light:Show()
    if not (row.entry and not row.entry.taken) then return end
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetLootItem(row.entry.slot)
    GameTooltip:Show()
end

local function update_loot_tip_hidden(row)
    row.light:Hide()
    GameTooltip:Hide()
end

local function render_taken(row)
    local entry = row.entry
    if not entry or entry.taken then return end
    if IsModifiedClick() and GetLootSlotLink and HandleModifiedItemClick(GetLootSlotLink(entry.slot)) then return end
    LootSlot(entry.slot)
end

local function create_loot_row(parent)
    local row = CreateFrame("Button", nil, parent)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row.light = row:CreateTexture(nil, "BACKGROUND")
    row.light:SetAllPoints()
    row.light:SetColorTexture(colours.gold[1], colours.gold[2], colours.gold[3], 0.08)
    row.light:Hide()
    row.cell = CreateFrame("Frame", nil, row)
    row.icon = row.cell:CreateTexture(nil, "ARTWORK")
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.unusable = library.create_unusable(row.cell, row.icon)
    row.edge = library.create_ring(row.cell, "OVERLAY", 5, nil, true)
    row.count = library.create_text(row.cell, "caption", colours.ink)
    row.count:SetPoint("BOTTOMRIGHT", row.cell, "BOTTOMRIGHT", -2, 2)
    row.name = library.create_text(row, "small", colours.ink)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
    row.kind = library.create_text(row, "small", colours.quiet)
    row.kind:SetJustifyH("LEFT")
    row.kind:SetWordWrap(false)
    row:SetScript("OnClick", render_taken)
    row:SetScript("OnEnter", render_loot_tip)
    row:SetScript("OnLeave", update_loot_tip_hidden)
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
    local inner, head, row = library.read_size(-4), library.read_size(4), library.read_draft_size(ROW)
    local width = library.read_draft_size(WIDTH)
    local foot = library.read_size(2)
    loot:SetSize(width + 2 * inner, head + 1 + ROWS * row + foot + 2 * inner)
    loot.list:ClearAllPoints()
    loot.list:SetPoint("TOPLEFT", loot.body, "TOPLEFT")
    library.update_list(loot.list, loot.entries or {}, width, ROWS * row, row)
    loot.foot:SetFontObject(library.read_font("small"))
    loot.foot:ClearAllPoints()
    loot.foot:SetPoint("BOTTOMLEFT", loot, "BOTTOMLEFT", inner + library.read_draft_size(12), inner + library.read_size(-4))
    loot.foot:SetText(string.format(library.texts.slots_free, read_free_slots()))
end

local function update_loot_place()
    local scale = loot:GetEffectiveScale()
    local x, y = GetCursorPosition()
    local inner, head = library.read_size(-4), library.read_size(4)
    loot:ClearAllPoints()
    loot:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale - inner - library.read_draft_size(12 + CELL / 2), y / scale + inner + head + library.read_draft_size(ROW) / 2)
end

local function create_loot()
    loot = library.create_dialog("VGALootWindow", library.texts.loot)
    loot.list = library.create_list(loot.body, create_loot_row, update_loot_row)
    loot.foot = library.create_text(loot, "small", colours.quiet)
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
