-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.ui's bank, as the accepted draft A draws it (manual/view/vga-bank.html, K0894): LibVGA's window with pages (library.create_paged_window), in its sidebar every tab of the character's bank the player has bought, under its own name, and, while another can be bought, »Reiter kaufen«; a tab's page its slots eight to a row and six high, as the game's bank lays a tab of 48, each LibVGA's container slot - the game's own item button in a holder carrying the tab's number, so taking, dropping, moving, splitting, a right click and the tooltip are the game's own (library.create_container_slot, K0893) -, beneath them »Reagenzien einlagern«, which deposits as the game's own button does (C_Bank.AutoDepositItemsIntoBank); the page »Reiter kaufen« names the next tab, »Reiter 2 von 9«, and the game's own words for it, its cost in our coins and the gold »Kaufen«, off while the gold does not reach; »Kaufen« asks first in LibVGA's confirm dialog with the game's own question and amount line (library.render_confirm, K0897), only its »Kaufen« buying (C_Bank.PurchaseBankTab); once bought, the window turns to the new tab and »Reiter kaufen« offers the next or goes; the player's gold in the status line. Only what Forever offers is built, as measured (K0895): the character's bank, its tabs, their buying and the deposit; Forever offers no warband bank and no moving of gold into the character's. On a client without bank tabs the one page shows the old bank and its bag places under »Taschenplätze« (K0850). The game's bank window is veiled, never hidden, so the visit stays open; closing ours ends it through the game's close (K0835, K0890). Its tabs' slots are laid by LibVGA's slot page (library.create_slot_page), which the bank kept from the last visit lays too; vga.read_bank_pages names the pages there are, each with its title and container, for that keeping (K1017).

-- {K1017} {K0897} {K0896} {K0895} {K0894} {K0893} {K0891} {K0890} {K0873} {K0860} {K0850} {K0838} {K0836} {K0835} {K0830} {K0831} {K0832}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local CELL = 36
local COLUMNS = 8
local GAP = 6
local BANK = -1
local BANK_BAGS = 7
local TABS = 9
local window

local function read_kind()
    return Enum and Enum.BankType and Enum.BankType.Character
end

local function check_tabbed()
    return Enum and Enum.BagIndex and Enum.BagIndex.CharacterBankTab_1 ~= nil and C_Bank ~= nil
end

local function read_tab_bag(index)
    return Enum.BagIndex["CharacterBankTab_" .. index]
end

local function read_bought_tabs()
    local tabs = C_Bank.FetchPurchasedBankTabData and C_Bank.FetchPurchasedBankTabData(read_kind()) or {}
    local named = {}
    for index = 1, TABS do
        local bag = read_tab_bag(index)
        for _, tab in ipairs(tabs) do
            if bag and tab.ID == bag then named[index] = tab.name ~= "" and tab.name or nil end
        end
        named[index] = named[index] or (C_Container.GetContainerNumSlots(bag or BANK) or 0) > 0 and string.format(library.texts.bank_tab, index) or nil
    end
    return named
end

local function read_bank_bag(index)
    local first = (Enum and Enum.BagIndex and Enum.BagIndex.BankBag_1) or ((NUM_BAG_SLOTS or 4) + 1)
    return first + index - 1
end

local function read_bag_cell(index, parent)
    window.bag_cells[index] = window.bag_cells[index] or library.create_cell(parent, { kind = "slot" })
    return window.bag_cells[index]
end

local function read_slot(bag, slot, parent)
    window.holders[bag] = window.holders[bag] or library.create_container_holder(parent, bag)
    local holder = window.holders[bag]
    holder.slots[slot] = holder.slots[slot] or library.create_container_slot(holder, slot)
    return holder.slots[slot]
end

local SLOTS = { columns = COLUMNS, cell = CELL, gap = GAP }

local function read_slots_width()
    return library.read_slot_page_width(SLOTS)
end

local function update_slots(page, bag)
    local cells = {}
    for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
        local button = read_slot(bag, slot, page.slots)
        library.update_container_slot(button, bag, slot, {})
        cells[slot] = button
    end
    library.update_slot_page(page, cells)
end

local function update_bags(page)
    local bought = GetNumBankSlots and GetNumBankSlots() or 0
    local row = {}
    for index = 1, BANK_BAGS do
        local cell = read_bag_cell(index, page.bags)
        local inventory = C_Container.ContainerIDToInventoryID and C_Container.ContainerIDToInventoryID(read_bank_bag(index))
        library.update_cell_size(cell, library.read_draft_size(CELL))
        library.update_cell(cell, { picture = inventory and GetInventoryItemTexture and GetInventoryItemTexture("player", inventory), unusable = index > bought })
        cell:Show()
        row[index] = cell
    end
    local _, height = library.update_grid(page.bags_grid, { row }, nil)
    page.bags:SetSize(BANK_BAGS * library.read_draft_size(CELL + GAP) - library.read_draft_size(GAP), height or 0)
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

local function update_old_page(page)
    local width = page:GetWidth()
    library.update_safely("bank slots", update_slots, page, BANK)
    library.update_safely("bank bags", update_bags, page)
    library.update_safely("bank buying", update_buying, page, width)
    library.update_section(page.places, library.texts.bank_bags, { { page.bags }, { page.buying } }, width)
    local _, height = library.update_grid(page.grid, { { page.slots }, { page.places } }, width)
    return height
end

local function update_tab_page(page)
    library.update_safely("bank slots", update_slots, page, read_tab_bag(page.index))
    library.update_button(page.deposit)
    library.update_button_enabled(page.deposit, C_Bank.DoesBankTypeSupportAutoDeposit == nil or C_Bank.DoesBankTypeSupportAutoDeposit(read_kind()))
    local _, height = library.update_grid(page.grid, { { page.slots }, { page.deposit } }, page:GetWidth())
    return height
end

local function read_offer()
    local kind = read_kind()
    local offer = C_Bank.FetchNextPurchasableBankTabData and C_Bank.FetchNextPurchasableBankTabData(kind) or {}
    local most = C_Bank.FetchMaxNumBankTabs and C_Bank.FetchMaxNumBankTabs(kind) or TABS
    local next_tab = (C_Bank.FetchNumPurchasedBankTabs and C_Bank.FetchNumPurchasedBankTabs(kind) or 0) + 1
    local body = offer.purchasePromptBody or ""
    return { offer = offer, name = string.format(library.texts.bank_tab, next_tab), meta = string.format(library.texts.bank_tab_of, next_tab, most), words = body:match("^(.-)|n") or body, question = (body:gsub("|n", " "):gsub("%s+", " ")), ready = offer.canAfford == true and C_Bank.CanPurchaseBankTab(kind) }
end

local function update_offer_page(page)
    local read = read_offer()
    library.update_item_row(page.offer, { icon = library.media .. "TabBank", name = read.meta, sub = read.words, quality = 1, lines = 2 }, 0, page:GetWidth())
    library.update_money(page.cost, read.offer.tabCost or 0)
    library.update_button(page.buy)
    library.update_button_enabled(page.buy, read.ready)
    library.update_grid(page.grid, { { page.offer }, { page.buying } }, page:GetWidth())
    library.update_grid(page.buying_grid, { { page.cost, page.buy } }, page:GetWidth())
end

local function update_sidebar_old()
    for index = 1, TABS do library.update_sidebar_entry(window.sidebar, "tab" .. index, "", false) end
    library.update_sidebar_entry(window.sidebar, "buy", library.texts.bank_tab_buy, false)
    library.update_sidebar_entry(window.sidebar, "bank", library.texts.bank, true)
    window.chosen = "bank"
end

local function update_sidebar_tabs()
    library.update_sidebar_entry(window.sidebar, "bank", library.texts.bank, false)
    local named = read_bought_tabs()
    for index = 1, TABS do
        local key = "tab" .. index
        window.titles[key] = named[index] or ""
        library.update_sidebar_entry(window.sidebar, key, named[index], named[index] ~= nil)
    end
    local bought = C_Bank.FetchNumPurchasedBankTabs and C_Bank.FetchNumPurchasedBankTabs(read_kind()) or 0
    if window.chosen == "buy" and window.bought and bought > window.bought then window.chosen = "tab" .. bought end
    window.bought = bought
    local can = C_Bank.CanPurchaseBankTab and C_Bank.CanPurchaseBankTab(read_kind()) or false
    library.update_sidebar_entry(window.sidebar, "buy", library.texts.bank_tab_buy, can)
    if window.chosen ~= "buy" and not named[tonumber((window.chosen or ""):match("%d+") or 0) or 0] then window.chosen = "tab1" end
end

local function update_page(key)
    local page = window.pages[key]
    if key == "buy" then return update_offer_page(page) end
    if key == "bank" then return update_old_page(page) end
    return update_tab_page(page)
end

local function update_size()
    local main = window.tabbed and "tab1" or "bank"
    local height = update_page(main) or 0
    local band = math.ceil(window.heading:GetStringHeight()) + 2 * library.read_size(-2)
    window:SetHeight(library.read_dialog_frame_height(window) + band + height + library.read_size(0))
end

function vga.read_bank_pages()
    local found = {}
    if not check_tabbed() then return { { title = library.texts.bank, bag = BANK } } end
    local named = read_bought_tabs()
    for index = 1, TABS do
        if named[index] then found[#found + 1] = { title = named[index], bag = read_tab_bag(index) } end
    end
    return found
end

vga.bank_slot_plan = SLOTS

function vga.update_bank()
    if not (window and window:IsShown()) then return end
    library.update_safely("bank tabs", window.tabbed and update_sidebar_tabs or update_sidebar_old)
    library.update_paged_window(window, library.read_paged_window_width(window, read_slots_width()))
    library.update_dialog_status(window, library.texts.gold_label, GetMoney and GetMoney() or 0)
    window.heading:SetText(window.titles[window.chosen] or "")
    update_size()
    update_page(window.chosen)
end

local function render_slot_bought()
    if PurchaseSlot then PurchaseSlot() end
end

local function render_tab_purchased()
    C_Bank.PurchaseBankTab(read_kind())
end

local function render_tab_bought()
    local read = read_offer()
    library.render_confirm({ title = read.offer.purchasePromptTitle or library.texts.bank, icon = library.media .. "TabBank", name = read.name, meta = read.meta, question = read.question, label = read.offer.purchasePromptConfirmation or library.texts.price, copper = read.offer.tabCost or 0, word = library.texts.buy, ready = read.ready, on_confirm = render_tab_purchased })
end

local function render_deposit()
    C_Bank.AutoDepositItemsIntoBank(read_kind())
end

local function read_columns(count)
    local columns = {}
    for index = 1, count do columns[index] = CELL end
    return columns
end

local function create_slots(page)
    library.create_slot_page(page, SLOTS)
    page.grid = library.create_grid(page, { columns = { "auto" }, row = 0, row_gap = 10, y = "top", x = "right" })
end

local function create_old_page(page)
    local texts = library.texts
    create_slots(page)
    page.places = library.create_section(page, { kind = "caption", gap = 10 })
    page.bags = CreateFrame("Frame", nil, page.places)
    page.bags_grid = library.create_grid(page.bags, { columns = read_columns(BANK_BAGS), gap = GAP, row = CELL, y = "top" })
    page.buying = CreateFrame("Frame", nil, page.places)
    page.next = library.create_text(page.buying, "small", colours.quiet)
    page.cost = library.create_money(page.buying, colours.ink)
    page.cost.kind = "small"
    page.buy = library.create_button(page.buying, texts.buy_slot, "gold", render_slot_bought)
    page.buying_grid = library.create_grid(page.buying, { columns = { "rest", "auto", "auto" }, gap = GAP, row = 0 })
end

local function create_tab_page_maker(index)
    return function(page)
        page.index = index
        create_slots(page)
        page.deposit = library.create_button(page, library.texts.bank_deposit, "plain", render_deposit)
    end
end

local function create_offer_page(page)
    page.offer = library.create_item_row(page, {})
    page.buying = CreateFrame("Frame", nil, page)
    page.cost = library.create_money(page.buying, colours.ink)
    page.buy = library.create_button(page.buying, library.texts.buy, "gold", render_tab_bought)
    page.buying_grid = library.create_grid(page.buying, { columns = { "rest", "auto" }, gap = GAP, row = 0, x = { "right", "right" } })
    page.grid = library.create_grid(page, { columns = { "rest" }, row = 0, row_gap = 14, y = "top" })
end

local function read_plan(texts)
    local entries, pages = { { key = "bank", title = texts.bank, icon = "TabBank" } }, { { key = "bank", title = texts.bank, build = create_old_page } }
    for index = 1, TABS do
        local title = string.format(texts.bank_tab, index)
        entries[#entries + 1] = { key = "tab" .. index, title = title, icon = "TabBank" }
        pages[#pages + 1] = { key = "tab" .. index, title = title, build = create_tab_page_maker(index) }
    end
    entries[#entries + 1] = { key = "buy", title = texts.bank_tab_buy, icon = "TabBuy" }
    pages[#pages + 1] = { key = "buy", title = texts.bank_tab_buy, build = create_offer_page }
    return entries, pages
end

local function render_closed()
    library.render_game_ended(BankFrame, C_Bank and C_Bank.CloseBankFrame or CloseBankFrame)
end

local function render_page_chosen(_, key)
    window.chosen = key
    vga.update_bank()
end

local function create_window()
    local texts = library.texts
    local entries, pages = read_plan(texts)
    window = library.create_paged_window("VGABankWindow", { title = texts.bank, groups = { { title = texts.bank, entries = entries } }, pages = pages, foot = { status = true }, on_page = render_page_chosen })
    window.bag_cells, window.holders = {}, {}
    library.update_dialog_closing(window, function() library.update_safely("bank closed", render_closed) end)
end

local function update_opened()
    if not window then create_window() end
    library.update_game_veiled(BankFrame, true)
    window.tabbed = check_tabbed()
    window.chosen = window.tabbed and "tab1" or "bank"
    library.update_dialog_placed(window)
    window:Show()
    vga.update_bank()
    library.update_paged_window_page(window, window.chosen)
end

local function update_closed()
    if window and window:IsShown() then window:Hide() end
end

local HEARD = { BANKFRAME_OPENED = update_opened, BANKFRAME_CLOSED = update_closed, PLAYERBANKSLOTS_CHANGED = vga.update_bank, PLAYERBANKBAGSLOTS_CHANGED = vga.update_bank, BAG_UPDATE_DELAYED = vga.update_bank, PLAYER_MONEY = vga.update_bank, BANK_TABS_CHANGED = vga.update_bank, BANK_TAB_SETTINGS_UPDATED = vga.update_bank }

local events = CreateFrame("Frame")
library.update_events(events, { "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "PLAYERBANKSLOTS_CHANGED", "PLAYERBANKBAGSLOTS_CHANGED", "BAG_UPDATE_DELAYED", "PLAYER_MONEY", "BANK_TABS_CHANGED", "BANK_TAB_SETTINGS_UPDATED" })
events:SetScript("OnEvent", function(_, event) library.update_safely("bank " .. event, HEARD[event]) end)
