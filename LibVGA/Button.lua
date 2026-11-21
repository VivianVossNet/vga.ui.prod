-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's buttons as the accepted draft draws them (manual/view/vga-settings.html, .button): gold for the one action a page offers - »Anordnen …« -, large and in VGA's orange, the mark's, for »Fertig«, which ends arranging, plain metal for the way elsewhere - »Alle Einstellungen …« -, and a quiet red word for what cannot be taken back - »Alles zurücksetzen …«, which asks once before it acts. Every button answers a press: while held its face turns darker, its light at the bottom, and its word sinks a pixel (K0638). A button whose action cannot be done now is shown off - the metal face at half strength, its word in the quiet ink, taking no click (library.update_button_enabled, K0683).

-- {K0383} {K0638} {K0683}

local library = LibVGA
local colours = library.colours
local ALARM = { 0.898, 0.545, 0.471 }
local GOLD_INK = { 0.102, 0.082, 0.043 }
local METAL_TOP = { 0.227, 0.239, 0.267 }
local METAL_BOTTOM = { 0.118, 0.125, 0.145 }
local ASK_SECONDS = 4
local ORANGE_TOP = { 0.969, 0.518, 0.373 }
local ORANGE_BOTTOM = { 0.851, 0.314, 0.184 }
local ORANGE_INK = { 0.102, 0.039, 0.024 }

local function update_pressed(button)
    button.pressed = true
    library.update_button(button)
end

local function update_released(button)
    button.pressed = nil
    library.update_button(button)
end

function library.create_button(parent, text, kind, on_click)
    local button = CreateFrame("Button", nil, parent)
    button.kind, button.words = kind, text
    button.edge = library.create_surface(button, "BACKGROUND", 0)
    button.face = library.create_surface(button, "BACKGROUND", 1)
    button.text = library.create_text(button, "caption")
    button.text:SetPoint("CENTER")
    button.text:SetText(text)
    button:SetScript("OnMouseDown", update_pressed)
    button:SetScript("OnMouseUp", update_released)
    button:SetScript("OnHide", update_released)
    button:SetScript("OnClick", function(self)
        if self.ask and not self.asking then
            self.asking = true
            self.text:SetText(self.ask)
            library.update_button(self)
            C_Timer.After(ASK_SECONDS, function()
                self.asking = false
                self.text:SetText(self.words)
                library.update_button(self)
            end)
            return
        end
        self.asking = false
        self.text:SetText(self.words)
        on_click(self)
    end)
    return button
end

function library.update_button(button)
    local pad, radius = library.read_size(-2), library.read_size(-6)
    local large = button.kind == "orange"
    button.text:SetFontObject(library.read_font(large and "title" or (button.kind == "gold" and "caption" or "small")))
    button:SetSize(math.ceil(button.text:GetStringWidth()) + (large and 4 or 2) * pad + (button.kind == "alarm" and 0 or pad), library.read_size(large and 4 or 2))
    local plain, pressed = button.kind == "alarm", button.pressed and not button.off
    button.text:ClearAllPoints()
    button.text:SetPoint("CENTER", button, "CENTER", 0, pressed and -1 or 0)
    library.update_surface(button.edge, -1, radius + 1, { 0, 0, 0 }, { 0, 0, 0 }, plain and 0 or 1)
    if button.off then
        library.update_surface(button.face, 0, radius, METAL_TOP, METAL_BOTTOM, 0.5)
        button.text:SetTextColor(unpack(colours.quiet))
    elseif large then
        library.update_surface(button.face, 0, radius, pressed and ORANGE_BOTTOM or ORANGE_TOP, pressed and ORANGE_TOP or ORANGE_BOTTOM)
        button.text:SetTextColor(unpack(ORANGE_INK))
    elseif button.kind == "gold" then
        library.update_surface(button.face, 0, radius, pressed and colours.gold or colours.gold_high, pressed and colours.gold_low or colours.gold)
        button.text:SetTextColor(unpack(GOLD_INK))
    else
        library.update_surface(button.face, 0, radius, pressed and METAL_BOTTOM or METAL_TOP, pressed and METAL_TOP or METAL_BOTTOM, plain and 0 or 1)
        button.text:SetTextColor(unpack(plain and ALARM or colours.ink))
    end
end

function library.update_button_enabled(button, on)
    button.off = not on
    button:SetEnabled(on)
    library.update_button(button)
end
