-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.ui's one settings dialog as the accepted draft orders it (manual/view/vga-settings.html), standing high on the screen, its top fixed, as tall as its tallest tab, whichever is shown, so no content ever changes the dialog's size (K0637), as wide as its sidebar and its widest page: at the left a sidebar in the way of the macOS System Settings (Sidebar.lua, K0565) - Darstellung: Allgemein; Im Kampf: Einheiten, Plaketten, Bögen, Schadensmesser (K0721); Leisten: Aktionsleisten, Erfahrung; Welt: Quests, Minimap, Taschen; set apart Anordnen and Profile -, at the right the chosen page under its title, at most seven rows a page; Allgemein ending in the red »Alles zurücksetzen …«, which asks once; the last tab, Anordnen, reached from everywhere, with the alignment - free or on a grid of eight or of sixteen pixels - and the gold »Anordnen …«, which closes the dialog and shows the handles; every choice working at once - a new face measured again a moment later, when the game has loaded its file, so that every width follows it; the one menu there is - a widget's gold corner opens it on the widget's tab, the widget's own settings in the group »Widgets« at the tab's foot; and the command /vga. The units' page switches the game's own »Ziel des Ziels« (showTargetOfTarget, K0696), out of combat. The page Komfort, with the star, gathers the game's own conveniences, out of combat: »Schnell plündern« (autoLootDefault, K0705) and »Zauber auf Fenster unter der Maus« (enableMouseoverCast, K0697), moved there from the bags' and the units' pages (K0712).

-- {K0268} {K0311} {K0316} {K0324} {K0330} {K0337} {K0383} {K0384} {K0430} {K0565} {K0637} {K0696} {K0697} {K0705} {K0712} {K0721}

local library = LibVGA

local settings
local ORDER = { "mainbar", "experience", "arcs", "meter", "quests", "bags", "map" }
local GROUPS = {
    { title = "appearance", keys = { "general" } },
    { title = "in_fight", keys = { "units", "plates", "arcs", "meter" } },
    { title = "bars", keys = { "mainbar", "experience" }, names = { mainbar = "action_bars" } },
    { title = "world", keys = { "quests", "map", "bags" } },
    { keys = { "comfort" } },
    { keys = { "arrange", "profiles" } },
}
local FROM_TOP = 0.12
local FONT_LOADED = 0.3

local function update_height()
    local tallest = 0
    for _, page in pairs(settings.pages) do tallest = math.max(tallest, page.wanted or 0) end
    if tallest > 0 then settings:SetHeight(settings.frame_height + tallest) end
end

local function update_tab(name)
    settings.chosen = name
    settings.heading:SetText(settings.titles[name] or "")
    for key, page in pairs(settings.pages) do
        page:SetShown(key == name)
    end
    update_height()
end

local function update_top(dialog)
    dialog:StopMovingOrSizing()
    local left, top = dialog:GetLeft(), dialog:GetTop()
    dialog:ClearAllPoints()
    dialog:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
end

local function read_switch_order(labels)
    local texts = library.texts
    if #labels ~= 2 then return nil end
    if labels[1] == texts.off and labels[2] == texts.on then return 2 end
    if labels[1] == texts.on and labels[2] == texts.off then return 1 end
    return nil
end

function library.create_choice_row(page, label, labels, chosen, on_choose)
    local row = library.create_row(page, label)
    local on_index = read_switch_order(labels)
    if on_index then
        row.control = library.create_switch(row, chosen == on_index, function(on) on_choose(on and on_index or 3 - on_index) end)
        row.control.on_index = on_index
        return row
    end
    row.control = library.create_choice(row, labels, chosen, on_choose)
    return row
end

local function update_arranging()
    settings:Hide()
    library.update_edit(true, true)
end

local function update_reset_all()
    library.update_reset()
    library.render_settings_anew()
end

local function create_general_page(page)
    local texts = library.texts
    local sizes = { "small", "medium", "large" }
    local size = library.create_choice_row(page, texts.interface_size, { texts.small, texts.medium, texts.large }, ({ small = 1, medium = 2, large = 3 })[LibVGASettings.size] or 2, function(index)
        LibVGASettings.size = sizes[index]
        library.update_elements()
    end)
    local faces_row = library.create_row(page, "", "wide")
    local samples, chosen = {}, 1
    for index, key in ipairs(library.face_order) do
        local name, plain = library.read_face(key)
        samples[index] = { label = name, sample = "Ag", face = plain }
        if key == (LibVGASettings.face or "geologica") then chosen = index end
    end
    faces_row.control = library.create_pictures(faces_row, samples, chosen, function(index)
        library.update_choice_setting("face", library.face_order[index])
        C_Timer.After(FONT_LOADED, library.update_elements)
    end, "tile")
    local frames = library.create_row(page, texts.background)
    frames.control = library.create_slider(frames, library.ground_stops, library.read_ground(), function(value)
        LibVGASettings.ground = value
        library.update_grounds()
    end)
    frames.control.on_settle = library.update_elements
    local dialogs = library.create_row(page, texts.dialogs)
    dialogs.control = library.create_slider(dialogs, library.dialog_stops, library.read_dialog_ground(), function(value)
        LibVGASettings.dialog = value
        library.update_elements()
    end)
    local faces = library.create_choice_row(page, texts.portraits, { texts.animated, texts.still_picture }, library.read_faces_moving() and 1 or 2, function(index)
        library.update_choice_setting("faces", index == 1 and "moving" or "still")
    end)
    local cursor = library.create_choice_row(page, texts.cursor, { texts.off, texts.on }, library.read_cursor_trail() and 2 or 1, function(index)
        library.update_choice_setting("cursor", index == 2 and "on" or "off")
    end)
    local reset = library.create_button(page, texts.reset_all, "alarm", update_reset_all)
    reset.ask = texts.reset_sure
    local font = library.create_row(page, texts.font, "heading")
    font.members = { faces_row }
    page.rows = { font, faces_row, size, frames, dialogs, faces, cursor }
    page.foot = { reset }
end

local function write_target_of_target(index)
    if InCombatLockdown() then return end
    SetCVar("showTargetOfTarget", index == 1 and "1" or "0")
    library.update_elements()
end

local AURA_PLACES = { "frame", "top", "both" }

local function create_auras_row(page, word, key)
    local texts, chosen = library.texts, 1
    for index, place in ipairs(AURA_PLACES) do
        if place == (LibVGASettings[key] or "frame") then chosen = index end
    end
    return library.create_choice_row(page, word, { texts.at_frame, texts.top, texts.both }, chosen, function(index)
        library.update_choice_setting(key, AURA_PLACES[index])
    end)
end

local function write_mouseover_cast(index)
    if InCombatLockdown() then return end
    SetCVar("enableMouseoverCast", index == 1 and "1" or "0")
end

local function create_units_page(page)
    local texts = library.texts
    page.rows = {
        library.create_choice_row(page, texts.values, { texts.absolute, texts.percent }, library.read_values_percent() and 2 or 1, function(index)
            library.update_choice_setting("values", index == 2 and "percent" or "absolute")
        end),
        library.create_choice_row(page, texts.target_of_target, { texts.on, texts.off }, GetCVarBool("showTargetOfTarget") and 1 or 2, write_target_of_target),
        create_auras_row(page, texts.buffs_player, "buffs_player"),
        create_auras_row(page, texts.buffs_target, "buffs_target"),
    }
    for _, row in ipairs(library.create_widget_rows(page, "units", {
        { key = "units", title = texts.unit_frames },
        { key = "party", title = texts.party },
    })) do page.rows[#page.rows + 1] = row end
end

local function create_plates_page(page)
    local texts = library.texts
    page.rows = {
        library.create_choice_row(page, texts.level, { texts.shield, texts.number }, library.read_plate_number() and 2 or 1, function(index)
            library.update_choice_setting("plate_level", index == 2 and "number" or "shield")
        end),
        library.create_choice_row(page, texts.friends, { texts.line, texts.frame }, LibVGASettings.friend_style == "frame" and 2 or 1, function(index)
            library.update_choice_setting("friend_style", index == 2 and "frame" or "line")
        end),
        library.create_choice_row(page, texts.guild, { texts.above_name, texts.below_name }, LibVGASettings.friend_name == "above" and 1 or 2, function(index)
            library.update_choice_setting("friend_name", index == 1 and "above" or "below")
        end),
    }
end

local function write_auto_loot(index)
    if InCombatLockdown() then return end
    SetCVar("autoLootDefault", index == 1 and "1" or "0")
end

local function read_seconds_labels()
    local labels = {}
    for seconds = 1, 3 do labels[seconds] = string.format(library.texts.seconds_short, seconds) end
    return labels
end

local function write_tip_fix_after(index)
    LibVGASettings.tip_fix_after = index
end

local function create_comfort_page(page)
    local texts = library.texts
    page.rows = {
        library.create_choice_row(page, texts.auto_loot, { texts.on, texts.off }, GetCVarBool("autoLootDefault") and 1 or 2, write_auto_loot),
        library.create_choice_row(page, texts.mouseover_cast, { texts.on, texts.off }, GetCVarBool("enableMouseoverCast") and 1 or 2, write_mouseover_cast),
        library.create_choice_row(page, texts.tip_fix_after, read_seconds_labels(), LibVGASettings.tip_fix_after or 3, write_tip_fix_after),
    }
end

local function create_arrange_page(page)
    local texts = library.texts
    page.rows = {
        library.create_choice_row(page, texts.alignment, { texts.free, texts.grid, texts.grid16 }, ({ grid = 2, grid16 = 3 })[LibVGASettings.alignment] or 1, function(index)
            LibVGASettings.alignment = ({ "free", "grid", "grid16" })[index]
        end),
    }
    page.foot = { library.create_button(page, texts.arrange, "gold", update_arranging) }
end

local function read_pages()
    local texts = library.texts
    local pages = {
        { key = "general", title = texts.general, icon = "TabGeneral", build = create_general_page },
        { key = "units", title = texts.units, icon = "TabUnits", build = create_units_page },
        { key = "plates", title = texts.plates, icon = "TabPlates", build = create_plates_page },
        { key = "comfort", title = texts.comfort, icon = "StarFull", build = create_comfort_page },
    }
    for _, key in ipairs(ORDER) do
        local element = library.elements[key]
        if element and element.tab then
            pages[#pages + 1] = { key = key, title = element.title or key, icon = element.icon, build = element.tab }
        end
    end
    pages[#pages + 1] = { key = "arrange", title = texts.arranging, icon = "TabArrange", build = create_arrange_page }
    pages[#pages + 1] = { key = "profiles", title = texts.profiles, icon = "TabProfiles", build = library.create_profiles_page }
    return pages
end

local function read_groups(pages)
    local texts, by_key, groups = library.texts, {}, {}
    for _, entry in ipairs(pages) do by_key[entry.key] = entry end
    for _, group in ipairs(GROUPS) do
        local made = { title = group.title and texts[group.title], entries = {} }
        for _, key in ipairs(group.keys) do
            local entry = by_key[key]
            if entry then made.entries[#made.entries + 1] = { key = key, icon = entry.icon, title = group.names and texts[group.names[key]] or entry.title } end
        end
        if #made.entries > 0 then groups[#groups + 1] = made end
    end
    return groups
end

local function create_settings()
    settings = library.create_dialog("LibVGASettingsDialog", "vga.ui · " .. library.texts.settings)
    settings:HookScript("OnHide", library.update_eyes_closed)
    settings:SetClipsChildren(true)
    library.update_dialog_pin_state(settings, { dropped = update_top })
    settings.pages, settings.order, settings.titles = {}, {}, {}
    local pages = read_pages()
    for index, entry in ipairs(pages) do
        local page = CreateFrame("Frame", nil, settings.body)
        entry.build(page)
        settings.pages[entry.key] = page
        settings.order[index] = entry.key
        settings.titles[entry.key] = entry.title
    end
    settings.titles.mainbar = library.texts.action_bars
    settings.heading = library.create_text(settings.body, "title", library.colours.ink)
    settings.sidebar = library.create_sidebar(settings.body, read_groups(pages), update_tab)
    library.create_element("settings", { update = library.update_settings })
    update_tab("general")
end

local function read_foot_height(page)
    return page.foot and library.read_size(2) + 2 * library.read_size(-2) or 0
end

local function update_foot(page)
    local pad = library.read_size(0)
    for index, button in ipairs(page.foot or {}) do
        library.update_button(button)
        button:ClearAllPoints()
        if index == 1 and button.kind ~= "alarm" then
            button:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", pad, library.read_size(-2))
        else
            button:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -pad, library.read_size(-2))
        end
    end
end

function library.update_settings()
    if not settings then return end
    library.update_dialog(settings)
    local side, gap = library.read_sidebar_width(settings.sidebar), library.read_size(0)
    local side_height = library.update_sidebar(settings.sidebar, settings.chosen)
    settings.heading:SetFontObject(library.read_font("title"))
    local band = math.ceil(settings.heading:GetStringHeight()) + 2 * library.read_size(-2)
    local widest, columns = 0, {}
    for _, key in ipairs(settings.order) do
        local page = settings.pages[key]
        columns[key] = library.update_row_controls(page.rows or {})
        page.wanted = math.max(library.read_rows_height(page.rows or {}) + read_foot_height(page) + band, side_height)
        widest = math.max(widest, library.read_rows_width(page.rows or {}, columns[key]))
    end
    local head, inner = library.read_size(4), library.read_size(-4)
    local width = math.max(side + gap + widest, settings.title:GetStringWidth() + library.read_size(6)) + 2 * inner
    settings.frame_height = head + 1 + 2 * inner
    settings:SetWidth(width)
    settings.sidebar:ClearAllPoints()
    settings.sidebar:SetPoint("TOPLEFT", settings.body, "TOPLEFT")
    settings.sidebar:SetPoint("BOTTOMLEFT", settings.body, "BOTTOMLEFT")
    settings.sidebar:SetWidth(side)
    settings.heading:ClearAllPoints()
    settings.heading:SetPoint("TOPLEFT", settings.body, "TOPLEFT", side + gap, -library.read_size(-2))
    for _, key in ipairs(settings.order) do
        local page = settings.pages[key]
        page:ClearAllPoints()
        page:SetPoint("TOPLEFT", settings.body, "TOPLEFT", side + gap, -band)
        page:SetPoint("BOTTOMRIGHT", settings.body, "BOTTOMRIGHT")
        library.update_rows(page.rows or {}, page, 0, columns[key], width - 2 * inner - side - gap)
        update_foot(page)
    end
    update_height()
end

function library.render_settings_anew()
    local chosen = settings and settings.chosen
    if settings then settings:Hide() end
    settings = nil
    library.render_settings(chosen or "general")
end

function library.render_settings(key)
    if not settings then
        create_settings()
        settings:SetPoint("TOP", UIParent, "TOP", 0, -math.floor(UIParent:GetHeight() * FROM_TOP))
        library.update_settings()
    end
    settings:Show()
    for _, name in ipairs(settings.order) do
        if name == (key or settings.chosen) then
            library.update_sidebar(settings.sidebar, name)
            update_tab(name)
        end
    end
end

SLASH_LIBVGA1 = "/vga"
local function update_from_command(message)
    if (message or ""):lower():match("^%s*edit") then
        library.update_edit(not library.editing, true)
    elseif (message or ""):lower():match("^%s*overlap") then
        library.render_overlaps()
    elseif (message or ""):lower():match("^%s*outline") then
        library.update_choice_setting("plate_outline", LibVGASettings.plate_outline == "light" and "thick" or "light")
    else
        library.render_settings()
    end
end
SlashCmdList.LIBVGA = update_from_command
