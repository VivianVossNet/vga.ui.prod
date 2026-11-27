-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.ui's quest tracker as the accepted draft draws .qw (manual/view/vga-probe.html), at most half the screen's height, a longer list scrolling under its head (Questscroll.lua, K0548), its most height a slider's between a fifth and half the screen (K0550): a quest whose objectives are all done shows its title alone, its struck objectives hidden unless the tab Quests says to show them; a quest with a time limit shows the time left on a small line under its title, the word first and the time after it, so only the line's end changes, green, yellow in the last two minutes, red in the last thirty seconds; a quest whose targets lie in a dungeon carries the game's word Dungeon after its title, quiet grey - by the game's quest tag, or by Questie's dungeon list for the quest's zone -; a widget in the tooltip's look, at least as wide as the draft and wider where a title or objective needs it, at least 250 draft pixels, up to the most width set on the settings' slider, freely between 250 and 384, the default (K0550), a width chosen before as Schmal, Mittel or Breit kept as 250, 320 or 384; an objective longer than that is broken at its words onto further lines, the count on the first, a pixel between its lines, each line of a done one struck through as long as its words - growing towards the screen's middle: its place is kept by its outer corner - the upper right on the right half of the screen, the upper left on the left -, a place saved before by its upper left moved once to its upper right where it stands right -, the VGA mark, »Quests dieser Zone« in gold and the count shown of all in the log in its head; the watched quests whose next target lies in the player's zone, in the order the settings choose - the nearest first, by difficulty, the easiest first, or as watched in the quest log -, at most eight; each with its title in gold and its distance at the right, before the title a kept place for a mark - a green tick on a finished quest, a line arrow turned towards its target on an open one, gold on the nearest open, grey on the rest; its objectives with their counts, each after a small bead in exactly the game's colour of the quest's difficulty, a white light at its upper left and a faint shade at its lower right laid over it, centred under the arrow and on the middle of its line, its words set in where the title's begin, as the game colours it, a thin gold bar under each still open, the finished struck through; the data source at the foot; a left click on a quest opens it in the game's quest log, as Blizzard's tracker does, out of combat; a click on an open quest's arrow makes it the navigation's target instead of the nearest - a second click on the same arrow lets it go, a click on another's takes that one -, kept for each zone on its own: a quest chosen in one zone counts only there and counts again on returning; while a marker the player set stands on the map, every arrow is grey and the navigation follows the marker, and a click on an arrow takes the marker off and that quest becomes the target (K0748); resting on the arrow explains this in a tooltip. The source is automatic - Questie when it is loaded and ready, else the game's own quest log -; Questie's internal modules are read guarded, the game's data standing where they fail. Blizzard's tracker and Questie's own are hidden while it runs - Blizzard's only faded out, never hidden by our hand, since a hide from our code runs the tracker's own updates tainted and the game then refuses it its auras and the map's pins (K0972). Its text size is chosen on the tab Quests, »Schrift: Klein | Mittel | Groß«, Mittel as it always was, Klein and Groß two pixels smaller and larger in every face it uses; every height is measured from its text, so the rows grow with it and nothing runs into anything (K0710). Its settings rows with a slider are LibVGA's (library.create_slider_row, K0872).

-- {K0972} {K0872} {K0802} {K0792} {K0791} {K0789} {K0783} {K0748} {K0710} {K0711} {K0260} {K0370} {K0371} {K0390} {K0401} {K0408} {K0422} {K0424}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local MOST = 8
local YARD = 0.9144
local TITLE = { 0.945, 0.812, 0.431 }
local OBJECTIVE = { 0.788, 0.773, 0.737 }
local DONE = { 0.435, 0.424, 0.4 }
local TRACK = { 0.165, 0.177, 0.2 }
local SOURCE = { 0.525, 0.725, 0.91 }
local TICK = { 0.498, 0.816, 0.416 }
local WIDTH = 300
local MIN_WIDTH = 250
local MOST_WIDTHS = { narrow = 250, middle = 320, wide = 384 }
local WIDTH_MOST = 384
local WIDTH_STEP = 2
local HEIGHT_LEAST = 0.2
local HEIGHT_MOST = 0.5
local HEIGHT_STEP = 0.01
local TIME_GREEN = { 0.37, 0.82, 0.42 }
local TIME_YELLOW = { 0.95, 0.79, 0.25 }
local TIME_RED = { 0.93, 0.27, 0.22 }
local DUNGEON_TAG = 81
local SPACING = 1
local OTHERS = { "ObjectiveTrackerFrame", "Questie_BaseFrame" }
local atan2 = math.atan2 or math.atan
local tracker
local FONT_SHIFTS = { small = -2, large = 2 }
local FONT_SIZES = { "small", "normal", "large" }

local function read_quest_font(kind)
    return library.read_frame_font(kind, FONT_SHIFTS[LibVGASettings.quest_font or "small"])
end
local hooked = {}

local read_draft = library.read_draft_size

local function create_objective(parent)
    local objective = CreateFrame("Frame", nil, parent)
    objective.grid = library.create_grid(objective, { columns = { 12, "rest", "auto" }, gaps = { 6, 8 }, row = 0, x = { "left", "left", "right" }, y = "top", fill = { [2] = true } })
    objective.text = library.create_text(objective, "body", OBJECTIVE)
    objective.text:SetJustifyH("LEFT")
    objective.text:SetWordWrap(true)
    objective.text:SetSpacing(SPACING)
    objective.count = library.create_text(objective, "figures_body", OBJECTIVE)
    objective.dot = library.create_bead(objective, "ARTWORK", 0)
    objective.strikes = {}
    objective.bar = CreateFrame("Frame", nil, objective)
    objective.bar.track = library.create_surface(objective.bar, "ARTWORK", 0)
    objective.bar.fill = CreateFrame("Frame", nil, objective.bar)
    objective.bar.fill.surface = library.create_surface(objective.bar.fill, "ARTWORK", 1)
    return objective
end

local function update_opened(quest, button)
    if button ~= "LeftButton" or not quest.id or InCombatLockdown() then return end
    if QuestMapFrame_OpenToQuestDetails then QuestMapFrame_OpenToQuestDetails(quest.id) end
end

local function update_pin(pin)
    local quest, map = pin:GetParent(), tracker.map
    if not (quest.id and map) then return end
    LibVGASettings.quest_pins = LibVGASettings.quest_pins or {}
    local pins = LibVGASettings.quest_pins
    local marker = vga.read_marker_aim()
    pins[map] = (marker or pins[map] ~= quest.id) and quest.id or nil
    if marker then vga.update_marker_cleared() end
    library.update_elements()
end

local function update_pin_safely(pin)
    library.update_safely("quest pinned", update_pin, pin)
end

local function render_pin_tip(pin)
    local texts = library.texts
    GameTooltip:SetOwner(pin, "ANCHOR_LEFT")
    GameTooltip:AddLine(texts.pin_title, colours.gold[1], colours.gold[2], colours.gold[3])
    for _, key in ipairs({ "pin_click", "pin_again", "pin_zone", "pin_marker" }) do
        GameTooltip:AddLine(texts[key], colours.ink[1], colours.ink[2], colours.ink[3], true)
    end
    GameTooltip:Show()
end

local function update_pin_left()
    GameTooltip:Hide()
end

local function create_quest()
    local quest = CreateFrame("Frame", nil, tracker.body.content)
    quest.grid = library.create_grid(quest, { columns = { 12, "rest", "auto" }, gaps = { 6, 8 }, padding = { 10, 12, 0, 12 }, row = 0, x = { "left", "left", "right" }, y = { "top", "baseline", "baseline" }, fill = { [2] = true } })
    quest:EnableMouse(true)
    quest:SetScript("OnMouseUp", function(self, button) library.update_safely("quest opened", update_opened, self, button) end)
    quest.arrow = quest:CreateTexture(nil, "OVERLAY")
    quest.pin = library.create_icon_button(quest, nil, update_pin_safely, { on_enter = render_pin_tip, on_leave = update_pin_left })
    quest.title = library.create_text(quest, "bold", TITLE)
    quest.title:SetJustifyH("LEFT")
    quest.title:SetWordWrap(false)
    quest.distance = library.create_text(quest, "figures_small", colours.quiet)
    quest.timer = library.create_text(quest, "small", TIME_GREEN)
    quest.timer:SetJustifyH("LEFT")
    quest.line = library.create_hairline(quest)
    quest.objectives = {}
    return quest
end

local ORDERS = { "near", "difficulty", "journal" }

local function write_zones(index)
    library.update_choice_setting("quest_zones", index == 2 and "all" or "current")
end

local function read_stops(least, most, step)
    local stops = {}
    for value = least, most, step do stops[#stops + 1] = value end
    if stops[#stops] ~= most then stops[#stops + 1] = most end
    return stops
end

local function render_pixels(value)
    return value .. " px"
end

function vga.read_quest_most_width()
    local chosen = LibVGASettings.quest_most_width or MOST_WIDTHS[LibVGASettings.quest_width or "wide"] or WIDTH_MOST
    return math.min(math.max(chosen, MIN_WIDTH), WIDTH_MOST)
end

function vga.read_quest_most_height()
    return math.min(math.max(LibVGASettings.quest_most_height or HEIGHT_MOST, HEIGHT_LEAST), HEIGHT_MOST)
end

local function write_most_width(value)
    LibVGASettings.quest_most_width = value
    library.update_element("quests")
end

local function write_most_height(value)
    LibVGASettings.quest_most_height = value
    library.update_element("quests")
end

local function create_width_row(page, texts)
    local row = library.create_slider_row(page, texts.most_width, read_stops(MIN_WIDTH, WIDTH_MOST, WIDTH_STEP), vga.read_quest_most_width(), write_most_width)
    row.control.render = render_pixels
    return row
end

local function create_height_row(page, texts)
    return library.create_slider_row(page, texts.most_height, read_stops(HEIGHT_LEAST, HEIGHT_MOST, HEIGHT_STEP), vga.read_quest_most_height(), write_most_height)
end

local function read_font_size_index()
    for index, size in ipairs(FONT_SIZES) do
        if size == (LibVGASettings.quest_font or "small") then return index end
    end
    return 1
end

local function write_font_size(index)
    library.update_choice_setting("quest_font", FONT_SIZES[index])
end

local function create_quests_page(page)
    local texts = library.texts
    local chosen = ({ near = 1, difficulty = 2, journal = 3 })[LibVGASettings.quest_order or "near"] or 1
    page.rows = {
        library.create_choice_row(page, texts.order, { texts.nearest_first, texts.difficulty, texts.journal }, chosen, function(index)
            library.update_choice_setting("quest_order", ORDERS[index])
        end),
        library.create_choice_row(page, texts.finished_quests, { texts.parts_hidden, texts.parts_shown }, LibVGASettings.quest_finished == "show" and 2 or 1, function(index)
            library.update_choice_setting("quest_finished", index == 1 and "hide" or "show")
        end),
        library.create_choice_row(page, texts.quest_zones, { texts.current_zone, texts.all_zones }, vga.check_all_zones() and 2 or 1, write_zones),
        library.create_choice_row(page, texts.font, { texts.small, texts.medium, texts.large }, read_font_size_index(), write_font_size),
        create_width_row(page, texts),
        create_height_row(page, texts),
    }
    for _, row in ipairs(library.create_widget_rows(page, "quests", { { key = "quests", title = texts.quest_tracker } })) do page.rows[#page.rows + 1] = row end
end

local function update_outer_place()
    local places = LibVGASettings.places
    local place = places and places.quests
    if not place or place[1] ~= "TOPLEFT" or LibVGASettings.quests_outer then return end
    LibVGASettings.quests_outer = true
    local width = read_draft(WIDTH)
    if place[3] + width / 2 > UIParent:GetWidth() / 2 then
        places.quests = { "TOPRIGHT", "BOTTOMLEFT", place[3] + width, place[4] }
        library.update_places()
    end
end

local function create_tracker()
    tracker = library.create_frame("VGAQuestTracker", UIParent)
    tracker.corner:SetScript("OnClick", function(corner) library.update_safely("options", library.render_widget, corner, "quests") end)
    library.create_frame_head(tracker, { top = 4, read_font = read_quest_font })
    tracker.source = CreateFrame("Frame", nil, tracker)
    tracker.source.ring = library.create_ring(tracker.source, "BORDER", 0)
    tracker.source.text = library.create_text(tracker.source, "caption", SOURCE)
    tracker.source.text:SetPoint("CENTER")
    tracker.quests = {}
    tracker.body = vga.create_quest_body(tracker)
    tracker.body.content.top = 0
    tracker.measure = library.create_text(tracker, "body")
    tracker.measure:Hide()
    tracker.place_outer = true
    library.create_place(tracker, "quests", "TOPRIGHT", ObjectiveTrackerFrame or UIParent, 0, 0)
    update_outer_place()
end

local function read_bearing(map, from, to)
    local _, here = C_Map.GetWorldPosFromMapPos(map, CreateVector2D(from.x, from.y))
    local _, there = C_Map.GetWorldPosFromMapPos(map, CreateVector2D(to[1], to[2]))
    if not (here and there) then return nil end
    return atan2(there.y - here.y, there.x - here.x)
end

function vga.read_heading(target)
    local map = C_Map.GetBestMapForUnit("player")
    local spot = map and C_Map.GetPlayerMapPosition(map, "player")
    local facing = GetPlayerFacing and GetPlayerFacing()
    local bearing = spot and target and facing and read_bearing(map, spot, target)
    return bearing and bearing - facing
end

local function update_arrows()
    for _, quest in ipairs(tracker.quests) do
        local target = quest:IsShown() and not quest.complete and quest.target
        local heading = target and vga.read_heading(target)
        if target then quest.arrow:SetShown(heading ~= nil) end
        if heading then quest.arrow:SetRotation(heading) end
    end
end

function vga.render_distance(yards)
    if not yards then return "" end
    if LibVGASettings.quest_unit == "yards" then return math.floor(yards + 0.5) .. " " .. library.texts.yards end
    return math.floor(yards * YARD + 0.5) .. " " .. library.texts.metres
end

local function render_objective_text(text)
    return (text or ""):gsub("^%s*%d+%s*/%s*%d+%s*", ""):gsub("%s*:?%s*%d+%s*/%s*%d+%s*$", "")
end

local function read_objectives(id)
    local found = {}
    for _, objective in ipairs(C_QuestLog.GetQuestObjectives(id) or {}) do
        found[#found + 1] = {
            text = render_objective_text(objective.text), done = objective.finished,
            have = objective.numFulfilled or 0, need = objective.numRequired or 0,
        }
    end
    return found
end

local function read_map_points(map)
    local points = {}
    for _, point in ipairs(map and C_QuestLog.GetQuestsOnMap(map) or {}) do points[point.questID] = { point.x, point.y } end
    return points
end

local function read_dungeon_tag(id)
    local tag = C_QuestLog.GetQuestTagInfo and C_QuestLog.GetQuestTagInfo(id)
    return tag ~= nil and tag.tagID == DUNGEON_TAG
end

local function read_time_left(id)
    if not C_QuestLog.GetTimeAllowed then return nil end
    local total, elapsed = C_QuestLog.GetTimeAllowed(id)
    if not (total and elapsed and total > 0) then return nil end
    return math.max(0, total - elapsed)
end

local function read_game_quest(entry, points)
    local id = entry.questID
    local square = C_QuestLog.GetDistanceSqToQuest(id)
    local level = entry.difficultyLevel or entry.level or 0
    local colour = GetQuestDifficultyColor and GetQuestDifficultyColor(level) or { r = 1, g = 0.82, b = 0 }
    return {
        id = id, title = entry.title, here = entry.isOnMap, point = points[id], complete = C_QuestLog.IsComplete(id),
        distance = square and math.sqrt(square), objectives = read_objectives(id), level = level, colour = colour,
        dungeon = read_dungeon_tag(id), left = read_time_left(id),
    }
end

local function read_game_quests(map)
    local points, watched, total, zone = read_map_points(map), {}, 0, nil
    for index = 1, C_QuestLog.GetNumQuestLogEntries() do
        local entry = C_QuestLog.GetInfo(index)
        if entry and entry.isHeader then zone = entry.title end
        if entry and not entry.isHeader and entry.questID then
            total = total + 1
            if C_QuestLog.GetQuestWatchType(entry.questID) ~= nil then
                watched[#watched + 1] = read_game_quest(entry, points)
                watched[#watched].zone = zone
            end
        end
    end
    return watched, total
end

local function update_from_questie(quest, map)
    local loader = QuestieLoader
    local found = loader:ImportModule("QuestieDB").GetQuest(quest.id)
    local spot, zone, _, distance = loader:ImportModule("DistanceUtils").GetNearestSpawnForQuest(found)
    if not spot then return end
    local zones = loader:ImportModule("ZoneDB")
    local zone_map = zones:GetUiMapIdByAreaId(zone)
    quest.here = zone_map == map
    local zone_map_data = zone_map and C_Map.GetMapInfo(zone_map)
    if zone_map_data and zone_map_data.name then quest.zone = zone_map_data.name end
    quest.dungeon = quest.dungeon or (found.zoneOrSort and found.zoneOrSort > 0 and zones:GetDungeonLocation(found.zoneOrSort) ~= nil)
    quest.point = { spot[1] / 100, spot[2] / 100 }
    quest.distance = distance
end

local function read_source()
    local chosen = LibVGASettings.quest_source or "auto"
    local questie = QuestieLoader and Questie and Questie.API and Questie.API.isReady
    if chosen ~= "wow" and questie then return "questie" end
    return "wow"
end

local function read_watch_order()
    local order = {}
    for index = 1, (C_QuestLog.GetNumQuestWatches and C_QuestLog.GetNumQuestWatches() or 0) do
        local id = C_QuestLog.GetQuestIDForQuestWatchIndex(index)
        if id then order[id] = index end
    end
    return order
end

local function check_nearer(one, other)
    return (one.distance or math.huge) < (other.distance or math.huge)
end

local function read_sorter()
    if LibVGASettings.quest_order == "difficulty" then
        return function(one, other)
            if one.level ~= other.level then return one.level < other.level end
            return check_nearer(one, other)
        end
    end
    if LibVGASettings.quest_order == "journal" then
        local order = read_watch_order()
        return function(one, other) return (order[one.id] or math.huge) < (order[other.id] or math.huge) end
    end
    return check_nearer
end

local function read_shown_quests(map, source)
    local watched, total = read_game_quests(map)
    local shown = {}
    for _, quest in ipairs(watched) do
        if source == "questie" then library.update_safely("quests questie", update_from_questie, quest, map) end
        if quest.here or vga.check_all_zones() then shown[#shown + 1] = quest end
    end
    table.sort(shown, read_sorter())
    if vga.check_all_zones() then return shown, total end
    for index = (LibVGASettings.quest_most or MOST) + 1, #shown do shown[index] = nil end
    return shown, total
end

local function update_bar(bar, share)
    local radius = 1
    library.update_surface(bar.track, 0, radius, TRACK, TRACK)
    bar.fill:ClearAllPoints()
    bar.fill:SetPoint("TOPLEFT")
    bar.fill:SetPoint("BOTTOMLEFT")
    bar.fill:SetWidth(math.max(1, bar:GetWidth() * share))
    bar.fill:SetShown(share > 0)
    library.update_surface(bar.fill.surface, 0, radius, colours.gold, colours.gold)
end

local function read_text_width(text, kind)
    local measure = tracker.measure
    measure:SetFontObject(read_quest_font(kind))
    measure:SetText(text or "")
    if measure.GetUnboundedStringWidth then return measure:GetUnboundedStringWidth() end
    return measure:GetStringWidth()
end

local function read_lines(text, width)
    local lines, line = {}, ""
    for word in (text or ""):gmatch("%S+") do
        local tried = line == "" and word or line .. " " .. word
        if line ~= "" and read_text_width(tried, "body") > width then
            lines[#lines + 1], line = line, word
        else
            line = tried
        end
    end
    lines[#lines + 1] = line
    return lines
end

local function update_strikes(objective, lines, line, shown)
    for index, words in ipairs(lines) do
        local strike = objective.strikes[index] or objective:CreateTexture(nil, "OVERLAY")
        strike:SetColorTexture(DONE[1], DONE[2], DONE[3], 1)
        strike:ClearAllPoints()
        strike:SetPoint("LEFT", objective.text, "TOPLEFT", 0, -((index - 1) * (line + SPACING) + line / 2))
        strike:SetSize(math.max(1, read_text_width(words, "body")), 1)
        strike:SetShown(shown)
        objective.strikes[index] = strike
    end
    for index = #lines + 1, #objective.strikes do objective.strikes[index]:Hide() end
end

local function update_objective(objective, data, top, width, colour_of_quest)
    local pad, done = read_draft(12), data.done
    local colour = done and DONE or OBJECTIVE
    objective:ClearAllPoints()
    objective:SetPoint("TOPLEFT", objective:GetParent(), "TOPLEFT", pad, -top)
    objective:SetWidth(width - 2 * pad)
    objective.text:SetFontObject(read_quest_font("body"))
    objective.count:SetFontObject(read_quest_font("body"))
    local count = data.need > 0 and (data.have .. "/" .. data.need) or ""
    local column = read_draft(12)
    local room = width - 2 * pad - column - read_draft(6) - read_draft(8) - read_text_width(count, "body")
    local lines = read_lines(data.text, room)
    objective.text:SetText(table.concat(lines, "\n"))
    objective.count:SetText(count)
    objective.text:SetTextColor(colour[1], colour[2], colour[3])
    objective.count:SetTextColor(colour[1], colour[2], colour[3])
    local line = math.ceil(objective.count:GetStringHeight())
    local lines_height = line * #lines + SPACING * (#lines - 1)
    local dot = read_draft(5)
    objective.dot:SetSize(dot, dot)
    objective.dot:SetVertexColor(colour_of_quest.r, colour_of_quest.g, colour_of_quest.b, 1)
    objective.dot:ClearAllPoints()
    objective.dot:SetPoint("CENTER", objective, "TOPLEFT", column / 2, -line / 2)
    library.update_grid(objective.grid, { { nil, objective.text, objective.count } }, width - 2 * pad)
    update_strikes(objective, lines, line, done and true or false)
    local bar = read_draft(3)
    objective.bar:ClearAllPoints()
    objective.bar:SetPoint("TOPLEFT", objective, "TOPLEFT", 0, -(lines_height + read_draft(5)))
    objective.bar:SetSize(width - 2 * pad, bar)
    objective.bar:SetShown(not done)
    update_bar(objective.bar, data.need > 0 and math.min(data.have / data.need, 1) or 0)
    local height = lines_height + (done and 0 or read_draft(5) + bar)
    objective:SetHeight(height)
    return height
end

local function check_all_done(data)
    for _, objective_data in ipairs(data.objectives) do
        if not objective_data.done then return false end
    end
    return true
end

local function update_quest_objectives(quest, data, top, width)
    local strike, gap = LibVGASettings.quest_done ~= "hide", read_draft(5)
    local folded = LibVGASettings.quest_finished ~= "show" and check_all_done(data)
    local shown = 0
    for _, objective_data in ipairs(data.objectives) do
        if not folded and (strike or not objective_data.done) then
            shown = shown + 1
            quest.objectives[shown] = quest.objectives[shown] or create_objective(quest)
            quest.objectives[shown]:Show()
            top = top + gap + update_objective(quest.objectives[shown], objective_data, top + gap, width, data.colour)
        end
    end
    for index = shown + 1, #quest.objectives do quest.objectives[index]:Hide() end
    return top
end

local function update_mark(quest, data, active)
    local colour = data.complete and TICK or (active and colours.gold or colours.quiet)
    quest.arrow:SetTexture(library.media .. (data.complete and "Tick" or "Arrow"))
    quest.arrow:SetVertexColor(colour[1], colour[2], colour[3], 1)
    if data.complete then quest.arrow:SetRotation(0) end
    quest.arrow:SetShown(data.complete or data.point ~= nil)
    quest.pin:SetShown(not data.complete and data.point ~= nil)
    quest.complete, quest.target = data.complete, data.point
end

local function read_time_colour(left)
    if left <= 30 then return TIME_RED end
    if left <= 120 then return TIME_YELLOW end
    return TIME_GREEN
end

local function update_timer(quest, data)
    quest.timer:SetShown(data.left ~= nil)
    if not data.left then return 0 end
    local colour = read_time_colour(data.left)
    quest.timer:SetFontObject(read_quest_font("small"))
    quest.timer:SetTextColor(colour[1], colour[2], colour[3])
    quest.timer:SetText(string.format("%s %d:%02d", library.texts.time_left, math.floor(data.left / 60), math.floor(data.left % 60)))
    quest.timer:ClearAllPoints()
    quest.timer:SetPoint("TOPLEFT", quest.title, "BOTTOMLEFT", 0, -read_draft(2))
    return math.ceil(quest.timer:GetStringHeight()) + read_draft(2)
end

local function update_quest(quest, data, top, width, active)
    local pad, arrow = read_draft(12), read_draft(12)
    quest:ClearAllPoints()
    quest:SetPoint("TOPLEFT", tracker.body.content, "TOPLEFT", 0, -(top - tracker.body.content.top))
    quest:SetWidth(width)
    quest.id = data.id
    quest.title:SetFontObject(read_quest_font("bold"))
    quest.distance:SetFontObject(read_quest_font("small"))
    quest.title:SetText(data.dungeon and (data.title .. "  |cff8f8f8f" .. (LFG_TYPE_DUNGEON or library.texts.dungeon) .. "|r") or data.title)
    quest.distance:SetText(vga.render_distance(data.distance))
    quest.arrow:SetSize(arrow, arrow)
    quest.pin:SetAllPoints(quest.arrow)
    update_mark(quest, data, active)
    library.update_grid(quest.grid, { { quest.arrow, quest.title, quest.distance } }, width)
    local below = update_timer(quest, data)
    local bottom = update_quest_objectives(quest, data, read_draft(10) + math.ceil(quest.title:GetStringHeight()) + below, width) + read_draft(10)
    quest:SetHeight(bottom)
    quest.line:ClearAllPoints()
    quest.line:SetPoint("BOTTOMLEFT")
    quest.line:SetPoint("BOTTOMRIGHT")
    quest.line:SetHeight(1)
    quest.line:SetAlpha(library.read_ground("quests"))
    return bottom
end

local function update_head(width, shown, total)
    local title = vga.check_all_zones() and library.texts.quests or library.texts.quests_zone
    return library.update_frame_head(tracker, title, shown .. " " .. library.texts.of .. " " .. total, width)
end

local function update_foot(top, source)
    local text = tracker.source.text
    text:SetFontObject(read_quest_font("caption"))
    text:SetText(library.texts.data .. ": " .. (source == "questie" and "QUESTIE" or "WOW"))
    tracker.source:ClearAllPoints()
    tracker.source:SetPoint("TOPLEFT", tracker, "TOPLEFT", read_draft(12), -(top + read_draft(6)))
    tracker.source:SetSize(math.ceil(text:GetStringWidth()) + 2 * read_draft(6), math.ceil(text:GetStringHeight()) + 2 * read_draft(1) + 2)
    library.update_ring(tracker.source.ring, 1, SOURCE, 0.33)
    return top + read_draft(6) + tracker.source:GetHeight() + read_draft(8) + read_draft(4)
end

local function update_others()
    for _, name in ipairs(OTHERS) do
        local other = _G[name]
        if other and not hooked[other] then
            hooked[other] = true
            other:HookScript("OnShow", function(shown) shown:SetAlpha(0) end)
        end
        if other then other:SetAlpha(0) end
        if other and other ~= ObjectiveTrackerFrame and not InCombatLockdown() then other:Hide() end
    end
end

local function read_quest_width(data)
    local pad = read_draft(12)
    local widest = 2 * pad + read_draft(12) + read_draft(6) + read_text_width(data.title, "bold") + read_draft(8) + read_text_width(vga.render_distance(data.distance), "small")
    for _, objective in ipairs(data.objectives) do
        local count = objective.need > 0 and (objective.have .. "/" .. objective.need) or ""
        local needed = 2 * pad + read_draft(12) + read_draft(6) + read_text_width(objective.text, "body") + read_draft(8) + read_text_width(count, "body")
        widest = math.max(widest, needed)
    end
    return widest
end

local function read_width(shown, total)
    local pad = read_draft(12)
    local head = 2 * pad + read_draft(16) + read_draft(8) + read_text_width(library.texts.quests_zone, "bold") + read_draft(16) + read_text_width(shown and (#shown .. " " .. library.texts.of .. " " .. total) or "", "small") + read_draft(14)
    local widest = math.max(read_draft(MIN_WIDTH), head)
    local most = read_draft(vga.read_quest_most_width())
    for _, data in ipairs(shown) do widest = math.max(widest, math.min(read_quest_width(data), most)) end
    return math.ceil(widest)
end

local function read_rows(shown, map)
    if not vga.check_all_zones() then return shown, nil end
    local here = map and C_Map.GetMapInfo(map)
    local visible, rows, most = {}, {}, LibVGASettings.quest_most or MOST
    for _, group in ipairs(vga.read_zone_groups(shown, here and here.name or "")) do
        rows[#rows + 1] = { group = group }
        if vga.check_zone_open(group) then
            for _, quest in ipairs(group.quests) do
                if #visible < most then
                    visible[#visible + 1] = quest
                    rows[#rows + 1] = { quest = quest }
                end
            end
        end
    end
    return visible, rows
end

local function update_rows(rows, top, width, active)
    local quest_index, label_index = 0, 0
    tracker.labels = tracker.labels or {}
    for _, row in ipairs(rows) do
        if row.group then
            label_index = label_index + 1
            tracker.labels[label_index] = tracker.labels[label_index] or vga.create_zone_label(tracker.body.content)
            top = top + vga.update_zone_label(tracker.labels[label_index], row.group, top, width)
        else
            quest_index = quest_index + 1
            tracker.quests[quest_index] = tracker.quests[quest_index] or create_quest()
            tracker.quests[quest_index]:Show()
            top = top + update_quest(tracker.quests[quest_index], row.quest, top, width, row.quest == active)
            tracker.quests[quest_index].line:SetShown(false)
        end
    end
    for index = label_index + 1, #tracker.labels do tracker.labels[index]:Hide() end
    return top, quest_index
end

local function update_tracker()
    if not tracker then return end
    update_others()
    library.update_frame(tracker)
    local map = C_Map.GetBestMapForUnit("player")
    local source = read_source()
    local all, total = read_shown_quests(map, source)
    local shown, rows = read_rows(all, map)
    local width = read_width(shown, total)
    local top = update_head(width, #shown, total)
    local head = top
    tracker.body.content.top = head
    tracker.map = map
    local pinned = map and LibVGASettings.quest_pins and LibVGASettings.quest_pins[map]
    local active
    for _, data in ipairs(shown) do
        if not data.complete and (not active or check_nearer(data, active)) then active = data end
    end
    for _, data in ipairs(shown) do
        if data.id == pinned and not data.complete and data.point then active = data end
    end
    local marker = vga.read_marker_aim()
    if marker then active = nil end
    if rows then
        top = update_rows(rows, top, width, active)
    else
        for index, data in ipairs(shown) do
            tracker.quests[index] = tracker.quests[index] or create_quest()
            tracker.quests[index]:Show()
            top = top + update_quest(tracker.quests[index], data, top, width, data == active)
            tracker.quests[index].line:SetShown(index < #shown)
        end
        for _, label in ipairs(tracker.labels or {}) do label:Hide() end
    end
    for index = #shown + 1, #tracker.quests do tracker.quests[index]:Hide() end
    local foot = update_foot(head, source) - head
    local room = vga.update_quest_body(tracker, head, top - head, width, foot)
    tracker:SetSize(width, update_foot(head + room, source))
    vga.quest_aim = marker or active or nil
    vga.update_quest_items(tracker, tracker.quests, shown)
    update_arrows()
end

local function update_tracker_safely()
    library.update_safely("quests", update_tracker)
end

vga.update_quest_tracker = update_tracker_safely

local function update_arrow_safely(_, elapsed)
    tracker.since = (tracker.since or 0) + elapsed
    if tracker.since < 0.1 then return end
    tracker.since = 0
    library.update_safely("quests arrows", update_arrows)
end

local function create_tracker_safely()
    create_tracker()
    library.create_element("quests", { title = library.texts.quests, icon = "TabQuests", update = update_tracker, tab = create_quests_page })
    tracker:SetScript("OnUpdate", update_arrow_safely)
    C_Timer.NewTicker(1, update_tracker_safely)
    if Questie and Questie.API and Questie.API.RegisterOnReady then Questie.API.RegisterOnReady(update_tracker_safely) end
end

local events = CreateFrame("Frame")
for _, name in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "QUEST_LOG_UPDATE", "QUEST_WATCH_LIST_CHANGED", "USER_WAYPOINT_UPDATED", "ZONE_CHANGED", "ZONE_CHANGED_NEW_AREA" }) do
    pcall(events.RegisterEvent, events, name)
end
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then library.update_safely("quests login", create_tracker_safely) end
    update_tracker_safely()
end)
