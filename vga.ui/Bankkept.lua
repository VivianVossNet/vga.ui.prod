-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: the bank as last seen, as the accepted draft draws it (manual/view/vga-bank-view.html, A, K1017): at every visit to a bank and every change while there, the contents of each page vga.ui's bank shows (vga.read_bank_pages) are kept for the character (LibVGACharacter.bank_kept) - for each slot the item's link, picture, count and quality - with the time; a key in the stance keys' look - LibVGA's cell, the game's bank picture - made here for the work bar above the bars' widget, which places it (vga.create_bank_key, vga.ui/Workbar.lua, K1019, K1020), opens the kept bank in LibVGA's window with pages: in its sidebar each kept page under its name, on each LibVGA's slot page (library.create_slot_page) of LibVGA's item cells, eight to a row as at the bank, each with its count and, under the mouse, the game's tooltip of its link, nothing to take or deposit; beneath the slots »Stand: … · zuletzt bei der Bank« with day and time; the player's gold in the status line. Before any visit the key is greyed, opens nothing, and its tooltip says to visit a bank once; after one its tooltip names when the bank was seen.

-- {K1019} {K1017}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local PAGES = 9
local PICTURES = { "Interface\\Icons\\Achievement_GuildPerk_MobileBanking", "Interface\\Icons\\INV_Misc_Bag_10" }
local window
local button
local at_bank

local function read_kept()
    return LibVGACharacter and LibVGACharacter.bank_kept
end

local function read_item(bag, slot)
    local found = C_Container.GetContainerItemInfo(bag, slot)
    if not found then return false end
    return { link = found.hyperlink, icon = found.iconFileID, count = found.stackCount, quality = found.quality }
end

local function read_page(entry)
    local size, items = C_Container.GetContainerNumSlots(entry.bag) or 0, {}
    for slot = 1, size do items[slot] = read_item(entry.bag, slot) end
    return { title = entry.title, size = size, items = items }
end

local function write_kept()
    if not (at_bank and vga.read_bank_pages) then return end
    local pages = {}
    for _, entry in ipairs(vga.read_bank_pages()) do pages[#pages + 1] = read_page(entry) end
    LibVGACharacter = LibVGACharacter or {}
    LibVGACharacter.bank_kept = { at = time(), pages = pages }
    vga.update_bank_kept_button()
end

local function read_stamp(kept)
    return date("%d.%m. %H:%M", kept.at)
end

local function read_cell(page, slot)
    page.kept_cells[slot] = page.kept_cells[slot] or library.create_cell(page.slots, { kind = "slot", item = true })
    return page.kept_cells[slot]
end

local function update_kept_page(page, kept_page, kept)
    local cells = {}
    for slot = 1, kept_page.size do
        local cell, item = read_cell(page, slot), kept_page.items[slot]
        library.update_cell_size(cell, library.read_draft_size(vga.bank_slot_plan.cell))
        library.update_cell(cell, item and { picture = item.icon, count = item.count, quality = item.quality, link = item.link } or {})
        cells[slot] = cell
    end
    for slot = kept_page.size + 1, #page.kept_cells do page.kept_cells[slot]:Hide() end
    library.update_slot_page(page, cells)
    page.stamp:SetFontObject(library.read_font("small"))
    page.stamp:SetText(string.format(library.texts.bank_kept_at, read_stamp(kept)))
    local _, height = library.update_grid(page.grid, { { page.slots }, { page.stamp } }, page:GetWidth())
    return height or 0
end

local function update_window()
    local kept = read_kept()
    if not (window and window:IsShown() and kept) then return end
    for index = 1, PAGES do
        local kept_page = kept.pages[index]
        library.update_sidebar_entry(window.sidebar, "kept" .. index, kept_page and kept_page.title, kept_page ~= nil)
        window.titles["kept" .. index] = kept_page and kept_page.title or ""
    end
    if not kept.pages[tonumber((window.chosen or ""):match("%d+") or 0) or 0] then window.chosen = "kept1" end
    library.update_paged_window(window, library.read_paged_window_width(window, library.read_slot_page_width(vga.bank_slot_plan)))
    library.update_dialog_status(window, library.texts.gold_label, GetMoney and GetMoney() or 0)
    window.heading:SetText(window.titles[window.chosen] or "")
    local index = tonumber(window.chosen:match("%d+"))
    local height = update_kept_page(window.pages[window.chosen], kept.pages[index], kept)
    local band = math.ceil(window.heading:GetStringHeight()) + 2 * library.read_size(-2)
    window:SetHeight(library.read_dialog_frame_height(window) + band + height + library.read_size(0))
end

local function create_kept_page(page)
    page.kept_cells = {}
    library.create_slot_page(page, vga.bank_slot_plan)
    page.stamp = library.create_text(page, "small", colours.quiet)
    page.grid = library.create_grid(page, { columns = { "auto" }, row = 0, row_gap = 10, y = "top", x = "right" })
end

local function render_page_chosen(_, key)
    window.chosen = key
    update_window()
end

local function create_window()
    local texts = library.texts
    local entries, pages = {}, {}
    for index = 1, PAGES do
        entries[index] = { key = "kept" .. index, title = texts.bank, icon = "TabBank" }
        pages[index] = { key = "kept" .. index, title = texts.bank, build = create_kept_page }
    end
    window = library.create_paged_window("VGABankKeptWindow", { title = texts.bank_kept_title, groups = { { title = texts.bank, entries = entries } }, pages = pages, foot = { status = true }, on_page = render_page_chosen })
end

local function render_kept()
    if not read_kept() then return end
    if window and window:IsShown() then return window:Hide() end
    if not window then create_window() end
    window.chosen = window.chosen or "kept1"
    library.update_dialog_placed(window)
    window:Show()
    update_window()
    library.update_paged_window_page(window, window.chosen)
end

local function render_button_tip(self)
    local kept = read_kept()
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine(library.texts.bank_view, colours.gold[1], colours.gold[2], colours.gold[3])
    GameTooltip:AddLine(kept and string.format(library.texts.bank_view_kept, read_stamp(kept)) or library.texts.bank_view_none, 1, 1, 1, true)
    GameTooltip:Show()
end

local function render_button_tip_hidden(self)
    if GameTooltip:GetOwner() == self then GameTooltip:Hide() end
end

local function read_picture()
    for _, picture in ipairs(PICTURES) do
        if not C_Texture or not C_Texture.GetFileIDFromPath or C_Texture.GetFileIDFromPath(picture) then return picture end
    end
    return PICTURES[#PICTURES]
end

function vga.update_bank_kept_button(size)
    if not button then return end
    if size then library.update_cell_size(button, size) end
    library.update_cell(button, { picture = button.picture_file, unusable = read_kept() == nil })
end

function vga.create_bank_key(parent)
    button = library.create_cell(parent, { kind = "slot", name = "VGABankKeptButton" })
    button.picture_file = read_picture()
    button:SetScript("OnClick", function() library.update_safely("bank kept", render_kept) end)
    button:SetScript("OnEnter", render_button_tip)
    button:SetScript("OnLeave", render_button_tip_hidden)
    vga.update_bank_kept_button()
    return button
end

local function update_opened()
    at_bank = true
    write_kept()
end

local function update_closed()
    write_kept()
    at_bank = false
end

local HEARD = { BANKFRAME_OPENED = update_opened, BANKFRAME_CLOSED = update_closed, PLAYERBANKSLOTS_CHANGED = write_kept, BAG_UPDATE_DELAYED = write_kept, BANK_TABS_CHANGED = write_kept }

local events = CreateFrame("Frame")
library.update_events(events, { "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "PLAYERBANKSLOTS_CHANGED", "BAG_UPDATE_DELAYED", "BANK_TABS_CHANGED" })
events:SetScript("OnEvent", function(_, event) library.update_safely("bank kept " .. event, HEARD[event]) end)
