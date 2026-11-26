-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's map canvas, the object the accepted world map draws (manual/view/vga-map.html, K0806, K0811): a clipped area showing a plane of map units - its pictures on a frame of their own that cuts them at the view's edge, and a part of the plane, its bounds, as the view: a continent of the world map, one view per continent (library.update_map_bounds, K0821) - - for the world map the game's world map 947, zero to one across and down -, its view a centre and a zoom in pixels per unit, kept between the least, where the whole plane fits, and the most its owner names; the mouse wheel zooms about the pointer, a double click zooms in twice as far there, a drag pans; its pictures - files of the game, each with the plane's rectangle it covers - are laid by the canvas from a pool of textures, only those given, the rest hidden and released, so the owner gives only what is in view (library.read_map_view); its marks, regions of the owner's, are set at a plane point by library.update_map_mark. The plane keeps its own proportions: a unit across is the plane's aspect times a unit down (library.update_map_aspect - the world map 947 is 1002 by 668), so the game's art is never squeezed, and the plane fits the canvas whole by its narrower side; a picture may be cropped (its texture coordinates up to s1, t1), carry an alpha, and be cut out by a mask - a picture of the game's laid over its own rectangle as a MaskTexture -; library.read_map_depth gives how many doublings the view is in from the whole plane, from which an owner fades its levels softly into each other (K0819). The owner hears when the view changed, where the pointer stands in plane units, and of a click that did not drag, with its plane point (K0815).

-- {K0821} {K0820} {K0819} {K0815} {K0811} {K0806}

local library = LibVGA
local STEP = 1.25
local DOUBLE = 0.3
local STILL = 4

local function read_canvas_size(canvas)
    return canvas:GetWidth(), canvas:GetHeight()
end

local function read_across(canvas)
    return canvas.zoom * canvas.aspect
end

function library.read_map_view(canvas)
    local width, height = read_canvas_size(canvas)
    local half_width, half_height = width / 2 / read_across(canvas), height / 2 / canvas.zoom
    return canvas.u - half_width, canvas.v - half_height, canvas.u + half_width, canvas.v + half_height
end

local function read_screen_point(canvas)
    local x, y = GetCursorPosition()
    local scale = canvas:GetEffectiveScale()
    return x / scale - (canvas:GetLeft() or 0), (canvas:GetTop() or 0) - y / scale
end

function library.read_map_point(canvas)
    local x, y = read_screen_point(canvas)
    local left, top = library.read_map_view(canvas)
    return left + x / read_across(canvas), top + y / canvas.zoom
end

local function read_least_zoom(canvas)
    local width, height = read_canvas_size(canvas)
    local bounds = canvas.bounds
    return math.max(1, math.min(width / ((bounds[2] - bounds[1]) * canvas.aspect), height / (bounds[4] - bounds[3])))
end

function library.read_map_depth(canvas)
    return math.log(canvas.zoom / read_least_zoom(canvas)) / math.log(2)
end

function library.update_map_aspect(canvas, aspect)
    canvas.aspect = aspect or 1
end

function library.update_map_bounds(canvas, rect)
    canvas.bounds = rect or { 0, 1, 0, 1 }
end

local function read_mask(canvas, mask, left, top)
    canvas.masks[mask.file] = canvas.masks[mask.file] or canvas.ground:CreateMaskTexture()
    local shape = canvas.masks[mask.file]
    shape:SetTexture(mask.file, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    shape:ClearAllPoints()
    shape:SetPoint("TOPLEFT", canvas, "TOPLEFT", (mask.u0 - left) * read_across(canvas), -(mask.v0 - top) * canvas.zoom)
    shape:SetSize((mask.u1 - mask.u0) * read_across(canvas), (mask.v1 - mask.v0) * canvas.zoom)
    return shape
end

local function update_picture_mask(canvas, texture, picture, left, top)
    if texture.vga_mask then texture:RemoveMaskTexture(texture.vga_mask) end
    texture.vga_mask = picture.mask and read_mask(canvas, picture.mask, left, top) or nil
    if texture.vga_mask then texture:AddMaskTexture(texture.vga_mask) end
end

local function update_picture(canvas, texture, picture, left, top)
    texture:SetTexture(picture.file)
    texture:SetTexCoord(0, picture.s1 or 1, 0, picture.t1 or 1)
    texture:ClearAllPoints()
    texture:SetPoint("TOPLEFT", canvas, "TOPLEFT", (picture.u0 - left) * read_across(canvas), -(picture.v0 - top) * canvas.zoom)
    texture:SetSize((picture.u1 - picture.u0) * read_across(canvas), (picture.v1 - picture.v0) * canvas.zoom)
    texture:SetDrawLayer("BACKGROUND", picture.level or 0)
    texture:SetAlpha(picture.alpha or 1)
    update_picture_mask(canvas, texture, picture, left, top)
    texture:Show()
end

function library.update_map_pictures(canvas, pictures)
    local left, top = library.read_map_view(canvas)
    for index, picture in ipairs(pictures) do
        canvas.pool[index] = canvas.pool[index] or canvas.ground:CreateTexture(nil, "BACKGROUND")
        update_picture(canvas, canvas.pool[index], picture, left, top)
    end
    for index = #pictures + 1, #canvas.pool do
        canvas.pool[index]:Hide()
        canvas.pool[index]:SetTexture(nil)
    end
    canvas.pictures = pictures
end

function library.read_map_mark_point(canvas, across, down)
    local left, top = library.read_map_view(canvas)
    return (across - left) * read_across(canvas), (down - top) * canvas.zoom
end

local function read_held(centre, half, low, high)
    if half >= (high - low) / 2 then return (low + high) / 2 end
    return math.max(low + half, math.min(high - half, centre))
end

function library.update_map_view(canvas, across, down, zoom)
    canvas.zoom = math.max(read_least_zoom(canvas), math.min(canvas.most or 1e9, zoom or canvas.zoom))
    local width, height = read_canvas_size(canvas)
    local bounds = canvas.bounds
    canvas.u = read_held(across or canvas.u, width / 2 / read_across(canvas), bounds[1], bounds[2])
    canvas.v = read_held(down or canvas.v, height / 2 / canvas.zoom, bounds[3], bounds[4])
    if canvas.on_view then canvas.on_view(canvas) end
end

local function update_zoom_at_pointer(canvas, factor)
    local across, down = library.read_map_point(canvas)
    local x, y = read_screen_point(canvas)
    local width, height = read_canvas_size(canvas)
    local zoom = canvas.zoom * factor
    library.update_map_view(canvas, across - (x - width / 2) / (zoom * canvas.aspect), down - (y - height / 2) / zoom, zoom)
end

local function render_wheel(canvas, delta)
    update_zoom_at_pointer(canvas, delta > 0 and STEP or 1 / STEP)
end

local function render_pressed(canvas, button)
    if button ~= "LeftButton" then return end
    local x, y = GetCursorPosition()
    canvas.drag = { x = x, y = y, across = canvas.u, down = canvas.v }
    canvas.pressed_at = { x, y }
end

local function check_still(canvas)
    local pressed = canvas.pressed_at
    if not pressed then return true end
    local x, y = GetCursorPosition()
    return math.abs(x - pressed[1]) + math.abs(y - pressed[2]) < STILL
end

local function render_released(canvas, button)
    if canvas.on_click and check_still(canvas) then canvas.on_click(canvas, button, library.read_map_point(canvas)) end
    if button ~= "LeftButton" then return end
    canvas.drag, canvas.pressed_at = nil, nil
    local now = GetTime()
    if canvas.last_click and now - canvas.last_click < DOUBLE then update_zoom_at_pointer(canvas, 2) end
    canvas.last_click = now
end

local function update_dragged(canvas)
    local drag = canvas.drag
    if not drag then return end
    local x, y = GetCursorPosition()
    local scale = canvas:GetEffectiveScale() * canvas.zoom
    library.update_map_view(canvas, drag.across - (x - drag.x) / (scale * canvas.aspect), drag.down + (y - drag.y) / scale)
end

local function update_canvas(canvas)
    if not canvas then return end
    update_dragged(canvas)
    if canvas.on_pointer and canvas.IsMouseOver and canvas:IsMouseOver() then canvas.on_pointer(canvas, library.read_map_point(canvas)) end
end

function library.create_map_canvas(parent, plan)
    local canvas = CreateFrame("Frame", nil, parent)
    canvas:SetClipsChildren(true)
    canvas:EnableMouse(true)
    canvas:EnableMouseWheel(true)
    canvas.pool, canvas.pictures, canvas.masks, canvas.aspect, canvas.bounds = {}, {}, {}, plan.aspect or 1, { 0, 1, 0, 1 }
    canvas.ground = CreateFrame("Frame", nil, canvas)
    canvas.ground:SetAllPoints()
    canvas.ground:SetClipsChildren(true)
    canvas.u, canvas.v, canvas.zoom, canvas.most = 0.5, 0.5, 1, plan.most
    canvas.on_view, canvas.on_pointer, canvas.on_click = plan.on_view, plan.on_pointer, plan.on_click
    canvas.marks = CreateFrame("Frame", nil, canvas)
    canvas.marks:SetAllPoints()
    canvas.marks:SetFrameLevel(canvas:GetFrameLevel() + 2)
    canvas:SetScript("OnMouseWheel", function(self, delta) library.update_safely("map wheel", render_wheel, self, delta) end)
    canvas:SetScript("OnMouseDown", render_pressed)
    canvas:SetScript("OnMouseUp", function(self, button) library.update_safely("map click", render_released, self, button) end)
    canvas:SetScript("OnUpdate", function(self) library.update_safely("map canvas", update_canvas, self) end)
    return canvas
end
