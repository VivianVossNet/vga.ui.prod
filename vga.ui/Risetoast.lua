-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: the character's rise as LibVGA's toast (K1040), of the kind »rise«, gold rimmed, silenced by its switch on the tab »Hinweise«, as manual/view/vga-toasts.html lists it: a level reached (PLAYER_LEVEL_UP), »Stufe 20 erreicht«, with the book ornament above and beneath and LibVGA's green tick (K1037, K1042); at that level, where the trainer last seen had a skill waiting for it (LibVGACharacter.trainer_next, kept by vga.ui/Trainer.lua), »Neue Fähigkeiten beim Lehrer«, once; a profession's rank rising, »Kochkunst 74 → 75«, counted on in one toast per profession while it shows (plan.key, K1038), read from every one of the five places GetProfessions answers, a place left empty never ending the reading (manual/16 R4.4a); a faction's standing rising, »Sturmwind: Wohlwollend« with the tick, by the game's own name of the standing (FACTION_STANDING_LABEL…), read through C_Reputation where Forever has it, else GetFactionInfo. The first reading of ranks and standings only takes note. The pictures are the game's, not yet seen in Forever.

-- {K1042} {K1040} {K1038} {K1037}

local library = LibVGA
local LEVEL_PICTURE = "Interface\\Icons\\Spell_Holy_SurgeOfLight"
local TRAINER_PICTURE = "Interface\\Icons\\INV_Misc_Book_09"
local REPUTATION_PICTURE = "Interface\\Icons\\INV_Misc_Note_02"
local PLACES = 5
local ranks
local standings

local function render(line, picture, extra)
    local plan = { head = library.texts.toast_rise, line = line, picture = picture, kind = "rise" }
    for key, value in pairs(extra or {}) do plan[key] = value end
    library.render_toast(plan)
end

local function render_trainer(level)
    local waiting = LibVGACharacter and LibVGACharacter.trainer_next
    if not (waiting and level >= waiting) then return end
    LibVGACharacter.trainer_next = nil
    render(library.texts.rise_trainer, TRAINER_PICTURE)
end

local function render_level(level)
    level = tonumber(level) or UnitLevel("player")
    render(string.format(library.texts.rise_level, level), LEVEL_PICTURE, { ornate = true, done = true })
    render_trainer(level)
end

local function read_ranks()
    local found, places = {}, { GetProfessions() }
    for place = 1, PLACES do
        if places[place] then
            local name, picture, rank = GetProfessionInfo(places[place])
            if name then found[name] = { rank = rank or 0, picture = picture } end
        end
    end
    return found
end

local function update_ranks()
    if not (GetProfessions and GetProfessionInfo) then return end
    local now = read_ranks()
    for name, skill in pairs(now) do
        local before = ranks and ranks[name]
        if before and skill.rank > before.rank then render(string.format(library.texts.rise_skill, name, before.rank, skill.rank), skill.picture, { key = "rise:" .. name }) end
    end
    ranks = now
end

local function read_faction(index)
    if C_Reputation and C_Reputation.GetFactionDataByIndex then
        local data = C_Reputation.GetFactionDataByIndex(index)
        return data and data.name, data and data.reaction, data and data.isHeader
    end
    local name, _, standing, _, _, _, _, _, header = GetFactionInfo(index)
    return name, standing, header
end

local function read_standings()
    local found, count = {}, C_Reputation and C_Reputation.GetNumFactions and C_Reputation.GetNumFactions() or (GetNumFactions and GetNumFactions()) or 0
    for index = 1, count do
        local name, standing, header = read_faction(index)
        if name and standing and not header then found[name] = standing end
    end
    return found
end

local function update_standings()
    local now = read_standings()
    for name, standing in pairs(now) do
        local before = standings and standings[name]
        local label = _G["FACTION_STANDING_LABEL" .. standing]
        if before and standing > before and label then render(string.format(library.texts.rise_reputation, name, label), REPUTATION_PICTURE, { done = true }) end
    end
    standings = now
end

local HEARD = { PLAYER_LEVEL_UP = render_level, SKILL_LINES_CHANGED = update_ranks, UPDATE_FACTION = update_standings, PLAYER_ENTERING_WORLD = update_ranks }

local events = CreateFrame("Frame")
library.update_events(events, { "PLAYER_LEVEL_UP", "SKILL_LINES_CHANGED", "UPDATE_FACTION", "PLAYER_ENTERING_WORLD" })
events:SetScript("OnEvent", function(_, event, first) library.update_safely("rise toast " .. event, HEARD[event], first) end)
