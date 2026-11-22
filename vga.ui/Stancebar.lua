-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.ui's own stance bar, built as the pet bar (Petbar.lua): a protected key of our own for each of the player's stances, forms, auras or presences, each casting its form's spell, dressed as the main bar's keys - rounded, a black line, the icon cropped, edged as the bags' slots - three pixels with gently rounded corners over the icon, the slot's grey, gold while its form is taken -, bound to the player's own stance keys, a click taken on press and on release; shown while the player has a form; standing four pixels above the main bar's widget, its left edge sixteen draft pixels in from the widget's, in the one-row and two-row forms alike, at the bars' scale, free to be placed on its own in the edit mode. Blizzard's stance bar is put away; nothing protected is moved or changed in a fight, a form learnt in one is laid after it. Each key shows the game's tooltip of its form (K0726).

-- {K0377} {K0518} {K0726}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local DRAFT_BASE = 13
local KEYS = 10
local ABOVE = 4
local INWARD = 16
local BLACK = { 0, 0, 0 }
local EDGE_WIDTH = 3
local SLOT_EDGE = { 0.18, 0.192, 0.22 }
local stancebar

local function read_draft(pixels)
    return math.floor(pixels * library.read_base() / DRAFT_BASE + 0.5)
end

local function create_key(index)
    local key = CreateFrame("CheckButton", "VGAStanceKey" .. index, stancebar, "SecureActionButtonTemplate")
    key:SetAttribute("type", "spell")
    key:RegisterForClicks("AnyUp", "AnyDown")
    key.icon = key:CreateTexture(nil, "ARTWORK")
    library.update_cell_picture(key.icon, key, EDGE_WIDTH)
    key.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    key.cooldown = CreateFrame("Cooldown", nil, key, "CooldownFrameTemplate")
    library.update_cell_picture(key.cooldown, key, EDGE_WIDTH)
    key.line = library.create_surface(key, "BACKGROUND", 0)
    key.edge = library.create_ring(key, "OVERLAY", 6, nil, true)
    key.hotkey = library.create_text(key, "caption")
    key:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
    key:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.15)
    vga.create_key_tip(key, "SetShapeshift", index)
    return key
end

local function update_key(key, index)
    local texture, active, castable, spell = GetShapeshiftFormInfo(index)
    key.icon:SetTexture(texture)
    key.icon:SetDesaturated(castable == false)
    library.update_ring(key.edge, EDGE_WIDTH, active and colours.gold or SLOT_EDGE, 1)
    local start, duration, enabled = GetShapeshiftFormCooldown(index)
    if start and duration and (enabled == 1 or enabled == true) then key.cooldown:SetCooldown(start, duration) end
    local binding = GetBindingKey("SHAPESHIFTBUTTON" .. index)
    key.hotkey:SetText(binding and GetBindingText(binding, 1) or "")
    if not InCombatLockdown() then key:SetAttribute("spell", spell) end
end

local function read_count()
    return math.min(GetNumShapeshiftForms and GetNumShapeshiftForms() or 0, KEYS)
end

local function update_keys()
    for index = 1, read_count() do library.update_safely("stance key", update_key, stancebar.keys[index], index) end
end

local function update_layout()
    local size, gap, radius, count = read_draft(30), read_draft(3), 2 * EDGE_WIDTH, read_count()
    stancebar:SetSize(math.max(count * size + (count - 1) * gap, 1), size)
    for index, key in ipairs(stancebar.keys) do
        key:SetShown(index <= count)
        key:SetSize(size, size)
        key:ClearAllPoints()
        key:SetPoint("LEFT", stancebar, "LEFT", (index - 1) * (size + gap), 0)
        library.update_surface(key.line, -1, radius + 1, BLACK, BLACK)
        key.hotkey:SetFontObject(library.read_font("caption"))
        key.hotkey:ClearAllPoints()
        key.hotkey:SetPoint("TOPRIGHT", key, "TOPRIGHT", -read_draft(3), -read_draft(2))
    end
end

local function update_place()
    local widget = vga.read_bars_anchor and vga.read_bars_anchor()
    if (LibVGASettings.places or {}).stancebar or not widget or not widget:GetLeft() then return end
    local scale = VGAActionBar and VGAActionBar:GetScale() or 1
    stancebar:SetScale(scale)
    stancebar:ClearAllPoints()
    stancebar:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", widget:GetLeft() / scale + read_draft(INWARD), (widget:GetTop() + ABOVE) / scale)
end

local function update_bindings()
    ClearOverrideBindings(stancebar)
    for index, key in ipairs(stancebar.keys) do
        for _, binding in ipairs({ GetBindingKey("SHAPESHIFTBUTTON" .. index) }) do
            SetOverrideBindingClick(stancebar, false, binding, key:GetName(), "LeftButton")
        end
    end
end

local function update_kept_away()
    if StanceBar:GetParent() ~= stancebar.hider and not InCombatLockdown() then StanceBar:SetParent(stancebar.hider) end
end

local function update_put_away()
    if not StanceBar then return end
    if not stancebar.kept then
        stancebar.kept = true
        hooksecurefunc(StanceBar, "SetParent", function() library.update_safely("stancebar kept", update_kept_away) end)
    end
    update_kept_away()
end

local function update_stancebar()
    if not stancebar then return end
    update_keys()
    if InCombatLockdown() then return end
    update_put_away()
    update_layout()
    update_place()
end

local function create_stancebar()
    stancebar = CreateFrame("Frame", "VGAStancebar", UIParent, "SecureHandlerStateTemplate")
    stancebar.hider = CreateFrame("Frame")
    stancebar.hider:Hide()
    stancebar.keys = {}
    for index = 1, KEYS do stancebar.keys[index] = create_key(index) end
    RegisterStateDriver(stancebar, "visibility", "[nopossessbar,novehicleui] show; hide")
    library.create_place(stancebar, "stancebar", "BOTTOMLEFT", UIParent, 0, 0)
    library.create_element("stancebar", { update = update_stancebar })
    update_bindings()
end

local events = CreateFrame("Frame")
for _, name in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED", "UPDATE_SHAPESHIFT_FORMS", "UPDATE_SHAPESHIFT_FORM", "UPDATE_SHAPESHIFT_USABLE", "UPDATE_SHAPESHIFT_COOLDOWN", "SPELLS_CHANGED", "UPDATE_BINDINGS" }) do
    pcall(events.RegisterEvent, events, name)
end
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then library.update_safely("stancebar login", create_stancebar) end
    if not stancebar then return end
    if event == "UPDATE_BINDINGS" and not InCombatLockdown() then library.update_safely("stancebar keys", update_bindings) end
    library.update_safely("stancebar", update_stancebar)
end)
