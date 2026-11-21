-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's money field as the accepted draft draws .input.money (manual/view/vga-auctions.html, K0632): one dark rounded field with a fine line, inside it gold, silver and copper to type, each figure followed by its coin as LibVGA's money shows them, each part as wide as its digits need; read back as copper.

-- {K0632}

local library = LibVGA
local colours = library.colours
local FIELD = { 0.031, 0.035, 0.043 }
local COINS = { "CoinGold", "CoinSilver", "CoinCopper" }
local DIGITS = { 5, 2, 2 }

function library.create_money_field(parent, on_change)
    local field = CreateFrame("Frame", nil, parent)
    field.edge = library.create_surface(field, "BACKGROUND", 0)
    field.ground = library.create_surface(field, "BACKGROUND", 1)
    field.measure = library.create_text(field, "small")
    field.measure:Hide()
    field.parts = {}
    for index, coin in ipairs(COINS) do
        local part = CreateFrame("EditBox", nil, field)
        part:SetAutoFocus(false)
        part:SetNumeric(true)
        part:SetMaxLetters(DIGITS[index])
        part:SetJustifyH("RIGHT")
        part:SetTextColor(colours.ink[1], colours.ink[2], colours.ink[3], 1)
        part.coin = field:CreateTexture(nil, "ARTWORK")
        part.coin:SetTexture(library.media .. coin)
        part:SetScript("OnEscapePressed", part.ClearFocus)
        part:SetScript("OnEnterPressed", part.ClearFocus)
        part:SetScript("OnTextChanged", on_change)
        field.parts[index] = part
    end
    return field
end

function library.update_money_field_layout(field)
    local height, pad, coin, near = library.read_size(2), library.read_draft_size(10), library.read_draft_size(10), library.read_draft_size(2)
    local radius = library.read_draft_size(7)
    field.measure:SetFontObject(library.read_font("small"))
    local x = pad
    for index, part in ipairs(field.parts) do
        field.measure:SetText(string.rep("0", index == 1 and 3 or DIGITS[index]))
        local width = math.ceil(field.measure:GetStringWidth()) + 2
        part:SetFontObject(library.read_font("small"))
        part:SetSize(width, height)
        part:ClearAllPoints()
        part:SetPoint("LEFT", field, "LEFT", x, 0)
        part.coin:SetSize(coin * 0.7, coin * 0.7)
        part.coin:ClearAllPoints()
        part.coin:SetPoint("LEFT", part, "RIGHT", near, 0)
        x = x + width + near + coin * 0.7 + library.read_draft_size(6)
    end
    field:SetSize(x - library.read_draft_size(6) + pad, height)
    library.update_surface(field.edge, 0, radius, colours.edge, colours.edge)
    library.update_surface(field.ground, 1, radius - 1, FIELD, FIELD)
end

function library.update_money_field(field, copper)
    local parts = { math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100 }
    for index, part in ipairs(field.parts) do part:SetText(parts[index]) end
end

function library.read_money_field(field)
    local values = {}
    for index, part in ipairs(field.parts) do values[index] = tonumber(part:GetText()) or 0 end
    return values[1] * 10000 + values[2] * 100 + values[3]
end
