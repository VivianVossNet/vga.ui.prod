-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's slim progress as the accepted draft draws .bar (manual/view/vga-auctions.html, K0632): four draft pixels high, fully rounded, a grey track and the done share in gold over it.

-- {K0632}

local library = LibVGA
local colours = library.colours
local HEIGHT = 4

function library.create_progress(parent)
    local progress = CreateFrame("Frame", nil, parent)
    progress.track = library.create_surface(progress, "BACKGROUND", 0)
    progress.done = CreateFrame("Frame", nil, progress)
    progress.done:SetPoint("TOPLEFT")
    progress.done:SetPoint("BOTTOMLEFT")
    progress.fill = library.create_surface(progress.done, "ARTWORK", 0)
    return progress
end

function library.update_progress(progress, share, width)
    local height = math.max(2, library.read_draft_size(HEIGHT))
    progress:SetSize(width, height)
    progress.done:SetWidth(math.max(height, width * math.min(math.max(share, 0), 1)))
    library.update_surface(progress.track, 0, height / 2, colours.edge, colours.edge)
    library.update_surface(progress.fill, 0, height / 2, colours.gold, colours.gold)
end
