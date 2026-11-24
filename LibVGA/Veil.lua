-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's veil over one of the game's own windows that vga.ui replaces - the merchant's, the gossip, the quest window -: the game's window stays shown, so the visit, the talk or the quest stays open as the game keeps it, but it is made invisible, shrunk and laid off the screen, out of the mouse's reach; unveiled it takes back its look and lets the game place it again. Hiding the game's window instead would end the visit (K0832). Closing ours ends the visit through library.render_game_ended: the game's own close where the client has it, and the game's window hidden in any case, before its veil is lifted - so the game's window never shows when ours is closed, on a client whose close is named otherwise or missing (K0890).

-- {K0890} {K0832} {K0645}

local library = LibVGA
local OFF_SCREEN = 4000

function library.update_game_veiled(frame, veiled)
    if not frame then return end
    frame:SetAlpha(veiled and 0 or 1)
    frame:SetScale(veiled and 0.01 or 1)
    if frame.EnableMouse and not InCombatLockdown() then frame:EnableMouse(not veiled) end
    if not veiled then
        if UpdateUIPanelPositions then UpdateUIPanelPositions(frame) end
        return
    end
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMRIGHT", OFF_SCREEN, -OFF_SCREEN)
end

function library.render_game_ended(frame, close)
    if close then close() end
    if frame and frame:IsShown() then
        if HideUIPanel then HideUIPanel(frame) end
        frame:Hide()
    end
    library.update_game_veiled(frame, false)
end
