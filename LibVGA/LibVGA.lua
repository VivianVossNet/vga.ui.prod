-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's ground: the scale on one curve with one dial, the sizes, the fonts - five faces to choose, Geologica by default, Blizzard's Friz Quadrata from the game itself, in its Cyrillic file, which every client carries and which holds the Latin letters too, Exo 2, Philosopher and Fira Sans - and the colours, the register of elements and the guard that keeps a fault with its place. Every size grows and shrinks with the screen like a rem: the base is the chosen size times the screen's height over 1200 interface units, the height the owner's own screen gives, so his look stays and every other screen keeps the same proportions; a change of the game's scale or the screen lays everything anew. Every kind is kept a second time in the face's figure copy, its digits all one width - the face's own tabular digits made its default ones, since the game cannot switch a font's features (tools/figures/figures.py) -, named »figures_« and the kind, for every field of figures; Philosopher and Friz Quadrata, which have none, take Geologica's (K0789). Every frame face is kept also two pixels smaller and two larger, so an element may offer its own text size - library.read_frame_font(kind, shift) with a shift of -2 or 2 (K0710). An element may name the size it starts at where none was chosen, library.size_defaults[key] - the damage meter starts small (K0732). A text's width and height are read plainly where the game gives them, and where it gives a secret value - on regions laid in an item tooltip - measured again on a hidden FontString on UIParent with the same font and words (library.read_string_width, library.read_string_height, K0758); events heard one by one, an event the game does not know kept as a fault and never stopping the others (library.update_events, K0823); a sample's height or width in a given font on the same hidden FontString (library.read_sample_height, K0781; library.read_sample_width, K0817); where even the hidden one gives a secret value - words the game keeps secret, a damage meter's amounts in a fight -, the measure is 0, never a secret value, so no layout adding it up breaks (K0817). A height the game keeps secret even on the hidden FontString is read as one line of the text's font size, never 0 and never secret, so a chip, a bubble or a row keeps its room - as a quest started by an item showed, whose words' measures were secret (K0845). Events are registered only where the game knows them (C_EventUtils.IsEventValid), so one another version of the game lacks is neither registered nor written as a fault (K0913).

-- {K0913} {K0874} {K0845} {K0823} {K0817} {K0789} {K0758} {K0710} {K0732} {K0294} {K0295} {K0296} {K0297} {K0311} {K0325} {K0384} {K0448}

local NAME = ...
local MEDIA = "Interface\\AddOns\\" .. NAME .. "\\Media\\"
local FONTS = "Interface\\AddOns\\" .. NAME .. "\\Fonts\\"
local STEP = 1.272
local SIZES = { small = 9, medium = 11, large = 14 }
local SMALLEST_TEXT = 9
local REFERENCE_HEIGHT = 1200
local DIALOG_FLOOR = 0.4
local FACES = {
    geologica = { "Geologica", FONTS .. "Geologica-Regular.ttf", FONTS .. "Geologica-Medium.ttf", FONTS .. "GeologicaFigures-Regular.ttf", FONTS .. "GeologicaFigures-Medium.ttf" },
    friz = { "Friz Quadrata", "Fonts\\FRIZQT___CYR.TTF", "Fonts\\FRIZQT___CYR.TTF" },
    exo = { "Exo 2", FONTS .. "Exo2-Regular.ttf", FONTS .. "Exo2-Medium.ttf", FONTS .. "Exo2Figures-Regular.ttf", FONTS .. "Exo2Figures-Medium.ttf" },
    philosopher = { "Philosopher", FONTS .. "Philosopher-Regular.ttf", FONTS .. "Philosopher-Bold.ttf" },
    fira = { "Fira Sans", FONTS .. "FiraSans-Regular.ttf", FONTS .. "FiraSans-Medium.ttf", FONTS .. "FiraSansFigures-Regular.ttf", FONTS .. "FiraSansFigures-Medium.ttf" },
}

LibVGA = LibVGA or {}
local library = LibVGA
library.media = MEDIA
library.DIALOG_FLOOR = DIALOG_FLOOR
library.ground_stops = { 0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1 }
library.dialog_stops = { 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1 }
library.talk_delay_stops = { 0, 0.5, 1, 1.5, 2, 2.5, 3 }
library.talk_delay_default = 1
library.loot_linger_stops = { 0, 1, 2 }
library.loot_linger_default = 1
library.elements = library.elements or {}
library.colours = {
    metal_top = { 0.29, 0.31, 0.34 },
    silver = { 0.788, 0.773, 0.737 },
    metal_bottom = { 0.09, 0.10, 0.11 },
    ground = { 0.05, 0.055, 0.067 },
    head_top = { 0.165, 0.176, 0.2 },
    head_bottom = { 0.102, 0.11, 0.125 },
    line = { 0.137, 0.149, 0.173 },
    ink = { 0.914, 0.902, 0.875 },
    quiet = { 0.604, 0.588, 0.549 },
    greyed = { 0.29, 0.29, 0.29 },
    label = { 0.788, 0.773, 0.737 },
    dark_ink = { 0.102, 0.082, 0.043 },
    threat = { 0.937, 0.416, 0.29 },
    gold = { 0.894, 0.718, 0.314 },
    blue = { 0.31, 0.557, 0.91 },
    gold_high = { 0.965, 0.863, 0.557 },
    gold_low = { 0.612, 0.455, 0.141 },
    orange = { 0.976, 0.565, 0.188 },
    orange_low = { 0.6, 0.29, 0.063 },
    edge = { 0.173, 0.184, 0.208 },
    green = { 0.247, 0.749, 0.353 },
    parchment_gold = { 0.93, 0.79, 0.38 },
    parchment_green = { 0.56, 0.84, 0.61 },
    dark_green = { 0.071, 0.149, 0.059 },
}

function library.read_screen_share()
    local height = UIParent and UIParent:GetHeight()
    if not height or height <= 0 then return 1 end
    return height / REFERENCE_HEIGHT
end

function library.read_base()
    return (SIZES[LibVGASettings and LibVGASettings.size] or SIZES.medium) * library.read_screen_share()
end

function library.read_size(step)
    return math.floor(library.read_base() * STEP ^ step + 0.5)
end

function library.read_ground(key)
    local own = key and LibVGASettings and LibVGASettings.grounds and LibVGASettings.grounds[key]
    return own or (LibVGASettings and LibVGASettings.ground) or 0.75
end

local SIZE_STEPS = { small = 0.8, normal = 1, large = 1.25 }
local SHIFTS = { [-2] = "_less", [2] = "_more" }

library.size_defaults = library.size_defaults or {}

function library.read_size_step(key)
    local chosen = key and LibVGASettings and LibVGASettings.sizes and LibVGASettings.sizes[key] or library.size_defaults[key]
    return SIZE_STEPS[chosen] or 1, SIZE_STEPS[chosen] and chosen or "normal"
end

function library.read_faces_moving()
    return not (LibVGASettings and LibVGASettings.faces == "still")
end

function library.read_eased(share)
    return 1 - (1 - share) ^ 3
end

function library.read_dialog_ground()
    return math.max((LibVGASettings and LibVGASettings.dialog) or 1, library.DIALOG_FLOOR)
end

local fonts = {}

function library.read_font(kind)
    return fonts[kind]
end

function library.read_frame_font(kind, shift)
    local suffix = shift and SHIFTS[shift] or ""
    return fonts["open_" .. kind .. suffix] or fonts["open_" .. kind]
end

library.face_order = { "geologica", "friz", "exo", "philosopher", "fira" }

function library.read_face(key)
    local face = FACES[key or (LibVGASettings and LibVGASettings.face)] or FACES.geologica
    return face[1], face[2] or FACES.geologica[2], face[3] or FACES.geologica[3]
end

function library.read_figure_face()
    local face = FACES[LibVGASettings and LibVGASettings.face] or FACES.geologica
    return face[4] or FACES.geologica[4], face[5] or FACES.geologica[5]
end

local function update_font(name, shape, edge, shift)
    fonts[name] = fonts[name] or CreateFont("LibVGAFont_" .. name)
    fonts[name]:SetFont(shape[1], math.max(SMALLEST_TEXT, library.read_size(shape[2]) + (shift or 0)), edge)
    fonts[name]:SetTextColor(unpack(shape[4] or library.colours.ink))
    fonts[name]:SetShadowColor(0, 0, 0, (edge == "" and shape[4] == nil or name == "number_light") and 0.8 or 0)
    fonts[name]:SetShadowOffset(0, -1)
end

local function read_shapes(plain, medium)
    return {
        tiny = { plain, -2 },
        small = { plain, -1 },
        body = { plain, 0 },
        bold = { medium, 0 },
        title = { medium, 1 },
        caption = { medium, -1 },
        figure = { medium, -1, "OUTLINE" },
        figure_dark = { medium, -1, "", library.colours.dark_ink },
        number = { medium, 1, "THICKOUTLINE" },
        number_light = { medium, 1, "OUTLINE" },
    }
end

local function update_shapes(shapes, prefix)
    local open = library.read_ground() < 0.5
    for name, shape in pairs(shapes) do
        local kind = prefix .. name
        update_font(kind, shape, shape[3] or "")
        update_font("open_" .. kind, shape, shape[3] or (open and "OUTLINE" or ""))
        for shift, suffix in pairs(SHIFTS) do update_font("open_" .. kind .. suffix, shape, shape[3] or (open and "OUTLINE" or ""), shift) end
    end
end

local function update_fonts()
    local _, plain, medium = library.read_face()
    update_shapes(read_shapes(plain, medium), "")
    update_shapes(read_shapes(library.read_figure_face()), "figures_")
end

function library.create_element(key, element)
    library.elements[key] = element
    if library.ready and element.update then
        element.update()
    end
end

function library.read_values_percent()
    local chosen = LibVGASettings and (LibVGASettings.values or LibVGASettings.target_health)
    return chosen == "percent"
end

function library.read_plate_number()
    return not (LibVGASettings and LibVGASettings.plate_level == "shield")
end

function library.read_cursor_trail()
    return LibVGASettings and LibVGASettings.cursor == "on"
end

function library.update_choice_setting(key, value)
    LibVGASettings[key] = value
    library.update_elements()
end

function library.read_unit_name(unit)
    if GetUnitName then return GetUnitName(unit, false) or "" end
    return UnitName(unit) or ""
end

function library.update_safely(name, work, ...)
    local ok, message = xpcall(work, function(fault) return tostring(fault) .. " | " .. (debugstack(2, 4, 0) or "") end, ...)
    if not ok and LibVGASettings then
        LibVGASettings.faults = LibVGASettings.faults or {}
        local held = LibVGASettings.faults[name] or { count = 0 }
        held.count = held.count + 1
        held.message = message:sub(1, 600)
        if library.write_debug then library.write_debug("error", message:match("AddOns[/\\]([^/\\]+)") or "LibVGA", name .. ": " .. message:match("^[^|]*"), message) end
        held.last = time()
        LibVGASettings.faults[name] = held
    end
    return ok
end

local function write_unknown_event(frame, event)
    frame:RegisterEvent(event)
end

local function check_event_known(event)
    local check = C_EventUtils and C_EventUtils.IsEventValid
    return check == nil or check(event)
end

function library.update_events(frame, events)
    for _, event in ipairs(events) do
        if check_event_known(event) then library.update_safely("unknown event " .. event, write_unknown_event, frame, event) end
    end
end

function library.update_element(key)
    local element = library.elements[key]
    if element and element.update then library.update_safely("update " .. key, element.update) end
end

function library.update_elements()
    update_fonts()
    for key, element in pairs(library.elements) do
        if element.update then
            library.update_safely("update " .. key, element.update)
        end
    end
end

function library.create_text(parent, kind, colour)
    local text = parent:CreateFontString(nil, "OVERLAY")
    text:SetFontObject(library.read_font(kind))
    if colour then
        text:SetTextColor(unpack(colour))
    end
    return text
end

local probe

local function read_probe(text)
    probe = probe or UIParent:CreateFontString(nil, "OVERLAY")
    probe:Hide()
    local face, size, flags = text:GetFont()
    if face then probe:SetFont(face, size, flags or "") end
    probe:SetText(text:GetText() or "")
    return probe
end

local function check_plain(value)
    return not (issecretvalue and issecretvalue(value))
end

local function read_plain_measure(value)
    if check_plain(value) then return value or 0 end
    return 0
end

local function read_font_line(region)
    local _, size = region:GetFont()
    if type(size) == "number" and check_plain(size) then return size end
    return 0
end

function library.read_string_width(text)
    local width = text:GetStringWidth()
    if check_plain(width) then return width end
    return read_plain_measure(read_probe(text):GetStringWidth())
end

function library.read_string_height(text)
    local height = text:GetStringHeight()
    if check_plain(height) then return height end
    local measured = read_probe(text):GetStringHeight()
    if check_plain(measured) then return measured or 0 end
    return read_font_line(text)
end

function library.read_sample_width(font, words)
    probe = probe or UIParent:CreateFontString(nil, "OVERLAY")
    probe:Hide()
    probe:SetFontObject(font)
    probe:SetText(words)
    return read_plain_measure(probe:GetStringWidth())
end

function library.read_sample_height(font, words)
    probe = probe or UIParent:CreateFontString(nil, "OVERLAY")
    probe:Hide()
    probe:SetFontObject(font)
    probe:SetText(words)
    local height = probe:GetStringHeight()
    if check_plain(height) then return height or 0 end
    return read_font_line(probe)
end

local KEPT_ON_RESET = { faults = true, measures = true, friendly = true, reach = true }

function library.update_defaults()
    LibVGASettings.size = SIZES[LibVGASettings.size] and LibVGASettings.size or "medium"
    LibVGASettings.font = nil
    LibVGASettings.faults = LibVGASettings.faults or {}
    LibVGASettings.ground = LibVGASettings.ground or 0.75
    LibVGASettings.dialog = LibVGASettings.dialog or 1
    LibVGASettings.places = LibVGASettings.places or {}
    LibVGASettings.grounds = LibVGASettings.grounds or {}
    LibVGASettings.sizes = LibVGASettings.sizes or {}
end

function library.update_reset()
    for key in pairs(LibVGASettings) do
        if not KEPT_ON_RESET[key] then LibVGASettings[key] = nil end
    end
    for key, value in pairs(library.read_defaults()) do LibVGASettings[key] = value end
    library.update_defaults()
    library.update_places_back()
    library.update_places()
    library.update_elements()
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(_, _, loaded)
    if loaded ~= NAME then return end
    library.update_storage()
    library.update_defaults()
    library.ready = true
    library.update_elements()
end)

update_fonts()

local function update_for_screen()
    if InCombatLockdown() then return end
    library.update_elements()
end

local screen = CreateFrame("Frame")
for _, name in ipairs({ "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED" }) do pcall(screen.RegisterEvent, screen, name) end
screen:SetScript("OnEvent", function() library.update_safely("screen", update_for_screen) end)

