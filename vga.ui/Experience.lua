-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: The experience bar as the accepted draft draws it (manual/view/vga-xp.html, V1a): above it the level and the share in the light ink at the left, the rested bonus white at the right, without one a quiet »kein Bonus«, both set in far enough that the gryphons never cover them, after the level and share, in brackets, the time left to the next level, »Stufe 22 · 71 % (~28 m)«, reckoned from the experience of the last fifteen minutes and refreshed every minute or after every fight as the settings say, the brackets left out whole while no time is known; all three to be switched off; then the frame rate, the world latency and the addons' memory, 60 fps · 42 ms · 38 MB, the memory white below 200 MB, yellow from 200 to red at 300 (K0587), and the money with the accepted coins (manual/view/vga-windows.html), each switched on and off, and the bag slots in use of all, »35/40«, yellow with ten or fewer left, orange with fewer than five, red when none is; the row laid as a table of equal columns over the width between the insets - level with its time, values, money and slots together in one column, parted by a small dot as the system values are, »2 · 7/24«, bonus -, the first column's content left-aligned, the last's right-aligned, every middle one's centred, and a column switched off or not needed gone, the others sharing its room; on its own tab of the settings, its colour chosen from the same seven swatches as the reputation bar's - blue, green, silver, violet, gold, orange, bronze -, the player's choice, blue for experience and green for reputation by default, a choice made earlier kept (K0695); the bar the mage's blue by default, without the fine light streaks - any of the seven as the settings say (K0567, K0695) -, its colour darkened a little towards grey while no rested bonus is left, rounded, in a black line, with ten fine divisions, moving like every other bar of LibVGA; the rested bonus, as the game shows it, a fainter underlay of the bar's colour at 0.3 opacity, swept by the bars' slanted shine at the same opacity whenever it grows - resting in a city, an inn or a camp - reaching beyond the fill as far as the bonus goes. While a faction is watched the bar shows its reputation instead, in a colour of its own chosen from three swatches - the hunter's green by default, gold or our orange, never blue -, hatched with light diagonal strokes: »Ruf« with the standing's name and the share at the left, the faction's name at the right, without a time column - or, as the settings say (»Ruf und Erfahrung: Beide«), both at once, each bar half as high, two pixels apart, the experience above with its texts, the reputation beneath (K0549). Laid by the main bar between its rows.

-- {K0298} {K0300} {K0375} {K0378} {K0383} {K0388} {K0397} {K0404} {K0428} {K0430} {K0437} {K0451} {K0483} {K0516} {K0519} {K0526} {K0531} {K0549} {K0567} {K0587} {K0695}

local _, vga = ...
local library = LibVGA
local DRAFT_BASE = 13
local DIVISIONS = 10
local INSET = 40
local BOTH_GAP = 2
local PURSE_APART = 4
local SHADES = { "mage", "hunter", "silver", "violet", "gold", "orange", "bronze" }
local SWATCHES = { violet = { 0.706, 0.565, 0.945 }, gold = { 0.894, 0.718, 0.314 }, silver = { 0.788, 0.808, 0.839 }, bronze = { 0.753, 0.541, 0.322 }, orange = { 0.941, 0.541, 0.165 }, hunter = { 0.498, 0.69, 0.29 }, mage = { 0.353, 0.604, 0.878 } }
local WINDOW = 900
local MINUTE = 60
local gains = {}
local seen = {}
local LABEL = { 0.914, 0.902, 0.875 }
local HATCH_ALPHA = 0.22
local RESTED_ALPHA = 0.3
local SPENT_GREY = { 0.45, 0.46, 0.48 }
local SPENT_SHARE = 0.35
local WARM = { 1, 0.82, 0.25 }
local ALARM = { 0.93, 0.27, 0.22 }
local ORANGE = { 0.96, 0.55, 0.2 }
local WHITE = { 1, 1, 1 }
local MEMORY_YELLOW = 200
local MEMORY_RED = 300
local MEMORY_EVERY = 10
local memory = { used = 0, read = 0 }

local function read_draft(pixels)
    return math.floor(pixels * library.read_base() / DRAFT_BASE + 0.5)
end

local function create_hatch(bar)
    local hatch = bar:CreateTexture(nil, "ARTWORK", nil, 2)
    hatch:SetTexture(library.media .. "Hatch", "REPEAT", "REPEAT")
    hatch:SetHorizTile(true)
    hatch:SetVertTile(true)
    hatch:SetAllPoints(bar:GetStatusBarTexture())
    hatch:SetAlpha(HATCH_ALPHA)
    return hatch
end

function vga.create_experience(parent)
    local block = CreateFrame("Frame", nil, parent)
    block.level = library.create_text(block, "body", LABEL)
    block.bonus = library.create_text(block, "body", LABEL)
    block.system = library.create_text(block, "body", LABEL)
    block.system:SetJustifyH("CENTER")
    block.purse = CreateFrame("Frame", nil, block)
    block.money = library.create_money(block.purse, LABEL)
    block.dot = library.create_text(block.purse, "body", LABEL)
    block.dot:SetText("·")
    block.slots = library.create_text(block.purse, "body", LABEL)
    block.cells = { block.level, block.system, block.purse, block.bonus }
    vga.experience_block = block
    block.bar = library.create_bar(block, "gold")
    block.divisions = {}
    for index = 1, DIVISIONS - 1 do
        local division = block.bar:CreateTexture(nil, "OVERLAY", nil, 1)
        division:SetColorTexture(0, 0, 0, 0.4)
        block.divisions[index] = division
    end
    block.hatch = create_hatch(block.bar)
    block.second = library.create_bar(block, "hunter")
    block.second.hatch = create_hatch(block.second)
    block.second:Hide()
    block.rested = CreateFrame("StatusBar", nil, block.bar)
    block.rested:SetAllPoints()
    block.rested:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    block.rested.clip = CreateFrame("Frame", nil, block.rested)
    block.rested.clip:SetPoint("TOPLEFT")
    block.rested.clip:SetPoint("BOTTOMRIGHT", block.rested:GetStatusBarTexture(), "BOTTOMRIGHT")
    block.rested.clip:SetClipsChildren(true)
    block.rested.shine = block.rested.clip:CreateTexture(nil, "OVERLAY")
    block.rested.shine:SetTexture(library.media .. "Shine")
    block.rested.shine:SetBlendMode("ADD")
    block.rested.shine:SetAlpha(RESTED_ALPHA)
    block.rested.shine:Hide()
    vga.create_experience_tips(block)
    block:SetScript("OnSizeChanged", vga.update_experience)
    return block
end

function vga.read_experience_labels()
    return LibVGASettings.xp_labels ~= "off"
end

local function read_memory()
    local now = GetTime()
    if now - memory.read < MEMORY_EVERY then return memory.used end
    memory.read = now
    local update = UpdateAddOnMemoryUsage or (C_AddOns and C_AddOns.UpdateAddOnMemoryUsage)
    local usage = GetAddOnMemoryUsage or (C_AddOns and C_AddOns.GetAddOnMemoryUsage)
    local count = (C_AddOns and C_AddOns.GetNumAddOns and C_AddOns.GetNumAddOns()) or (GetNumAddOns and GetNumAddOns()) or 0
    if not (update and usage) then return memory.used end
    update()
    local total = 0
    for index = 1, count do total = total + (usage(index) or 0) end
    memory.used = total
    return total
end

local function read_warning_colour(value, yellow, red, rising)
    local share = rising and (value - yellow * 0.5) / (yellow * 0.5) or (yellow * 1.5 - value) / (yellow * 0.5)
    local from, to = WHITE, WARM
    if (rising and value >= yellow) or (not rising and value <= yellow) then
        share = rising and (value - yellow) / (red - yellow) or (yellow - value) / (yellow - red)
        from, to = WARM, ALARM
    end
    share = math.max(0, math.min(1, share))
    local mixed = {}
    for index = 1, 3 do mixed[index] = from[index] + (to[index] - from[index]) * share end
    return mixed
end

local function read_warning(value, yellow, red, rising)
    local mixed = read_warning_colour(value, yellow, red, rising)
    return string.format("|cff%02x%02x%02x", math.floor(mixed[1] * 255 + 0.5), math.floor(mixed[2] * 255 + 0.5), math.floor(mixed[3] * 255 + 0.5))
end

local function read_system()
    local _, _, _, world = GetNetStats()
    return math.floor((GetFramerate() or 0) + 0.5), world or 0, math.floor(read_memory() / 1024 + 0.5)
end

local function read_memory_warning(used)
    if used < MEMORY_YELLOW then return read_warning(0, MEMORY_YELLOW, MEMORY_RED, true) end
    return read_warning(used, MEMORY_YELLOW, MEMORY_RED, true)
end

local function render_system()
    local frames, latency, used = read_system()
    return string.format("%s%d fps|r · %s%d ms|r · %s%d MB|r", read_warning(frames, 30, 24, false), frames, read_warning(latency, 150, 300, true), latency, read_memory_warning(used), used)
end

local function read_slots_colour(free)
    if free <= 0 then return ALARM end
    if free < 5 then return ORANGE end
    if free <= 10 then return WARM end
    return LABEL
end

local function update_purse(block)
    local apart = read_draft(PURSE_APART)
    block.money:ClearAllPoints()
    block.money:SetPoint("TOPLEFT", block.purse, "TOPLEFT")
    block.dot:SetFontObject(library.read_frame_font("body"))
    block.dot:ClearAllPoints()
    block.dot:SetPoint("TOPLEFT", block.money, "TOPRIGHT", apart, 0)
    block.slots:ClearAllPoints()
    block.slots:SetPoint("TOPLEFT", block.dot, "TOPRIGHT", apart, 0)
    block.purse:SetSize(block.money:GetWidth() + 2 * apart + block.dot:GetStringWidth() + block.slots:GetStringWidth(), library.read_size(0) + read_draft(5))
end

local function update_extras(block)
    if not block then return end
    local shown = vga.read_experience_labels()
    block.system:SetShown(shown and LibVGASettings.xp_system ~= "off")
    block.purse:SetShown(shown and LibVGASettings.xp_money ~= "off")
    block.system:SetText(render_system())
    library.update_money(block.money, GetMoney())
    block.slots:SetFontObject(library.read_frame_font("body"))
    local used, total = vga.read_bag_slots()
    block.slots:SetText(string.format("%d/%d", used, total))
    block.slots:SetTextColor(unpack(read_slots_colour(total - used)))
    update_purse(block)
end

local function read_shade(chosen, fallback)
    local wanted = chosen or fallback
    for index, shade in ipairs(SHADES) do
        if shade == wanted then return index, shade end
    end
    return read_shade(fallback, fallback)
end

function vga.read_experience_shade()
    return read_shade(LibVGASettings.xp_colour, "mage")
end

function vga.read_reputation_shade()
    return read_shade(LibVGASettings.reputation_colour, "hunter")
end

local function create_shade_row(page, title, shades, chosen, key)
    local swatches = {}
    for index, shade in ipairs(shades) do swatches[index] = { colour = SWATCHES[shade] } end
    local row = library.create_row(page, title)
    row.control = library.create_pictures(row, swatches, chosen, function(index)
        library.update_choice_setting(key, shades[index])
    end, "swatch")
    return row
end

local function check_loose()
    return LibVGASettings.mainbar_form == "loose"
end

local function write_both(index)
    library.update_choice_setting("xp_both", index == 2 and "both" or "one")
end

local function create_experience_page(page)
    local texts = library.texts
    page.rows = {
        library.create_choice_row(page, texts.xp_labels, { texts.on, texts.off }, vga.read_experience_labels() and 1 or 2, function(index)
            library.update_choice_setting("xp_labels", index == 1 and "on" or "off")
        end),
        library.create_choice_row(page, texts.system_values, { texts.on, texts.off }, LibVGASettings.xp_system == "off" and 2 or 1, function(index)
            library.update_choice_setting("xp_system", index == 1 and "on" or "off")
        end),
        library.create_choice_row(page, texts.money, { texts.on, texts.off }, LibVGASettings.xp_money == "off" and 2 or 1, function(index)
            library.update_choice_setting("xp_money", index == 1 and "on" or "off")
        end),
        create_shade_row(page, texts.xp_colour, SHADES, vga.read_experience_shade(), "xp_colour"),
        create_shade_row(page, texts.reputation_colour, SHADES, vga.read_reputation_shade(), "reputation_colour"),
        library.create_choice_row(page, texts.xp_and_reputation, { texts.one_bar, texts.both_bars }, LibVGASettings.xp_both == "both" and 2 or 1, write_both),
        library.create_choice_row(page, texts.xp_time, { texts.every_minute, texts.after_fight }, LibVGASettings.xp_pace == "fight" and 2 or 1, function(index)
            library.update_choice_setting("xp_pace", index == 2 and "fight" or "minute")
        end),
    }
    for _, row in ipairs(library.create_widget_rows(page, "experience", {
        { key = "xpbar", title = texts.xp_bar, sized = true, when = check_loose },
    })) do page.rows[#page.rows + 1] = row end
end

library.create_element("experience", { title = library.texts.experience, icon = "TabExperience", tab = create_experience_page })

function vga.read_experience_height()
    return (vga.read_experience_labels() and library.read_size(0) + read_draft(5) or 0) + read_draft(14)
end

local function update_marks(block, height)
    local width = block.bar:GetWidth()
    for index, division in ipairs(block.divisions) do
        division:ClearAllPoints()
        division:SetPoint("TOPLEFT", block.bar, "TOPLEFT", math.floor(width * index / DIVISIONS + 0.5), 0)
        division:SetSize(1, height)
    end
end

local function read_mixed(colour, other, share)
    return CreateColor(colour[1] + (other[1] - colour[1]) * share, colour[2] + (other[2] - colour[2]) * share, colour[3] + (other[3] - colour[3]) * share, 1)
end

local function update_fill(block, shade, spent)
    local top, bottom = library.read_bar_colours(shade)
    local share = spent and SPENT_SHARE or 0
    block.bar:GetStatusBarTexture():SetGradient("VERTICAL", read_mixed(bottom, SPENT_GREY, share), read_mixed(top, SPENT_GREY, share))
    block.rested:SetStatusBarColor(top[1], top[2], top[3], RESTED_ALPHA)
end

local function read_reputation()
    local watched = C_Reputation and C_Reputation.GetWatchedFactionData and C_Reputation.GetWatchedFactionData()
    if watched and watched.name then
        local low, high = watched.currentReactionThreshold or 0, watched.nextReactionThreshold or 0
        return { name = watched.name, reaction = watched.reaction, have = (watched.currentStanding or 0) - low, most = math.max(high - low, 0), standing = watched.currentStanding or 0, top = high }
    end
    if GetWatchedFactionInfo then
        local name, reaction, low, high, value = GetWatchedFactionInfo()
        if name then return { name = name, reaction = reaction, have = value - low, most = math.max(high - low, 0), standing = value, top = high } end
    end
    return nil
end

vga.read_watched_reputation = read_reputation

local function read_standing_name(reaction)
    return _G["FACTION_STANDING_LABEL" .. tostring(reaction)] or ""
end

local function update_reputation_texts(block, faction)
    local share = faction.most > 0 and math.min(faction.have / faction.most, 1) or 1
    block.level:SetText(string.format("%s %s · %d %%", library.texts.reputation_short, read_standing_name(faction.reaction), math.floor(share * 100)))
    block.bonus:SetText(faction.name)
    block.bonus:SetTextColor(unpack(LABEL))
end

local function update_progress(block, faction, most, bonus)
    local _, shade = (faction and vga.read_reputation_shade or vga.read_experience_shade)()
    library.update_bar_kind(block.bar, shade)
    block.mode = faction and "reputation" or "experience"
    block.hatch:SetShown(faction ~= nil)
    if faction then
        update_fill(block, shade, false)
        block.rested:Hide()
        library.update_bar_value(block.bar, faction.most > 0 and faction.have or 1, faction.most > 0 and faction.most or 1)
        return
    end
    update_fill(block, shade, bonus <= 0)
    local have = UnitXP("player") or 0
    block.rested:SetShown(bonus > 0)
    block.rested:SetMinMaxValues(0, most)
    local rested = math.min(have + bonus * most, most)
    block.rested:SetValue(rested)
    if bonus > 0 and block.rested_was and rested > block.rested_was then library.render_bar_shine(block.rested) end
    block.rested_was = bonus > 0 and rested or nil
    block.rested:SetFrameLevel(math.max(0, block.bar:GetFrameLevel() - 1))
    library.update_bar_value(block.bar, have, most)
end

local function update_second(block, faction, height)
    local second = block.second
    second:SetShown(faction ~= nil)
    if not faction then return end
    local _, shade = vga.read_reputation_shade()
    second:ClearAllPoints()
    second:SetPoint("BOTTOMLEFT")
    second:SetPoint("BOTTOMRIGHT")
    second:SetHeight(height)
    library.update_bar_shape(second, math.min(read_draft(4), math.floor(height / 2)))
    library.update_bar_kind(second, shade)
    second.hatch:Show()
    library.update_bar_value(second, faction.most > 0 and faction.have or 1, faction.most > 0 and faction.most or 1)
end

local function read_cell_point(index, count)
    if index == 1 then return "TOPLEFT", 0 end
    if index == count then return "TOPRIGHT", 1 end
    return "TOP", 0.5
end

local function update_columns(block)
    local inset = read_draft(INSET)
    local shown = {}
    for _, cell in ipairs(block.cells) do
        if cell:IsShown() then shown[#shown + 1] = cell end
    end
    local width = math.max(0, (block:GetWidth() or 0) - 2 * inset) / math.max(#shown, 1)
    block.money:SetHeight(library.read_size(0) + read_draft(5))
    for index, cell in ipairs(shown) do
        local point, share = read_cell_point(index, #shown)
        cell:ClearAllPoints()
        cell:SetPoint(point, block, "TOPLEFT", inset + (index - 1 + share) * width, 0)
    end
end

function vga.update_experience(block)
    local most = UnitXPMax("player") or 0
    block:SetShown(most > 0)
    if most <= 0 then return end
    local height = read_draft(14)
    local share = math.min((UnitXP("player") or 0) / most, 1)
    local bonus = (GetXPExhaustion() or 0) / most
    block.level:SetFontObject(library.read_frame_font("body"))
    block.bonus:SetFontObject(library.read_frame_font("body"))
    local watched = read_reputation()
    local both = watched ~= nil and LibVGASettings.xp_both == "both"
    local faction = not both and watched or nil
    block.level:SetShown(vga.read_experience_labels())
    block.bonus:SetShown(vga.read_experience_labels())
    block.system:SetFontObject(library.read_frame_font("body"))
    update_extras(block)
    if faction then
        update_reputation_texts(block, faction)
    else
        local estimate = block.estimate and string.format(" (%s)", block.estimate) or ""
        block.level:SetText(string.format("%s %d · %d %%%s", library.texts.level_short, UnitLevel("player") or 0, math.floor(share * 100), estimate))
        block.bonus:SetText(bonus > 0 and string.format("%s +%d %%", library.texts.rested, math.floor(bonus * 100 + 0.5)) or library.texts.no_bonus)
        block.bonus:SetTextColor(unpack(bonus > 0 and LABEL or library.colours.quiet))
    end
    update_columns(block)
    local half = both and math.floor((height - BOTH_GAP) / 2) or height
    block.bar:ClearAllPoints()
    block.bar:SetPoint("BOTTOMLEFT", 0, both and half + BOTH_GAP or 0)
    block.bar:SetPoint("BOTTOMRIGHT", 0, both and half + BOTH_GAP or 0)
    block.bar:SetHeight(half)
    library.update_bar_shape(block.bar, math.min(read_draft(4), math.floor(half / 2)))
    update_progress(block, faction, most, bonus)
    update_marks(block, half)
    update_second(block, both and watched or nil, half)
end

local function render_left(seconds)
    local texts = library.texts
    local hours, minutes = math.floor(seconds / 3600), math.ceil((seconds % 3600) / MINUTE)
    if hours > 0 then return string.format("~%d %s %d %s", hours, texts.hours, minutes, texts.minutes) end
    return string.format("~%d %s", math.max(minutes, 1), texts.minutes)
end

local function read_window_total(list, now)
    local total = 0
    for index = #list, 1, -1 do
        if now - list[index][1] > WINDOW then table.remove(list, index) else total = total + list[index][2] end
    end
    return total
end

local function update_estimate()
    local block = vga.experience_block
    if not block then return end
    local now = GetTime()
    if read_reputation() then return end
    local total = read_window_total(gains, now)
    local elapsed = math.min(WINDOW, now - (seen.since or now))
    local most, have = UnitXPMax("player") or 0, UnitXP("player") or 0
    block.estimate = most > 0 and elapsed > 0 and total > 0 and render_left((most - have) / (total / elapsed)) or nil
    vga.update_experience(block)
end

local function write_gain()
    local have, most = UnitXP("player") or 0, UnitXPMax("player") or 0
    if seen.have then
        local gained = have >= seen.have and have - seen.have or (seen.most - seen.have) + have
        if gained > 0 then gains[#gains + 1] = { GetTime(), gained } end
    end
    seen.have, seen.most = have, most
end

local function update_faction()
    if vga.experience_block then vga.update_experience(vga.experience_block) end
    update_estimate()
end

local events = CreateFrame("Frame")
for _, name in ipairs({ "PLAYER_LOGIN", "PLAYER_XP_UPDATE", "PLAYER_REGEN_ENABLED", "PLAYER_MONEY", "UPDATE_FACTION" }) do events:RegisterEvent(name) end
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        seen.since = GetTime()
        write_gain()
        C_Timer.After(1, function() library.update_safely("experience estimate", update_estimate) end)
        C_Timer.NewTicker(1, function() library.update_safely("experience values", update_extras, vga.experience_block) end)
        C_Timer.NewTicker(MINUTE, function()
            if LibVGASettings.xp_pace ~= "fight" then library.update_safely("experience estimate", update_estimate) end
        end)
    elseif event == "PLAYER_XP_UPDATE" then
        write_gain()
    elseif event == "UPDATE_FACTION" then
        library.update_safely("experience reputation", update_faction)
    elseif event == "PLAYER_MONEY" then
        library.update_safely("experience money", update_extras, vga.experience_block)
    elseif LibVGASettings.xp_pace == "fight" then
        library.update_safely("experience estimate", update_estimate)
    end
end)

vga.read_system, vga.read_warning_colour = read_system, read_warning_colour
vga.read_memory_warning = read_memory_warning
