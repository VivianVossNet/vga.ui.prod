-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: The quest tracker's item boxes: a quest whose log carries a usable item gets a small box left of the tracker, its middle level with the quest's, in the look of the minimap's button slots - a dark ground, the item's icon rounded, a grey ring that turns gold under the mouse, the item's tooltip beside it -; a click uses the item through the game's secure action button. A quest scrolled out of the tracker's view has no box. As the game forbids moving such a button in a fight, the boxes are laid out of combat only, the tracker's every-second refresh laying them again when the fight has ended; with the tracker hidden they hide.

-- {K0793} {K0469}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local SIZE = 24
local GAP = 6
local boxes = {}

local read_draft = library.read_draft_size

local function read_item(quest_id)
    local index = quest_id and C_QuestLog.GetLogIndexForQuestID and C_QuestLog.GetLogIndexForQuestID(quest_id)
    if not (index and GetQuestLogSpecialItemInfo) then return nil end
    local link, icon, _, shown_complete = GetQuestLogSpecialItemInfo(index)
    if not link then return nil end
    local complete = C_QuestLog.IsComplete and C_QuestLog.IsComplete(quest_id)
    if complete and not shown_complete then return nil end
    return { link = link, icon = icon, id = link:match("item:(%d+)") }
end

local function render_tip(box)
    if not box.link then return end
    library.update_cell_lit(box, true)
    GameTooltip:SetOwner(box, "ANCHOR_LEFT")
    GameTooltip:SetHyperlink(box.link)
    GameTooltip:Show()
end

local function update_left(box)
    library.update_cell_lit(box, false)
    GameTooltip:Hide()
end

local function create_box()
    local box = library.create_cell(UIParent, { kind = "round", picture = true, template = "SecureActionButtonTemplate" })
    box:RegisterForClicks("AnyUp", "AnyDown")
    box:SetAttribute("type", "item")
    box:SetScript("OnEnter", render_tip)
    box:SetScript("OnLeave", update_left)
    box:Hide()
    return box
end

local function update_box(box, quest, tracker, item)
    local share = tracker:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local size = read_draft(SIZE) * share
    box.share = share
    local middle = (quest:GetTop() + quest:GetBottom()) / 2 * share
    box:SetSize(size, size)
    box:ClearAllPoints()
    box:SetPoint("RIGHT", UIParent, "BOTTOMLEFT", tracker:GetLeft() * share - read_draft(GAP) * share, middle)
    box:SetAttribute("item", item.id and ("item:" .. item.id) or item.link)
    box.link = item.link
    box.icon:SetTexture(item.icon)
    library.update_round_cell(box, false)
    box:Show()
end

local function check_in_view(quest, tracker)
    local body = tracker.body
    if not (body and body:GetTop() and body:GetBottom()) then return true end
    local middle = (quest:GetTop() + quest:GetBottom()) / 2
    return middle <= body:GetTop() and middle >= body:GetBottom()
end

function vga.update_quest_items(tracker, quests, shown)
    if InCombatLockdown() then return end
    local used = 0
    for index, data in ipairs(tracker:IsShown() and shown or {}) do
        local quest, item = quests[index], read_item(data.id)
        if item and quest:GetTop() and tracker:GetLeft() and check_in_view(quest, tracker) then
            used = used + 1
            boxes[used] = boxes[used] or create_box()
            update_box(boxes[used], quest, tracker, item)
        end
    end
    for index = used + 1, #boxes do boxes[index]:Hide() end
end
