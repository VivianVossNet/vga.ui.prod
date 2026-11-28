-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: reads a sentence of the game's own, in the player's language, by the game's own pattern for it (K1036, K1037): a global string such as DUEL_WINNER_KNOCKOUT »%1$s hat %2$s in einem Duell besiegt« or ERR_ZONE_EXPLORED_XP »Entdeckt: %s: %d Erfahrung erhalten« is turned once into a Lua pattern - its signs taken literally, each %s or %1$s a word, each %d a number -, and a message is read against it: the words come back in the order the string numbers them, whatever order the language puts them in. A message the game keeps secret (issecretvalue, manual/16 R3.2) or a string the game lacks reads nothing. vga.ui/Dueltoast.lua and vga.ui/Discoverytoast.lua use it.

-- {K1037} {K1036}

local _, vga = ...
local MAGIC = "[%(%)%.%[%]%*%+%-%?%^%$]"
local made = {}

local function read_made(format)
    if made[format] then return made[format] end
    local order = {}
    local function read_numbered(place, kind)
        order[#order + 1] = tonumber(place)
        return kind == "d" and "(%d+)" or "(.+)"
    end
    local function read_plain(kind)
        order[#order + 1] = #order + 1
        return kind == "d" and "(%d+)" or "(.+)"
    end
    local pattern = format:gsub(MAGIC, "%%%0"):gsub("%%(%d)%%%$([sd])", read_numbered):gsub("%%([sd])", read_plain)
    made[format] = { pattern = "^" .. pattern .. "$", order = order }
    return made[format]
end

function vga.read_game_sentence(format, message)
    if type(format) ~= "string" or type(message) ~= "string" then return nil end
    if issecretvalue and issecretvalue(message) then return nil end
    local shape = read_made(format)
    local found = { message:match(shape.pattern) }
    if #found == 0 then return nil end
    local words = {}
    for index, place in ipairs(shape.order) do words[place] = found[index] end
    return words
end
