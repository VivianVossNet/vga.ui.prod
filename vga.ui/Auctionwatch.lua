-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.auctions' page Beobachtet (K0655): every item watched by the eye on Kaufen in LibVGA's list in one of LibVGA's groups under sortable heads - picture, name in its quality's colour, required level, today's lowest, the market value, the lowest against it as a chip, and the eye, whose click lets the item go -; a quiet line where nothing is watched. The buy threshold and the notice of the accepted draft follow.

-- {K0798} {K0789} {K0785} {K0655} {K0686}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local watch_page

local function read_name(row) return row.name end
local function read_level(row) return vga.read_item_level(row.item) end
local function read_lowest(row) return row.lowest end
local function read_market(row) return row.market end

local function read_deal_share(row)
    return row.market and row.lowest and row.market > 0 and row.lowest / row.market or nil
end

local function read_eye_room()
    return library.read_size(2)
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
    local page = watch_page
    line.row = row
    local columns, x = page.table.columns, page.table.pad
    library.update_item_row(line, { icon = row.icon, id = row.item, name = row.name, quality = row.quality }, x, x + columns.rights[1])
    line.level:SetText(vga.read_level_text(vga.read_item_level(row.item)))
    library.update_money(line.lowest, math.floor((row.lowest or 0) + 0.5))
    line.lowest:SetShown(row.lowest ~= nil)
    library.update_money(line.market, math.floor((row.market or 0) + 0.5))
    line.market:SetShown(row.market ~= nil)
    library.update_chip(line.chip, vga.read_deal(row.lowest or 0, row.market))
    library.update_eye_layout(line.eye)
    library.update_eye_shown(line.eye, true)
    library.update_grid_columns(line, columns, x, { { line.level, 2 }, { line.lowest, 3, "right" }, { line.market, 4, "right" }, { line.chip, 5 }, { line.eye, 6, "right" } })
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
    local line = library.create_item_row(parent, { on_enter = render_row_tip, on_leave = vga.update_item_tip_hidden })
    line.level = library.create_text(line, "figures_small", colours.label)
    line.lowest = library.create_money(line, colours.ink)
    line.market = library.create_money(line, colours.quiet)
    line.chip = library.create_chip(line)
    line.eye = library.create_eye(line, function() render_unwatched(line) end, { library.texts.watch_on, library.texts.watch_off })
    return line
end

local function render_watch_sorted()
    vga.update_watch_page(watch_page, watch_page.full_width)
end

function vga.create_watch_page(page)
    local texts = library.texts
    watch_page = page
    local columns = {
        { key = "item", word = texts.item, sort = read_name, inset = "icon" },
        { key = "level", word = texts.level, sort = read_level, least = "60" },
        { key = "lowest_now", word = texts.lowest_now, sort = read_lowest, least = "money", x = "right" },
        { key = "market_value", word = texts.market_value, sort = read_market, least = "money", x = "right" },
        { key = "to_market", word = texts.to_market, sort = read_deal_share, least = "chip" },
        { key = "eye", least = read_eye_room },
    }
    page.table = library.create_item_table(page, { columns = columns, create_row = create_watch_row, update_row = update_watch_row, empty = texts.watched_empty, on_sort = render_watch_sorted })
    page.list, page.heads, page.empty, page.group = page.table.list, page.table.heads, page.table.empty, page.table
    page.lines = page.list.rows
end

function vga.update_watch_page(page, width)
    page.full_width = width
    page.table:ClearAllPoints()
    page.table:SetPoint("TOPLEFT", page, "TOPLEFT")
    local least = library.read_draft_size(28) + 3 * library.read_draft_size(40)
    library.update_item_table(page.table, read_rows(), width, math.max(page:GetHeight(), least))
end
