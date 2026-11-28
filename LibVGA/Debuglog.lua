-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's debug log, what the debug console shows (K0919): it gathers, always, the Lua errors of every addon and of the game - by an error handler of its own laid before the one it found, which is still called, so Tinkerbox's and the game's own go on -, the actions the game blocked or forbade, the faults LibVGA catches itself (library.update_safely) and the messages of tests (library.render_debug); entries alike in kind, source and text - memory addresses reckoned out - are one entry with a counter, its first and last time and its detail; each knows its source - the first addon in its path or its stack that is neither the game's own nor this log's handler, so an error the game raises for an addon's code names that addon; the game where there is none; LibVGA; a test (K0970). It tells its listeners whenever an entry is written, and counts the errors and blocked actions not yet seen - messages never - until the console is opened, and keeps every entry new until it is closed again. One task: gather what the console shows. Errors and blocked actions are kept across sessions for the account (LibVGAAccount.debug_log): written at logout, the newest two hundred of the last seven days, each with its count and its first and last time as dates, and read back at login with what was still unseen, so the badge counts it again; a time of an earlier day reads its date; tests stay with their session; »Leeren« clears the kept ones too (K0988).

-- {K0988} {K0970} {K0919}

local library = LibVGA
local entries, keyed, listeners = {}, {}, {}
local unseen, order = 0, 0
local KEPT_DAYS = 7
local KEPT_MOST = 200
local DAY = 86400
local KEPT_KINDS = { error = true, blocked = true }
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

local function read_clock(at)
    if date("%Y%m%d", at) == date("%Y%m%d") then return date("%H:%M:%S", at) end
    return date("%d.%m. %H:%M", at)
end

local function update_entry_clock(entry)
    entry.first, entry.last = read_clock(entry.first_at), read_clock(entry.at)
end

local function write_entry(entry)
    local key = read_key(entry.kind, entry.source, entry.text)
    if keyed[key] then return keyed[key] end
    order = order + 1
    entry.order, entry.count = order, entry.count or 0
    keyed[key] = entry
    entries[#entries + 1] = entry
    return entry
end

function library.write_debug(kind, source, text, detail)
    local now = time()
    local entry = write_entry({ kind = kind, source = source, text = tostring(text), detail = detail or tostring(text), first_at = now })
    order = order + 1
    entry.count, entry.at, entry.order, entry.new = entry.count + 1, now, order, true
    update_entry_clock(entry)
    if kind ~= "test" then unseen = unseen + 1 end
    update_listeners()
    return entry
end

local function check_later(one, other)
    if one.at ~= other.at then return one.at > other.at end
    return one.order > other.order
end

function library.write_debug_kept()
    local kept, since = {}, time() - KEPT_DAYS * DAY
    for _, entry in ipairs(entries) do
        if KEPT_KINDS[entry.kind] and entry.at >= since then kept[#kept + 1] = entry end
    end
    table.sort(kept, check_later)
    for index = #kept, KEPT_MOST + 1, -1 do kept[index] = nil end
    local saved = {}
    for index, entry in ipairs(kept) do saved[index] = { kind = entry.kind, source = entry.source, text = entry.text, detail = entry.detail, count = entry.count, first_at = entry.first_at, at = entry.at, new = entry.new } end
    LibVGAAccount = LibVGAAccount or {}
    LibVGAAccount.debug_log = { entries = saved, unseen = unseen }
end

function library.update_debug_restored()
    local saved = LibVGAAccount and LibVGAAccount.debug_log
    if not saved then return end
    local since = time() - KEPT_DAYS * DAY
    for _, kept in ipairs(saved.entries or {}) do
        if KEPT_KINDS[kept.kind] and (kept.at or 0) >= since then
            local entry = write_entry({ kind = kept.kind, source = kept.source, text = kept.text, detail = kept.detail, first_at = kept.first_at or kept.at, at = kept.at, new = kept.new })
            if entry.order then entry.count = entry.count + (kept.count or 1) end
            entry.at = math.max(entry.at or 0, kept.at)
            update_entry_clock(entry)
        end
    end
    unseen = unseen + (saved.unseen or 0)
    update_listeners()
end

function library.read_debug_entries(kind)
    local found = {}
    for _, entry in ipairs(entries) do
        if not kind or entry.kind == kind then found[#found + 1] = entry end
    end
    table.sort(found, check_later)
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
    if LibVGAAccount then LibVGAAccount.debug_log = nil end
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
local HEARD = { PLAYER_LOGIN = library.update_debug_restored, PLAYER_LOGOUT = library.write_debug_kept }
library.update_events(events, { "ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN", "PLAYER_LOGIN", "PLAYER_LOGOUT" })
events:SetScript("OnEvent", function(_, event, addon, action)
    if HEARD[event] then return library.update_safely("debug " .. event, HEARD[event]) end
    pcall(write_blocked, addon, action)
end)
