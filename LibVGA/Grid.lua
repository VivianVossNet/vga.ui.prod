-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's grid, as the accepted catalogue draws it (manual/view/vga-catalogue.html, K0775) after the grid's draft (manual/view/vga-grid.html, K0736, K0740): a frame's content laid in rows and columns as CSS grid lays them - each column fixed in draft pixels, as wide as its widest content (»auto«) or the rest of the width (»rest«), a gap between columns, padding around, a text in a column named to be cut held to its column's width and ended in »…« by the game -, every row at least 22 draft pixels high, the height of every box in a row (K0774); every length of a plan - padding, gaps, row, row gap - in draft pixels, or as { pixels = n } where a length is already reckoned on screen, as LibVGA's sizes are (K0800); or at least plan.row where a grid stacks a window's sections, each as high as it is (plan.row = 0, K0798). Alignment is three simple options on the boxes, never on a text's metrics (K0773, K0774): x puts a box at its cell's left edge, middle or right edge; y puts every box's top edge, centre or bottom edge on one line of its row, the centre by default; z lays a region at the back, normal or in front - a texture or a text in the draw layer BACKGROUND, ARTWORK or OVERLAY, a frame at its parent's frame level or one or two above. Rows may be parted by LibVGA's hairline - between them, or with lines = "all" above the first too (K0783) -, which keeps 8 draft pixels above and below it, so no element ever touches it (K0772, K0773). A list's row, whose columns LibVGA's list reckons (library.read_columns, lefts and rights in pixels), lays its cells on them through the same grid - each region at its column's left edge, middle or right edge, on the row's middle line, or on the middle of a band given by its top and height, as a list's column heads (library.update_grid_columns, K0798). A cell may hold several regions, each at the column's alignment or its own x given beside it - a meter row's rank and class picture in one column (K0799) -, plan.gaps names the gap at each column boundary where they differ, and plan.row_gap the room between rows, in draft pixels (K0799). A frame's measure the game keeps secret - on a region laid in a tooltip - counts as none, so the column's or row's own size holds (K0799). A cell may also stack its regions one above the other - { stack = { name, meta }, gap = n }, each at the column's alignment or its own x -, the stack as one box aligned in its row by y; y = "baseline" puts the regions of a row on one line at its foot, the foot of each text's line, so a title and a smaller figure beside it share their line; a frame's content may be laid as sections, several grids one after another, each with its own plan, library.update_grid_sections returning their height, a grid laid from a given top by update_grid's fourth argument; a column named in plan.fill gives its text the column's width and lets it wrap, the width given before the row's height is read, so a wrapped text counts with all its lines (K0801). Every row's top, height and gap, the padding and the hairline's margin lie on whole screen pixels in the frame's own scale (library.read_whole_pixels), so the gaps between rows are the same at every size and UI scale (K0829). The grid is laid anew by its owner at every change of size, face or language; it reports the width and height it took.

-- {K0829} {K0801} {K0800} {K0799} {K0798} {K0776} {K0772} {K0773} {K0774} {K0775} {K0736} {K0740}

local library = LibVGA
local ROW = 22
local HAIRLINE_MARGIN = 8
local LAYERS = { back = "BACKGROUND", normal = "ARTWORK", front = "OVERLAY" }
local LEVELS = { back = 0, normal = 1, front = 2 }
local X_POINTS = { left = "LEFT", middle = "", right = "RIGHT" }
local Y_POINTS = { top = "TOP", middle = "", bottom = "BOTTOM", baseline = "BOTTOM" }
local X_SHARES = { left = 0, middle = 0.5, right = 1 }
local Y_SHARES = { top = 0, middle = 0.5, bottom = 1, baseline = 1 }

function library.read_hairline_margin()
    return library.read_draft_size(HAIRLINE_MARGIN)
end

function library.create_grid(frame, plan)
    return { frame = frame, plan = plan, lines = {} }
end

local function check_text(region)
    return region.GetObjectType and region:GetObjectType() == "FontString"
end

local function read_plain(value)
    if issecretvalue and issecretvalue(value) then return 0 end
    return value or 0
end

local read_stack_size

local function read_region_width(region)
    if region.stack then return (read_stack_size(region)) end
    if region.vga_width then return region.vga_width end
    if check_text(region) then return library.read_string_width(region) end
    return read_plain(region:GetWidth())
end

local function read_region_height(region)
    if region.stack then return select(2, read_stack_size(region)) end
    if check_text(region) then return library.read_string_height(region) end
    return read_plain(region:GetHeight())
end

function library.read_grid_length(length)
    if type(length) == "table" then return length.pixels end
    return library.read_draft_size(length or 0)
end

local function read_padding(plan)
    local padding = plan.padding or { 0, 0, 0, 0 }
    local length = library.read_grid_length
    return { top = length(padding[1]), right = length(padding[2]), bottom = length(padding[3]), left = length(padding[4]) }
end

local function read_stack_item(item)
    if item.GetObjectType then return item, nil end
    return item[1], item[2]
end

function read_stack_size(cell)
    local width, height, gap = 0, 0, library.read_grid_length(cell.gap)
    for index, region in ipairs(cell.stack) do
        local item = read_stack_item(region)
        width = math.max(width, read_region_width(item))
        height = height + read_region_height(item) + (index > 1 and gap or 0)
    end
    return width, height
end

local function read_cell_regions(cell)
    if cell.GetObjectType then return { { cell } } end
    if cell.stack then return { { cell } } end
    local regions = {}
    for index, item in ipairs(cell) do regions[index] = item.GetObjectType and { item } or item end
    return regions
end

local function read_auto_width(rows, column)
    local widest = 0
    for _, row in ipairs(rows) do
        for _, item in ipairs(row[column] and read_cell_regions(row[column]) or {}) do widest = math.max(widest, read_region_width(item[1])) end
    end
    return widest
end

local function read_track_widths(plan, rows)
    local widths, fixed, rests = {}, 0, 0
    for column, track in ipairs(plan.columns) do
        if track == "rest" then
            rests = rests + 1
        else
            widths[column] = track == "auto" and read_auto_width(rows, column) or library.read_grid_length(track)
            fixed = fixed + widths[column]
        end
    end
    return widths, fixed, rests
end

local function read_columns(plan, rows, width, padding)
    local widths, fixed, rests = read_track_widths(plan, rows)
    local gaps, inner = {}, fixed
    for column = 1, #plan.columns - 1 do
        gaps[column] = library.read_grid_length(plan.gaps and plan.gaps[column] or plan.gap)
        inner = inner + gaps[column]
    end
    local rest = rests > 0 and width and math.max(0, (width - padding.left - padding.right - inner) / rests) or 0
    local lefts, x = {}, padding.left
    for column in ipairs(plan.columns) do
        widths[column] = widths[column] or rest
        lefts[column] = x
        x = x + widths[column] + (gaps[column] or 0)
    end
    return lefts, widths, x + padding.right
end

local function read_option(option, column)
    if type(option) == "table" then return option[column] end
    return option
end

local function read_row_height(plan, row)
    local height = library.read_grid_length(plan.row or ROW)
    for _, cell in pairs(row) do
        for _, item in ipairs(read_cell_regions(cell)) do height = math.max(height, read_region_height(item[1])) end
    end
    return height
end

local function update_cut(region, width)
    region:SetWidth(width)
    region:SetWordWrap(false)
end

local function read_point(x, y)
    local point = Y_POINTS[y] .. X_POINTS[x]
    return point == "" and "CENTER" or point
end

local update_cell

local function update_stack(grid, cell, column, box, x)
    local _, height = read_stack_size(cell)
    local y = read_option(grid.plan.y, column) or "middle"
    local top, gap = box.top + (box.height - height) * Y_SHARES[y], library.read_grid_length(cell.gap)
    for _, item in ipairs(cell.stack) do
        local region, own_x = read_stack_item(item)
        local own = { left = box.left, width = box.width, top = top, height = read_region_height(region) }
        update_cell(grid, region, column, own, own_x or x, "top")
        top = top + own.height + gap
    end
end

function update_cell(grid, region, column, box, own_x, own_y)
    local plan = grid.plan
    local x, y = own_x or read_option(plan.x, column) or "left", own_y or read_option(plan.y, column) or "middle"
    if region.stack then return update_stack(grid, region, column, box, own_x) end
    if plan.cut and plan.cut[column] then update_cut(region, box.width) end
    if plan.fill and plan.fill[column] then region:SetWidth(box.width) end
    region:ClearAllPoints()
    region:SetPoint(read_point(x, y), grid.frame, "TOPLEFT", box.left + box.width * X_SHARES[x], -(box.top + box.height * Y_SHARES[y]))
end

local function read_column_x(columns, offset, column, x)
    return offset + columns.lefts[column] + (columns.rights[column] - columns.lefts[column]) * X_SHARES[x]
end

function library.update_grid_columns(frame, columns, offset, cells, band)
    for _, cell in ipairs(cells) do
        local region, x = cell[1], cell[3] or "left"
        local across = read_column_x(columns, offset, cell[2], x) + (cell[4] or 0)
        region:ClearAllPoints()
        if band then
            region:SetPoint(read_point(x, "middle"), frame, "TOPLEFT", across, -(band.top + band.height / 2))
        else
            region:SetPoint(read_point(x, "middle"), frame, "LEFT", across, 0)
        end
    end
end

local function read_line(grid, index)
    grid.lines[index] = grid.lines[index] or library.create_hairline(grid.frame)
    return grid.lines[index]
end

local function update_line(grid, index, top, width)
    local line = read_line(grid, index)
    line:ClearAllPoints()
    line:SetPoint("TOPLEFT", grid.frame, "TOPLEFT", 0, -top)
    line:SetSize(width, 1)
    line:Show()
end

local function update_lines_hidden(grid, from)
    for index = from, #grid.lines do grid.lines[index]:Hide() end
end

local function update_widths_first(plan, row, widths)
    for column, cell in pairs(row) do
        local held = (plan.fill and plan.fill[column]) or (plan.cut and plan.cut[column])
        if held and cell.GetObjectType then cell:SetWidth(widths[column]) end
    end
end

local function update_row(grid, row, top, lefts, widths)
    update_widths_first(grid.plan, row, widths)
    local height = library.read_whole_pixels(read_row_height(grid.plan, row), grid.frame)
    for column, cell in pairs(row) do
        local box = { left = lefts[column], width = widths[column], top = top, height = height }
        for _, item in ipairs(read_cell_regions(cell)) do update_cell(grid, item[1], column, box, item[2]) end
    end
    return height
end

function library.update_grid(grid, rows, width, start)
    local plan, padding = grid.plan, read_padding(grid.plan)
    local lefts, widths, natural = read_columns(plan, rows, width, padding)
    local frame = grid.frame
    local full, margin, used = width or natural, library.read_whole_pixels(library.read_hairline_margin(), frame), 0
    local top = library.read_whole_pixels((start or 0) + padding.top, frame)
    for index, row in ipairs(rows) do
        if index > 1 then top = top + library.read_whole_pixels(library.read_grid_length(plan.row_gap), frame) end
        if plan.lines and (index > 1 or plan.lines == "all") then
            used = used + 1
            update_line(grid, used, top + margin, full)
            top = top + 2 * margin + 1
        end
        top = top + update_row(grid, row, top, lefts, widths)
    end
    update_lines_hidden(grid, used + 1)
    return full, top + padding.bottom - (start or 0)
end

function library.update_grid_sections(sections, width)
    local top = 0
    for _, section in ipairs(sections) do
        local _, height = library.update_grid(section[1], section[2], width, top)
        top = top + height
    end
    return top
end

function library.update_layer(region, depth)
    if region:GetObjectType() ~= "Frame" then return region:SetDrawLayer(LAYERS[depth]) end
    region:SetFrameLevel(region:GetParent():GetFrameLevel() + LEVELS[depth])
end
