-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's map mark, a sign on LibVGA's map canvas as the owner's own pictures draw them (LibVGA/Media/Map, K0813) and the cartographer's draft sizes them (manual/view/vga-map-signs.html, K0809): 18 draft pixels at the world's zoom, 24 at a continent's, 32 at a zone's, scaled by the chosen size; a hit area of at least 24 draft pixels around it; a card in LibVGA's tooltip look on hover - its first line the title in gold, the others beneath -; a click handed to its item; the player's sign turned by the facing; places - quests to take, flight masters, vendors, repair, barbers, the auction house, inns, class and profession trainers - at three quarters of that size (K0825; before half, K0822), the quests in the quest view keeping it whole (library.read_map_mark_scale, K0822); marks given way by their layer when they crowd - the player above the party, the party above quests, quests above the rest. A layer of marks is laid by library.update_map_marks from its owner's items - kind, place in the plane, card, facing, what a click does -, its marks pooled, the unused hidden (K0815).

-- {K0825} {K0822} {K0815} {K0813} {K0809}

local library = LibVGA
local colours = library.colours
local SIZES = { world = 18, continent = 24, zone = 32 }
local HIT = 24
local LEVELS = { me = 10, party = 8, quests = 6 }
local REST = 4
local PLACE = 0.75
local PLACES = { QuestTake = true, QuestTakeLow = true, Flight = true, FlightUnknown = true, Vendor = true, Repair = true, Barber = true, Auction = true, ClassTrainer = true, ProfessionTrainer = true, Inn = true }

function library.read_map_mark_scale(kind)
    return PLACES[kind] and PLACE or 1
end

function library.read_map_mark_size(tier)
    return library.read_draft_size(SIZES[tier] or SIZES.zone)
end

local function render_mark_entered(mark)
    local card = mark.item and mark.item.card
    if not card then return end
    GameTooltip:SetOwner(mark, "ANCHOR_RIGHT")
    GameTooltip:AddLine(card[1], colours.gold[1], colours.gold[2], colours.gold[3])
    for index = 2, #card do GameTooltip:AddLine(card[index], colours.ink[1], colours.ink[2], colours.ink[3], true) end
    GameTooltip:Show()
end

local function render_mark_left()
    GameTooltip:Hide()
end

local function render_mark_clicked(mark, button)
    local item = mark.item
    if item and item.on_click then item.on_click(item, button) end
end

function library.create_map_mark(canvas, kind)
    local mark = CreateFrame("Button", nil, canvas.marks)
    mark:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    mark.picture = mark:CreateTexture(nil, "ARTWORK")
    mark.picture:SetPoint("CENTER")
    mark:SetScript("OnEnter", render_mark_entered)
    mark:SetScript("OnLeave", render_mark_left)
    mark:SetScript("OnClick", function(self, button) library.update_safely("map mark click", render_mark_clicked, self, button) end)
    library.update_map_mark_look(mark, kind, library.read_map_mark_size("zone"))
    return mark
end

function library.update_map_mark_look(mark, kind, size, facing)
    mark.picture:SetTexture(library.media .. "Map\\" .. kind)
    mark.picture:SetSize(size, size)
    mark.picture:SetRotation(facing or 0)
    local hit = math.max(size, library.read_draft_size(HIT))
    mark:SetSize(hit, hit)
end

function library.update_map_marks(canvas, layer, items, size)
    canvas.mark_layers = canvas.mark_layers or {}
    local pool = canvas.mark_layers[layer] or {}
    canvas.mark_layers[layer] = pool
    for index, item in ipairs(items) do
        pool[index] = pool[index] or library.create_map_mark(canvas, item.kind)
        local mark = pool[index]
        mark.item = item
        library.update_map_mark_look(mark, item.kind, size * library.read_map_mark_scale(item.kind), item.facing)
        mark:SetFrameLevel(canvas.marks:GetFrameLevel() + (LEVELS[layer] or REST))
        library.update_map_mark(canvas, mark, item.across, item.down)
    end
    for index = #items + 1, #pool do
        pool[index].item = nil
        pool[index]:Hide()
    end
end
