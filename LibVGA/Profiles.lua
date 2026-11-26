-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: Each character's own layout and the account's named profiles: a character keeps its settings - places, sizes, grounds, every choice - for itself; a layout is saved under a name for the whole account and loaded by any character; a new character starts with the profile saved or loaded last, the first one after this change with the layout the account had before, and on a fresh installation with the delivered layout; the settings' tab »Profile« - a name and behind it »Speichern«, active only once the name holds at least three characters, each a letter of a European script, a digit, an apostrophe, a hyphen or a space inside it (K0576), then every saved profile with »Laden«, »Überschreiben« - the present layout saved over it - and »Löschen«, the last two asking once; the active profile - the one saved or loaded last - marked by an orange chevron before its name, pointing at it (K0729). The mark that a character's chat font was set to its 12 pixels stays with the character and is never saved in a profile, as the game keeps the chat's font per character, so a new character starting from a profile gets its 12 pixels too (K0730); the same holds for the mark that its chat window was given vga.ui's size once (K0731).

-- {K0794} {K0778} {K0777} {K0387} {K0449} {K0576} {K0729} {K0730} {K0731}

local library = LibVGA
local colours = library.colours
local NOT_IN_PROFILE = { faults = true, measures = true, friendly = true, reach = true, quest_pins = true, history = true, bag_fresh = true, bag_held = true, key_fresh = true, chat_font_set = true, chat_sized = true, plates_simple = true }

local function read_copy(source)
    if type(source) ~= "table" then return source end
    local copy = {}
    for key, value in pairs(source) do copy[key] = read_copy(value) end
    return copy
end

local function read_layout(source)
    local layout = {}
    for key, value in pairs(source or {}) do
        if not NOT_IN_PROFILE[key] then layout[key] = read_copy(value) end
    end
    return layout
end

function library.update_storage()
    LibVGAAccount = LibVGAAccount or {}
    LibVGAAccount.profiles = LibVGAAccount.profiles or {}
    if not LibVGAAccount.legacy and LibVGASettings then LibVGAAccount.legacy = read_layout(LibVGASettings) end
    if not LibVGACharacter then
        local start = LibVGAAccount.profiles[LibVGAAccount.last_profile or ""] or LibVGAAccount.legacy or library.read_defaults()
        LibVGACharacter = read_layout(start)
    end
    LibVGASettings = LibVGACharacter
end

local function write_profile(name)
    LibVGAAccount.profiles[name] = read_layout(LibVGASettings)
    LibVGAAccount.last_profile = name
    library.render_settings_anew()
    library.render_toast({ head = library.texts.settings, line = string.format(library.texts.profile_saved, name) })
end

local function update_profile(name)
    if InCombatLockdown() or not LibVGAAccount.profiles[name] then return end
    for key in pairs(LibVGASettings) do
        if not NOT_IN_PROFILE[key] then LibVGASettings[key] = nil end
    end
    for key, value in pairs(read_layout(LibVGAAccount.profiles[name])) do LibVGASettings[key] = value end
    LibVGAAccount.last_profile = name
    library.update_defaults()
    library.update_places()
    library.update_elements()
    library.render_settings_anew()
    library.render_toast({ head = library.texts.settings, line = string.format(library.texts.profile_loaded, name) })
end

local function delete_profile(name)
    LibVGAAccount.profiles[name] = nil
    if LibVGAAccount.last_profile == name then LibVGAAccount.last_profile = nil end
    library.render_settings_anew()
end

local function create_profile_row(page, name)
    local texts = library.texts
    local row = library.create_row(page, name)
    if LibVGAAccount.last_profile == name then library.create_row_mark(row) end
    row.control = CreateFrame("Frame", nil, row)
    local load = library.create_button(row.control, texts.load, "plain", function() update_profile(name) end)
    local overwrite = library.create_button(row.control, texts.overwrite, "plain", function() write_profile(name) end)
    overwrite.ask = texts.overwrite_sure
    local remove = library.create_button(row.control, texts.delete, "alarm", function() delete_profile(name) end)
    remove.ask = texts.delete_sure
    local gap = library.read_size(-2)
    for _, button in ipairs({ load, overwrite, remove }) do library.update_button(button) end
    remove:SetPoint("RIGHT", row.control, "RIGHT")
    overwrite:SetPoint("RIGHT", remove, "LEFT", -gap, 0)
    load:SetPoint("RIGHT", overwrite, "LEFT", -gap, 0)
    row.control:SetSize(load:GetWidth() + overwrite:GetWidth() + remove:GetWidth() + 2 * gap, load:GetHeight())
    return row
end

local function read_names()
    local names = {}
    for name in pairs(LibVGAAccount.profiles) do names[#names + 1] = name end
    table.sort(names)
    return names
end

local NAME_LEAST = 3
local NAME_MARKS = { [32] = true, [39] = true, [45] = true, [0x2019] = true }
local NAME_SCRIPTS = { { 0x30, 0x39 }, { 0x41, 0x5A }, { 0x61, 0x7A }, { 0xC0, 0xD6 }, { 0xD8, 0xF6 }, { 0xF8, 0x24F }, { 0x370, 0x3FF }, { 0x400, 0x4FF }, { 0x1E00, 0x1EFF } }

local function read_code_point(character)
    local first = character:byte(1)
    if first < 0x80 then return first end
    local code = first % (first >= 0xF0 and 0x08 or first >= 0xE0 and 0x10 or 0x20)
    for index = 2, #character do code = code * 0x40 + character:byte(index) % 0x40 end
    return code
end

local function check_name_character(code)
    if NAME_MARKS[code] then return true end
    for _, range in ipairs(NAME_SCRIPTS) do
        if code >= range[1] and code <= range[2] then return true end
    end
    return false
end

local function read_name(input)
    return (input:GetText() or ""):match("^%s*(.-)%s*$")
end

local function check_name(name)
    local count = 0
    for character in name:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        if not check_name_character(read_code_point(character)) then return false end
        count = count + 1
    end
    return count >= NAME_LEAST
end

local function update_save_enabled(input)
    local valid = check_name(read_name(input))
    input.save:SetEnabled(valid)
    input.save:SetAlpha(valid and 1 or 0.4)
end

local function write_input(input)
    local name = read_name(input)
    if check_name(name) then write_profile(name) end
end

local function create_name_control(row)
    local control = CreateFrame("Frame", nil, row)
    local input = library.create_input(control, { most = 32, on_enter = write_input, on_change = update_save_enabled })
    library.update_input(input, library.read_slider_width())
    input.save = library.create_button(control, library.texts.save, "gold", function() write_input(input) end)
    library.update_button(input.save)
    local gap = library.read_size(-2)
    input:SetPoint("LEFT", control, "LEFT")
    input.save:SetPoint("LEFT", input, "RIGHT", gap, 0)
    control:SetSize(input:GetWidth() + gap + input.save:GetWidth(), math.max(input:GetHeight(), input.save:GetHeight()))
    update_save_enabled(input)
    control.input = input
    return control
end

function library.create_profiles_page(page)
    local texts = library.texts
    local named = library.create_row(page, texts.profile_name)
    named.control = create_name_control(named)
    local heading = library.create_row(page, texts.saved_profiles, "heading")
    page.rows = { named, heading }
    heading.members = {}
    for _, name in ipairs(read_names()) do
        local row = create_profile_row(page, name)
        page.rows[#page.rows + 1] = row
        heading.members[#heading.members + 1] = row
    end
    if #heading.members == 0 then
        local none = library.create_row(page, texts.no_profiles)
        none.label:SetTextColor(unpack(colours.quiet))
        page.rows[#page.rows + 1] = none
        heading.members[1] = none
    end
end
