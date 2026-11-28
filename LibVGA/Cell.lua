-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's cell, as the accepted catalogue draws it (manual/view/vga-catalogue.html »Zelle«, K0775) after the main bar's keys and the bags' slots (manual/view/vga-probe.html .slot, .key; K0726) - its parts made here once for every cell that shows them: the quest's question mark and the fixed item's two blue rounded corners, at the upper right and the lower left, a third of the cell long (library.create_cell_pinned, K0899, K0901) -: a square of the draft's size, a black rounded line round it, the picture cropped and filling it up to its edge's inner side, the edge three draft pixels wide with gently rounded corners in the slot's grey - gold while the cell is active -, the game's cooldown veil over the picture (library.create_cooldown), its key small at its upper right, a light under the mouse. A key is a protected button of the game's made with the template and name its owner gives, so it may act in a fight; its owner fills it - picture, whether it is active or cannot be used, its cooldown and its key - and places it (K0781). The same parts dress a button or frame the game or its user owns - a ground, a black line, the bold edge, each where asked, the edge on another frame where it must lie above the button - in the user's own colours (library.create_cell_dress): the action keys, the bags' slots, the loot's and the split dialog's slots, the game menu's holders. A round cell is the rounded picture in a fine ring, gold while the mouse rests on it, on a dark ground - the quest items beside the tracker and the minimap's collected buttons -, the game's own masks on a foreign picture replaced by LibVGA's rounded one (library.update_cell_round_mask, K0793). A cell given an item's quality rims itself in that quality's colour from uncommon up, as the bank's draft draws it (K0836). A round cell may be a portrait (plan.portrait): the picture a circle, ringed two draft pixels wide in gold while lit, else in silver, a black line of one draft pixel round it, all of LibVGA's disc, as the talk's draft draws .face (library.update_portrait_cell, K0858). A cell may carry a quest item's mark, a small gold question mark at its lower left, as far in from the edge as its count stands at the right (library.create_cell_quest, K0874). A cell made for an item (plan.item) shows its count at its lower right and, under the mouse, the game's tooltip of its link, as the bank kept from the last visit shows its items (state.count, state.link, K1017).

-- {K1017} {K0901} {K0874} {K0858} {K0836} {K0801} {K0793} {K0781} {K0726} {K0775}

local library = LibVGA
local COUNT_RIGHT = 4
local COUNT_BOTTOM = 2
local colours = library.colours
local BLACK = { 0, 0, 0 }
local EDGE_WIDTH = 3
local SLOT_EDGE = { 0.18, 0.192, 0.22 }
local UNCOMMON = 2

local ROUND_TOP = { 0.071, 0.075, 0.09 }
local ROUND_BOTTOM = { 0.043, 0.047, 0.059 }
local ROUND_RADIUS = 4
local ROUND_INSET = 3
local PORTRAIT_LINE = 1
local PORTRAIT_BAND = 2

function library.update_cell_inside(cell, picture, count, inset)
    local draft = library.read_draft_size
    if picture then
        picture:ClearAllPoints()
        picture:SetPoint("TOPLEFT", cell, "TOPLEFT", inset, -inset)
        picture:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", -inset, inset)
    end
    if not count then return end
    count:ClearAllPoints()
    count:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", -draft(COUNT_RIGHT), draft(COUNT_BOTTOM))
end

local PINNED_SHARE, PINNED_INSET = 12 / 38, 1

function library.create_cell_pinned(cell)
    local marks = { cell:CreateTexture(nil, "OVERLAY", nil, 6), cell:CreateTexture(nil, "OVERLAY", nil, 6) }
    for _, mark in ipairs(marks) do
        mark:SetTexture(library.media .. "GoldCornerSmall")
        mark:Hide()
    end
    marks[2]:SetTexCoord(1, 0, 1, 0)
    return marks
end

function library.update_cell_pinned(marks, cell, shown)
    local size, inset, blue = math.floor(cell:GetWidth() * PINNED_SHARE + 0.5), library.read_draft_size(PINNED_INSET), colours.blue
    for index, mark in ipairs(marks) do
        mark:SetShown(shown)
        mark:SetVertexColor(blue[1], blue[2], blue[3], 1)
        mark:SetSize(size, size)
        mark:ClearAllPoints()
        if index == 1 then mark:SetPoint("TOPRIGHT", cell, "TOPRIGHT", -inset, -inset) else mark:SetPoint("BOTTOMLEFT", cell, "BOTTOMLEFT", inset, inset) end
    end
end

function library.create_cell_quest(cell)
    local mark = library.create_text(cell, "figure", colours.gold)
    mark:SetText("?")
    return mark
end

function library.update_cell_quest(mark, cell, shown, colour)
    local draft = library.read_draft_size
    mark:SetShown(shown)
    if not shown then return end
    mark:SetFontObject(library.read_font("figure"))
    mark:SetTextColor(colour[1], colour[2], colour[3], 1)
    mark:ClearAllPoints()
    mark:SetPoint("BOTTOMLEFT", cell, "BOTTOMLEFT", draft(COUNT_RIGHT), draft(COUNT_BOTTOM))
end

function library.create_cell_dress(frame, plan)
    if plan.ground then frame.vga_ground = library.create_surface(frame, "BACKGROUND", plan.ground) end
    if plan.line then frame.vga_line = library.create_surface(frame, "BACKGROUND", plan.line) end
    frame.vga_edge = library.create_ring(plan.edge_frame or frame, "OVERLAY", plan.edge or 5, nil, true)
    frame.vga_dressed = true
    return frame
end

function library.update_cell_round_mask(cell, picture)
    if not (picture and picture.AddMaskTexture) then return end
    if picture.GetNumMaskTextures and picture.GetMaskTexture then
        for index = picture:GetNumMaskTextures(), 1, -1 do picture:RemoveMaskTexture(picture:GetMaskTexture(index)) end
    end
    cell.rounded = cell.rounded or cell:CreateMaskTexture()
    cell.rounded:SetTexture(library.media .. "MaskRounded", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    cell.rounded:SetAllPoints(picture)
    picture:AddMaskTexture(cell.rounded)
end

local function read_disc(cell, level)
    local disc = cell:CreateTexture(nil, "BACKGROUND", nil, level)
    disc:SetTexture(library.media .. "Disc")
    return disc
end

local function create_portrait(cell)
    cell.rim, cell.band = read_disc(cell, 0), read_disc(cell, 1)
    cell.rim:SetVertexColor(BLACK[1], BLACK[2], BLACK[3], 1)
    cell.icon = cell:CreateTexture(nil, "ARTWORK")
    cell.disc = cell:CreateMaskTexture()
    cell.disc:SetTexture(library.media .. "Disc", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    cell.disc:SetAllPoints(cell.icon)
    if cell.icon.AddMaskTexture then cell.icon:AddMaskTexture(cell.disc) end
    return cell
end

function library.update_portrait_cell(cell, lit)
    local line, band = library.read_draft_size(PORTRAIT_LINE), library.read_draft_size(PORTRAIT_BAND)
    local colour = lit and colours.gold or colours.silver
    cell.rim:ClearAllPoints()
    cell.rim:SetPoint("TOPLEFT", -line, line)
    cell.rim:SetPoint("BOTTOMRIGHT", line, -line)
    cell.band:SetAllPoints()
    cell.band:SetVertexColor(colour[1], colour[2], colour[3], 1)
    cell.icon:ClearAllPoints()
    cell.icon:SetPoint("TOPLEFT", band, -band)
    cell.icon:SetPoint("BOTTOMRIGHT", -band, band)
end

local function create_round(cell, plan)
    if plan.portrait then return create_portrait(cell) end
    cell.ground = library.create_surface(cell, "BACKGROUND", 0)
    if plan.picture then
        cell.icon = cell:CreateTexture(nil, "ARTWORK")
        cell.own_picture = true
        library.update_cell_round_mask(cell, cell.icon)
    end
    cell.over = CreateFrame("Frame", nil, cell)
    cell.over:SetAllPoints()
    cell.over:SetFrameLevel(cell:GetFrameLevel() + 3)
    cell.ring = library.create_ring(cell.over, "OVERLAY", 0)
    return cell
end

function library.update_round_cell(cell, lit, alpha)
    library.update_surface(cell.ground, 0, ROUND_RADIUS, ROUND_TOP, ROUND_BOTTOM, alpha or 1)
    library.update_ring(cell.ring, 1, lit and colours.gold or colours.metal_top, 1)
    if not cell.own_picture then return end
    local inset = library.read_draft_size(ROUND_INSET) * (cell.share or 1)
    cell.icon:ClearAllPoints()
    cell.icon:SetPoint("TOPLEFT", inset, -inset)
    cell.icon:SetPoint("BOTTOMRIGHT", -inset, inset)
end

function library.update_cell_lit(cell, lit)
    library.update_ring(cell.ring, 1, lit and colours.gold or colours.metal_top, 1)
end

local function render_cell_tip(cell)
    if not cell.link then return end
    GameTooltip:SetOwner(cell, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink(cell.link)
    GameTooltip:Show()
end

local function render_cell_tip_hidden(cell)
    if GameTooltip:GetOwner() == cell then GameTooltip:Hide() end
end

local function create_cell_item(cell)
    cell.count = library.create_text(cell, "figures_small", colours.ink)
    cell.count:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", -library.read_draft_size(3), library.read_draft_size(2))
    cell:SetScript("OnEnter", render_cell_tip)
    cell:SetScript("OnLeave", render_cell_tip_hidden)
end

function library.create_cell(parent, plan)
    if plan.kind == "round" then return create_round(CreateFrame(plan.frame or "Button", plan.name, parent, plan.template), plan) end
    local cell = CreateFrame(plan.kind == "key" and "CheckButton" or "Button", plan.name, parent, plan.template)
    cell.vga_cell = true
    cell.icon = cell:CreateTexture(nil, "ARTWORK")
    library.update_cell_picture(cell.icon, cell, EDGE_WIDTH)
    cell.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    cell.cooldown = library.create_cooldown(cell, "veil")
    library.update_cell_picture(cell.cooldown, cell, EDGE_WIDTH)
    library.create_cell_dress(cell, { line = 0, edge = 6 })
    cell.line, cell.edge = cell.vga_line, cell.vga_edge
    cell.hotkey = library.create_text(cell, "caption")
    cell:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
    cell:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.15)
    if plan.item then create_cell_item(cell) end
    return cell
end

function library.update_cell_size(cell, size)
    cell:SetSize(size, size)
    library.update_surface(cell.line, -1, 2 * EDGE_WIDTH + 1, BLACK, BLACK)
    cell.hotkey:SetFontObject(library.read_font("caption"))
    cell.hotkey:ClearAllPoints()
    cell.hotkey:SetPoint("TOPRIGHT", cell, "TOPRIGHT", -library.read_draft_size(3), -library.read_draft_size(2))
end

local function read_edge_colour(state)
    if state.active then return colours.gold end
    if (state.quality or 1) >= UNCOMMON then return library.read_quality_colour(state.quality) end
    return SLOT_EDGE
end

function library.update_cell(cell, state)
    cell.icon:SetTexture(state.picture)
    cell.icon:SetShown(state.picture ~= nil)
    cell.icon:SetDesaturated(state.unusable or false)
    library.update_ring(cell.edge, EDGE_WIDTH, read_edge_colour(state), 1)
    library.update_cooldown(cell.cooldown, state.start, state.duration)
    cell.hotkey:SetText(state.hotkey or "")
    cell.link = state.link
    if cell.count then cell.count:SetText(state.count and state.count > 1 and state.count or "") end
end
