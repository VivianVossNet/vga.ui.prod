-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's list of switches, the layers panel the accepted world map draws (manual/view/vga-map.html, K0806, K0811): a panel on the pop-up menu's ground, rounded, its rows in groups each under a small quiet heading in capitals, each row a word and LibVGA's switch at its right, laid by LibVGA's grid; a row without anything to show yet greyed and not to be switched. Its owner names the groups, the rows' keys and words, which are on and which can be switched, and hears every change by key. Asked to (widget), it lies on LibVGA's widget frame with the widgets' head - the mark and a title - instead of the menu's ground, its ground's strength its owner's where named, as the minimap's filters do at three quarters (K0954, K0956). A row may carry a picture at its left - a sign of the maps with its tint and strength, or a game's own picture in a round gold-rimmed cell for a race's or class's search -, as the minimap's filters do (K0952).

-- {K0956} {K0954} {K0952} {K0811} {K0806}

local library = LibVGA
local colours = library.colours
local MENU = { 0.102, 0.11, 0.129 }
local WIDTH = 260
local PAD = 10
local GAP = 8
local PICTURE = 22

local function create_picture(holder, row)
    local picture = holder:CreateTexture(nil, "ARTWORK")
    picture:SetTexture(row.picture)
    picture:SetDesaturated(row.tint ~= nil)
    if row.tint then picture:SetVertexColor(row.tint[1], row.tint[2], row.tint[3], 1) end
    picture:SetAlpha(row.faint or 1)
    if row.round then
        holder.disc = holder:CreateMaskTexture()
        holder.disc:SetTexture(library.media .. "Disc", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        holder.disc:SetAllPoints(picture)
        picture:AddMaskTexture(holder.disc)
        holder.ring = library.create_ring(holder, "OVERLAY", 0, picture)
    end
    return picture
end

local function create_row(list, row)
    local made = { key = row.key, enabled = row.enabled ~= false }
    made.holder = CreateFrame("Frame", nil, list)
    made.word = library.create_text(made.holder, "small", colours.ink)
    made.word:SetText(row.word)
    made.word:SetJustifyH("LEFT")
    if row.picture then made.picture = create_picture(made.holder, row) end
    made.switch = library.create_switch(list, row.on, function(on) list.on_change(row.key, on) end)
    made.switch:EnableMouse(made.enabled)
    made.word:SetAlpha(made.enabled and 1 or 0.4)
    made.switch:SetAlpha(made.enabled and 1 or 0.4)
    return made
end

local function create_ground(parent, widget)
    if not widget then
        local list = CreateFrame("Frame", nil, parent)
        list.menu_ground = library.create_surface(list, "BACKGROUND", 0)
        return list
    end
    local list = library.create_frame(nil, parent)
    library.create_frame_head(list, {})
    list.widget_title, list.widget_ground = widget.title, widget.ground
    return list
end

function library.create_switch_list(parent, groups, on_change, widget)
    local list = create_ground(parent, widget)
    list.on_change, list.rows, list.lines = on_change, {}, {}
    for _, group in ipairs(groups) do
        local heading = library.create_text(list, "small", colours.quiet)
        heading:SetText(library.read_capitals(group.heading))
        list.lines[#list.lines + 1] = { heading }
        for _, row in ipairs(group.rows) do
            local made = create_row(list, row)
            list.rows[#list.rows + 1] = made
            list.lines[#list.lines + 1] = { made.holder, made.switch }
        end
    end
    list.grid = library.create_grid(list, { columns = { "rest", "auto" }, gap = GAP, padding = { PAD, PAD, PAD, PAD }, x = { "left", "right" }, row = 26 })
    return list
end

local function update_holder(row)
    local size, gap = library.read_draft_size(PICTURE), library.read_draft_size(GAP)
    local room = row.picture and size + gap or 0
    row.word:SetFontObject(library.read_font("small"))
    row.word:ClearAllPoints()
    row.word:SetPoint("LEFT", row.holder, "LEFT", room, 0)
    row.holder:SetSize(room + math.ceil(library.read_string_width(row.word)), size)
    if not row.picture then return end
    row.picture:SetSize(size, size)
    row.picture:ClearAllPoints()
    row.picture:SetPoint("LEFT", row.holder, "LEFT")
    if row.holder.ring then library.update_ring(row.holder.ring, 1, colours.gold, 1) end
end

function library.update_switch_list_on(list, key, on)
    for _, row in ipairs(list.rows) do
        if row.key == key then
            row.switch.on = on == true
            library.update_switch(row.switch)
        end
    end
end

function library.update_switch_list(list)
    for _, row in ipairs(list.rows) do
        update_holder(row)
        library.update_switch(row.switch)
    end
    local wanted = library.read_draft_size(WIDTH)
    local top = list.widget_title and library.update_frame_head(list, list.widget_title, nil, wanted) or 0
    list.grid.plan.padding = { { pixels = top + library.read_draft_size(PAD) }, PAD, PAD, PAD }
    local width, height = library.update_grid(list.grid, list.lines, wanted)
    list:SetSize(width, height)
    if list.menu_ground then library.update_surface(list.menu_ground, 0, library.read_size(-4), MENU, MENU) else library.update_frame(list, list.widget_ground) end
    return width, height
end
