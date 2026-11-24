-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.ui's bank, as the accepted draft draws it (manual/view/vga-npc-windows.html, K0830, K0831): LibVGA's window with pages - Bank, Taschenplätze in the menu bar with the accepted flat icons -, the bank's own slots as LibVGA's cells on the grid, each with its item's picture and count, its tooltip over the cell, a right click taking the item to the bags, a left click picking it up as the game does; the bank's bag places as cells too; The game's bank window is veiled, never hidden, so the visit stays open (K0835). Drawn as the draft draws it (K0836): one page, the bank's slots rimmed in their item's quality, beneath them LibVGA's section »Taschenplätze« (library.create_section, K0873) with the bag places, the next place's cost and the gold »Platz kaufen« in one row, the player's gold in the status line. On a client whose character bank has tabs - Enum.BagIndex.CharacterBankTab_1 and on - the slots of every tab stand in one grid and the bag places and their buying, which such a bank has not, are left out; each part is drawn on its own guard, so one the game refuses leaves the others; at every opening the game's bank is measured into LibVGASettings.measures.bank - its bank containers and their slots, the old container's, and C_Bank's functions (K0850).

-- {K0873} {K0860} {K0850} {K0838} {K0836} {K0835} {K0830} {K0831} {K0832}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local WIDTH, HEIGHT = 560, 470
local CELL = 36
local COLUMNS = 7
local GAP = 6
local BANK = -1
local BANK_BAGS = 7
local TABS = 6
local window

local function read_bank_containers()
    local first = Enum and Enum.BagIndex and Enum.BagIndex.CharacterBankTab_1
    if not first then return { BANK }, false end
    local containers = {}
    for index = 1, TABS do
        local id = Enum.BagIndex["CharacterBankTab_" .. index]
        if id then containers[#containers + 1] = id end
    end
    return containers, true
end

local function write_bank_measure()
    local found = {}
    for key, id in pairs(Enum and Enum.BagIndex or {}) do
        if tostring(key):find("Bank") then found[#found + 1] = key .. "=" .. tostring(id) .. ":" .. tostring(C_Container.GetContainerNumSlots(id)) end
    end
    table.sort(found)
    local bank = {}
    for key in pairs(C_Bank or {}) do bank[#bank + 1] = key end
    table.sort(bank)
    LibVGASettings.measures = LibVGASettings.measures or {}
    LibVGASettings.measures.bank = table.concat(found, " ") .. " | old -1:" .. tostring(C_Container.GetContainerNumSlots(BANK)) .. " GetNumBankSlots:" .. type(GetNumBankSlots) .. " | C_Bank: " .. table.concat(bank, " ")
end

local function read_bank_bag(index)
    local first = (Enum and Enum.BagIndex and Enum.BagIndex.BankBag_1) or ((NUM_BAG_SLOTS or 4) + 1)
    return first + index - 1
end

local function render_cell_clicked(cell, button)
    if not cell.bag then return end
    if button == "RightButton" then return C_Container.UseContainerItem(cell.bag, cell.slot) end
    C_Container.PickupContainerItem(cell.bag, cell.slot)
end

local function render_cell_tip(cell)
    if not cell.bag then return end
    library.update_item_tip_owner(GameTooltip, cell)
    GameTooltip:SetBagItem(cell.bag, cell.slot)
    GameTooltip:Show()
end

local function render_tip_hidden()
    GameTooltip:Hide()
end

local function create_bank_cell(parent)
    local cell = library.create_cell(parent, { kind = "slot" })
    cell:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    cell:SetScript("OnClick", render_cell_clicked)
    cell:SetScript("OnEnter", render_cell_tip)
    cell:SetScript("OnLeave", render_tip_hidden)
    cell.count = library.create_text(cell, "figures_small", colours.ink)
    return cell
end

local function read_cell(cells, parent, index)
    cells[index] = cells[index] or create_bank_cell(parent)
    return cells[index]
end

local function update_cell(cell, bag, slot)
    local found = C_Container.GetContainerItemInfo and C_Container.GetContainerItemInfo(bag, slot)
    cell.bag, cell.slot = bag, slot
    library.update_cell_size(cell, library.read_draft_size(CELL))
    library.update_cell(cell, { picture = found and found.iconFileID, quality = found and found.quality })
    cell.count:SetText(found and found.stackCount and found.stackCount > 1 and found.stackCount or "")
    library.update_cell_inside(cell, nil, cell.count, 0)
    cell:Show()
end

local function read_rows(cells)
    local rows = {}
    for index, cell in ipairs(cells) do
        local row = math.floor((index - 1) / COLUMNS) + 1
        rows[row] = rows[row] or {}
        rows[row][#rows[row] + 1] = cell
    end
    return rows
end

local function update_slots(page, containers)
    local count = 0
    for _, bag in ipairs(containers) do
        for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
            count = count + 1
            update_cell(read_cell(window.cells, page.slots, count), bag, slot)
        end
    end
    for index = count + 1, #window.cells do window.cells[index]:Hide() end
    local _, height = library.update_grid(page.slots_grid, read_rows({ table.unpack(window.cells, 1, count) }), nil)
    page.slots:SetSize(COLUMNS * library.read_draft_size(CELL + GAP), height or 0)
end

local function update_bags(page)
    local bought = GetNumBankSlots and GetNumBankSlots() or 0
    local row = {}
    for index = 1, BANK_BAGS do
        local cell = read_cell(window.bag_cells, page.bags, index)
        local inventory = C_Container.ContainerIDToInventoryID and C_Container.ContainerIDToInventoryID(read_bank_bag(index))
        library.update_cell_size(cell, library.read_draft_size(CELL))
        library.update_cell(cell, { picture = inventory and GetInventoryItemTexture and GetInventoryItemTexture("player", inventory), unusable = index > bought })
        cell.bag = nil
        cell:Show()
        row[index] = cell
    end
    local _, height = library.update_grid(page.bags_grid, { row }, nil)
    page.bags:SetSize(BANK_BAGS * library.read_draft_size(CELL + GAP), height or 0)
end

local function update_buying(page, width)
    local texts, bought, full = library.texts, 0, false
    if GetNumBankSlots then bought, full = GetNumBankSlots() end
    local cost = not full and GetBankSlotCost and GetBankSlotCost(bought + 1) or nil
    page.next:SetText(cost and texts.next_slot or texts.no_more_slots)
    page.cost:SetShown(cost ~= nil)
    library.update_money(page.cost, cost or 0)
    library.update_button(page.buy)
    library.update_button_enabled(page.buy, cost ~= nil)
    local _, height = library.update_grid(page.buying_grid, { { page.next, page.cost, page.buy } }, width)
    page.buying:SetSize(width, height or 0)
end

local function update_bank_page(page)
    local width = page:GetWidth()
    local containers, tabbed = read_bank_containers()
    library.update_safely("bank slots", update_slots, page, containers)
    local rows = { { page.slots } }
    page.places:SetShown(not tabbed)
    if not tabbed then
        library.update_safely("bank bags", update_bags, page)
        library.update_safely("bank buying", update_buying, page, width)
        library.update_section(page.places, library.texts.bank_bags, { { page.bags }, { page.buying } }, width)
        rows[#rows + 1] = { page.places }
    end
    library.update_grid(page.grid, rows, width)
end

function vga.update_bank()
    if not (window and window:IsShown()) then return end
    library.update_paged_window(window, library.read_draft_size(WIDTH), library.read_draft_size(HEIGHT))
    library.update_dialog_status(window, library.texts.gold_label, GetMoney and GetMoney() or 0)
    update_bank_page(window.pages.bank)
end

local function render_slot_bought()
    if PurchaseSlot then PurchaseSlot() end
end

local function create_page(page)
    local texts = library.texts
    page.slots = CreateFrame("Frame", nil, page)
    page.slots_grid = library.create_grid(page.slots, { columns = { CELL, CELL, CELL, CELL, CELL, CELL, CELL }, gap = GAP, row = CELL, row_gap = GAP, y = "top" })
    page.places = library.create_section(page, { kind = "caption", gap = 10 })
    page.bags = CreateFrame("Frame", nil, page.places)
    page.bags_grid = library.create_grid(page.bags, { columns = { CELL, CELL, CELL, CELL, CELL, CELL, CELL }, gap = GAP, row = CELL, y = "top" })
    page.buying = CreateFrame("Frame", nil, page.places)
    page.next = library.create_text(page.buying, "small", colours.quiet)
    page.cost = library.create_money(page.buying, colours.ink)
    page.cost.kind = "small"
    page.buy = library.create_button(page.buying, texts.buy_slot, "gold", render_slot_bought)
    page.buying_grid = library.create_grid(page.buying, { columns = { "rest", "auto", "auto" }, gap = GAP, row = 0 })
    page.grid = library.create_grid(page, { columns = { "rest" }, row = 0, row_gap = 10, y = "top" })
end

local function render_closed()
    library.update_game_veiled(BankFrame, false)
    if CloseBankFrame then CloseBankFrame() end
end

local function create_window()
    local texts = library.texts
    local entries = { { key = "bank", title = texts.bank, icon = "TabBank" } }
    local pages = { { key = "bank", title = texts.bank, build = create_page } }
    window = library.create_paged_window("VGABankWindow", { title = texts.bank, groups = { { title = texts.bank, entries = entries } }, pages = pages, foot = { status = true }, on_page = vga.update_bank })
    window.cells, window.bag_cells = {}, {}
    window.buy, window.bags_heading = window.pages.bank.buy, window.pages.bank.places.heading
    library.update_dialog_closing(window, function() library.update_safely("bank closed", render_closed) end)
end

local function update_opened()
    if not window then create_window() end
    library.update_game_veiled(BankFrame, true)
    window.chosen = "bank"
    library.update_dialog_placed(window)
    window:Show()
    library.update_safely("bank measure", write_bank_measure)
    library.update_paged_window_page(window, "bank")
    vga.update_bank()
end

local function update_closed()
    if window and window:IsShown() then window:Hide() end
end

local HEARD = { BANKFRAME_OPENED = update_opened, BANKFRAME_CLOSED = update_closed, PLAYERBANKSLOTS_CHANGED = vga.update_bank, PLAYERBANKBAGSLOTS_CHANGED = vga.update_bank, BAG_UPDATE_DELAYED = vga.update_bank, PLAYER_MONEY = vga.update_bank }

local events = CreateFrame("Frame")
library.update_events(events, { "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "PLAYERBANKSLOTS_CHANGED", "PLAYERBANKBAGSLOTS_CHANGED", "BAG_UPDATE_DELAYED", "PLAYER_MONEY" })
events:SetScript("OnEvent", function(_, event) library.update_safely("bank " .. event, HEARD[event]) end)
