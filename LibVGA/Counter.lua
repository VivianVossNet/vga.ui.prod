-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's counter on rolls, each digit in its own measured window, and the ratio of two counters.

-- {K0789} {K0302} {K0312}

local library = LibVGA

local ROLL = 0.35

local function render_grouped(value)
    local text = tostring(math.floor(value + 0.5))
    local grouped = text:reverse():gsub("(%d%d%d)", "%1 "):reverse()
    return (grouped:gsub("^ ", ""))
end

local function create_slot(counter)
    local slot = CreateFrame("Frame", nil, counter)
    slot:SetClipsChildren(true)
    slot.old = slot:CreateFontString(nil, "OVERLAY")
    slot.new = slot:CreateFontString(nil, "OVERLAY")
    return slot
end

local function update_roll(counter, elapsed)
    counter.time = counter.time + elapsed
    local share = math.min(1, counter.time / ROLL)
    local eased = library.read_eased(share)
    local height = counter:GetHeight()
    for _, slot in ipairs(counter.slots) do
        if slot.rolling then
            local shift = height * eased * slot.rolling
            slot.old:SetPoint("CENTER", slot, "CENTER", 0, shift)
            slot.new:SetPoint("CENTER", slot, "CENTER", 0, shift - height * slot.rolling)
        end
    end
    if share >= 1 then
        for _, slot in ipairs(counter.slots) do
            if slot.rolling then
                slot.old:SetText(slot.new:GetText())
                slot.old:SetPoint("CENTER", slot, "CENTER", 0, 0)
                slot.new:SetText("")
                slot.rolling = nil
            end
        end
        counter:SetScript("OnUpdate", nil)
    end
end

local function read_glyph_width(counter, character)
    if character == " " then
        counter.probe:SetText("0")
        return math.ceil(counter.probe:GetStringWidth() * 0.3)
    end
    counter.probe:SetText(character)
    return math.ceil(counter.probe:GetStringWidth())
end

local function update_counter_slots(counter, text, previous)
    local font = library.read_font("figures_" .. counter.kind)
    counter.probe:SetFontObject(font)
    counter.probe:SetText("0")
    local height = math.ceil(counter.probe:GetStringHeight()) + 2
    local x = 0
    for index = 1, #text do
        local slot = counter.slots[index]
        local character = text:sub(index, index)
        local width = read_glyph_width(counter, character)
        local before = previous and previous:sub(index, index)
        if before and before ~= character and before ~= " " then
            width = math.max(width, read_glyph_width(counter, before))
        end
        slot:ClearAllPoints()
        slot:SetSize(width, height)
        slot:SetPoint("LEFT", counter, "LEFT", x, 0)
        x = x + width
    end
    counter:SetSize(math.max(x, 1), height)
end

local function update_counter_layout(counter, text)
    local font = library.read_font("figures_" .. counter.kind)
    for index = 1, #text do
        local slot = counter.slots[index] or create_slot(counter)
        counter.slots[index] = slot
        local character = text:sub(index, index)
        for _, part in ipairs({ slot.old, slot.new }) do
            part:SetFontObject(font)
            if counter.colour then part:SetTextColor(unpack(counter.colour)) end
        end
        slot.old:SetText(character == " " and "" or character)
        slot.old:SetPoint("CENTER", slot, "CENTER", 0, 0)
        slot.new:SetText("")
        slot.rolling = nil
        slot:Show()
    end
    for index = #text + 1, #counter.slots do
        counter.slots[index]:Hide()
    end
    update_counter_slots(counter, text)
    counter:SetScript("OnUpdate", nil)
end

function library.create_counter(parent, kind, colour)
    local counter = CreateFrame("Frame", nil, parent)
    counter.kind, counter.colour, counter.slots = kind, colour, {}
    counter.probe = counter:CreateFontString(nil, "OVERLAY")
    counter.probe:Hide()
    counter.plain = counter:CreateFontString(nil, "OVERLAY")
    counter.plain:SetPoint("CENTER")
    return counter
end

function library.update_counter(counter, value)
    if issecretvalue and issecretvalue(value) then
        for _, slot in ipairs(counter.slots) do slot:Hide() end
        counter.plain:SetFontObject(library.read_font("figures_" .. counter.kind))
        if not pcall(counter.plain.SetFormattedText, counter.plain, "%s", value) then counter.plain:SetText("") end
        counter.plain:Show()
        counter.shown, counter.value = nil, nil
        counter:SetSize(library.read_size(6), library.read_size(1))
        return
    end
    counter.plain:Hide()
    local text = render_grouped(value)
    if not counter.shown or #text ~= #counter.shown or counter.font ~= library.read_base() then
        counter.font = library.read_base()
        update_counter_layout(counter, text)
        counter.shown, counter.value = text, value
        return
    end
    local direction = value > counter.value and 1 or -1
    local moving = false
    for index = 1, #text do
        local slot, character = counter.slots[index], text:sub(index, index)
        if character ~= counter.shown:sub(index, index) and character ~= " " then
            if slot.rolling then slot.old:SetText(slot.new:GetText()) end
            slot.new:SetText(character)
            slot.rolling = direction
            moving = true
        end
    end
    update_counter_slots(counter, text, counter.shown)
    counter.shown, counter.value = text, value
    if moving then
        counter.time = 0
        counter:SetScript("OnUpdate", update_roll)
    end
end

function library.create_ratio(parent, kind)
    local ratio = CreateFrame("Frame", nil, parent)
    ratio.plain = library.create_text(ratio, kind)
    ratio.plain:SetPoint("CENTER")
    ratio.left = library.create_counter(ratio, kind)
    ratio.slash = library.create_text(ratio, kind)
    ratio.slash:SetText("/")
    ratio.right = library.create_counter(ratio, kind)
    return ratio
end

function library.update_ratio_kind(ratio, kind)
    if ratio.left.kind == kind then return end
    for _, counter in ipairs({ ratio.left, ratio.right }) do
        counter.kind, counter.font, counter.shown = kind, nil, nil
    end
    ratio.plain:SetFontObject(library.read_font("figures_" .. kind))
    ratio.slash:SetFontObject(library.read_font("figures_" .. kind))
end

function library.update_ratio(ratio, value, most)
    local secret = issecretvalue and (issecretvalue(value) or issecretvalue(most))
    ratio.left:SetShown(not secret)
    ratio.slash:SetShown(not secret)
    ratio.right:SetShown(not secret)
    ratio.plain:SetShown(secret)
    if secret then
        ratio.plain:SetFontObject(library.read_font("figures_" .. ratio.left.kind))
        if not pcall(ratio.plain.SetFormattedText, ratio.plain, "%s / %s", value, most) then ratio.plain:SetText("") end
        ratio:SetSize(library.read_size(6) * 2, library.read_size(1))
        return
    end
    library.update_counter(ratio.left, value)
    library.update_counter(ratio.right, most)
    ratio.slash:SetFontObject(library.read_font("figures_" .. ratio.left.kind))
    ratio.left:ClearAllPoints()
    ratio.slash:ClearAllPoints()
    ratio.right:ClearAllPoints()
    local gap = library.read_size(-4)
    ratio.left:SetPoint("LEFT", ratio, "LEFT")
    ratio.slash:SetPoint("LEFT", ratio.left, "RIGHT", gap, 0)
    ratio.right:SetPoint("LEFT", ratio.slash, "RIGHT", gap, 0)
    ratio:SetSize(ratio.left:GetWidth() + ratio.slash:GetStringWidth() + ratio.right:GetWidth() + 2 * gap, ratio.left:GetHeight())
end
