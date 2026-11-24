-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's mark of the active row, as the accepted draft draws it (manual/view/vga-profile-active.html, K0779): the whole row on a quiet gold ground, its name gold and bold, every control in it as it is; nothing before the name, nothing that moves it. Any row of any list or dialog may carry it - the dialog's rows through library.create_row_mark, the profiles' active one so -, and it is LibVGA's one look of an active row, as library.update_chosen is the one look of a chosen entry.

-- {K0779}

local library = LibVGA
local colours = library.colours
local QUIET = 0.10
local GOLD_TEXT = { 0.945, 0.812, 0.431 }

function library.create_active_mark(row, label)
    local mark = { label = label, on = false }
    mark.ground = row:CreateTexture(nil, "BACKGROUND", nil, 2)
    mark.ground:SetAllPoints(row)
    mark.ground:SetColorTexture(colours.gold[1], colours.gold[2], colours.gold[3], QUIET)
    mark.ground:Hide()
    return mark
end

function library.update_active_mark(mark, on)
    mark.on = on and true or false
    mark.ground:SetShown(mark.on)
    local ink = mark.on and GOLD_TEXT or colours.label
    mark.label:SetFontObject(library.read_font(mark.on and "bold" or "body"))
    mark.label:SetTextColor(ink[1], ink[2], ink[3], 1)
end
