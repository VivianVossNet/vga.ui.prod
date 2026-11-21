-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's history graph as the accepted draft draws it (manual/view/vga-auctions.html, K0603, K0617), built of the game's lines the way the experience bar's tooltip draws its graphs: bars along the foot for a quantity, a band between two series - the day's lowest and median - drawn smooth as trapezoids from day to day, and lines for series, solid or dashed in true dashes of four draft pixels and gaps of three along their length, as the draft draws them (K0640); the values scaled between the lowest and the highest shown, the band's included, so nothing is drawn outside the graph, which clips its pieces too, the bars to the lower third; an optional note in its middle where there is too little to draw (K0628) - then none of the few real values is drawn, only a faint sample graph behind the note, so nothing looks broken and the player sees what is to come (K0634).

-- {K0617} {K0628} {K0634} {K0640}

local library = LibVGA
local BAR_SHARE = 0.3
local DASH, DASH_GAP = 4, 3

function library.create_graph(parent)
    local graph = CreateFrame("Frame", nil, parent)
    graph.ground = graph:CreateTexture(nil, "BACKGROUND")
    graph.ground:SetAllPoints()
    graph.ground:SetColorTexture(0, 0, 0, 0)
    graph:SetClipsChildren(true)
    graph.note = library.create_text(graph, "small", library.colours.quiet)
    graph.note:SetPoint("CENTER")
    graph.lines, graph.bars, graph.band = {}, {}, {}
    return graph
end

local function read_piece(pool, graph, kind)
    pool.used = (pool.used or 0) + 1
    if not pool[pool.used] then
        pool[pool.used] = kind == "line" and graph:CreateLine(nil, "ARTWORK") or graph:CreateTexture(nil, "BORDER")
    end
    pool[pool.used]:Show()
    return pool[pool.used]
end

local function update_unused(pool)
    for index = (pool.used or 0) + 1, #pool do pool[index]:Hide() end
    pool.used = 0
end

local function read_range(data)
    local least, most = math.huge, -math.huge
    local lists = {}
    for _, series in ipairs(data.series) do lists[#lists + 1] = series.values end
    if data.band then lists[#lists + 1], lists[#lists + 2] = data.band.low, data.band.high end
    for _, values in ipairs(lists) do
        for _, value in pairs(values) do least, most = math.min(least, value), math.max(most, value) end
    end
    if least == math.huge then return 0, 1 end
    if most - least < 1 then return least - 1, most + 1 end
    return least, most
end

local function write_segment(graph, from, to, colour, thickness)
    local line = read_piece(graph.lines, graph, "line")
    line:SetThickness(thickness)
    line:SetColorTexture(colour[1], colour[2], colour[3], colour[4] or 1)
    line:SetStartPoint("BOTTOMLEFT", graph, from[1], from[2])
    line:SetEndPoint("BOTTOMLEFT", graph, to[1], to[2])
end

local function write_dashes(graph, from, to, colour, thickness)
    local dash, gap = library.read_draft_size(DASH), library.read_draft_size(DASH_GAP)
    local x, y = to[1] - from[1], to[2] - from[2]
    local length = math.sqrt(x * x + y * y)
    local done = graph.dash_left or 0
    while done < length do
        local finish = math.min(done + dash, length)
        write_segment(graph, { from[1] + x * done / length, from[2] + y * done / length }, { from[1] + x * finish / length, from[2] + y * finish / length }, colour, thickness)
        done = finish + gap
    end
    graph.dash_left = done - length
end

local function update_series(graph, series, read_place)
    local before
    graph.dash_left = 0
    for index = 1, graph.count do
        local value = series.values[index]
        if value then
            local point = read_place(index, value)
            if before and series.dashed then write_dashes(graph, before, point, series.colour, series.thickness or 1.5) end
            if before and not series.dashed then write_segment(graph, before, point, series.colour, series.thickness or 1.5) end
            before = point
        end
    end
end

local function write_trapezoid(graph, band, first, second)
    local top, bottom = math.max(first.high[2], second.high[2]), math.min(first.low[2], second.low[2])
    local piece = read_piece(graph.band, graph)
    piece:SetColorTexture(band.colour[1], band.colour[2], band.colour[3], band.colour[4])
    piece:ClearAllPoints()
    piece:SetPoint("BOTTOMLEFT", graph, "BOTTOMLEFT", first.low[1], bottom)
    piece:SetSize(math.max(1, second.low[1] - first.low[1]), math.max(1, top - bottom))
    piece:SetVertexOffset(UPPER_LEFT_VERTEX or 1, 0, first.high[2] - top)
    piece:SetVertexOffset(LOWER_LEFT_VERTEX or 2, 0, first.low[2] - bottom)
    piece:SetVertexOffset(UPPER_RIGHT_VERTEX or 3, 0, second.high[2] - top)
    piece:SetVertexOffset(LOWER_RIGHT_VERTEX or 4, 0, second.low[2] - bottom)
end

local function update_band(graph, band, read_place)
    local before
    for index = 1, graph.count do
        local low, high = band.low[index], band.high[index]
        if low and high then
            local corner = { low = read_place(index, low), high = read_place(index, high) }
            if before then write_trapezoid(graph, band, before, corner) end
            before = corner
        end
    end
end

local function update_bars(graph, bars, height, step)
    local most = 1
    for _, value in pairs(bars.values) do most = math.max(most, value) end
    for index = 1, graph.count do
        local value = bars.values[index]
        if value and value > 0 then
            local piece = read_piece(graph.bars, graph)
            piece:SetColorTexture(bars.colour[1], bars.colour[2], bars.colour[3], bars.colour[4] or 1)
            piece:ClearAllPoints()
            piece:SetPoint("BOTTOMLEFT", graph, "BOTTOMLEFT", (index - 1) * step + step * 0.15, 0)
            piece:SetSize(step * 0.7, math.max(1, height * BAR_SHARE * value / most))
        end
    end
end

local SAMPLE = { 52, 50, 55, 53, 58, 56, 54, 59, 62, 60, 57, 61, 64, 62, 66, 63, 61, 65, 68, 66, 64, 67, 70, 68, 71, 69, 72, 70, 74, 72 }
local SAMPLE_BARS = { 3, 5, 2, 6, 4, 3, 5, 7, 4, 3, 6, 5, 4, 7, 3, 5, 6, 4, 5, 8, 4, 6, 5, 3, 7, 5, 6, 4, 7, 6 }
local SAMPLE_ALPHA = 0.12

local function read_sample(data)
    local low, high, bars = {}, {}, {}
    for index, value in ipairs(SAMPLE) do low[index], high[index], bars[index] = value - 6, value + 4, SAMPLE_BARS[index] end
    local series = {}
    for index, given in ipairs(data.series) do
        local colour = given.colour
        series[index] = { values = index == 1 and SAMPLE or high, colour = { colour[1], colour[2], colour[3], SAMPLE_ALPHA }, dashed = given.dashed, thickness = given.thickness }
    end
    local band = data.band and { low = low, high = SAMPLE, colour = { data.band.colour[1], data.band.colour[2], data.band.colour[3], SAMPLE_ALPHA / 2 } }
    local bar = data.bars and { values = bars, colour = { data.bars.colour[1], data.bars.colour[2], data.bars.colour[3], SAMPLE_ALPHA * 2 } }
    return { count = #SAMPLE, series = series, band = band, bars = bar }
end

function library.update_graph(graph, data, width, height)
    local note = data.note
    if note then data = read_sample(data) end
    graph:SetSize(width, height)
    graph.count = math.max(data.count, 2)
    graph.note:SetText(note or "")
    graph.note:SetShown(note ~= nil)
    local least, most = read_range(data)
    local step = width / graph.count
    local foot = height * BAR_SHARE
    local function read_place(index, value)
        return { (index - 0.5) * step, foot + (height - foot - library.read_size(-4)) * (value - least) / (most - least) }
    end
    if data.bars then update_bars(graph, data.bars, height, step) end
    if data.band then update_band(graph, data.band, read_place) end
    for _, series in ipairs(data.series) do update_series(graph, series, read_place) end
    for _, pool in ipairs({ graph.lines, graph.bars, graph.band }) do update_unused(pool) end
end
