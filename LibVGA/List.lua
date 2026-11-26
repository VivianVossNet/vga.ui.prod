-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's list (K0631): rows of one height over any number of items, the scrolling body of LibVGA/Scroll.lua its frame and its bar; only as many rows are made as the room shows and one more, their height and the gap between them on whole screen pixels so every gap is even (K0829), and they are laid anew on the items in view whenever the list scrolls or its items change, so no window makes rows or a scroll bar of its own; a hairline between the rows as the draft's lists draw them (K0632). Heads made by library.create_sort_head sort the list by a click - ascending, a second click descending - after the reader the user gives for each key (list.sorters), a small arrow beside the chosen head, the list then laid anew (list.on_sort): every listing sorts by its column titles (K0655). The user gives a maker of one row and a filler that sets a row to an item, and may hear when the rows in view were laid (list.on_rows), to make a column of chips one width (library.read_list_rows_shown). A column title whose value needs explaining shows its explanation as a tooltip once the mouse has rested on it for a second - the text given, else the texts' head_tip_ and the column's key - and hides it when the mouse leaves (K0685). A list's columns are laid by library.read_columns: every column as wide as the widest it can hold - a title, the largest money of 9 999 gold, a figure - and one, the name's, taking what is left, at least four draft pixels between any two, so no column runs into the next whatever it shows (library.read_widest_money, library.read_widest_text, K0686). Items its user names to stand last (list.read_last) stay after the others, whatever the list is sorted by, each part in its order - the bags' fixed items at the merchant's sell page (K0943). A list standing in a group beneath its column heads lies below the heads' band, its word for an empty list one row further down (library.update_list_in_group, K0798).

-- {K0943} {K0829} {K0798} {K0631} {K0632} {K0655} {K0685} {K0686}

local library = LibVGA
local TIP_SECONDS = 1
local LEAST_GAP = 4
local WIDEST_MONEY = 99999999

local function update_rows(list)
    local step = list.row_height + list.gap
    local first = math.floor(list:GetVerticalScroll() / step) + 1
    local count = math.ceil(list:GetHeight() / step) + 1
    for slot = 1, count do list.rows[slot] = list.rows[slot] or list.create_row(list.content, slot) end
    for slot, row in ipairs(list.rows) do
        local index = first + slot - 1
        local item = slot <= count and list.items[index] or nil
        row:SetShown(item ~= nil)
        if item then
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", list.content, "TOPLEFT", 0, -(index - 1) * step)
            row:SetSize(list.width, list.row_height)
            row.index = index
            row.rule = row.rule or library.create_hairline(row)
            row.rule:ClearAllPoints()
            row.rule:SetPoint("TOPLEFT", row, "TOPLEFT", 0, list.gap / 2)
            row.rule:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, list.gap / 2)
            row.rule:SetHeight(1)
            row.rule:SetShown(index > 1)
            list.update_row(row, item, index)
        end
    end
    if list.on_rows then list.on_rows(list) end
end

function library.create_list(parent, create_row, update_row)
    local list = library.create_scroll(parent)
    list.rows, list.items, list.gap = {}, {}, 2
    list.create_row, list.update_row = create_row, update_row
    list.on_scroll = update_rows
    return list
end

local function read_sorted(list, items)
    local read = list.sort_key and list.sorters and list.sorters[list.sort_key]
    if not read then return items end
    local sorted, falling = {}, list.sort_falling
    for index, item in ipairs(items) do sorted[index] = item end
    table.sort(sorted, function(one, other)
        local first, second = read(one), read(other)
        if first == nil or second == nil then return first ~= nil end
        if falling then return first > second end
        return first < second
    end)
    return sorted
end

local function read_parted(list, items)
    if not list.read_last then return items end
    local first, last = {}, {}
    for _, item in ipairs(items) do
        if list.read_last(item) then last[#last + 1] = item else first[#first + 1] = item end
    end
    for _, item in ipairs(last) do first[#first + 1] = item end
    return first
end

local function update_head_looks(list)
    for _, head in ipairs(list.heads or {}) do
        local chosen = list.sort_key == head.key
        head.arrow:SetShown(chosen)
        head.arrow:SetTexture(library.media .. (list.sort_falling and "ChipDown" or "ChipUp"))
        local ink = chosen and library.colours.label or library.colours.quiet
        head.word:SetTextColor(ink[1], ink[2], ink[3], 1)
    end
end

local function render_sorted(head)
    local list = head.list
    if list.sort_key == head.key then
        list.sort_falling = not list.sort_falling
    else
        list.sort_key, list.sort_falling = head.key, false
    end
    update_head_looks(list)
    if list.on_sort then list.on_sort(list) end
end

local function render_head_tip(head)
    head.waiting = nil
    GameTooltip:SetOwner(head, "ANCHOR_BOTTOM")
    GameTooltip:SetText(head.word:GetText(), 1, 1, 1)
    GameTooltip:AddLine(head.tip, nil, nil, nil, true)
    GameTooltip:Show()
end

local function update_head_entered(head)
    if not head.tip then return end
    head.waiting = C_Timer.NewTimer(TIP_SECONDS, function() render_head_tip(head) end)
end

local function update_head_left(head)
    if head.waiting then head.waiting:Cancel() end
    head.waiting = nil
    if GameTooltip:GetOwner() == head then GameTooltip:Hide() end
end

function library.update_list_in_group(group, list, empty, head, row)
    list:ClearAllPoints()
    list:SetPoint("TOPLEFT", group, "TOPLEFT", 0, -head)
    empty:ClearAllPoints()
    empty:SetPoint("TOP", group, "TOP", 0, -(head + row))
end

function library.create_sort_head(list, parent, word, key, tip)
    local head = CreateFrame("Button", nil, parent)
    head.list, head.key = list, key
    head.tip = tip or library.texts["head_tip_" .. key]
    head:SetScript("OnEnter", update_head_entered)
    head:SetScript("OnLeave", update_head_left)
    head.word = library.create_text(head, "caption", library.colours.quiet)
    head.word:SetText(word)
    head.arrow = head:CreateTexture(nil, "ARTWORK")
    head:SetScript("OnClick", render_sorted)
    list.heads = list.heads or {}
    list.heads[#list.heads + 1] = head
    return head
end

function library.update_sort_head(head, right)
    local mark, gap = math.ceil(library.read_size(-3)), library.read_size(-6)
    head.word:SetFontObject(library.read_font("caption"))
    head.word:ClearAllPoints()
    head.arrow:ClearAllPoints()
    head.arrow:SetSize(mark, mark)
    if right then
        head.word:SetPoint("RIGHT")
        head.arrow:SetPoint("RIGHT", head.word, "LEFT", -gap, 0)
    else
        head.word:SetPoint("LEFT")
        head.arrow:SetPoint("LEFT", head.word, "RIGHT", gap, 0)
    end
    head:SetSize(math.ceil(head.word:GetStringWidth()) + gap + mark, math.ceil(head.word:GetStringHeight()) + 2)
    update_head_looks(head.list)
end

function library.update_list(list, items, width, room, row_height)
    items = read_parted(list, read_sorted(list, items))
    list.items, list.width, list.row_height = items, width, library.read_whole_pixels(row_height, list)
    list.gap = library.read_whole_pixels(list.gap or 0, list)
    list.on_scroll = nil
    library.update_scroll(list, width, room, math.max(#items * (row_height + list.gap) - list.gap, 0))
    list.on_scroll = update_rows
    update_rows(list)
end

function library.read_list_rows_shown(list)
    local shown = {}
    for _, row in ipairs(list.rows) do
        if row:IsShown() then shown[#shown + 1] = row end
    end
    return shown
end

function library.read_columns(width, sizes, apart)
    local gap, fixed, count = library.read_draft_size(apart or LEAST_GAP), 0, #sizes
    for _, size in ipairs(sizes) do fixed = fixed + (size or 0) end
    local rest = math.max(0, width - fixed - gap * (count - 1))
    local columns, x = { lefts = {}, rights = {} }, 0
    for index, size in ipairs(sizes) do
        columns.lefts[index], columns.rights[index] = x, x + (size or rest)
        x = columns.rights[index] + gap
    end
    return columns
end

function library.read_widest_money(probe)
    probe:Hide()
    library.update_money(probe, WIDEST_MONEY)
    return math.ceil(probe:GetWidth())
end

function library.read_widest_text(probe, text)
    probe:Hide()
    probe:SetText(text)
    return math.ceil(probe:GetStringWidth())
end
