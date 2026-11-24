-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: The game menu and the bag bar as manual/view/vga-gamemenu.html draws them (K0513, K0515): two rows of our keys - 38 draft pixels high, three apart, a dark ground and our three-pixel edge with gently rounded corners in a light bronze, the bags' keys square, the menu's as slim as the game's picture, 0.74 as wide as high -, the game's own micro buttons and bag buttons laid into them in the game's order - Forever's eleven micro buttons as its own menu holds them, measured: character, professions, spellbook, talents, legacy, quest log, guild, group finder, collections, game menu, help; retail's further buttons, which have no use in Forever, are left out, left in the game's hidden menu and taking no clicks there; each keeps its place, so the row is always whole, as long and left-aligned as the game's own, and a button the game hides leaves its key standing empty, ground and edge without a picture -, centred, a bag scaled to fit inside the edge, a micro button scaled until its picture - measured at 0.68 of the button's height - fills the key, its own frame clipped away under our edge, the game's own frames on them - a micro button's background and pushed background, a bag's normal and pushed frame, border and overlay - always hidden, the key's dark ground rounded as its edge, so nothing of the game's and no corner shows beside our edge (K0542); so they open their windows as ever, in a fight too, and grow and shrink with our keys at every size. The menu shows the game's own pictures by default; as the settings say (menu_icons), our line icons in ink instead, the game's button then drawn invisible beneath them but still taking the click, a locked one dimmed. The bag bar shows, as the game shows them, the key ring at the far left in a slim key, its tall picture scaled to the key's height, then the reagent bag, the four bags and the backpack; its expand arrow is put away. Whatever the game does to a button laid in - moving it, taking it back to its own bar, rescaling it, as it does when a bag is opened or changed - is undone at once: every button is watched and set back into its key. Laid and placed by the main bar (Actionbars.lua) in place of the game's containers.

-- {K0800} {K0793} {K0513} {K0515} {K0523} {K0524} {K0525} {K0528} {K0529} {K0530} {K0537} {K0542}

local _, vga = ...
local library = LibVGA
local KEY = 38
local GAP = 3
local EDGE_WIDTH = 3
local BRONZE = { 0.541, 0.427, 0.278 }
local GROUND = { 0.031, 0.035, 0.043 }
local LOCKED = 0.32
local GAME_FRAMES = { "Background", "PushedBackground", "IconBorder", "IconOverlay", "SlotBackground", "Border" }
local PICTURE_SHARE = 0.68
local PICTURE_ASPECT = 0.74
local MENU = {
    { "CharacterMicroButton", "MenuCharacter" }, { "ProfessionMicroButton", "FilterHammer" }, { "SpellbookMicroButton", "MenuBook" },
    { "TalentMicroButton", "TabQuests" }, { "LegacyMicroButton", "MenuShield" }, { "QuestLogMicroButton", "MenuQuest" },
    { "GuildMicroButton", "MenuBanner" }, { "LFDMicroButton", "MenuEye" }, { "CollectionsMicroButton", "MenuShoe" },
    { "MainMenuMicroButton", "MenuCog" }, { "HelpMicroButton", "FilterQuest" },
}
local KEY_RING = "KeyRingButton"
local BAGS = { "CharacterReagentBag0Slot", "CharacterBag3Slot", "CharacterBag2Slot", "CharacterBag1Slot", "CharacterBag0Slot", "MainMenuBarBackpackButton" }

local read_draft = library.read_draft_size

local function check_own_icons()
    return LibVGASettings.menu_icons == "ours"
end

local function create_holder(row)
    local holder = CreateFrame("Frame", nil, row)
    holder.cover = CreateFrame("Frame", nil, holder)
    holder.cover:SetAllPoints()
    library.create_cell_dress(holder, { ground = 0, edge = 6, edge_frame = holder.cover })
    holder.ground, holder.cover.edge = holder.vga_ground, holder.vga_edge
    holder.cover.icon = holder.cover:CreateTexture(nil, "ARTWORK")
    holder.cover.icon:SetPoint("CENTER")
    return holder
end

local function read_menu_buttons()
    local buttons = {}
    for _, entry in ipairs(MENU) do
        local button = _G[entry[1]]
        if type(button) == "table" and button.IsShown then buttons[#buttons + 1] = button end
    end
    return buttons
end

local function read_bag_buttons()
    local buttons = {}
    local ring = _G[KEY_RING]
    if type(ring) == "table" and ring.IsShown and ring:IsShown() then
        ring.vga_tall = true
        buttons[1] = ring
    end
    for _, name in ipairs(BAGS) do
        local button = _G[name]
        if button and button:IsShown() then buttons[#buttons + 1] = button end
    end
    return buttons
end

local function read_own_icon(button)
    for _, entry in ipairs(MENU) do
        if entry[1] == button:GetName() then return entry[2] end
    end
    return nil
end

local function update_icon(holder, button, own)
    local icon = own and read_own_icon(button) or nil
    holder.cover.icon:SetShown(icon ~= nil)
    button:SetAlpha(icon and 0 or 1)
    if not icon then return end
    local size = read_draft(22)
    holder.cover.icon:SetTexture(library.media .. icon)
    holder.cover.icon:SetSize(size, size)
    local ink = library.colours.ink
    holder.cover.icon:SetVertexColor(ink[1], ink[2], ink[3], button:IsEnabled() and 1 or LOCKED)
end

local function read_key_width(slim)
    local inner = read_draft(KEY) - 2 * EDGE_WIDTH
    return slim and math.floor(inner * PICTURE_ASPECT + 0.5) + 2 * EDGE_WIDTH or read_draft(KEY)
end

local function update_unframed(button)
    for _, part in ipairs(GAME_FRAMES) do
        local region = button[part]
        if type(region) == "table" and region.SetAlpha then region:SetAlpha(0) end
    end
    if not button.vga_bag then return end
    for _, region in pairs({ normal = button:GetNormalTexture(), pushed = button:GetPushedTexture() }) do region:SetAlpha(0) end
end

local function update_seated(button)
    local holder = button.vga_holder
    if not holder then return end
    button.vga_seating = true
    update_unframed(button)
    if button:GetParent() ~= holder then button:SetParent(holder) end
    button:ClearAllPoints()
    button:SetPoint("CENTER", holder, "CENTER")
    if button.vga_scale then button:SetScale(button.vga_scale) end
    button.vga_seating = nil
end

local function update_kept(button)
    if button.vga_seating then return end
    library.update_safely("game menu seat", update_seated, button)
end

local function update_guarded(button)
    if button.vga_guarded then return end
    button.vga_guarded = true
    for _, method in ipairs({ "SetPoint", "SetParent", "SetScale", "Show", "Hide", "SetShown" }) do hooksecurefunc(button, method, update_kept) end
end

local function read_button_scale(button, inner, slim)
    local most = math.max(button:GetWidth(), button:GetHeight(), 1)
    if button.vga_tall then return inner / math.max(button:GetHeight(), 1) end
    return slim and inner / (most * PICTURE_SHARE) or inner / most
end

local function update_holder(holder, button, own, slim)
    local narrow = (slim or button.vga_tall) and true or false
    local size, inner, width = read_draft(KEY), read_draft(KEY) - 2 * library.read_cell_inset(EDGE_WIDTH), read_key_width(narrow)
    holder:SetSize(width, size)
    holder:SetClipsChildren(narrow)
    holder:Show()
    button.vga_holder, button.vga_scale = holder, read_button_scale(button, inner, slim)
    update_guarded(button)
    update_seated(button)
    holder.cover:SetFrameLevel(button:GetFrameLevel() + 2)
    library.update_ring(holder.cover.edge, EDGE_WIDTH, BRONZE, 1)
    library.update_surface(holder.ground, 0, 2 * EDGE_WIDTH, GROUND, GROUND)
    update_icon(holder, button, own)
    return width
end

local function update_row(row, buttons, own, slim)
    row.holders = row.holders or {}
    local cells, columns = {}, {}
    for index, button in ipairs(buttons) do
        row.holders[index] = row.holders[index] or create_holder(row)
        update_holder(row.holders[index], button, own, slim)
        cells[index], columns[index] = row.holders[index], "auto"
    end
    for index = #buttons + 1, #row.holders do row.holders[index]:Hide() end
    row.grid = row.grid or library.create_grid(row, {})
    row.grid.plan = { columns = columns, gap = GAP, row = KEY }
    local width = library.update_grid(row.grid, { cells })
    row:SetSize(math.max(width, 1), read_draft(KEY))
end

local function update_put_away()
    for _, part in ipairs({ MicroMenuContainer, BagsBar, BagBarExpandToggle }) do
        if part then part:SetAlpha(0) end
    end
    if BagBarExpandToggle then BagBarExpandToggle:EnableMouse(false) end
    for _, child in ipairs({ MicroMenu and MicroMenu:GetChildren() }) do
        if not read_own_icon(child) and child.EnableMouse then child:EnableMouse(false) end
    end
end

function vga.update_game_menu()
    update_put_away()
    update_row(vga.game_menu, read_menu_buttons(), check_own_icons(), true)
    for _, button in ipairs(read_bag_buttons()) do button.vga_bag = true end
    update_row(vga.bag_row, read_bag_buttons(), false, false)
end

vga.game_menu = CreateFrame("Frame", "VGAGameMenu", UIParent)
vga.bag_row = CreateFrame("Frame", "VGABagRow", UIParent)
