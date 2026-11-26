-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: The VGA button on the minimap's rim, as manual/view/vga-probe.html draws .mapc .btn: a small badge as the code forges show them: the original VGA mark at its left, then a label in the dark ground of our widgets with »VGA.RUN« small in white, its corners slightly rounded, where the minimap of vga.ui asks for it, or else on the round rim at the lower right; a click opens the settings for every frame; a red counter at its upper right counts the errors and blocked actions the debug log gathered and nobody has seen, and a click on the counter alone opens the debug console (K0919).

-- {K0919} {K0331} {K0421} {K0424} {K0427} {K0429} {K0431} {K0432}

local library = LibVGA
local WHITE = { 1, 1, 1 }
local GREY_HIGH = { 0.071, 0.075, 0.09 }
local GREY_LOW = { 0.043, 0.047, 0.059 }
local RADIUS = 3
local ANGLE = math.rad(-35)
local COUNTER = 18
local RED = { 0.886, 0.404, 0.353 }
local update_counter

local function render_tip(button)
    GameTooltip:SetOwner(button, "ANCHOR_LEFT")
    GameTooltip:SetText("vga.ui · " .. library.texts.settings)
    GameTooltip:Show()
end

local function delete_tip()
    GameTooltip:Hide()
end

local function render_settings_safely()
    library.update_safely("minimap", library.render_settings)
end

local function render_console_safely()
    library.update_safely("debug console", library.render_debug_opened)
end

local function create_counter(button)
    local counter = CreateFrame("Button", nil, button)
    counter:SetFrameLevel(button:GetFrameLevel() + 2)
    counter.ground = library.create_surface(counter, "BACKGROUND", 0)
    counter.figure = library.create_text(counter, "caption", WHITE)
    counter:SetScript("OnClick", render_console_safely)
    counter:Hide()
    return counter
end

local function create_button()
    local button = CreateFrame("Button", "LibVGAMinimapButton", Minimap)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    button.mark = button:CreateTexture(nil, "ARTWORK")
    button.mark:SetTexture(library.media .. "Mark")
    button.tag = library.create_surface(button, "BACKGROUND", 0)
    button.name = library.create_text(button, "caption", WHITE)
    button.name:SetText("VGA.RUN")
    button:SetScript("OnClick", render_settings_safely)
    button:SetScript("OnEnter", render_tip)
    button:SetScript("OnLeave", delete_tip)
    button.counter = create_counter(button)
    return button
end

local button

local function update_place(width, height)
    button:ClearAllPoints()
    if library.read_minimap_anchor then
        button:SetPoint(library.read_minimap_anchor())
        return
    end
    local reach = Minimap:GetWidth() / 2
    button:SetPoint("CENTER", Minimap, "CENTER", reach * math.cos(ANGLE) + (width - height) / 2, reach * math.sin(ANGLE))
end

function update_counter()
    local counter, unseen = button.counter, library.read_debug_unseen and library.read_debug_unseen() or 0
    counter:SetShown(unseen > 0)
    if unseen == 0 then return end
    local high = library.read_draft_size(COUNTER)
    counter.figure:SetFontObject(library.read_font("caption"))
    counter.figure:SetText(unseen)
    counter:SetSize(math.max(high, math.ceil(counter.figure:GetStringWidth()) + high / 2), high)
    library.update_surface(counter.ground, 0, high / 2, RED, RED)
    counter.figure:SetPoint("CENTER")
    counter:ClearAllPoints()
    counter:SetPoint("CENTER", button, "TOPRIGHT", high / 3, 0)
end

local function update_button()
    local size, pad = library.read_size(1), library.read_size(-5)
    button.name:SetFontObject(library.read_font("caption"))
    local tag = math.ceil(button.name:GetStringWidth()) + 2 * pad
    button:SetSize(size + tag, size)
    update_place(size + tag, size)
    button.mark:SetSize(size, size)
    button.mark:ClearAllPoints()
    button.mark:SetPoint("LEFT")
    library.update_surface(button.tag, 0, RADIUS, GREY_HIGH, GREY_LOW)
    button.name:ClearAllPoints()
    button.name:SetPoint("CENTER", button, "LEFT", size + tag / 2, 0)
    update_counter()
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function()
    if not Minimap then return end
    button = create_button()
    library.create_element("minimap", { update = update_button })
    if library.create_debug_listener then library.create_debug_listener(update_counter) end
    library.update_safely("minimap", update_button)
end)
