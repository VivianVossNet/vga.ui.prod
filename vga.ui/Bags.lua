-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.ui's bags as the accepted drafts draw them (manual/view/vga-reference.html §3, vga-windows.html A, vga-rewards.html): a dialog of the template, always framed, the backpack and its bags as one grid of ten columns in the game's order, no sorted sections; beneath it every special bag - a profession's bag in one of the four places, the reagent bag in its own - as an area set apart, its name in small capitals above it, a quiver or an ammunition pouch always last; at its head a search field, »Taschen durchsuchen«, and the segmented filters - Alle as a word, then as icons with their word as tooltip: Ausrüstung a breastplate, Verbrauch a bottle, Handwerk a hammer, Quest a question mark, Plunder - the poor, grey items - a teddy -, what does not match darkened whole in its place - icon and edges together, through the frame's own alpha, since the game's item button narrows SetAlpha to its icon and border - so nothing moves; each slot in the template's inset metal, our edge laid over the game's slot, three pixels wide with gently rounded corners - an item's quality from uncommon up in its colour, a new one too, a quest item in gold, an empty slot in the metal's grey -, a quest item with a small gold question mark in its lower left corner, a little in from the icon's edge - an item that starts a quest not yet taken instead with an exclamation mark, in LibVGA's orange so it is seen at once (LibVGA's sign »offer« in orange, Media/Sign/OfferOrange.tga, K0857, made from the gold one by tools/questmark/questmark.py, K0851; K0846 misread the owner and is undone), in the middle of its slot, two thirds as high, vaulted like the leader's crown, a thin black rim and a soft shadow below to the right (Media/Sign/OfferGold.tga, manual/view/vga-queststart.html, K0761) -, a kept corner for our rarity's gem once vga.data brings it; an item new for five minutes - stamped when the game first calls it new, kept over a reload - brighter, without a glow behind it, its edge its quality's, every three seconds a shimmer running once round its rim that ends in a star flashing at its corner, until its five minutes are over; at the foot, in the status line LibVGA's dialog owns, the slots in use of all and the money with the accepted coins (K0784). The game's own bags open and close as ever - B, the bag bar, a merchant, the mailbox -, kept under a hidden parent before they show, so they never appear and never clear their new items, while ours follow them and sound as they did; the bank stays the game's. At the filters' right end a button with the sorting arrows opens the settings on the tab »Taschen«, where the order is chosen (Bagsettings.lua); their size, place and pin are Bagplace.lua's. Using, dragging, selling and the tooltip are the game's own item buttons'. Right of the sorting button the button »Aufräumen« pushes every item together from the top left (vga.ui/Bagtidy.lua, K0644). Alt and a right click on an item pins it to the end of the bags or loosens it again - the hearthstone and the tools always stand there, each fixed item carrying two small blue rounded corners, at its upper right and its lower left (vga.write_bag_pin, manual/view/vga-bags-pin.html, K0898, K0899). An item that would be an upgrade carries a small green arrow pointing up in its upper right corner, vaulted like the crown, a thin black rim and a soft shadow (Media/UpgradeArrow.tga, K0762; before a green dot, vga.ui/Bagupgrade.lua, K0723).

-- {K0899} {K0898} {K0857} {K0851} {K0846} {K0802} {K0793} {K0789} {K0784} {K0783} {K0777} {K0762} {K0761} {K0258} {K0259} {K0303} {K0403} {K0405} {K0406} {K0407} {K0409} {K0410} {K0411} {K0412} {K0413} {K0414} {K0644} {K0723}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local COLUMNS = 10
local SLOT = 38
local GAP = 4
local PAD = 12
local FRESH_SECONDS = 300
local FILTERS = { false, { [2] = true, [4] = true }, { [0] = true }, { [3] = true, [5] = true, [7] = true, [9] = true }, { [12] = true } }
local QUEST_FILTER = 5
local SECTION_TOP = 8
local AMMO_FAMILIES = 3
local SECTION_GAP = 6
local JUNK_FILTER = 6
local bags
local hidden = CreateFrame("Frame")
hidden:Hide()
local watched = {}

local read_draft = library.read_draft_size

local function read_last_bag()
    return Constants and Constants.InventoryConstants and Constants.InventoryConstants.NumBagSlots or NUM_BAG_SLOTS or 4
end

local function read_final_bag()
    local reagent = Constants and Constants.InventoryConstants and Constants.InventoryConstants.NumReagentBagSlots or 0
    return read_last_bag() + reagent
end

local function read_bag_slots()
    local used, total = 0, 0
    for bag = 0, read_final_bag() do
        local size = C_Container.GetContainerNumSlots(bag) or 0
        total = total + size
        for slot = 1, size do
            if C_Container.GetContainerItemInfo(bag, slot) then used = used + 1 end
        end
    end
    return used, total
end

local function read_category(item)
    local _, _, _, _, _, class = C_Item.GetItemInfoInstant(item.itemID)
    return class
end

local function check_match(bag, slot, item)
    local filter, wanted = bags.filter.chosen, bags.wanted
    if filter == 1 and wanted == "" then return true end
    if not item then return false end
    if filter == QUEST_FILTER and not library.check_container_quest(bag, slot, item) then return false end
    if filter == JUNK_FILTER and item.quality ~= 0 then return false end
    if filter > 1 and filter < QUEST_FILTER and not FILTERS[filter][read_category(item) or -1] then return false end
    local name = item.itemName or C_Item.GetItemNameByID(item.itemID) or ""
    return wanted == "" or string.find(name:lower(), wanted, 1, true) ~= nil
end

local function check_fresh(bag, slot, item)
    LibVGASettings.bag_fresh = LibVGASettings.bag_fresh or {}
    local stamps, key, now = LibVGASettings.bag_fresh, bag .. ":" .. slot, time()
    if not item then
        stamps[key] = nil
        return false
    end
    local stamp = stamps[key]
    if stamp and stamp.link ~= item.hyperlink then stamp = nil end
    if not stamp and C_NewItems.IsNewItem(bag, slot) == true then stamp = { link = item.hyperlink, at = now } end
    stamps[key] = stamp and now - stamp.at < FRESH_SECONDS and stamp or nil
    return stamps[key] ~= nil
end

local function update_slot(button, bag, slot)
    local found = C_Container.GetContainerItemInfo(bag, slot)
    local new = check_fresh(bag, slot, found)
    local item = library.update_container_slot(button, bag, slot, { new = new, dim = not check_match(bag, slot, found), upgrade = found ~= nil and vga.check_item_upgrade(found.hyperlink), pinned = vga.check_bag_pinned(found) })
    button.vga_new = new
    button.vga_at = new and LibVGASettings.bag_fresh[bag .. ":" .. slot].at or nil
    return item ~= nil
end

local function update_stale(button)
    button.vga_new = false
    library.delete_shimmer(button)
end

local function update_shimmer()
    local phase, side = library.read_shimmer_phase(), read_draft(SLOT)
    for _, button in ipairs(bags.slots) do
        if button.vga_new and button.vga_at and time() - button.vga_at >= FRESH_SECONDS then
            update_stale(button)
        elseif button:IsShown() and button.vga_new then
            library.update_shimmer(button, phase, side)
        end
    end
end

local function update_shimmer_safely()
    library.update_safely("bags shimmer", update_shimmer)
end

local function check_ammo(bag)
    local _, family = C_Container.GetContainerNumFreeSlots(bag)
    return family ~= nil and bit.band(family, AMMO_FAMILIES) ~= 0
end

local function check_special(bag)
    if bag > read_last_bag() or check_ammo(bag) then return true end
    return bag > 0 and IsInventoryItemProfessionBag ~= nil and IsInventoryItemProfessionBag("player", C_Container.ContainerIDToInventoryID(bag)) == true
end

local function read_groups()
    local main, special, ammo = { 0 }, {}, {}
    for bag = 1, read_final_bag() do
        if (C_Container.GetContainerNumSlots(bag) or 0) > 0 then
            if check_ammo(bag) then
                ammo[#ammo + 1] = bag
            elseif check_special(bag) then
                special[#special + 1] = bag
            else
                main[#main + 1] = bag
            end
        end
    end
    for _, bag in ipairs(ammo) do special[#special + 1] = bag end
    return main, special
end

local function update_label(holder)
    holder.label:SetFontObject(library.read_font("small"))
    holder.label:SetText(library.read_capitals(C_Container.GetBagName(holder:GetID()) or ""))
    holder.label:Show()
end

local function render_pin(button, mouse)
    if mouse ~= "RightButton" or not IsAltKeyDown() then return end
    local item = C_Container.GetContainerItemInfo(button:GetParent():GetID(), button:GetID())
    if not item then return end
    vga.write_bag_pin(item.itemID)
    library.update_element("bags")
end

local function create_slot(holder, slot)
    local button = library.create_container_slot(holder, slot)
    button:HookScript("OnClick", function(self, mouse) library.update_safely("bag pin", render_pin, self, mouse) end)
    return button
end

local function read_entries(group)
    local entries = {}
    for _, bag in ipairs(group) do
        for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
            entries[#entries + 1] = { bag = bag, slot = slot, item = C_Container.GetContainerItemInfo(bag, slot) }
        end
    end
    return vga.update_bag_order(entries)
end

local function read_slot_rows(group, counted)
    local size, rows = read_draft(SLOT), { {} }
    for place, entry in ipairs(read_entries(group)) do
        local holder = bags.holders[entry.bag]
        holder.slots[entry.slot] = holder.slots[entry.slot] or create_slot(holder, entry.slot)
        local button = holder.slots[entry.slot]
        counted.index = counted.index + 1
        bags.slots[counted.index] = button
        button:SetSize(size, size)
        button:Show()
        if update_slot(button, entry.bag, entry.slot) then counted.used = counted.used + 1 end
        local row = math.floor((place - 1) / COLUMNS) + 1
        rows[row] = rows[row] or {}
        rows[row][(place - 1) % COLUMNS + 1] = button
    end
    return rows
end

local function create_slot_grid()
    local columns = {}
    for column = 1, COLUMNS do columns[column] = SLOT end
    return library.create_grid(bags.grid, { columns = columns, gap = GAP, row = SLOT, row_gap = GAP, y = "top" })
end

local function update_hidden_slots()
    for bag, holder in pairs(bags.holders) do
        holder.label:Hide()
        for slot = (C_Container.GetContainerNumSlots(bag) or 0) + 1, #holder.slots do holder.slots[slot]:Hide() end
    end
end

local function update_grid()
    local counted = { index = 0, used = 0 }
    local main, special = read_groups()
    update_hidden_slots()
    local sections = { { bags.slot_grid, read_slot_rows(main, counted) } }
    for _, bag in ipairs(special) do
        local holder = bags.holders[bag]
        update_label(holder)
        sections[#sections + 1] = { holder.label_grid, { { holder.label } } }
        sections[#sections + 1] = { holder.slot_grid, read_slot_rows({ bag }, counted) }
    end
    for extra = counted.index + 1, #bags.slots do bags.slots[extra] = nil end
    return counted.index, counted.used, library.update_grid_sections(sections)
end

local function update_lines(tools_height, grid_height)
    bags.tools_line:SetHeight(1)
    bags.tools_line:ClearAllPoints()
    bags.tools_line:SetPoint("TOPLEFT", bags.body, "TOPLEFT", 0, -tools_height)
    bags.tools_line:SetPoint("TOPRIGHT", bags.body, "TOPRIGHT", 0, -tools_height)
    return tools_height + 1 + grid_height
end

local function update_bags()
    if not bags or not bags:IsShown() then return end
    library.update_dialog(bags)
    local pad, size, gap = read_draft(PAD), read_draft(SLOT), read_draft(GAP)
    local inner = COLUMNS * size + (COLUMNS - 1) * gap
    local count, used, slots_height = update_grid()
    local grid_height = slots_height + 2 * pad
    library.update_input(bags.field, inner)
    library.update_choice(bags.filter)
    library.update_choice(bags.tidy)
    library.update_choice(bags.sort)
    library.update_grid_sections({ { bags.field_grid, { { bags.field } } }, { bags.tool_grid, { { bags.filter, nil, bags.sort, bags.tidy } } } }, inner + 2 * pad)
    local tools_height = pad + bags.field:GetHeight() + read_draft(8) + library.read_size(2) + pad
    bags.grid:ClearAllPoints()
    bags.grid:SetPoint("TOPLEFT", bags.body, "TOPLEFT", pad, -(tools_height + 1 + pad))
    bags.grid:SetSize(inner, grid_height - 2 * pad)
    library.update_dialog_foot(bags, string.format(library.texts.slots_used, used, count), GetMoney())
    local body_height = update_lines(tools_height, grid_height)
    bags:SetSize(inner + 2 * pad + 2 * library.read_size(-4), library.read_dialog_frame_height(bags) + body_height)
    vga.update_bag_place(bags)
end

local function update_bags_safely()
    library.update_safely("bags", update_bags)
end

local function render_tidy()
    bags.tidy.chosen = 0
    library.update_choice(bags.tidy)
    local main, special = read_groups()
    local groups = { main }
    for _, bag in ipairs(special) do groups[#groups + 1] = { bag } end
    vga.render_bag_tidy(groups)
end

local function render_sorting()
    bags.sort.chosen = 0
    library.update_choice(bags.sort)
    library.render_settings("bags")
end

local function write_filter()
    update_bags_safely()
end

local function write_wanted(field)
    bags.wanted = (field:GetText() or ""):lower():match("^%s*(.-)%s*$")
    update_bags_safely()
end

local function create_field()
    return library.create_input(bags.body, { hint = library.texts.search_bags, picture = "Search", most = 40, on_change = write_wanted })
end

local function check_ours(frame)
    local bag = frame:GetID()
    return frame == ContainerFrameCombinedBags or (bag ~= nil and bag >= 0 and bag <= read_final_bag())
end

local function check_wanted()
    for _, frame in ipairs(watched) do
        if frame:IsShown() and frame:GetParent() == hidden then return true end
    end
    return false
end

local function update_from_game()
    bags.pending = false
    local wanted = check_wanted()
    if wanted ~= bags:IsShown() then bags:SetShown(wanted) end
end

local function update_from_game_soon()
    if not bags or bags.pending then return end
    bags.pending = true
    C_Timer.After(0, update_from_game)
end

local function update_game_parent(frame)
    if frame:IsShown() then return end
    frame:SetParent(check_ours(frame) and hidden or UIParent)
end

local function update_game_frames()
    for _, frame in ipairs(watched) do update_game_parent(frame) end
end

local function update_opened()
    PlaySound(SOUNDKIT.IG_BACKPACK_OPEN)
    update_bags_safely()
end

local function update_closed()
    PlaySound(SOUNDKIT.IG_BACKPACK_CLOSE)
    if check_wanted() and CloseAllBags then CloseAllBags() end
    if C_NewItems and C_NewItems.ClearAll then C_NewItems.ClearAll() end
end

local function create_watch()
    local frames = { ContainerFrameCombinedBags }
    for index = 1, NUM_CONTAINER_FRAMES or 13 do frames[#frames + 1] = _G["ContainerFrame" .. index] end
    for _, frame in ipairs(frames) do
        if frame then
            watched[#watched + 1] = frame
            update_game_parent(frame)
            if frame.SetBagID then hooksecurefunc(frame, "SetBagID", update_game_parent) end
            hooksecurefunc(frame, "Show", update_from_game_soon)
            hooksecurefunc(frame, "Hide", update_from_game_soon)
        end
    end
    if ContainerFrame_SetFullScreenFrame then hooksecurefunc("ContainerFrame_SetFullScreenFrame", update_game_frames) end
end

local function update_on_event()
    if bags and bags:IsShown() then update_bags_safely() end
end

local function create_bags()
    local texts = library.texts
    bags = library.create_dialog("VGABags", texts.bags, { band = true, money = true })
    vga.create_bag_place(bags)
    bags:Hide()
    bags.wanted = ""
    bags.slots, bags.holders = {}, {}
    bags.field = create_field()
    bags.filter = library.create_choice(bags.body, {
        texts.filter_all,
        { icon = "FilterArmour", tip = texts.equipment },
        { icon = "FilterBottle", tip = texts.consumables },
        { icon = "FilterHammer", tip = texts.crafting },
        { icon = "FilterQuest", tip = texts.quest_items },
        { icon = "FilterJunk", tip = texts.junk },
    }, 1, write_filter)
    bags.tools_line = library.create_hairline(bags.body)
    bags.field_grid = library.create_grid(bags.body, { columns = { "auto" }, row = 0, padding = { PAD, PAD, 0, PAD }, y = "top" })
    bags.tool_grid = library.create_grid(bags.body, { columns = { "auto", "rest", "auto", "auto" }, gaps = { 0, 0, 6 }, row = 0, padding = { 8, PAD, 0, PAD }, x = { "left", "left", "left", "left" }, y = { "top", "top", "middle", "top" } })
    bags.grid = CreateFrame("Frame", nil, bags.body)
    bags.slot_grid = create_slot_grid()
    for bag = 0, read_final_bag() do
        local holder = library.create_container_holder(bags.grid, bag)
        holder.label = library.create_text(holder, "small", colours.quiet)
        holder.label_grid = library.create_grid(bags.grid, { columns = { "auto" }, row = 0, padding = { SECTION_TOP, 0, SECTION_GAP, 0 }, y = "top" })
        holder.slot_grid = create_slot_grid()
        bags.holders[bag] = holder
    end
    bags:HookScript("OnShow", update_opened)
    bags:SetScript("OnHide", update_closed)
    bags:SetScript("OnUpdate", update_shimmer_safely)
    create_watch()
    bags.sort = library.create_choice(bags.body, { { icon = "Sort", tip = texts.sort_tip } }, 0, render_sorting)
    bags.tidy = library.create_choice(bags.body, { { icon = "Tidy", tip = texts.tidy_tip } }, 0, render_tidy)
    library.create_element("bags", { update = update_bags, title = texts.bags, icon = "TabBags", tab = vga.create_bags_page })
end

local events = CreateFrame("Frame")
for _, name in ipairs({ "BAG_UPDATE_DELAYED", "ITEM_LOCK_CHANGED", "BAG_UPDATE_COOLDOWN", "BAG_NEW_ITEMS_UPDATED", "PLAYER_MONEY", "PLAYER_EQUIPMENT_CHANGED", "PLAYER_SPECIALIZATION_CHANGED" }) do
    pcall(events.RegisterEvent, events, name)
end
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        library.update_safely("bags login", create_bags)
    else
        update_on_event()
    end
end)
vga.read_bag_slots = read_bag_slots
vga.read_final_bag = read_final_bag

