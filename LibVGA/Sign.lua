-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's sign (K0857): the vaulted metal signs the talk with a figure carries, every one in gold and in silver - gold for what can be used now, silver for what runs, as the game colours its signs (K0854) -, the exclamation mark in orange too, for the bags' item that starts a quest (K0851): offer »!«, question »?«, coins, book, gryphon, hearthstone, temple, chat, anvil. Each is a picture of LibVGA's media, Media/Sign/<Name><Colour>.tga, made by tools/questmark/talksigns.py from the owner's pictures by Grok (K0852, K0853); library.read_sign_picture gives its name for any place that lays a picture - an item row's icon, a sidebar's entry -, and the sign object lays it on its own, 20 draft pixels square by default, its word as its tooltip, a click on it its owner's (create_sign, update_sign; before in the item row, K0855).

-- {K0857} {K0855} {K0854} {K0853} {K0852} {K0851}

local library = LibVGA
local NAMES = { offer = "Offer", question = "Question", coins = "Coins", book = "Book", gryphon = "Gryphon", hearthstone = "Hearthstone", temple = "Temple", chat = "Chat", anvil = "Anvil" }
local COLOURS = { gold = "Gold", silver = "Silver", orange = "Orange" }
local SIZE = 20

function library.read_sign_picture(name, colour)
    return "Sign\\" .. NAMES[name] .. COLOURS[colour or "gold"]
end

local function render_sign_tip(sign)
    if not sign.word then return end
    GameTooltip:SetOwner(sign, "ANCHOR_RIGHT")
    GameTooltip:SetText(sign.word)
    GameTooltip:Show()
end

local function render_sign_left()
    GameTooltip:Hide()
end

local function render_sign_clicked(sign)
    if sign.on_click then sign.on_click(sign) end
end

function library.create_sign(parent, on_click)
    local sign = CreateFrame("Frame", nil, parent)
    sign.on_click = on_click
    sign.picture = sign:CreateTexture(nil, "ARTWORK")
    sign.picture:SetAllPoints()
    sign:EnableMouse(true)
    sign:SetScript("OnEnter", render_sign_tip)
    sign:SetScript("OnLeave", render_sign_left)
    sign:SetScript("OnMouseUp", render_sign_clicked)
    return sign
end

function library.update_sign(sign, name, colour, word, size)
    local side = library.read_draft_size(size or SIZE)
    sign.picture:SetTexture(library.media .. library.read_sign_picture(name, colour))
    sign.word = word
    sign:SetSize(side, side)
end
