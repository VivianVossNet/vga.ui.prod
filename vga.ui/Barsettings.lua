-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: The settings' tab »Leisten« as the accepted drafts order it (manual/view/vga-settings.html, vga-settings-one.html): the form as three picture tiles - Eine Reihe, Zwei Reihen, Frei -, under Eine Reihe the number of bars; a row 1 to 8 choosing a bar, and beneath it, in a fieldset named after it, that bar's own settings - Anzeigen, Tasten je Reihe as pictures of the shape, Größe, Hintergrund -, what the form fixes for bars 1 to 3 greyed with its fixed value; under Frei the game menu and the bag bar as widgets; a bar's gold corner choosing it. Its settings rows with a popup, pictures or a slider are LibVGA's (library.create_popup_row, library.create_pictures_row, library.create_slider_row, K0872).

-- {K0872} {K0382} {K0383} {K0384} {K0385}

local _, vga = ...
local library = LibVGA
local FORMS = { "one", "two", "loose" }
local SIZES = { "small", "normal", "large" }
local DOUBLE_CLICK = 0.35
local FORM_BOX = { 96, 40 }
local FORM_PICTURES = {
    { { 4, 16, 28, 9 }, { 34, 16, 28, 9 }, { 64, 16, 28, 9 } },
    { { 10, 6, 36, 9 }, { 50, 6, 36, 9 }, { 18, 24, 60, 10 } },
    { { 6, 4, 18, 18 }, { 34, 22, 40, 9 }, { 80, 6, 10, 28 } },
}
local SHAPE_BOX = { 18, 14 }
local SHAPES = {
    { { 0, 5, 18, 4 } },
    { { 1, 2, 16, 4 }, { 1, 8, 16, 4 } },
    { { 3, 1, 12, 3 }, { 3, 5.5, 12, 3 }, { 3, 10, 12, 3 } },
    { { 5, 0, 8, 14 } },
    { { 6, 0, 6, 14 } },
    { { 8, 0, 2, 14 } },
}
local page

local function read_form_index()
    if vga.bars.read_loose() then return 3 end
    return vga.bars.read_one_row() and 1 or 2
end

local function read_ground_key(index)
    if vga.bars.check_free(index) then return "bar" .. index end
    return "mainbar"
end

local function read_place(list, wanted)
    for place, value in ipairs(list) do
        if value == wanted then return place end
    end
    return 1
end

local function update_choice_state(control, chosen)
    control.chosen = chosen
    if control.pictures then library.update_pictures(control) else library.update_choice(control) end
end

local function update_bar_rows()
    local index, texts = page.selected, library.texts
    local free = vga.bars.check_free(index)
    local fixed_show = not vga.bars.read_loose() and index < vga.bars.always_free
    page.bar_heading.label:SetText(library.read_capitals(string.format(texts.bar_name, index)))
    update_choice_state(page.show.control, vga.bars.read_shown(index) and 1 or 2)
    update_choice_state(page.keys.control, read_place(vga.bars.columns, vga.bars.read_columns(index)))
    local _, size = library.read_size_step("bar" .. index)
    update_choice_state(page.size.control, free and read_place(SIZES, size) or 2)
    local key = read_ground_key(index)
    page.ground.control.like = LibVGASettings.grounds[key] == nil and texts.like_all or nil
    library.update_slider_value(page.ground.control, library.read_ground(key))
    library.update_slider(page.ground.control)
    library.update_row_enabled(page.show, not fixed_show)
    library.update_row_enabled(page.keys, free)
    library.update_row_enabled(page.size, free)
end

local function update_selected(index)
    page.selected = index
    update_choice_state(page.picker.control, index)
    update_bar_rows()
    library.update_settings()
end

local function write_shown(place)
    LibVGASettings.bars_shown = LibVGASettings.bars_shown or {}
    LibVGASettings.bars_shown[page.selected] = place == 1
    library.update_elements()
    vga.update_bar_bindings()
end

local function write_columns(place)
    LibVGASettings.loose_columns = LibVGASettings.loose_columns or {}
    LibVGASettings.loose_columns[page.selected] = vga.bars.columns[place]
    library.update_elements()
end

local function write_size(place)
    LibVGASettings.sizes["bar" .. page.selected] = SIZES[place]
    library.update_elements()
end

local function write_ground(value)
    LibVGASettings.grounds[read_ground_key(page.selected)] = value
    page.ground.control.like = nil
    library.update_grounds()
end

local function update_ground_reset(control)
    local now = GetTime()
    if control.clicked and now - control.clicked < DOUBLE_CLICK then
        LibVGASettings.grounds[read_ground_key(page.selected)] = nil
        update_bar_rows()
        library.update_elements()
    end
    control.clicked = now
end

local function write_form(index)
    page.count:SetShown(index == 1)
    library.update_choice_setting("mainbar_form", FORMS[index])
    vga.update_bar_bindings()
    update_bar_rows()
end

local function write_count(index)
    library.update_choice_setting("mainbar_count", index == 1 and "two" or "three")
    vga.update_bar_bindings()
    update_bar_rows()
end

local END_KINDS = { "gryphon", "dragon", "wolf", "bear", "lion", "raptor", "knight" }

local function create_end_row(texts, title, key)
    local items = {}
    for index, kind in ipairs(END_KINDS) do items[index] = { kind, texts[kind] } end
    local row = library.create_popup_row(page, title, { { items = items } }, LibVGASettings[key] or "gryphon", function(value)
        library.update_choice_setting(key, value)
    end)
    return row
end

local function write_menu_icons(index)
    library.update_choice_setting("menu_icons", index == 2 and "ours" or "game")
end

local function create_form_rows(texts)
    local labels, pictures = { texts.one_row, texts.two_rows, texts.free }, {}
    for index, rects in ipairs(FORM_PICTURES) do pictures[index] = { box = FORM_BOX, rects = rects, label = labels[index] } end
    local form = library.create_pictures_row(page, "", pictures, read_form_index(), write_form, "tile", "wide")
    page.count = library.create_choice_row(page, texts.bars, { texts.count_two, texts.count_three }, LibVGASettings.mainbar_count == "two" and 1 or 2, write_count)
    page.count:SetShown(read_form_index() == 1)
    page.end_left = create_end_row(texts, texts.end_left, "bar_end_left")
    page.end_right = create_end_row(texts, texts.end_right, "bar_end_right")
    page.menu_icons = library.create_choice_row(page, texts.menu_icons, { texts.game_pictures, texts.vga_icons }, LibVGASettings.menu_icons == "ours" and 2 or 1, write_menu_icons)
    local heading = library.create_row(page, texts.form, "heading")
    heading.members = { form, page.count, page.end_left, page.end_right, page.menu_icons }
    return { heading, form, page.count, page.end_left, page.end_right, page.menu_icons }
end

local function create_bar_rows(texts)
    local numbers, shapes = {}, {}
    for index = 1, vga.bars.count do numbers[index] = tostring(index) end
    for place in ipairs(vga.bars.columns) do shapes[place] = { box = SHAPE_BOX, rects = SHAPES[place] } end
    page.picker = library.create_choice_row(page, texts.bar, numbers, 1, update_selected)
    page.show = library.create_choice_row(page, texts.show, { texts.on, texts.off }, 1, write_shown)
    page.keys = library.create_pictures_row(page, texts.keys_per_row, shapes, 1, write_columns, "shape")
    page.size = library.create_choice_row(page, texts.size, { texts.small, texts.medium, texts.large }, 2, write_size)
    page.ground = library.create_slider_row(page, texts.background, library.ground_stops, library.read_ground(), write_ground)
    page.ground.control.on_settle = library.update_elements
    page.ground.control:HookScript("OnMouseUp", update_ground_reset)
    page.bar_heading = library.create_row(page, "", "heading")
    page.bar_heading.members = { page.show, page.keys, page.size, page.ground }
    return { page.picker, page.bar_heading, page.show, page.keys, page.size, page.ground }
end

local function create_bar_places()
    for index = 1, vga.bars.count do
        library.create_widget_place("bar" .. index, "mainbar", page.bar_heading, function() update_selected(index) end)
    end
    library.create_widget_place("mainbar", "mainbar", page.bar_heading, function() update_selected(1) end)
end

function vga.create_bars_page(built)
    page = built
    page.selected = 1
    local texts = library.texts
    page.rows = {}
    for _, group in ipairs({ create_form_rows(texts), create_bar_rows(texts) }) do
        for _, row in ipairs(group) do page.rows[#page.rows + 1] = row end
    end
    for _, row in ipairs(library.create_widget_rows(page, "mainbar", {
        { key = "menu", title = texts.game_menu, sized = true, when = vga.bars.read_loose },
        { key = "bags", title = texts.bags, sized = true, when = vga.bars.read_loose },
    })) do page.rows[#page.rows + 1] = row end
    create_bar_places()
    update_bar_rows()
end
