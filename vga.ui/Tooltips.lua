-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: Blizzard's tooltips in LibVGA's tooltip skin (LibVGA/Tooltipskin.lua, K0795) - Blizzard's frame hidden, the rounded dark ground, the small gold corner -, laid whenever the game sets a tooltip's backdrop or shows it; the texts in the chosen face, the header bold.

-- {K0795} {K0260} {K0340} {K0756} {K0758}

local library = LibVGA

local function update_skin_safely(tip, style, embedded)
    library.update_safely("tooltip", library.update_tooltip_skin, tip, style, embedded)
end

local function update_fonts()
    local plain, size = library.read_font("body"):GetFont()
    local bold = library.read_font("bold"):GetFont()
    local shapes = {
        { GameTooltipHeaderText, bold, library.read_size(1) },
        { GameTooltipText, plain, size },
        { GameTooltipTextSmall, plain, library.read_size(-1) },
    }
    for _, shape in ipairs(shapes) do
        if shape[1] then shape[1]:SetFont(shape[2], shape[3], "") end
    end
end

local function update_tooltips()
    update_fonts()
    for _, tip in ipairs({ GameTooltip, ItemRefTooltip, ShoppingTooltip1, ShoppingTooltip2 }) do
        if tip then update_skin_safely(tip) end
    end
end

if SharedTooltip_SetBackdropStyle then
    hooksecurefunc("SharedTooltip_SetBackdropStyle", update_skin_safely)
end
for _, tip in ipairs({ GameTooltip, ItemRefTooltip, ShoppingTooltip1, ShoppingTooltip2 }) do
    if tip then tip:HookScript("OnShow", update_skin_safely) end
end
library.create_element("tooltips", { update = update_tooltips })
