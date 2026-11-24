-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: The experience line's tooltips: every text on it explains itself when the mouse has rested on it for a second - the level with the time to the next level beside it, the rested bonus, the system values, the money and the bag slots -; the system values' tooltip carries beneath its words three fine graphs of the last sixty minutes, frame rate, latency and memory, measured every thirty seconds and kept across a reload, each stretch coloured as the line colours its value, so a recent trouble shows at a glance. The bars explain themselves too, after the same second: the experience bar its standing in points, »1.234 / 5.600 Punkte«, the reputation bar - the one bar while a faction is watched, or the lower of both - the faction's name and its standing with the share, »Wohlwollend · 25 %« (K0552).

-- {K0799} {K0388} {K0404} {K0428} {K0455} {K0552}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local DWELL = 1
local waiting, pending
local EVERY = 30
local SPAN = 3600
local BROKEN = 90
local GRAPH_WIDTH = 220
local GRAPH_HEIGHT = 26
local GRAPH_GAP = 6
local GRAPHS = {
    { label = "fps", place = 2, yellow = 30, red = 24, rising = false, floor = 60 },
    { label = "ms", place = 3, yellow = 150, red = 300, rising = true, floor = 360 },
    { label = "MB", place = 4, yellow = 150, red = 300, rising = true, floor = 360 },
}
local graphs

local read_draft = library.read_draft_size

local function write_sample()
    local history = LibVGASettings.history or {}
    LibVGASettings.history = history
    local frames, latency, used = vga.read_system()
    local now = time()
    history[#history + 1] = { now, frames, latency, used }
    while history[1] and now - history[1][1] > SPAN do table.remove(history, 1) end
end

local function write_sample_safely()
    library.update_safely("experience history", write_sample)
end

local function create_graph(parent, entry)
    local graph = CreateFrame("Frame", nil, parent)
    graph.entry = entry
    graph.ground = graph:CreateTexture(nil, "BACKGROUND")
    graph.ground:SetAllPoints()
    graph.ground:SetColorTexture(0, 0, 0, 0.35)
    graph.label = library.create_text(graph, "small", colours.quiet)
    graph.label:SetText(entry.label)
    graph.lines = {}
    return graph
end

local function create_graphs()
    graphs = CreateFrame("Frame", nil, GameTooltip)
    graphs.rows = {}
    for index, entry in ipairs(GRAPHS) do graphs.rows[index] = create_graph(graphs, entry) end
    graphs:Hide()
    GameTooltip:HookScript("OnHide", function() graphs:Hide() end)
end

local function read_line(graph, index)
    graph.lines[index] = graph.lines[index] or graph:CreateLine(nil, "ARTWORK")
    return graph.lines[index]
end

local function read_ceiling(entry, history)
    local highest = entry.floor
    for _, sample in ipairs(history) do highest = math.max(highest, sample[entry.place]) end
    return highest
end

local function update_graph(graph, width, height)
    local entry, history, now = graph.entry, LibVGASettings.history or {}, time()
    local ceiling, drawn = read_ceiling(entry, history), 0
    for index = 2, #history do
        local before, sample = history[index - 1], history[index]
        if sample[1] - before[1] <= BROKEN then
            drawn = drawn + 1
            local line, colour = read_line(graph, drawn), vga.read_warning_colour(sample[entry.place], entry.yellow, entry.red, entry.rising)
            line:SetThickness(1)
            line:SetColorTexture(colour[1], colour[2], colour[3], 0.9)
            line:SetStartPoint("BOTTOMLEFT", graph, width * (1 - (now - before[1]) / SPAN), height * before[entry.place] / ceiling)
            line:SetEndPoint("BOTTOMLEFT", graph, width * (1 - (now - sample[1]) / SPAN), height * sample[entry.place] / ceiling)
            line:Show()
        end
    end
    for index = drawn + 1, #graph.lines do graph.lines[index]:Hide() end
    graph.label:SetFontObject(library.read_font("small"))
    graph.label:ClearAllPoints()
    graph.label:SetPoint("TOPLEFT", graph, "TOPLEFT", read_draft(3), -read_draft(2))
end

local function update_graphs()
    if not graphs then create_graphs() end
    local width, height, gap, pad = read_draft(GRAPH_WIDTH), read_draft(GRAPH_HEIGHT), read_draft(GRAPH_GAP), read_draft(10)
    local total = #graphs.rows * height + (#graphs.rows - 1) * gap
    local stacked = {}
    graphs.grid = graphs.grid or library.create_grid(graphs, { columns = { GRAPH_WIDTH }, row = GRAPH_HEIGHT, row_gap = GRAPH_GAP, y = "top" })
    for index, graph in ipairs(graphs.rows) do
        graph:SetSize(width, height)
        stacked[index] = { graph }
        update_graph(graph, width, height)
    end
    library.update_grid(graphs.grid, stacked)
    GameTooltip:SetWidth(math.max(GameTooltip:GetWidth(), width + 2 * pad))
    GameTooltip:SetHeight(GameTooltip:GetHeight() + total + pad)
    graphs:SetSize(width, total)
    graphs:ClearAllPoints()
    graphs:SetPoint("BOTTOMLEFT", GameTooltip, "BOTTOMLEFT", pad, pad)
    graphs:Show()
end

local function render_tip(hover)
    if not hover.region:IsShown() then return end
    local texts = library.texts
    local reputation = hover.reputation and hover:GetParent().mode == "reputation"
    local title, lines = hover.title, hover.lines
    if reputation then title, lines = hover.reputation[1], { hover.reputation[2] } end
    local heading, words = texts[title], {}
    for index, key in ipairs(lines or {}) do words[index] = texts[key] end
    if hover.read then heading, words = hover.read(hover:GetParent()) end
    GameTooltip:SetOwner(hover, "ANCHOR_TOP")
    GameTooltip:AddLine(heading, colours.gold[1], colours.gold[2], colours.gold[3])
    for _, line in ipairs(words) do GameTooltip:AddLine(line, colours.ink[1], colours.ink[2], colours.ink[3], true) end
    GameTooltip:Show()
    if hover.graphs then update_graphs() end
end

local function render_tip_safely(hover)
    library.update_safely("experience tip", render_tip, hover)
end

local function render_pending()
    waiting = nil
    if pending then render_tip_safely(pending) end
end

local function render_tip_later(hover)
    if waiting then waiting:Cancel() end
    pending = hover
    waiting = C_Timer.NewTimer(DWELL, render_pending)
end

local function update_left()
    if waiting then waiting:Cancel() end
    waiting, pending = nil, nil
    GameTooltip:Hide()
end

local function create_hover(block, region, title, lines, with_graphs, reputation)
    local hover = CreateFrame("Frame", nil, block)
    hover:SetPoint("TOPLEFT", region, "TOPLEFT")
    hover:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT")
    hover:EnableMouse(true)
    if hover.SetMouseClickEnabled then hover:SetMouseClickEnabled(false) end
    hover.title, hover.lines, hover.graphs, hover.reputation, hover.region = title, lines, with_graphs, reputation, region
    hover:SetScript("OnEnter", render_tip_later)
    hover:SetScript("OnLeave", update_left)
    return hover
end

local function render_points(value)
    return BreakUpLargeNumbers and BreakUpLargeNumbers(value) or tostring(value)
end

local function read_reputation_tip()
    local faction = vga.read_watched_reputation()
    if not faction then return library.texts.reputation_short, {} end
    local share = faction.most > 0 and math.min(faction.have / faction.most, 1) or 1
    local standing = _G["FACTION_STANDING_LABEL" .. tostring(faction.reaction)] or ""
    return faction.name, { string.format("%s · %d %%", standing, math.floor(share * 100)) }
end

local function read_experience_tip()
    local have, most = UnitXP("player") or 0, UnitXPMax("player") or 0
    return library.texts.experience, { string.format("%s / %s %s", render_points(have), render_points(most), library.texts.points) }
end

local function read_bar_tip(block)
    if block.mode == "reputation" then return read_reputation_tip() end
    return read_experience_tip()
end

local function create_hovers(block)
    create_hover(block, block.bar).read = read_bar_tip
    create_hover(block, block.second).read = read_reputation_tip
    create_hover(block, block.level, "level", { "tip_level", "tip_time" }, false, { "reputation_short", "tip_reputation" })
    create_hover(block, block.bonus, "tip_bonus_title", { "tip_bonus" }, false, { "faction", "tip_faction" })
    create_hover(block, block.system, "system_values", { "tip_fps", "tip_ms", "tip_mb", "tip_history" }, true)
    create_hover(block, block.money, "money", { "tip_money" })
    create_hover(block, block.slots, "bag_slots", { "tip_slots" })
end

local function create_history()
    write_sample()
    C_Timer.NewTicker(EVERY, write_sample_safely)
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function() library.update_safely("experience history", create_history) end)
vga.create_experience_tips = create_hovers
