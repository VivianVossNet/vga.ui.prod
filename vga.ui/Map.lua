-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.ui's minimap as the accepted draft draws it (manual/view/vga-minimap.html): wide - four by three, then forty pixels wider at the normal size, the same share at the others - or square, as the settings choose, small, normal or large, its corners gently rounded, framed as every widget of ours is - the tooltip's look, its outline, black line, dark ground and gold corner -, the game's round frame art put away; the game's own parts - zoom, mail, the queue - left as they are; the map sized and placed in our frame's own scale even where the game gives the minimap a scale of its own, its mouse area cut to the visible part so the square's hidden bands never take the clicks meant for the rims; the frame kept on the screen by the square's upper band too, so the square never reaches past the screen's top, where the game would cut the picture and squeeze the mask; the game's zoom buttons, plus above minus, in the visible map's lower right corner; the whole placed in the screen's upper right corner by default and moved as one while arranging, kept by its outer corner, the game's zone bar put away; only the VGA badge stays with the map, beneath the frame, four draft pixels down, its right edge two pixels in from the frame's lower right corner; the frame widened above and beneath the map by a line each, which Maprim.lua fills; other addons' pins outside the visible map hidden by Mappins.lua; a compass rose in the map, Maprose.lua; every other addon's small button is caught and set beneath the map, left-aligned at the frame's left edge and gathering to the right in slots of one size, a second row begun before it would reach the VGA badge at the right; each button's own gold border and round ground put away, each slot on the map frame's dark ground, the button brought to the slot's layer so our ring lies above it, its icon - the standard library's own, or else the button's largest picture that is no highlight, pressed or ground picture - set to fill the slot but a small inset and cut to a rounded square, any mask of its own taken off, a grey rounded square of ours laid closely round it, lit gold while the mouse rests on the button, the game's blue highlight put away, a button without an icon not shown at all, its tooltip - the game's or the addon library's own - and menu shown left of the frame, forty-eight pixels apart; the tab »Minimap« in the settings.

-- {K0799} {K0793} {K0421} {K0423} {K0424} {K0425} {K0427} {K0429} {K0430} {K0431} {K0432} {K0433} {K0434} {K0435} {K0436} {K0438} {K0439} {K0440} {K0441} {K0442} {K0443} {K0444} {K0445} {K0446} {K0447}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local SIDES = { small = 187, normal = 227, large = 280 }
local SHAPES = { "wide", "square" }
local SIZES = { "small", "normal", "large" }
local MASKS = { wide = "MaskWide", square = "MaskSquare" }
local CORNER = 8 / 170
local BUTTON = 22
local GAP = 4
local RING_INSET = 3
local PAD = 8
local MARGIN = 4
local BADGE_GAP = 4
local BESIDE = 48
local WIDER = 40 / 227
local TRACKING_BORDER = 136430
local ROUND_GROUND = 136467
local BADGE_SHIFT = 2
local ZOOM_GAP = 3
local KEPT_OUT = { LibVGAMinimapButton = true, MinimapBackdrop = true, MinimapZoomIn = true, MinimapZoomOut = true }
local SET_POINT, CLEAR_POINTS, SET_PARENT = UIParent.SetPoint, UIParent.ClearAllPoints, UIParent.SetParent
local frame
local caught = {}

local read_draft = library.read_draft_size

local function read_shape()
    return LibVGASettings.map_shape == "square" and "square" or "wide"
end

local function read_side()
    local _, size = library.read_size_step("map")
    return read_draft(SIDES[size] or SIDES.normal)
end

local function read_visible()
    local side = read_side()
    if read_shape() ~= "wide" then return side, side end
    return math.floor(side * (1 + WIDER) + 0.5), math.floor(side * 0.75 + 0.5)
end

local function update_noop()
end

local function check_catchable(child)
    local name = child.GetName and child:GetName()
    if not name or KEPT_OUT[name] or caught[child] then return false end
    if child:GetObjectType() ~= "Button" and child:GetObjectType() ~= "Frame" then return false end
    return name:find("^LibDBIcon10_") ~= nil or name:find("[Mm]inimap[_]?[Bb]utton") ~= nil
end

local function check_border(region)
    if not region.GetTexture then return false end
    local art = region:GetTexture()
    if art == TRACKING_BORDER or art == ROUND_GROUND then return true end
    return type(art) == "string" and (art:find("TrackingBorder") ~= nil or art:find("Minimap%-Background") ~= nil)
end

local function update_border_away(button)
    for _, region in ipairs({ button:GetRegions() }) do
        if check_border(region) then region:SetAlpha(0) end
    end
end

local function read_area(region)
    return (region:GetWidth() or 0) * (region:GetHeight() or 0)
end

local function read_state_textures(button)
    local states = {}
    for _, reader in ipairs({ "GetHighlightTexture", "GetPushedTexture", "GetNormalTexture", "GetDisabledTexture" }) do
        local state = button[reader] and button[reader](button)
        if state then states[state] = true end
    end
    return states
end

local function read_icon(button)
    if button.icon then return button.icon end
    local found, states = nil, read_state_textures(button)
    for _, region in ipairs({ button:GetRegions() }) do
        if region.GetObjectType and region:GetObjectType() == "Texture" and not states[region] and not check_border(region) and region:GetTexture() then
            if not found or read_area(region) > read_area(found) then found = region end
        end
    end
    return found
end

local function update_beside(shown)
    shown:ClearAllPoints()
    shown:SetPoint("TOPRIGHT", frame.widget, "TOPLEFT", -read_draft(BESIDE), 0)
end

local function update_tip_place(button)
    for _, tip in ipairs({ GameTooltip, LibDBIconTooltip }) do
        if tip and tip:IsShown() and tip:GetOwner() == button then update_beside(tip) end
    end
end

local function update_menu_place()
    local manager = Menu and Menu.GetManager and Menu.GetManager()
    local menu = manager and manager.GetOpenMenu and manager:GetOpenMenu()
    if menu then update_beside(menu) end
    if DropDownList1 and DropDownList1:IsShown() then update_beside(DropDownList1) end
end

local function update_tip_place_safely(button)
    library.update_safely("map tip", update_tip_place, button)
    C_Timer.After(0, function() library.update_safely("map tip", update_tip_place, button) end)
end

local function update_menu_place_soon()
    C_Timer.After(0, function() library.update_safely("map menu", update_menu_place) end)
end

local function update_icon_in_button(slot)
    local button, icon, inset = slot.button, slot.icon, read_draft(RING_INSET)
    if not icon then return end
    icon:ClearAllPoints()
    icon:SetPoint("TOPLEFT", button, "TOPLEFT", inset, -inset)
    icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -inset, inset)
    local light = button.GetHighlightTexture and button:GetHighlightTexture()
    if light and light ~= icon then light:SetAlpha(0) end
end

local function update_ring_lit(slot, lit)
    library.update_cell_lit(slot, lit)
end

local function update_lit(button)
    for _, slot in ipairs(frame.slots) do
        if slot.button == button then update_ring_lit(slot, true) end
    end
end

local function update_unlit(button)
    for _, slot in ipairs(frame.slots) do
        if slot.button == button then update_ring_lit(slot, false) end
    end
end

local function update_icon_again(button)
    for _, slot in ipairs(frame.slots) do
        if slot.button == button then update_icon_in_button(slot) end
    end
end

local function update_icon_again_safely(button)
    library.update_safely("map icon", update_icon_again, button)
end

local function write_caught(button)
    caught[button] = true
    frame.caught[#frame.caught + 1] = button
    local slot = library.create_cell(frame.widget, { kind = "round", frame = "Frame" })
    slot.button = button
    button:HookScript("OnEnter", update_tip_place_safely)
    button:HookScript("OnEnter", update_lit)
    button:HookScript("OnLeave", update_unlit)
    if button.HasScript and button:HasScript("OnClick") then button:HookScript("OnClick", update_menu_place_soon) end
    button:HookScript("OnMouseUp", update_menu_place_soon)
    update_border_away(button)
    slot.icon = read_icon(button)
    library.update_cell_round_mask(slot, slot.icon)
    button:HookScript("OnMouseDown", update_icon_again_safely)
    button:HookScript("OnMouseUp", update_icon_again_safely)
    frame.slots[#frame.slots + 1] = slot
    SET_PARENT(button, slot)
    button:SetFrameStrata(slot:GetFrameStrata())
    button:SetFrameLevel(slot:GetFrameLevel() + 1)
    slot.over:SetFrameLevel(slot:GetFrameLevel() + 3)
    button.SetPoint, button.ClearAllPoints = update_noop, update_noop
    if button.RegisterForDrag then button:RegisterForDrag() end
end

local function update_catch()
    if not frame then return end
    local found = false
    for _, holder in ipairs({ Minimap, MinimapBackdrop }) do
        for _, child in ipairs(holder and { holder:GetChildren() } or {}) do
            if check_catchable(child) then
                write_caught(child)
                found = true
            end
        end
    end
    if found then library.update_elements() end
end

local function update_catch_safely()
    library.update_safely("map catch", update_catch)
end

local function read_map_ratio()
    local own, ours = Minimap:GetEffectiveScale(), frame.widget:GetEffectiveScale()
    if not (own and ours) or own <= 0 then return 1 end
    return ours / own
end

local function update_corner(side, height)
    local pad, ratio = read_draft(PAD), read_map_ratio()
    Minimap:ClearAllPoints()
    Minimap:SetPoint("TOPRIGHT", frame.widget, "TOPRIGHT", -pad * ratio, (-pad - vga.read_map_line() + (side - height) / 2) * ratio)
end

local function update_zoom()
    local zoom_in, zoom_out, gap = Minimap.ZoomIn, Minimap.ZoomOut, read_draft(ZOOM_GAP)
    if not (zoom_in and zoom_out) then return end
    zoom_out:ClearAllPoints()
    zoom_out:SetPoint("BOTTOMRIGHT", frame.view, "BOTTOMRIGHT", -gap, gap)
    zoom_in:ClearAllPoints()
    zoom_in:SetPoint("BOTTOM", zoom_out, "TOP", 0, gap)
end

local function update_blob_rings()
    for _, name in ipairs({ "SetQuestBlobRingScalar", "SetQuestBlobRingAlpha", "SetArchBlobRingScalar", "SetArchBlobRingAlpha", "SetTaskBlobRingScalar", "SetTaskBlobRingAlpha" }) do
        if Minimap[name] then Minimap[name](Minimap, 0) end
    end
end

local function update_map()
    local side, height = read_visible()
    local ratio = read_map_ratio()
    Minimap:SetSize(side * ratio, side * ratio)
    Minimap:SetHitRectInsets(0, 0, (side - height) / 2 * ratio, (side - height) / 2 * ratio)
    update_corner(side, height)
    update_zoom()
    Minimap:SetMaskTexture(library.media .. MASKS[read_shape()])
    update_blob_rings()
    for _, art in ipairs({ MinimapCompassTexture, MinimapCompassTextureUnderlay }) do art:SetAlpha(0) end
    frame.view:ClearAllPoints()
    frame.view:SetPoint("CENTER", Minimap, "CENTER")
    frame.view:SetSize(side, height)
    local zoom = Minimap:GetZoom()
    Minimap:SetZoom(zoom > 0 and zoom - 1 or zoom + 1)
    Minimap:SetZoom(zoom)
end

local function check_filled(slot)
    local button = slot.button
    if not button:IsShown() then return false end
    return slot.icon ~= nil and slot.icon:GetTexture() ~= nil
end

local function read_shown_slots()
    local shown = {}
    for _, slot in ipairs(frame.slots) do
        if check_filled(slot) then shown[#shown + 1] = slot else slot:Hide() end
    end
    return shown
end

local function update_button_in_slot(slot, size)
    local button = slot.button
    button:SetScale(1)
    button:SetSize(size, size)
    CLEAR_POINTS(button)
    SET_POINT(button, "CENTER", slot, "CENTER")
    update_icon_in_button(slot)
    library.update_round_cell(slot, false, library.read_ground("map"))
end


local function read_foot_height()
    return vga.read_map_line()
end

local function read_badge_room()
    local badge = LibVGAMinimapButton
    return badge and badge:GetWidth() or 0
end

local function update_tray(width)
    local shown = read_shown_slots()
    local size, gap = read_draft(BUTTON), read_draft(GAP)
    local room = width - read_badge_room() - BADGE_SHIFT - 2 * gap
    local per_row = math.max(1, math.floor((room + gap) / (size + gap)))
    local columns, rows = {}, {}
    for column = 1, per_row do columns[column] = BUTTON end
    for index, slot in ipairs(shown) do
        local row = math.floor((index - 1) / per_row) + 1
        rows[row] = rows[row] or {}
        rows[row][(index - 1) % per_row + 1] = slot
        slot:SetSize(size, size)
        slot:Show()
        update_button_in_slot(slot, size)
    end
    frame.tray.grid.plan.columns = columns
    frame.tray:ClearAllPoints()
    frame.tray:SetPoint("TOPLEFT", frame.widget, "BOTTOMLEFT", 0, -read_draft(BADGE_GAP))
    library.update_grid(frame.tray.grid, rows)
end

local function update_frame_size()
    local side, height = read_visible()
    local pad = read_draft(PAD)
    local width = side + 2 * pad
    frame.widget:SetSize(width, height + 2 * pad + 2 * read_foot_height())
    frame.widget:SetClampRectInsets(0, 0, math.max(0, (side - height) / 2 - pad - read_foot_height()), 0)
    library.update_frame(frame.widget)
    vga.update_map_rim(frame.view, pad + read_foot_height())
    update_tray(width)
end

local function update_all()
    if not frame then return end
    update_map()
    update_frame_size()
end

function vga.read_map_anchor()
    return "TOPRIGHT", frame.widget, "BOTTOMRIGHT", -BADGE_SHIFT, -read_draft(BADGE_GAP)
end

local function write_shape(index)
    library.update_choice_setting("map_shape", SHAPES[index])
end

local function write_size(index)
    LibVGASettings.sizes.map = SIZES[index]
    library.update_elements()
end

local function read_place(list, wanted)
    for index, value in ipairs(list) do
        if value == wanted then return index end
    end
    return 1
end

local function create_map_page(page)
    local texts = library.texts
    local _, size = library.read_size_step("map")
    page.rows = {
        library.create_choice_row(page, texts.form, { "4 : 3", texts.square_shape }, read_place(SHAPES, read_shape()), write_shape),
        library.create_choice_row(page, texts.size, { texts.small, texts.medium, texts.large }, read_place(SIZES, size), write_size),
    }
end

local function read_minimap_shape()
    return "SQUARE"
end

GetMinimapShape = read_minimap_shape

local function render_options(corner)
    library.update_safely("options", library.render_widget, corner, "map")
end

local function create_map()
    if not (Minimap and MinimapCompassTexture) then return end
    frame = { caught = {}, slots = {} }
    frame.view = CreateFrame("Frame", nil, Minimap:GetParent())
    frame.widget = library.create_frame("VGAMapFrame", Minimap:GetParent())
    frame.tray = CreateFrame("Frame", nil, frame.widget)
    frame.tray:SetSize(1, 1)
    frame.tray.grid = library.create_grid(frame.tray, { columns = {}, gap = GAP, row = BUTTON, row_gap = GAP, y = "top" })
    frame.widget:SetFrameLevel(math.max(0, Minimap:GetFrameLevel() - 1))
    frame.widget.ground_key = "map"
    frame.widget.corner:SetScript("OnClick", render_options)
    frame.widget.place_outer = true
    library.create_place(frame.widget, "map", "TOPRIGHT", UIParent, -read_draft(MARGIN), -read_draft(MARGIN))
    vga.create_map_rim(frame.widget)
    vga.create_map_pins(frame.view)
    vga.create_minimap_signs(frame.view)
    vga.create_map_rose(frame.view)
    library.read_minimap_anchor = vga.read_map_anchor
    if MinimapCluster and MinimapCluster.UpdateMinimapConfig then hooksecurefunc(MinimapCluster, "UpdateMinimapConfig", update_all) end
    library.create_element("map", { title = library.texts.map, icon = "TabMap", update = update_all, tab = create_map_page })
    for _, moment in ipairs({ 1, 3, 8, 20 }) do C_Timer.After(moment, update_catch_safely) end
end

vga.update_map_catch = update_catch_safely

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        library.update_safely("map login", create_map)
    elseif frame then
        C_Timer.After(1, update_catch_safely)
    end
end)
