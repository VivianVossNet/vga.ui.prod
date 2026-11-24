-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.ui's merchant window, as the accepted draft draws it (manual/view/vga-npc-windows.html, K0830, K0831): LibVGA's window with pages - Kaufen, Verkaufen, Rückkauf in the menu bar with the accepted flat icons -, each page LibVGA's list page (library.create_list_page, K0871) with its tools made and laid here - LibVGA's search bar above Kaufen (library.create_search_bar, K0873), »Plunder verkaufen« above Verkaufen, none above Rückkauf -, every ware, every item of the bags with a price and every item sold back as LibVGA's item row, its tooltip only over picture and name (K0786), its price in our coins in the figure face; a click buys one, a shift-click asks the amount in vga.ui's own dialog (K0757); a click on an item of the bags sells it - an item fixed at the end of the bags shows there the bags' two blue corners, so it is not sold by mistake (item.pinned, K0901) -, »Plunder verkaufen« sells every poor item; a click on an item sold buys it back. The foot carries »Alles reparieren« with its cost where the merchant repairs - repair has no page of its own (K0830) - and the player's gold. The game's merchant window is veiled, never hidden, so the visit stays open as the game keeps it (library.update_game_veiled); closing ours ends the visit (K0832). At every opening it keeps for the account whether this merchant repairs, by the figure's number, so the talk can say so before the window opens (LibVGAAccount.repairers, K0848).

-- {K0901} {K0873} {K0860} {K0871} {K0848} {K0839} {K0838} {K0836} {K0832} {K0830} {K0831} {K0757} {K0786}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local WIDTH, HEIGHT = 640, 470
local HEADS = { buy = { "head_ware", "head_stock", "price" }, sell = { "head_from_bags", "head_amount", "head_sale" }, buyback = { "head_sold_last", "head_amount", "price" } }
local POOR = 0
local TOOLS_GAP = 8
local SEARCH_SHARE = 0.6
local window
local read_stock

local function read_texts()
    return library.texts
end

local function read_ware(index)
    local found = C_MerchantFrame and C_MerchantFrame.GetItemInfo and C_MerchantFrame.GetItemInfo(index)
    if type(found) == "table" then return found end
    if not GetMerchantItemInfo then return nil end
    local name, texture, price, stack, available, usable = GetMerchantItemInfo(index)
    return name and { name = name, texture = texture, price = price, stackCount = stack, numAvailable = available, isUsable = usable }
end

local function read_kind(link)
    local kind = link and select(7, C_Item.GetItemInfo(link))
    return type(kind) == "string" and kind or nil
end

local function read_ware_line(ware, link)
    if (ware.stackCount or 1) > 1 then return string.format(library.texts.per_purchase, ware.stackCount) end
    return read_kind(link) or ""
end

local function read_link_quality(link)
    return link and select(3, C_Item.GetItemInfo(link)) or 1
end

local function read_wares(tools)
    local wares, wanted = {}, (tools.input:GetText() or ""):lower()
    for index = 1, (GetMerchantNumItems and GetMerchantNumItems() or 0) do
        local ware = read_ware(index)
        local fits = ware and (wanted == "" or ware.name:lower():find(wanted, 1, true)) and (tools.choice.chosen ~= 2 or ware.isUsable ~= false)
        if fits then
            local link = GetMerchantItemLink and GetMerchantItemLink(index)
            wares[#wares + 1] = { index = index, name = ware.name, icon = ware.texture, price = ware.price, bundle = ware.stackCount or 1, stock = ware.numAvailable, quality = read_link_quality(link), link = link, sub = read_ware_line(ware, link) }
        end
    end
    return wares
end

local function read_bag_sales()
    local sales = {}
    for bag = 0, NUM_BAG_SLOTS or 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local found = C_Container.GetContainerItemInfo(bag, slot)
            local price = found and found.hyperlink and select(11, C_Item.GetItemInfo(found.hyperlink))
            if price and price > 0 and not found.hasNoValue then sales[#sales + 1] = { bag = bag, slot = slot, name = C_Item.GetItemInfo(found.hyperlink) or "", icon = found.iconFileID, price = price * found.stackCount, count = found.stackCount, quality = found.quality, link = found.hyperlink, sub = read_kind(found.hyperlink) or "", pinned = vga.check_bag_pinned(found) } end
        end
    end
    return sales
end

local function read_buybacks()
    local backs = {}
    for index = 1, (GetNumBuybackItems and GetNumBuybackItems() or 0) do
        local name, icon, price, count = GetBuybackItemInfo(index)
        if name then backs[#backs + 1] = { index = index, name = name, icon = icon, price = price, count = count, link = GetBuybackItemLink and GetBuybackItemLink(index), sub = library.texts.buy_it_back } end
    end
    return backs
end

local function render_bought_amount(owner, amount)
    if BuyMerchantItem then BuyMerchantItem(owner:GetID(), amount) end
end

local function render_row_clicked(row)
    local item = row.item
    if not item then return end
    if item.bag then return C_Container.UseContainerItem(item.bag, item.slot) end
    if row.page_key == "buyback" then return BuybackItem(item.index) end
    if IsShiftKeyDown and IsShiftKeyDown() and StackSplitFrame and StackSplitFrame.OpenStackSplitFrame then
        row.price = item.price
        return StackSplitFrame:OpenStackSplitFrame(GetMerchantItemMaxStack and GetMerchantItemMaxStack(item.index) or 20, row, "BOTTOMLEFT", "TOPLEFT", item.bundle)
    end
    BuyMerchantItem(item.index, 1)
end

local function render_row_tip(row)
    local item = row.item
    if not item then return end
    library.update_item_tip_owner(GameTooltip, row)
    if item.bag then GameTooltip:SetBagItem(item.bag, item.slot)
    elseif row.page_key == "buyback" then GameTooltip:SetBuybackItem(item.index)
    else GameTooltip:SetMerchantItem(item.index) end
    GameTooltip:Show()
end

local function render_tip_hidden()
    GameTooltip:Hide()
end

local function create_row_for(page_key)
    return function(parent)
        local row = library.create_item_row(parent, { chosen = true, cell = true, on_click = render_row_clicked, on_enter = render_row_tip, on_leave = render_tip_hidden })
        row.page_key = page_key
        row.stock = library.create_text(row, "figures_small", colours.ink)
        row.money = library.create_money(row, colours.ink)
        row.money.kind = "small"
        row.SplitStack = render_bought_amount
        return row
    end
end

local function update_row(row, item)
    local sheet = row:GetParent():GetParent():GetParent()
    local columns = sheet.columns
    row.item = item
    row:SetID(item.index or 0)
    library.update_item_row(row, { icon = item.icon, id = item.link, name = item.name, quality = item.quality, sub = item.sub, count = item.bundle or item.count, pinned = item.pinned }, sheet.pad, sheet.pad + columns.rights[1])
    library.update_item_row_chosen(row, false)
    row.stock:SetText(read_stock(item))
    library.update_money(row.money, item.price or 0)
    library.update_grid_columns(row, columns, sheet.pad, { { row.stock, 2, "right" }, { row.money, 3, "right" } })
end

function read_stock(item)
    if item.stock then return item.stock < 0 and "∞" or tostring(item.stock) end
    return tostring(item.count or 1)
end

local function render_junk_sold()
    for _, sale in ipairs(read_bag_sales()) do
        if sale.quality == POOR then C_Container.UseContainerItem(sale.bag, sale.slot) end
    end
end

local function render_page_changed()
    if window and window:IsShown() then vga.update_merchant() end
end

local function create_buy_tools(parent)
    local texts = read_texts()
    return library.create_search_bar(parent, { hint = texts.wares_search, labels = { texts.all_kinds, texts.usable }, on_search = render_page_changed, on_choose = render_page_changed, gap = TOOLS_GAP, share = SEARCH_SHARE, y = "top" })
end

local function update_buy_tools(listing, width)
    return { library.update_search_bar(listing.tools, width) }
end

local function create_sell_tools(parent)
    return { junk = library.create_button(parent, read_texts().sell_junk, "gold", render_junk_sold) }
end

local function update_sell_tools(listing)
    library.update_button(listing.tools.junk)
    return { listing.table.empty, listing.tools.junk }
end

local TOOLS = { buy = { create_buy_tools, update_buy_tools }, sell = { create_sell_tools, update_sell_tools } }

local function create_page(page, key)
    local texts = read_texts()
    page.key = key
    local words = HEADS[key]
    local columns = { { key = words[1] .. "_" .. key, word = texts[words[1]] }, { key = words[2] .. "_" .. key, word = texts[words[2]], least = 56, x = "right" }, { key = words[3] .. "_" .. key, word = texts[words[3]], least = "money", x = "right" } }
    local sheet = { columns = columns, create_row = create_row_for(key), update_row = update_row, empty = key == "buyback" and texts.nothing_sold or "" }
    local grid, made = { columns = { "rest" }, row_gap = 16, y = "top" }, TOOLS[key]
    local tools = made and { grid = { columns = { "rest", "auto" }, gap = TOOLS_GAP, y = "top" }, create = made[1], update = made[2] }
    page.listing = library.create_list_page(page, { table = sheet, grid = grid, leave = made and { 22, 16 }, tools = tools })
end

local function read_page_items(page)
    if page.key == "buy" then return read_wares(page.listing.tools) end
    if page.key == "sell" then return read_bag_sales() end
    return read_buybacks()
end

local function update_foot()
    local texts, cost, can = read_texts(), 0, CanMerchantRepair and CanMerchantRepair()
    if can and GetRepairAllCost then cost = GetRepairAllCost() or 0 end
    local repair = window.foot.buttons[1]
    repair.words = cost > 0 and texts.repair_all or texts.repair_none
    repair.text:SetText(repair.words)
    library.update_button_enabled(repair, can and cost > 0)
    library.update_dialog_foot(window, texts.repair_note, cost)
    library.update_dialog_status(window, texts.gold_label, GetMoney())
end

function vga.update_merchant()
    if not (window and window:IsShown()) then return end
    local height = library.read_draft_size(HEIGHT)
    local _, _, band = library.update_paged_window(window, library.read_draft_size(WIDTH), height)
    update_foot()
    local page = window.pages[window.chosen]
    library.update_list_page(page.listing, read_page_items(page), window.page_width, height - library.read_dialog_frame_height(window) - band)
end

local function render_repair()
    if RepairAllItems then RepairAllItems() end
    vga.update_merchant()
end

local function render_closed()
    library.render_game_ended(MerchantFrame, CloseMerchant)
end

local function create_page_maker(key)
    return function(page) create_page(page, key) end
end

local function read_plan(texts)
    local entries = { { key = "buy", title = texts.buy, icon = "TabBuy" }, { key = "sell", title = texts.sell, icon = "TabSell" }, { key = "buyback", title = texts.buyback, icon = "TabBuyback" } }
    local pages = {}
    for index, entry in ipairs(entries) do pages[index] = { key = entry.key, title = entry.title, build = create_page_maker(entry.key) } end
    return { title = texts.merchant, groups = { { title = texts.merchant, entries = entries } }, pages = pages, foot = { note = texts.repair_note, money = true, status = true, buttons = { { texts.repair_all, "plain", render_repair } } }, on_page = vga.update_merchant }
end

local function create_window()
    window = library.create_paged_window("VGAMerchantWindow", read_plan(read_texts()))
    library.update_dialog_closing(window, function() library.update_safely("merchant closed", render_closed) end)
end

local function write_repairer()
    local id = library.read_figure_id()
    if not id then return end
    LibVGAAccount.repairers = LibVGAAccount.repairers or {}
    LibVGAAccount.repairers[id] = (CanMerchantRepair and CanMerchantRepair()) and true or false
end

local function update_opened()
    write_repairer()
    if not window then create_window() end
    library.update_game_veiled(MerchantFrame, true)
    window.title:SetText(library.read_figure_title(read_texts().merchant))
    window.chosen = "buy"
    library.update_dialog_placed(window)
    window:Show()
    library.update_paged_window_page(window, "buy")
    vga.update_merchant()
end

local function update_closed()
    if window and window:IsShown() then window:Hide() end
end

local HEARD = { MERCHANT_SHOW = update_opened, MERCHANT_CLOSED = update_closed, MERCHANT_UPDATE = vga.update_merchant, BAG_UPDATE_DELAYED = vga.update_merchant, PLAYER_MONEY = vga.update_merchant, UPDATE_INVENTORY_DURABILITY = vga.update_merchant }

local events = CreateFrame("Frame")
library.update_events(events, { "MERCHANT_SHOW", "MERCHANT_CLOSED", "MERCHANT_UPDATE", "BAG_UPDATE_DELAYED", "PLAYER_MONEY", "UPDATE_INVENTORY_DURABILITY" })
events:SetScript("OnEvent", function(_, event) library.update_safely("merchant " .. event, HEARD[event]) end)
