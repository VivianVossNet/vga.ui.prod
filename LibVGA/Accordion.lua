-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's accordion label, first drawn for the quest tracker's zones (manual/view/vga-questzones.html, K0547) and lifted here (K0633) for the item tooltip's Auktionen and Entzaubern (manual/view/vga-tooltip.html, K0604): a thin line above, a chevron pointing right when closed and down when open, the word in small capitals and a figure or money at the right, all in VGA's orange but the money in the ink; twenty-six draft pixels high, with eight draft pixels of room before the line and eight more after it by default, so a separator never sits tight against the lines around it (K0671).

-- {K0547} {K0633} {K0671}

local library = LibVGA
local colours = library.colours
local LABEL_HEIGHT = 26
local MARGIN = 8
local CHEVRON = 9
local LINE = { 0.173, 0.184, 0.208 }
local CAPITALS = { ["ä"] = "Ä", ["ö"] = "Ö", ["ü"] = "Ü", ["é"] = "É", ["è"] = "È", ["à"] = "À", ["ç"] = "Ç", ["ñ"] = "Ñ" }

function library.read_capitals(name)
    local upper = name:upper()
    for small, capital in pairs(CAPITALS) do upper = upper:gsub(small, capital) end
    return upper
end

function library.create_accordion(parent)
    local label = CreateFrame("Button", nil, parent)
    label.line = label:CreateTexture(nil, "BACKGROUND")
    label.line:SetColorTexture(LINE[1], LINE[2], LINE[3], 1)
    label.chevron = label:CreateTexture(nil, "ARTWORK")
    label.chevron:SetTexture(library.media .. "NaviChevron")
    label.chevron:SetTexCoord(0, 1, 0.25, 0.75)
    label.chevron:SetVertexColor(colours.orange[1], colours.orange[2], colours.orange[3], 1)
    label.name = library.create_text(label, "caption", colours.orange)
    label.count = library.create_text(label, "small", colours.orange)
    label.money = library.create_money(label, colours.ink)
    label.money.kind = "small"
    label:RegisterForClicks("AnyUp")
    return label
end

function library.read_accordion_height()
    return library.read_draft_size(LABEL_HEIGHT + 2 * MARGIN)
end

function library.update_accordion(label, word, open, width, count, copper)
    local pad, height, chevron = library.read_draft_size(12), library.read_accordion_height(), library.read_draft_size(CHEVRON)
    local margin = library.read_draft_size(MARGIN)
    local middle = -margin / 2
    label:SetSize(width, height)
    label.line:ClearAllPoints()
    label.line:SetPoint("TOPLEFT", label, "TOPLEFT", 0, -margin)
    label.line:SetPoint("TOPRIGHT", label, "TOPRIGHT", 0, -margin)
    label.line:SetHeight(1)
    label.chevron:SetSize(chevron, math.floor(chevron / 2 + 0.5))
    label.chevron:ClearAllPoints()
    label.chevron:SetPoint("LEFT", label, "LEFT", pad, middle)
    label.chevron:SetRotation(open and math.pi or -math.pi / 2)
    label.name:SetFontObject(library.read_frame_font("caption"))
    label.name:SetText(word)
    label.name:ClearAllPoints()
    label.name:SetPoint("LEFT", label, "LEFT", pad + library.read_draft_size(20), middle)
    label.count:SetFontObject(library.read_frame_font("small"))
    label.count:SetText(count or "")
    label.count:ClearAllPoints()
    label.count:SetPoint("RIGHT", label, "RIGHT", -pad, middle)
    label.money:SetShown(copper ~= nil)
    if copper then
        library.update_money(label.money, copper)
        label.money:ClearAllPoints()
        label.money:SetPoint("RIGHT", label, "RIGHT", -pad, middle)
    end
    return height
end
