-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's container slot, a meta-object (K0860) made once for every place that shows the slots of a bag or a bank tab (K0893): the game's own item button of a container (ContainerFrameItemButtonTemplate) in a holder carrying the bag's number, so using, dragging, dropping, splitting, selling and the tooltip stay the game's own; dressed as the bags' accepted drafts draw it (manual/view/vga-reference.html §3, vga-windows.html A) - the template's inset metal, our edge laid over the game's slot, three pixels wide with gently rounded corners, an item's quality from uncommon up in its colour, a quest item in gold, an empty slot in the metal's grey; a quest item with a small gold question mark in its lower left corner, an item that starts a quest not yet taken instead with LibVGA's orange sign »offer« in the middle, two thirds as high (K0761, K0857); an upgrade a small green arrow in its upper right corner (K0762); its count in the figures' face at its lower right; a locked item greyed; an item the character cannot use veiled (create_unusable). Its owner fills it per slot with a plan: new - the shimmer's rim kept -, dim - darkened whole through the frame's own alpha, since the game's item button narrows SetAlpha to its icon and border -, upgrade, and pinned - two small rounded corners in blue on its edge, at its upper right and its lower left, LibVGA's cell's pinned corners (library.create_cell_pinned), so the upgrade arrow and the quest's question mark keep their places (K0899, before a gold pin, K0898). The bags and the bank use it (K0784, K0893).

-- {K0899} {K0898} {K0893} {K0860} {K0857} {K0784} {K0762} {K0761}

local library = LibVGA
local colours = library.colours
local EDGE_WIDTH = 3
local SLOT_GROUND = { 0.031, 0.035, 0.043 }
local SLOT_EDGE = { 0.18, 0.192, 0.22 }
local UPGRADE_ARROW, UPGRADE_INSET = 14, 2
local UNCOMMON = 2
local QUEST_CLASS = 12
local DIM = 0.25
local PARTS = { "IconBorder", "IconOverlay", "IconOverlay2", "NewItemTexture", "BattlepayItemTexture", "IconQuestTexture", "flash", "searchOverlay", "ItemContextOverlay", "ExtendedSlot", "UpgradeIcon", "JunkIcon" }
local WHOLE_ALPHA = CreateFrame("Frame").SetAlpha
local read_draft = library.read_draft_size

function library.create_container_holder(parent, bag)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetID(bag)
    holder:SetAllPoints()
    holder.slots = {}
    return holder
end

local function update_button_parts(button)
    for _, name in ipairs(PARTS) do
        if button[name] then button[name]:SetAlpha(0) end
    end
    if button.GetNormalTexture and button:GetNormalTexture() then button:GetNormalTexture():SetAlpha(0) end
    for _, state in ipairs({ button:GetHighlightTexture(), button:GetPushedTexture() }) do
        state:SetTexture("Interface\\Buttons\\WHITE8X8")
        state:SetVertexColor(1, 1, 1, 0.15)
        state:SetAllPoints(button)
    end
    if button.icon then
        button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        library.update_cell_picture(button.icon, button, EDGE_WIDTH)
    end
    if button.Cooldown then library.update_cell_picture(button.Cooldown, button, EDGE_WIDTH) end
end

function library.create_container_slot(holder, slot)
    local button = CreateFrame("ItemButton", nil, holder, "ContainerFrameItemButtonTemplate")
    button:SetID(slot)
    library.create_cell_dress(button, { ground = -6, edge = 5 })
    button.vga_gem = button:CreateTexture(nil, "OVERLAY", nil, 6)
    button.vga_gem:Hide()
    button.vga_quest = library.create_text(button, "figure", colours.gold)
    button.vga_quest:SetText("?")
    button.vga_start = button:CreateTexture(nil, "OVERLAY", nil, 7)
    button.vga_start:SetTexture(library.media .. library.read_sign_picture("offer", "orange"))
    button.vga_start:Hide()
    button.vga_unusable = library.create_unusable(button, button.icon)
    button.vga_upgrade = CreateFrame("Frame", nil, button)
    button.vga_upgrade.arrow = button.vga_upgrade:CreateTexture(nil, "OVERLAY")
    button.vga_upgrade.arrow:SetTexture(library.media .. "UpgradeArrow")
    button.vga_upgrade.arrow:SetAllPoints()
    button.vga_marks = library.create_cell_pinned(button)
    update_button_parts(button)
    library.create_shimmer(button)
    return button
end

function library.check_container_quest(bag, slot, item)
    local _, _, _, _, _, class = C_Item.GetItemInfoInstant(item.itemID)
    local quest = C_Container.GetContainerItemQuestInfo and C_Container.GetContainerItemQuestInfo(bag, slot)
    return class == QUEST_CLASS or (quest and (quest.isQuestItem or quest.questID)) and true or false
end

local function check_starter(bag, slot)
    local quest = C_Container.GetContainerItemQuestInfo and C_Container.GetContainerItemQuestInfo(bag, slot)
    return quest ~= nil and quest.questID ~= nil and not quest.isActive
end

local function update_quest_mark(button, quest)
    button.vga_quest:SetShown(quest)
    if not quest then return end
    button.vga_quest:SetFontObject(library.read_font("figure"))
    button.vga_quest:SetTextColor(colours.gold[1], colours.gold[2], colours.gold[3])
    button.vga_quest:ClearAllPoints()
    button.vga_quest:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", read_draft(3), read_draft(2))
end

local function update_start_mark(button, mark, shown)
    mark:SetShown(shown)
    if not shown then return end
    local size = math.floor(button:GetWidth() * 2 / 3 + 0.5)
    mark:SetSize(size, size)
    mark:ClearAllPoints()
    mark:SetPoint("CENTER", button, "CENTER", 0, 0)
end

local function update_upgrade_mark(button, shown)
    local arrow = button.vga_upgrade
    arrow:SetShown(shown)
    if not shown then return end
    local size = read_draft(UPGRADE_ARROW)
    arrow:SetSize(size, size)
    arrow:ClearAllPoints()
    arrow:SetPoint("TOPRIGHT", button, "TOPRIGHT", -read_draft(UPGRADE_INSET), -read_draft(UPGRADE_INSET))
end

function library.read_container_edge(item, quest)
    if quest then return colours.gold end
    if item and (item.quality or 0) >= UNCOMMON then return { C_Item.GetItemQualityColor(item.quality) } end
    return SLOT_EDGE
end

local function update_look(button, item, new, quest)
    library.update_surface(button.vga_ground, 0, 2 * EDGE_WIDTH, SLOT_GROUND, SLOT_GROUND)
    library.update_ring(button.vga_edge, EDGE_WIDTH, library.read_container_edge(item, quest), 1)
    if not new then library.delete_shimmer(button) end
end

local function update_count(button, item)
    SetItemButtonCount(button, item and item.stackCount or 0)
    if not button.Count then return end
    button.Count:SetFontObject(library.read_font("figures_caption"))
    button.Count:SetTextColor(1, 1, 1)
    button.Count:ClearAllPoints()
    button.Count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -read_draft(3), read_draft(1))
end

function library.update_container_slot(button, bag, slot, plan)
    local item = C_Container.GetContainerItemInfo(bag, slot)
    SetItemButtonTexture(button, item and item.iconFileID)
    library.update_unusable(button.vga_unusable, item and item.itemID)
    update_count(button, item)
    SetItemButtonDesaturated(button, item and item.isLocked)
    if button.UpdateCooldown then button:UpdateCooldown(item ~= nil) end
    local quest = item ~= nil and library.check_container_quest(bag, slot, item)
    update_look(button, item, plan.new, quest)
    local starter = item ~= nil and check_starter(bag, slot)
    update_quest_mark(button, quest and not starter)
    update_start_mark(button, button.vga_start, starter)
    update_upgrade_mark(button, item ~= nil and plan.upgrade == true)
    library.update_cell_pinned(button.vga_marks, button, item ~= nil and plan.pinned == true)
    WHOLE_ALPHA(button, plan.dim and DIM or 1)
    return item
end
