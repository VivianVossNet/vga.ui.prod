-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's breadcrumb, as the accepted catalogue draws it (manual/view/vga-catalogue.html »Brotkrumen«, K0775) after the auction house's path through the kinds (manual/view/vga-auctions.html .crumbs, K0624): the path's words in a line, the first quiet, the others gold, a quiet »›« between them, each word a button that leads back to its level; its owner names the words and what a click does (K0795). A path may be set in by crumbs.inset and tells the width it took, crumbs.width, so a pill holding it fits it (K0819).

-- {K0819} {K0795} {K0624} {K0775}

local library = LibVGA
local colours = library.colours

function library.create_crumbs(parent, area, count, on_choose)
    local crumbs = { area = area }
    for index = 1, count do
        local crumb = CreateFrame("Button", nil, parent)
        crumb.index = index
        crumb.word = library.create_text(crumb, "small", colours.gold)
        crumb.word:SetPoint("LEFT")
        crumb.mark = library.create_text(area, "small", colours.quiet)
        crumb.mark:SetText("›")
        crumb:SetScript("OnClick", on_choose)
        crumbs[index] = crumb
    end
    return crumbs
end

local function update_crumb(crumbs, crumb, word, x, top)
    local gap, height = library.read_size(-4), library.read_size(1) + library.read_size(-4)
    local ink = crumb.index == 1 and colours.label or colours.gold
    crumb.word:SetFontObject(library.read_font("small"))
    crumb.word:SetTextColor(ink[1], ink[2], ink[3], 1)
    crumb.word:SetText(word)
    crumb.mark:SetFontObject(library.read_font("small"))
    if crumb.index > 1 then
        crumb.mark:ClearAllPoints()
        crumb.mark:SetPoint("LEFT", crumbs.area, "TOPLEFT", x, -(top + height / 2))
        x = x + math.ceil(crumb.mark:GetStringWidth()) + gap
    end
    local width = math.ceil(crumb.word:GetStringWidth())
    crumb:SetSize(width, height)
    crumb:ClearAllPoints()
    crumb:SetPoint("TOPLEFT", crumbs.area, "TOPLEFT", x, -top)
    return x + width + gap
end

function library.update_crumbs(crumbs, words, top)
    local x = crumbs.inset or 0
    for index, crumb in ipairs(crumbs) do
        local shown = words[index] ~= nil
        crumb:SetShown(shown)
        crumb.mark:SetShown(shown and index > 1)
        if shown then x = update_crumb(crumbs, crumb, words[index], x, top) end
    end
    crumbs.width = x - library.read_size(-4) + (crumbs.inset or 0)
    return library.read_size(1) + library.read_size(-4)
end
