-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's day bars as the accepted draft draws them (manual/view/vga-auctions.html, page »Verlauf«, .days, K0684): one bar for each day, the oldest at the left, side by side with three draft pixels between them, standing on one line; a day's height its share of the largest amount of all the days, in green above nought and red below, a day without any a low grey bar of three draft pixels; the bars' room given by the caller, so the box never changes its size with the values.

-- {K0684}

local library = LibVGA
local UP = { 0.247, 0.749, 0.353 }
local DOWN = { 0.886, 0.404, 0.353 }
local NONE = { 0.227, 0.243, 0.275 }
local GAP = 3
local LEAST = 3

function library.create_day_bars(parent)
    local bars = CreateFrame("Frame", nil, parent)
    bars.days = {}
    return bars
end

local function read_bar(bars, index)
    bars.days[index] = bars.days[index] or bars:CreateTexture(nil, "ARTWORK")
    return bars.days[index]
end

function library.update_day_bars(bars, values, width, height)
    bars:SetSize(width, height)
    local count, gap, least, largest = #values, library.read_draft_size(GAP), library.read_draft_size(LEAST), 0
    for _, value in ipairs(values) do largest = math.max(largest, math.abs(value)) end
    local wide = (width - gap * (count - 1)) / math.max(count, 1)
    for index, value in ipairs(values) do
        local bar, colour = read_bar(bars, index), value > 0 and UP or (value < 0 and DOWN or NONE)
        bar:SetColorTexture(colour[1], colour[2], colour[3], 1)
        bar:SetSize(math.max(wide, 1), largest > 0 and value ~= 0 and math.max(least, math.abs(value) / largest * height) or least)
        bar:ClearAllPoints()
        bar:SetPoint("BOTTOMLEFT", bars, "BOTTOMLEFT", (index - 1) * (wide + gap), 0)
        bar:Show()
    end
    for index = count + 1, #bars.days do bars.days[index]:Hide() end
end
