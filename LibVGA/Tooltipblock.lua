-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's tooltip block, as the accepted catalogue names it (manual/view/vga-catalogue.html, K0775) after the grid's draft (manual/view/vga-grid.html, K0736): the room our parts take in one of the game's tooltips - a head above the game's lines, a foot below them - kept so that no line of the game's ever lies under ours and no room stays empty. Both are kept through the tooltip's bottom padding, added to whatever the game itself sets and laid again whenever the game reckons its padding anew or the tooltip shows; the head's room is made by moving the game's first line down by the head's height, its other lines following it, never by the top padding, which the game drops (K0780). Cleared with the tooltip, the padding and the first line go back. Its owner names a part's height and, where it lays its own pieces in the foot, what lays them, told the game's own bottom padding each time.

-- {K0780} {K0744} {K0754} {K0775} {K0736}

local library = LibVGA
local LINE = { "TOPLEFT", nil, "TOPLEFT", 10, -10 }
local blocks = setmetatable({}, { __mode = "k" })

local function check_kept(value, kept)
    return kept ~= nil and math.abs(value - kept) < 0.5
end

local function check_plain(value)
    return not (issecretvalue and issecretvalue(value))
end

local function read_first_line(tip)
    local name = tip:GetName()
    return name and _G[name .. "TextLeft1"]
end

local function read_line_point(block, line)
    if block.line_point then return block.line_point end
    local point, relative, relative_point, x, y = line:GetPoint(1)
    if point and check_plain(x) and check_plain(y) then
        block.line_point = { point, relative, relative_point, x, y }
    else
        block.line_point = { LINE[1], block.tip, LINE[3], LINE[4], LINE[5] }
    end
    return block.line_point
end

local function update_first_line(block, drop)
    local line = read_first_line(block.tip)
    if not line then return end
    local point = read_line_point(block, line)
    line:ClearAllPoints()
    line:SetPoint(point[1], point[2], point[3], point[4], point[5] - drop)
end

local function update_room(block)
    local tip = block.tip
    if block.head == 0 and block.foot == 0 then return end
    local width, height, left, top = tip:GetPadding()
    if not check_kept(height, block.padded) then block.base = height end
    block.padded = block.base + block.foot + block.head
    if not check_kept(height, block.padded) then tip:SetPadding(width, block.padded, left or 0, top or 0) end
    update_first_line(block, block.head)
    for _, lay in pairs(block.layers) do lay(tip, block.base) end
end

local function update_room_safely(tip)
    if blocks[tip] then library.update_safely("tooltip block", update_room, blocks[tip]) end
end

local function update_cleared(block)
    local tip = block.tip
    if block.padded then
        local width, height, left, top = tip:GetPadding()
        if check_kept(height, block.padded) then tip:SetPadding(width, block.base or 0, left or 0, top or 0) end
    end
    if block.head > 0 then update_first_line(block, 0) end
    block.head, block.foot, block.padded, block.base, block.layers = 0, 0, nil, nil, {}
end

local function update_cleared_safely(tip)
    library.update_safely("tooltip block cleared", update_cleared, blocks[tip])
end

function library.create_tooltip_block(tip)
    if blocks[tip] then return blocks[tip] end
    blocks[tip] = { tip = tip, head = 0, foot = 0, layers = {} }
    tip:HookScript("OnTooltipCleared", update_cleared_safely)
    tip:HookScript("OnShow", update_room_safely)
    return blocks[tip]
end

function library.update_tooltip_block(tip, part, height, lay)
    local block = library.create_tooltip_block(tip)
    block[part] = height
    block.layers[part] = lay
    update_room(block)
end

if hooksecurefunc and GameTooltip_CalculatePadding then hooksecurefunc("GameTooltip_CalculatePadding", update_room_safely) end
