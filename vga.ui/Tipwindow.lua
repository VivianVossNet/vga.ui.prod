-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: the item tooltip fixed into a window, as the accepted draft draws it (manual/view/vga-tooltip.html, K0604) after Crusader Kings III: while an item's tooltip shows and the mouse stands still, a small grey figure at its upper right counts the seconds down - 3, 2, 1 - (K0759); at the end of the seconds the settings choose - 1, 2 or 3, three by default, on the tab Komfort - the tooltip becomes a window of LibVGA's dialog laid so that the item's lines stay exactly where the tooltip showed them, the tooltip's own frame and gold corner gone (K0756): »Gegenstand« in the head with LibVGA's dialog pin and the close - every new window starts free, to be dragged where it is wanted, pinned it holds its place (K0764) -, the game's lines of the item beneath, and LibVGA's accordions »AUKTIONEN« and »ENTZAUBERN« with their chevrons, opened and closed by a click - the auctions with the history graph of thirty days, market value, lowest now, the seven days' trend as a chip and the basis; disenchanting with each material's amount, chance and market value, the expected value and the basis (K0752). The middle mouse button fixes at once; nothing is fixed in a fight. A window not pinned goes a second after the mouse leaves it; a pinned one stays until closed (K0753).

-- {K0753} {K0764} {K0759} {K0756} {K0604} {K0752}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local DELAYS = { 1, 2, 3 }
local LEAVE_AFTER = 1
local GRAPH_DAYS = 30
local LEAST_WIDTH = 250
local watch = { still = 0 }
local window

local function read_delay()
    return DELAYS[LibVGASettings.tip_fix_after or 3] or 3
end

local function read_shown_link()
    if not (GameTooltip:IsShown() and GameTooltip.GetItem) then return nil end
    local _, link = GameTooltip:GetItem()
    return link
end

local function create_line(parent, kind)
    local line = { label = library.create_text(parent, "small", colours.quiet), chance = library.create_text(parent, "small", colours.quiet) }
    line.label:SetJustifyH("LEFT")
    line.label:SetWordWrap(true)
    line.value = library.create_text(parent, "small", colours.ink)
    line.money = library.create_money(parent, colours.ink)
    line.money.kind = "small"
    line.kind = kind
    return line
end

local function read_line(fold, index)
    fold.lines[index] = fold.lines[index] or create_line(fold)
    return fold.lines[index]
end

local function update_line(line, top, width, label, chance, copper, words)
    local pad = library.read_draft_size(12)
    line.money:SetShown(copper ~= nil)
    if copper then library.update_money(line.money, copper) end
    line.value:SetText(copper == nil and (words or "–") or "")
    line.chance:SetText(chance or "")
    local right = copper and line.money:GetWidth() or line.value:GetStringWidth()
    local middle = chance and line.chance:GetStringWidth() + pad or 0
    line.label:SetText(label)
    line.label:SetWidth(math.max(1, width - right - middle - pad))
    line.label:ClearAllPoints()
    line.label:SetPoint("TOPLEFT", 0, -top)
    line.chance:ClearAllPoints()
    line.chance:SetPoint("TOPRIGHT", -(right + pad), -top)
    line.value:ClearAllPoints()
    line.value:SetPoint("TOPRIGHT", 0, -top)
    line.money:ClearAllPoints()
    line.money:SetPoint("TOPRIGHT", 0, -top)
    return top + line.label:GetStringHeight() + library.read_draft_size(4)
end

local function update_lines_left(fold, used)
    for index = used + 1, #fold.lines do
        local line = fold.lines[index]
        for _, part in ipairs({ line.label, line.chance, line.value, line.money }) do part:Hide() end
    end
    for index = 1, used do
        local line = fold.lines[index]
        for _, part in ipairs({ line.label, line.chance, line.value }) do part:Show() end
    end
end

local function read_rounded(copper)
    return copper and math.floor(copper + 0.5)
end

local function update_auctions_fold(fold, item, width)
    local texts = library.texts
    local market, lowest, offers = vga.read_market(item)
    local height = library.read_draft_size(44)
    library.update_graph(fold.graph, vga.read_history_graph(item, GRAPH_DAYS), width, height)
    fold.graph:ClearAllPoints()
    fold.graph:SetPoint("TOPLEFT")
    local top = height + library.read_draft_size(6)
    top = update_line(read_line(fold, 1), top, width, texts.market_value, nil, read_rounded(market))
    top = update_line(read_line(fold, 2), top, width, texts.lowest_now, nil, read_rounded(lowest))
    local _, median = vga.read_days(item, GRAPH_DAYS)
    local days = 0
    for _ in pairs(median) do days = days + 1 end
    top = update_line(read_line(fold, 3), top, width, texts.basis, nil, nil, string.format(texts.offers_days, offers or 0, days))
    fold.chip:ClearAllPoints()
    fold.chip:SetPoint("TOPRIGHT", 0, -top)
    library.update_chip(fold.chip, vga.read_week_trend(item))
    top = update_line(read_line(fold, 4), top, width, texts.days_7, nil, nil, "")
    update_lines_left(fold, 4)
    return top
end

local function read_material_name(item)
    local name = C_Item.GetItemNameByID and C_Item.GetItemNameByID(item)
    if not name and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(item) end
    return name or "…"
end

local function read_amount(yield)
    if yield[2] == yield[3] then return yield[2] .. "×" end
    return yield[2] .. "–" .. yield[3] .. "×"
end

local function read_chance(share)
    return (string.format("%.1f", share):gsub("%.0$", ""):gsub("%.", ",")) .. " %"
end

local function update_disenchant_fold(fold, found, width)
    local texts = library.texts
    local top = 0
    for index, yield in ipairs(found.yields) do
        top = update_line(read_line(fold, index), top, width, read_amount(yield) .. " " .. read_material_name(yield[1]), read_chance(yield[4]), read_rounded(vga.read_market(yield[1])))
    end
    local used = #found.yields
    top = update_line(read_line(fold, used + 1), top, width, texts.expected_value, nil, read_rounded(vga.read_disenchant_value(found)))
    local basis = found.learned and string.format(texts.disenchant_learned, found.learned) or string.format(texts.disenchant_rule, found.band[1], found.band[2])
    top = update_line(read_line(fold, used + 2), top, width, texts.basis, nil, nil, basis)
    update_lines_left(fold, used + 2)
    return top
end

local function create_fold(parent)
    local fold = CreateFrame("Frame", nil, parent)
    fold.lines = {}
    return fold
end

local function create_section(key)
    local label = library.create_accordion(window.body)
    label.key = key
    label.fold = create_fold(window.body)
    label:SetScript("OnClick", function(self)
        LibVGASettings.tip_open = LibVGASettings.tip_open or {}
        LibVGASettings.tip_open[self.key] = not LibVGASettings.tip_open[self.key] or nil
        library.update_safely("tip window", vga.update_tip_window)
    end)
    return label
end

local function check_open(key)
    return LibVGASettings.tip_open ~= nil and LibVGASettings.tip_open[key] == true
end

local function update_section(label, word, copper, top, width, fill)
    local open = check_open(label.key)
    local height = library.update_accordion(label, library.read_capitals(word), open, width, copper == nil and "–" or nil, copper)
    label:ClearAllPoints()
    label:SetPoint("TOPLEFT", 0, -top)
    label:Show()
    top = top + height
    label.fold:SetShown(open)
    if not open then return top end
    local pad = library.read_draft_size(12)
    local inner = width - 2 * pad - library.read_draft_size(20)
    local used = fill(label.fold, inner)
    label.fold:SetSize(inner, used)
    label.fold:ClearAllPoints()
    label.fold:SetPoint("TOPLEFT", pad + library.read_draft_size(20), -top)
    return top + used + library.read_draft_size(6)
end

local function update_sections(top, width)
    local item = window.item
    local market = vga.read_market(item)
    window.auctions:Hide()
    window.auctions.fold:Hide()
    if market then
        top = update_section(window.auctions, library.texts.auctions, read_rounded(market), top, width, function(fold, inner) return update_auctions_fold(fold, item, inner) end)
    end
    local found = vga.check_enchanter() and vga.read_disenchant(window.link)
    window.disenchant:Hide()
    window.disenchant.fold:Hide()
    if found then
        top = update_section(window.disenchant, library.texts.disenchant, read_rounded(vga.read_disenchant_value(found)), top, width, function(fold, inner) return update_disenchant_fold(fold, found, inner) end)
    end
    return top
end

function vga.update_tip_window()
    if not (window and window.link) then return end
    library.update_dialog(window)
    local pad = library.read_size(-2)
    local lines = window.lines
    local width = math.max(library.read_draft_size(LEAST_WIDTH), lines:GetWidth())
    lines:ClearAllPoints()
    lines:SetPoint("TOPLEFT", window.body, "TOPLEFT", 0, 0)
    local top = update_sections(lines:GetHeight(), width)
    local head = library.read_size(4) + library.read_size(-4)
    window:SetSize(width + 2 * library.read_size(-4), head + top + pad + library.read_size(-4))
end

local function update_left(_, elapsed)
    if window.pinned or window:IsMouseOver() then
        window.away = 0
        return
    end
    window.away = (window.away or 0) + elapsed
    if window.away >= LEAVE_AFTER then window:Hide() end
end

local TIP_PIN = {
    read = function() return window.pinned == true end,
    write = function(pinned) window.pinned = pinned or nil end,
    read_note = function(pinned) return pinned and library.texts.tip_unpin or library.texts.tip_pin end,
}

local function create_window()
    window = library.create_dialog("VGATipWindow", library.texts.item)
    library.update_dialog_pin_state(window, TIP_PIN)
    window.lines = CreateFrame("GameTooltip", "VGATipWindowLines", window.body, "GameTooltipTemplate")
    window.lines.vga_window = true
    library.update_tooltip_bare(window.lines)
    window.lines:SetScript("OnSizeChanged", function() library.update_safely("tip window size", vga.update_tip_window) end)
    window.auctions = create_section("auctions")
    window.auctions.fold.graph = library.create_graph(window.auctions.fold)
    window.auctions.fold.chip = library.create_chip(window.auctions.fold)
    window.disenchant = create_section("disenchant")
    window:SetScript("OnUpdate", function(_, elapsed) library.update_safely("tip window leave", update_left, nil, elapsed) end)
    window:Hide()
end

local function render_window(link)
    if not window then create_window() end
    local left, top = GameTooltip:GetLeft(), GameTooltip:GetTop()
    window.link, window.item, window.away, window.pinned = link, C_Item.GetItemInfoInstant(link), 0, nil
    library.update_dialog_pin(window)
    window.lines:SetOwner(window, "ANCHOR_NONE")
    window.lines:SetHyperlink(link)
    library.update_tooltip_bare(window.lines)
    window.lines:Show()
    window:ClearAllPoints()
    local inner, head = library.read_size(-4), library.read_size(4)
    if left and top then window:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left - inner, top + inner + head + 1) else window:SetPoint("CENTER") end
    window:Show()
    vga.update_tip_window()
    GameTooltip:Hide()
end

local function create_countdown()
    watch.count = library.create_text(GameTooltip, "small", colours.quiet)
    watch.count:Hide()
end

local function update_countdown()
    local left = math.max(1, math.ceil(read_delay() - watch.still))
    watch.count:SetFontObject(library.read_font("small"))
    watch.count:SetText(left)
    watch.count:ClearAllPoints()
    watch.count:SetPoint("TOPRIGHT", GameTooltip, "TOPRIGHT", -(library.read_size(-6) + library.read_size(0) + library.read_size(-6)), -library.read_size(-6))
    watch.count:Show()
end

function vga.read_tip_countdown()
    return watch.count
end

local function update_watch_reset()
    watch.link, watch.still = nil, 0
    if watch.count then watch.count:Hide() end
end

local function check_fixable(link)
    return link ~= nil and not InCombatLockdown() and not (window and window:IsShown() and window.link == link)
end

local function update_watch(_, elapsed)
    local link = read_shown_link()
    if not check_fixable(link) then return update_watch_reset() end
    local x, y = GetCursorPosition()
    if link ~= watch.link or x ~= watch.x or y ~= watch.y then
        watch.link, watch.x, watch.y, watch.still = link, x, y, 0
        update_countdown()
        return
    end
    watch.still = watch.still + elapsed
    update_countdown()
    if watch.still < read_delay() then return end
    update_watch_reset()
    render_window(link)
end

local function update_middle_button(button)
    if button ~= "MiddleButton" then return end
    local link = read_shown_link()
    if not check_fixable(link) then return end
    update_watch_reset()
    render_window(link)
end

local function create_watch()
    create_countdown()
    local driver = CreateFrame("Frame", "VGATipWatch", UIParent)
    driver:SetScript("OnUpdate", function(_, elapsed) library.update_safely("tip watch", update_watch, nil, elapsed) end)
    driver:RegisterEvent("GLOBAL_MOUSE_DOWN")
    driver:SetScript("OnEvent", function(_, _, button) library.update_safely("tip middle", update_middle_button, button) end)
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function()
    library.update_safely("tip window login", create_watch)
end)
