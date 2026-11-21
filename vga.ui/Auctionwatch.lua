-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.auctions' page Beobachtet (K0655): every item watched by the eye on Kaufen in LibVGA's list in one of LibVGA's groups under sortable heads - picture, name in its quality's colour, required level, today's lowest, the market value, the lowest against it as a chip, and the eye, whose click lets the item go -; a quiet line where nothing is watched. The buy threshold and the notice of the accepted draft follow.

-- {K0655} {K0686}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local HEADS = { "item", "level", "lowest_now", "market_value", "to_market" }
local watch_page

local function read_name(row) return row.name end
local function read_level(row) return vga.read_item_level(row.item) end
local function read_lowest(row) return row.lowest end
local function read_market(row) return row.market end

local function read_deal_share(row)
    return row.market and row.lowest and row.market > 0 and row.lowest / row.market or nil
end

local function read_rows()
    local rows = {}
    for _, item in ipairs(vga.read_watched()) do
        local market, lowest = vga.read_market(item)
        local name, _, quality, _, _, _, _, _, _, icon = C_Item.GetItemInfo(item)
        rows[#rows + 1] = { item = item, name = name or tostring(item), quality = quality, icon = icon or 134400, market = market, lowest = lowest }
    end
    return rows
end

local function update_watch_row(line, row)
    local page, size = watch_page, library.read_draft_size(26)
    line.row = row
    line.icon:SetTexture(row.icon)
    line.icon:SetSize(size, size)
    line.icon:ClearAllPoints()
    line.icon:SetPoint("LEFT", line, "LEFT", page.pad, 0)
    local colour = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[row.quality or 1]
    line.name:SetText(row.name)
    line.name:SetTextColor(colour and colour.r or 1, colour and colour.g or 1, colour and colour.b or 1, 1)
    line.name:ClearAllPoints()
    local columns, x = page.columns, page.pad
    line.name:SetPoint("LEFT", line.icon, "RIGHT", library.read_size(-4), 0)
    line.name:SetWidth(math.max(1, columns.rights[1] - size - library.read_size(-4)))
    line.level:SetText(vga.read_level_text(vga.read_item_level(row.item)))
    line.level:ClearAllPoints()
    line.level:SetPoint("LEFT", line, "LEFT", x + columns.lefts[2], 0)
    library.update_money(line.lowest, math.floor((row.lowest or 0) + 0.5))
    line.lowest:SetShown(row.lowest ~= nil)
    line.lowest:ClearAllPoints()
    line.lowest:SetPoint("RIGHT", line, "LEFT", x + columns.rights[3], 0)
    library.update_money(line.market, math.floor((row.market or 0) + 0.5))
    line.market:SetShown(row.market ~= nil)
    line.market:ClearAllPoints()
    line.market:SetPoint("RIGHT", line, "LEFT", x + columns.rights[4], 0)
    library.update_chip(line.chip, vga.read_deal(row.lowest or 0, row.market))
    line.chip:ClearAllPoints()
    line.chip:SetPoint("LEFT", line, "LEFT", x + columns.lefts[5], 0)
    library.update_eye_layout(line.eye)
    library.update_eye_shown(line.eye, true)
    line.eye:ClearAllPoints()
    line.eye:SetPoint("RIGHT", line, "LEFT", x + columns.rights[6], 0)
end

local function render_unwatched(line)
    if not line.row then return end
    vga.write_watched(line.row.item, nil)
    vga.update_watch_page(watch_page, watch_page.full_width)
end

local function render_row_tip(line)
    if line.row then vga.render_item_tip(line, { id = line.row.item }) end
end

local function create_watch_row(parent)
    local line = CreateFrame("Frame", nil, parent)
    line:EnableMouse(true)
    line.icon = line:CreateTexture(nil, "ARTWORK")
    line.name = library.create_text(line, "body", colours.ink)
    line.name:SetJustifyH("LEFT")
    line.name:SetWordWrap(false)
    line.level = library.create_text(line, "small", colours.label)
    line.lowest = library.create_money(line, colours.ink)
    line.market = library.create_money(line, colours.quiet)
    line.chip = library.create_chip(line)
    line.eye = library.create_eye(line, function() render_unwatched(line) end, { library.texts.watch_on, library.texts.watch_off })
    line:SetScript("OnEnter", render_row_tip)
    line:SetScript("OnLeave", vga.update_item_tip_hidden)
    return line
end

local function render_watch_sorted()
    vga.update_watch_page(watch_page, watch_page.full_width)
end

function vga.create_watch_page(page)
    local texts = library.texts
    watch_page = page
    page.group = library.create_group(page)
    page.list = library.create_list(page.group, create_watch_row, update_watch_row)
    page.list.sorters = { item = read_name, level = read_level, lowest_now = read_lowest, market_value = read_market, to_market = read_deal_share }
    page.list.on_sort = render_watch_sorted
    page.heads = {}
    for index, key in ipairs(HEADS) do page.heads[index] = library.create_sort_head(page.list, page.group, texts[key]:upper(), key) end
    page.empty = library.create_text(page.group, "small", colours.quiet)
    page.empty:SetText(texts.watched_empty)
    page.probe_money = library.create_money(page, colours.ink)
    page.probe_text = library.create_text(page, "small", colours.ink)
    page.probe_chip = library.create_chip(page)
    page.probe_chip:Hide()
    page.lines = page.list.rows
end

function vga.update_watch_page(page, width)
    page.full_width, page.pad = width, library.read_draft_size(12)
    page.width = width - 2 * page.pad
    local head, row = library.read_draft_size(28), library.read_draft_size(40)
    page.group:ClearAllPoints()
    page.group:SetPoint("TOPLEFT", page, "TOPLEFT")
    page.group:SetSize(width, math.max(page:GetHeight(), head + 3 * row))
    library.update_group(page.group)
    for index, heading in ipairs(page.heads) do library.update_sort_head(heading, index == 3 or index == 4) end
    local money, chip = library.read_widest_money(page.probe_money), library.read_widest_chip(page.probe_chip)
    local function read_room(index, least) return math.max(page.heads[index]:GetWidth(), least) end
    page.columns = library.read_columns(page.width, { false, read_room(2, library.read_widest_text(page.probe_text, "60")), read_room(3, money), read_room(4, money), read_room(5, chip), library.read_size(2) })
    local columns, icon = page.columns, library.read_draft_size(26) + library.read_size(-4)
    local places = { { "LEFT", columns.lefts[1] + icon }, { "LEFT", columns.lefts[2] }, { "RIGHT", columns.rights[3] }, { "RIGHT", columns.rights[4] }, { "LEFT", columns.lefts[5] } }
    for index, heading in ipairs(page.heads) do
        local place = places[index]
        heading:ClearAllPoints()
        heading:SetPoint(place[1], page.group, "TOPLEFT", page.pad + place[2], -head / 2)
    end
    local rows = read_rows()
    page.list:ClearAllPoints()
    page.list:SetPoint("TOPLEFT", page.group, "TOPLEFT", 0, -head)
    library.update_list(page.list, rows, width, page.group:GetHeight() - head, row)
    page.empty:SetShown(#rows == 0)
    page.empty:ClearAllPoints()
    page.empty:SetPoint("TOP", page.group, "TOP", 0, -(head + row))
end
