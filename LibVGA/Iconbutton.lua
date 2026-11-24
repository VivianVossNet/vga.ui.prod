-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's icon button, as the accepted catalogue draws it (manual/view/vga-catalogue.html »Bildknopf«, K0775) after the dialog's head buttons (vga-template.css .vt-x, vga-loot.html Pin): a button showing one picture, in one of two kinds - »head«, a small rounded metal face in a black ring with a light along its top, the picture centred at seven tenths of its size, its hit area four pixels larger than it on every side (K0773), as the dialog's close, pin and further head buttons wear it; »bare«, the picture alone filling the button in a quiet or given tint, as the auction search's star, the quest pin, the minimap's calendar and letter and the page switch's arrows wear it. A button the game must protect is made with the template and name its user gives. Its user names the picture, what a click does and what hovering shows, and lays it with its size (K0792).

-- {K0792} {K0773} {K0775}

local library = LibVGA
local colours = library.colours
local BLACK = { 0, 0, 0 }
local FACE_TOP = { 0.227, 0.239, 0.267 }
local FACE_BOTTOM = { 0.118, 0.125, 0.145 }
local HIT = 4
local PICTURE_SHARE = 0.7

local function create_head(button)
    button.ring = library.create_surface(button, "BACKGROUND", 0)
    button.face = library.create_surface(button, "BACKGROUND", 1)
    button.light = button:CreateTexture(nil, "BORDER")
    button.light:SetColorTexture(1, 1, 1, 0.12)
    button:SetHitRectInsets(-HIT, -HIT, -HIT, -HIT)
end

local function create_picture(button, picture, plan)
    button.picture = button:CreateTexture(nil, "ARTWORK")
    button.picture:SetTexture(library.media .. picture)
    if plan.kind == "head" and not plan.tint then return end
    local tint = plan.tint or colours.quiet
    button.picture:SetVertexColor(tint[1], tint[2], tint[3], 1)
    if plan.kind ~= "head" then button.picture:SetAllPoints() end
end

function library.create_icon_button(parent, picture, on_click, plan)
    local button = CreateFrame(plan.frame or "Button", plan.name, parent, plan.template)
    button.vga_icon_button, button.kind = true, plan.kind or "bare"
    if button.kind == "head" then create_head(button) end
    if picture then create_picture(button, picture, plan) end
    if on_click then button:SetScript("OnClick", on_click) end
    if plan.on_enter then button:SetScript("OnEnter", plan.on_enter) end
    if plan.on_leave then button:SetScript("OnLeave", plan.on_leave) end
    return button
end

local function update_head(button, size)
    local radius = library.read_size(-6)
    library.update_surface(button.ring, -1, radius + 1, BLACK, BLACK)
    library.update_surface(button.face, 0, radius, FACE_TOP, FACE_BOTTOM)
    button.light:ClearAllPoints()
    button.light:SetPoint("TOPLEFT", radius, 0)
    button.light:SetPoint("TOPRIGHT", -radius, 0)
    button.light:SetHeight(1)
    if not button.picture then return end
    local inner = math.floor(size * PICTURE_SHARE + 0.5)
    button.picture:SetSize(inner, inner)
    button.picture:ClearAllPoints()
    button.picture:SetPoint("CENTER")
end

function library.update_icon_button(button, size)
    button:SetSize(size, size)
    if button.kind == "head" then update_head(button, size) end
end
