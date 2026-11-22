-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: the tooltip of a key of our own, as the game's own action keys show it (K0726): the pet bar's keys the pet action, the stance bar's keys the form, both by the game's own tooltip lines (SetPetAction, SetShapeshift), the page switch's arrows a line of ours; placed where the game places its tooltips, and gone when the pointer leaves.

-- {K0726}

local _, vga = ...

local function render_key_tip(key)
    if GameTooltip_SetDefaultAnchor then
        GameTooltip_SetDefaultAnchor(GameTooltip, key)
    else
        GameTooltip:SetOwner(key, "ANCHOR_RIGHT")
    end
    if key.tip_method then
        GameTooltip[key.tip_method](GameTooltip, key.tip_value)
    else
        GameTooltip:SetText(key.tip_text or "", 1, 1, 1)
    end
    GameTooltip:Show()
end

local function update_key_tip_hidden()
    GameTooltip:Hide()
end

function vga.create_key_tip(key, method, value)
    key.tip_method, key.tip_value = method, value
    key:HookScript("OnEnter", render_key_tip)
    key:HookScript("OnLeave", update_key_tip_hidden)
end

function vga.create_text_tip(key, text)
    key.tip_text = text
    key:HookScript("OnEnter", render_key_tip)
    key:HookScript("OnLeave", update_key_tip_hidden)
end
