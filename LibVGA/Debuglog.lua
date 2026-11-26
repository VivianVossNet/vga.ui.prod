-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's debug log, what the debug console shows (K0919): it gathers, always and for the session, the Lua errors of every addon and of the game - by an error handler of its own laid before the one it found, which is still called, so Tinkerbox's and the game's own go on -, the actions the game blocked or forbade, the faults LibVGA catches itself (library.update_safely) and the messages of tests (library.render_debug); entries alike in kind, source and text - memory addresses reckoned out - are one entry with a counter, its first and last time and its detail; each knows its source - the first addon in its path or its stack that is neither the game's own nor this log's handler, so an error the game raises for an addon's code names that addon; the game where there is none; LibVGA; a test (K0970). It tells its listeners whenever an entry is written, and counts the errors and blocked actions not yet seen - messages never - until the console is opened, and keeps every entry new until it is closed again. One task: gather what the console shows.

-- {K0970} {K0919}

local library = LibVGA
local entries, keyed, listeners = {}, {}, {}
local unseen = 0
local GAME = "Blizzard_"
local OWN_ADDON, OWN_FILE = "LibVGA", "Debuglog.lua"

local function read_source(text)
    local addon = tostring(text):match("AddOns[/\\]([^/\\]+)[/\\]")
    if not addon then return nil end
    if addon:sub(1, #GAME) == GAME then return library.texts.debug_game end
    return addon
end

local function read_key(kind, source, text)
    local plain = tostring(text):gsub("0x%x+", ""):gsub("table: %x+", "table"):gsub("function: %x+", "function")
    return kind .. "|" .. tostring(source) .. "|" .. plain
end

local function update_listeners()
    for _, listener in ipairs(listeners) do library.update_safely("debug listener", listener) end
end

function library.write_debug(kind, source, text, detail)
    local key = read_key(kind, source, text)
    local entry = keyed[key]
    if not entry then
        entry = { kind = kind, source = source, text = tostring(text), detail = detail or tostring(text), count = 0, first = date("%H:%M:%S") }
        keyed[key] = entry
        entries[#entries + 1] = entry
    end
    entry.count, entry.last, entry.stamp, entry.new = entry.count + 1, date("%H:%M:%S"), GetTime(), true
    if kind ~= "test" then unseen = unseen + 1 end
    update_listeners()
    return entry
end

function library.read_debug_entries(kind)
    local found = {}
    for _, entry in ipairs(entries) do
        if not kind or entry.kind == kind then found[#found + 1] = entry end
    end
    table.sort(found, function(one, other) return one.stamp > other.stamp end)
    return found
end

function library.read_debug_unseen()
    return unseen
end

function library.read_debug_new()
    local new = 0
    for _, entry in ipairs(entries) do
        if entry.new then new = new + 1 end
    end
    return new
end

function library.update_debug_opened()
    unseen = 0
    update_listeners()
end

function library.update_debug_seen()
    for _, entry in ipairs(entries) do entry.new = false end
    update_listeners()
end

function library.write_debug_cleared()
    entries, keyed, unseen = {}, {}, 0
    update_listeners()
end

function library.create_debug_listener(listener)
    listeners[#listeners + 1] = listener
end

local function read_stack_source(stack)
    for addon, file in tostring(stack):gmatch("AddOns[/\\]([^/\\]+)[/\\]([^%]:]+)") do
        local own = addon == OWN_ADDON and file == OWN_FILE
        if not own and addon:sub(1, #GAME) ~= GAME then return addon end
    end
    return nil
end

local function write_error(message)
    local text = tostring(message)
    local stack = debugstack and debugstack(3) or ""
    local source = read_stack_source(text) or read_stack_source(stack) or read_source(text) or library.texts.debug_game
    library.write_debug("error", source, text, text .. "\n" .. stack)
end

local function create_handler()
    local before = geterrorhandler and geterrorhandler()
    if not (seterrorhandler and before) then return end
    seterrorhandler(function(message, ...)
        pcall(write_error, message)
        return before(message, ...)
    end)
end

local function write_blocked(addon, action)
    local text = tostring(action) .. " · " .. library.texts.debug_blocked_one
    library.write_debug("blocked", addon or library.texts.debug_game, text, text)
end

create_handler()
local events = CreateFrame("Frame")
library.update_events(events, { "ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN" })
events:SetScript("OnEvent", function(_, _, addon, action) pcall(write_blocked, addon, action) end)
