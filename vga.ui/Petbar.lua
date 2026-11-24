-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.ui's own pet bar: ten protected keys of our own on the pet's actions, dressed as the main bar's keys - rounded, a black line, the icon cropped, edged as the bags' slots - three pixels with gently rounded corners over the icon, the slot's grey, gold while an action is on or casts by itself -, bound to the player's own pet keys, a click taken on press and on release, as the game's setting to act on key down asks; shown while there is a pet with a bar; standing centred four pixels above the main bar's widget, at the bars' scale, free to be placed in the edit mode. Blizzard's pet bar is put away; nothing protected is moved in a fight. Each key shows the game's tooltip of its action (K0726).

-- {K0781} {K0377} {K0726}

local _, vga = ...
local library = LibVGA
local KEYS = 10
local ABOVE = 4
local petbar

local read_draft = library.read_draft_size

local function create_key(index)
    local key = library.create_cell(petbar, { kind = "key", name = "VGAPetKey" .. index, template = "SecureActionButtonTemplate" })
    key:SetAttribute("type", "pet")
    key:SetAttribute("action", index)
    key:RegisterForClicks("AnyUp", "AnyDown")
    key:RegisterForDrag("LeftButton")
    key:SetScript("OnDragStart", function() if not InCombatLockdown() then PickupPetAction(index) end end)
    key:SetScript("OnReceiveDrag", function() if not InCombatLockdown() then PickupPetAction(index) end end)
    vga.create_key_tip(key, "SetPetAction", index)
    return key
end

local function update_key(key, index)
    local name, texture, token, active, _, automatic = GetPetActionInfo(index)
    local start, duration, enabled = GetPetActionCooldown(index)
    local binding = GetBindingKey("BONUSACTIONBUTTON" .. index)
    library.update_cell(key, { picture = name and (token and _G[texture] or texture) or nil, active = active or automatic, start = enabled and start or nil, duration = duration, hotkey = binding and GetBindingText(binding, 1) or "" })
end

local function update_keys()
    for index, key in ipairs(petbar.keys) do library.update_safely("pet key", update_key, key, index) end
end

local function update_layout()
    local size, gap = read_draft(30), read_draft(3)
    petbar:SetSize(KEYS * size + (KEYS - 1) * gap, size)
    for index, key in ipairs(petbar.keys) do
        library.update_cell_size(key, size)
        key:ClearAllPoints()
        key:SetPoint("LEFT", petbar, "LEFT", (index - 1) * (size + gap), 0)
    end
end

local function update_place()
    local widget = vga.read_bars_anchor and vga.read_bars_anchor()
    if (LibVGASettings.places or {}).petbar or not widget or not widget:GetLeft() then return end
    local scale = VGAActionBar and VGAActionBar:GetScale() or 1
    petbar:SetScale(scale)
    petbar:ClearAllPoints()
    petbar:SetPoint("BOTTOM", UIParent, "BOTTOMLEFT", (widget:GetLeft() + widget:GetRight()) / 2 / scale, (widget:GetTop() + ABOVE) / scale)
end

local function update_bindings()
    ClearOverrideBindings(petbar)
    for index, key in ipairs(petbar.keys) do
        for _, binding in ipairs({ GetBindingKey("BONUSACTIONBUTTON" .. index) }) do
            SetOverrideBindingClick(petbar, false, binding, key:GetName(), "LeftButton")
        end
    end
end

local function update_kept_away()
    if PetActionBar:GetParent() ~= petbar.hider and not InCombatLockdown() then PetActionBar:SetParent(petbar.hider) end
end

local function update_put_away()
    if not PetActionBar then return end
    if not petbar.kept then
        petbar.kept = true
        hooksecurefunc(PetActionBar, "SetParent", function() library.update_safely("petbar kept", update_kept_away) end)
    end
    update_kept_away()
end

local function update_petbar()
    if not petbar then return end
    update_keys()
    if InCombatLockdown() then return end
    update_put_away()
    update_layout()
    update_place()
end

local function create_petbar()
    petbar = CreateFrame("Frame", "VGAPetbar", UIParent, "SecureHandlerStateTemplate")
    petbar.hider = CreateFrame("Frame")
    petbar.hider:Hide()
    petbar.keys = {}
    for index = 1, KEYS do petbar.keys[index] = create_key(index) end
    RegisterStateDriver(petbar, "visibility", "[@pet,exists,nopossessbar,novehicleui] show; hide")
    library.create_place(petbar, "petbar", "BOTTOMLEFT", UIParent, 0, 0)
    library.create_element("petbar", { update = update_petbar })
    update_bindings()
end

local events = CreateFrame("Frame")
for _, name in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED", "UNIT_PET", "PET_BAR_UPDATE", "PET_BAR_UPDATE_COOLDOWN", "PET_UI_UPDATE", "UPDATE_BINDINGS", "PLAYER_CONTROL_GAINED", "PLAYER_CONTROL_LOST" }) do
    pcall(events.RegisterEvent, events, name)
end
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then library.update_safely("petbar login", create_petbar) end
    if not petbar then return end
    if event == "UPDATE_BINDINGS" and not InCombatLockdown() then library.update_safely("petbar keys", update_bindings) end
    library.update_safely("petbar", update_petbar)
end)
