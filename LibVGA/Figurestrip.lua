-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's figure strip, an object made once (K0869, K0860) as the accepted draft draws the figures of the auction's pages (manual/view/vga-auctions.html, K0798): one of LibVGA's groups, fifty-two draft pixels high, holding so many cells side by side, in each a caption in capitals above its value, a hairline between the cells. Its owner feeds it a plan once - its figures, each { word, kind - »money«, »money_small«, »chip« or »text« -, font and colour of a text, colour of money } - and fills each figure's value with that value's own layer (library.update_money, library.update_chip, SetText); the strip owns its group, captions, values and hairlines and lays them at each laying by its width, reporting its height. One task: lay a strip of figures.

-- {K0869} {K0860} {K0798}

local library = LibVGA
local colours = library.colours
local HEIGHT = 52
local PAD = 12
local TOP = 10
local APART = 4

local function create_value(strip, figure)
    if figure.kind == "chip" then return library.create_chip(strip) end
    if figure.kind == "text" then return library.create_text(strip, figure.font or "bold", figure.colour or colours.ink) end
    local money = library.create_money(strip, figure.colour or colours.ink)
    if figure.kind == "money_small" then money.kind = "small" end
    return money
end

function library.create_figure_strip(parent, plan)
    local strip = library.create_group(parent)
    strip.figures = {}
    for index, figure in ipairs(plan.figures) do
        local made = { label = library.create_text(strip, "caption", colours.quiet), value = create_value(strip, figure) }
        made.label:SetText(library.read_capitals(figure.word))
        made.rule = index > 1 and library.create_hairline(strip) or nil
        strip.figures[index] = made
    end
    return strip
end

function library.update_figure_strip(strip, width)
    local height = library.read_draft_size(HEIGHT)
    strip:SetSize(width, height)
    library.update_group(strip)
    local cell, pad = width / #strip.figures, library.read_draft_size(PAD)
    for index, figure in ipairs(strip.figures) do
        local x = (index - 1) * cell
        figure.label:SetFontObject(library.read_font("caption"))
        figure.label:ClearAllPoints()
        figure.label:SetPoint("TOPLEFT", strip, "TOPLEFT", x + pad, -library.read_draft_size(TOP))
        figure.value:ClearAllPoints()
        figure.value:SetPoint("TOPLEFT", figure.label, "BOTTOMLEFT", 0, -library.read_draft_size(APART))
        if figure.rule then
            figure.rule:ClearAllPoints()
            figure.rule:SetPoint("TOPLEFT", strip, "TOPLEFT", x, -1)
            figure.rule:SetPoint("BOTTOMLEFT", strip, "BOTTOMLEFT", x, 1)
            figure.rule:SetWidth(1)
        end
    end
    return height
end
