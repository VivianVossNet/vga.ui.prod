-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: Other addons' pins on the minimap - Questie's quest signs, a rare finder's marks - are placed by their libraries over the minimap's whole square, so where our frame cuts the map to its visible part they would stand on the frame; ten times a second every pin not wholly inside the visible map - its whole picture, not only its middle: the box round the pin and every texture shown of it and of its children, since a library's pin may be a small frame at its picture's corner - is made invisible and shown again the moment it lies wholly inside once more, so none reaches into the rims (K0914, K0915); Questie's own pins (QuestieFrame…) are never shown on the minimap, whose signs vga.ui draws itself (K0922).

-- {K0922} {K0915} {K0914} {K0435}

local _, vga = ...
local library = LibVGA
local EVERY = 0.1
local QUESTIE = "QuestieFrame"
local KEPT = { LibVGAMinimapButton = true, MinimapBackdrop = true }
local hidden = {}
local watch

local function read_edges(region)
    local scale = region:GetEffectiveScale()
    local left, right, top, bottom = region:GetLeft(), region:GetRight(), region:GetTop(), region:GetBottom()
    if not (left and right and top and bottom) then return nil end
    return left * scale, right * scale, top * scale, bottom * scale
end

local function update_box_by(box, region)
    if not (region.IsShown and region:IsShown()) then return end
    local left, right, top, bottom = read_edges(region)
    if not left then return end
    box[1], box[2] = math.min(box[1] or left, left), math.max(box[2] or right, right)
    box[3], box[4] = math.max(box[3] or top, top), math.min(box[4] or bottom, bottom)
end

local function update_box_of(box, frame)
    update_box_by(box, frame)
    for _, region in ipairs({ frame:GetRegions() }) do
        if region.GetObjectType and region:GetObjectType() == "Texture" then update_box_by(box, region) end
    end
end

local function read_box(pin)
    local box = {}
    update_box_of(box, pin)
    for _, child in ipairs({ pin:GetChildren() }) do update_box_of(box, child) end
    return box
end

local function check_inside(pin, edges)
    local box = read_box(pin)
    if not box[1] then return true end
    return box[1] >= edges[1] and box[2] <= edges[2] and box[3] <= edges[3] and box[4] >= edges[4]
end

local function update_pin(pin, edges)
    local name = pin.GetName and pin:GetName()
    if name and KEPT[name] then return end
    local inside = not (name and name:sub(1, #QUESTIE) == QUESTIE) and check_inside(pin, edges)
    if not inside and not hidden[pin] then
        hidden[pin] = pin:GetAlpha()
        pin:SetAlpha(0)
    elseif inside and hidden[pin] then
        pin:SetAlpha(hidden[pin])
        hidden[pin] = nil
    end
end

local function update_pins()
    local left, right, top, bottom = read_edges(watch.view)
    if not left then return end
    local edges = { left, right, top, bottom }
    for _, pin in ipairs({ Minimap:GetChildren() }) do
        if pin:IsShown() then update_pin(pin, edges) end
    end
end

local function update_pins_safely(_, elapsed)
    watch.since = (watch.since or 0) + elapsed
    if watch.since < EVERY then return end
    watch.since = 0
    library.update_safely("map pins", update_pins)
end

function vga.create_map_pins(view)
    watch = CreateFrame("Frame", nil, view)
    watch.view = view
    watch:SetScript("OnUpdate", update_pins_safely)
end
