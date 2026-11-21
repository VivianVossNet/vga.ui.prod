-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's stepper as the accepted draft draws .step (manual/view/vga-auctions.html, K0632): one dark rounded field with a fine line, minus at the left, the number in the middle, plus at the right, the signs quiet, the number in the ink; a click on a sign asks the owner for the next number.

-- {K0632}

local library = LibVGA
local colours = library.colours
local FIELD = { 0.031, 0.035, 0.043 }
local SIGN, MIDDLE = 24, 40

local function render_step(sign)
    local stepper = sign:GetParent()
    stepper.on_step(stepper, sign.step)
end

local function create_sign(stepper, word, step)
    local sign = CreateFrame("Button", nil, stepper)
    sign.step = step
    sign.word = library.create_text(sign, "small", colours.quiet)
    sign.word:SetPoint("CENTER")
    sign.word:SetText(word)
    sign:SetScript("OnClick", render_step)
    return sign
end

function library.create_stepper(parent, on_step)
    local stepper = CreateFrame("Frame", nil, parent)
    stepper.on_step = on_step
    stepper.edge = library.create_surface(stepper, "BACKGROUND", 0)
    stepper.ground = library.create_surface(stepper, "BACKGROUND", 1)
    stepper.minus = create_sign(stepper, "−", -1)
    stepper.plus = create_sign(stepper, "+", 1)
    stepper.number = library.create_text(stepper, "small", colours.ink)
    stepper.number:SetPoint("CENTER")
    return stepper
end

function library.update_stepper(stepper, number)
    local sign, middle, height = library.read_draft_size(SIGN), library.read_draft_size(MIDDLE), library.read_size(2)
    local radius = library.read_draft_size(7)
    stepper:SetSize(2 * sign + middle, height)
    library.update_surface(stepper.edge, 0, radius, colours.edge, colours.edge)
    library.update_surface(stepper.ground, 1, radius - 1, FIELD, FIELD)
    for _, part in ipairs({ stepper.minus, stepper.plus }) do
        part:SetSize(sign, height)
        part.word:SetFontObject(library.read_font("small"))
    end
    stepper.minus:SetPoint("LEFT")
    stepper.plus:SetPoint("RIGHT")
    stepper.number:SetFontObject(library.read_font("small"))
    if number then stepper.number:SetText(number) end
end
