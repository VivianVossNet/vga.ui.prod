-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: the work bar, as manual/view/vga-bank-view.html draws it (K1019, K1020): a row of keys in the stance keys' look - LibVGA's cells, thirty draft pixels, three apart - standing four pixels above the bars' widget, its right edge sixteen draft pixels in from the widget's, the stance bar's place mirrored, at the bars' scale: at the right the key of the bank as last seen (vga.create_bank_key), then, twice the gap away, a key for each learnt profession that opens a window of its own - asked of C_TradeSkillUI.CanTradeSkillShowCraftingUI for the profession's first spell in the spell book (GetProfessions, GetProfessionInfo, C_SpellBook.GetSpellBookItemInfo) -, a protected key of our own casting that spell, as the game's professions book does through C_SpellBook.CastSpellBookItem (read in Forever's Blizzard_ProfessionsBook), its picture the profession's, the game's tooltip of the spell under the mouse; gathering professions without a window get none. The protected keys hang from the bar itself, never from the bank's plain key, as the game allows (manual/16 R2.3). Keys are set and the bar placed only out of a fight; a change in a fight waits for its end.

-- {K1020} {K1019}

local _, vga = ...
local library = LibVGA
local KEY = 30
local GAP = 3
local ABOVE = 4
local INWARD = 16
local MOST = 5
local BOOK = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
local bar

local function read_profession_spell(index)
    local name, picture, _, _, _, offset = GetProfessionInfo(index)
    local entry = C_SpellBook and C_SpellBook.GetSpellBookItemInfo and C_SpellBook.GetSpellBookItemInfo((offset or 0) + 1, BOOK)
    local spell = entry and entry.spellID
    if not (spell and C_TradeSkillUI and C_TradeSkillUI.CanTradeSkillShowCraftingUI and C_TradeSkillUI.CanTradeSkillShowCraftingUI(spell)) then return nil end
    return { name = name, picture = picture, spell = spell }
end

local function read_professions()
    local found = {}
    if not (GetProfessions and GetProfessionInfo) then return found end
    for _, index in ipairs({ GetProfessions() }) do
        local profession = index and read_profession_spell(index)
        if profession then found[#found + 1] = profession end
    end
    return found
end

local function render_key_tip(key)
    if not key.spell then return end
    GameTooltip:SetOwner(key, "ANCHOR_TOP")
    GameTooltip:SetSpellByID(key.spell)
    GameTooltip:Show()
end

local function render_key_tip_hidden(key)
    if GameTooltip:GetOwner() == key then GameTooltip:Hide() end
end

local function create_key(index)
    local key = library.create_cell(bar, { kind = "key", name = "VGAProfessionKey" .. index, template = "SecureActionButtonTemplate" })
    key:RegisterForClicks("AnyUp", "AnyDown")
    key:SetAttribute("type", "spell")
    key:HookScript("OnEnter", render_key_tip)
    key:HookScript("OnLeave", render_key_tip_hidden)
    return key
end

local function update_keys(size, gap)
    local professions = read_professions()
    local right = size + 2 * gap
    for index, key in ipairs(bar.professions) do
        local profession = professions[index]
        key:SetShown(profession ~= nil)
        if profession then
            key.spell = profession.spell
            key:SetAttribute("spell", profession.spell)
            library.update_cell_size(key, size)
            library.update_cell(key, { picture = profession.picture })
            key:ClearAllPoints()
            key:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -right, 0)
            right = right + size + gap
        end
    end
end

local function update_bar()
    if not bar or InCombatLockdown() then return end
    local size, gap = library.read_draft_size(KEY), library.read_draft_size(GAP)
    vga.update_bank_kept_button(size)
    bar.bank:ClearAllPoints()
    bar.bank:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
    update_keys(size, gap)
    local widget = vga.read_bars_anchor and vga.read_bars_anchor()
    if not (widget and widget:GetRight()) then return end
    local scale = VGAActionBar and VGAActionBar:GetScale() or 1
    bar:SetScale(scale)
    bar:SetSize(size, size)
    bar:ClearAllPoints()
    bar:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", widget:GetRight() / scale - library.read_draft_size(INWARD), (widget:GetTop() + ABOVE) / scale)
end

local function create_bar()
    bar = CreateFrame("Frame", "VGAWorkbar", UIParent)
    bar.bank = vga.create_bank_key(bar)
    bar.professions = {}
    for index = 1, MOST do bar.professions[index] = create_key(index) end
    library.create_element("workbar", { update = update_bar })
    update_bar()
end

local HEARD = { PLAYER_LOGIN = create_bar, SPELLS_CHANGED = update_bar, SKILL_LINES_CHANGED = update_bar, PLAYER_REGEN_ENABLED = update_bar }

local events = CreateFrame("Frame")
library.update_events(events, { "PLAYER_LOGIN", "SPELLS_CHANGED", "SKILL_LINES_CHANGED", "PLAYER_REGEN_ENABLED" })
events:SetScript("OnEvent", function(_, event) library.update_safely("work bar " .. event, HEARD[event]) end)
