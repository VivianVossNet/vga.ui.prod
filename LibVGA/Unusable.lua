-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's veil for an item the player cannot use (K0703): a faint, transparent red laid over the item's picture wherever an item is shown - the bags, the loot, every list of vga.auctions -, one element made once per picture and told the item each time, shown only where the game's C_PlayerInfo.CanUseItem says the player cannot use it, asked only with an item's number, since the game refuses anything else and a money row hands none (K0706).

-- {K0703} {K0706}

local library = LibVGA
local VEIL = { 0.9, 0.12, 0.1, 0.45 }

function library.create_unusable(frame, picture)
    local veil = frame:CreateTexture(nil, "OVERLAY", nil, 1)
    veil:SetColorTexture(VEIL[1], VEIL[2], VEIL[3], VEIL[4])
    veil:SetAllPoints(picture)
    veil:Hide()
    return veil
end

function library.update_unusable(veil, item)
    local check = C_PlayerInfo and C_PlayerInfo.CanUseItem
    veil:SetShown(type(item) == "number" and check ~= nil and not check(item))
end
