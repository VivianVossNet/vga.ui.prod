-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: the trade toasts (K1040), LibVGA's toast of the kind »trade«, green rimmed, silenced by its switch on the tab »Hinweise«, as manual/view/vga-toasts.html lists them: an auction bought outright or a bulk purchase, »Leinenstoff gekauft« with what it cost beneath, from the ledger's own record of it (vga.write_bought, vga.ui/Auctionledger.lua), never a merchant's piece; an auction won by bidding, sold, outbid or expired, read from the game's own sentence of it in the system chat (ERR_AUCTION_WON_S, ERR_AUCTION_SOLD_S, ERR_AUCTION_OUTBID_S, ERR_AUCTION_EXPIRED_S, by vga.read_game_sentence); everything repaired at a merchant, »Alles repariert« with its cost beneath (vga.render_repaired, called by vga.ui/Merchant.lua); a trade with another player complete (ERR_TRADE_COMPLETE, the game's info message). What is done, and done well - bought, won, sold, repaired, traded - carries LibVGA's green tick (K1042). Whether Forever sends each of those sentences is not yet seen in the game.

-- {K1042} {K1040} {K1036}

local _, vga = ...
local library = LibVGA
local PICTURE = "Interface\\Icons\\INV_Misc_Coin_02"
local BOUGHT = { auction = true, commodity = true }
local SENTENCES = { { "ERR_AUCTION_WON_S", "trade_won", true }, { "ERR_AUCTION_SOLD_S", "trade_sold", true }, { "ERR_AUCTION_OUTBID_S", "trade_outbid" }, { "ERR_AUCTION_EXPIRED_S", "trade_expired" } }

local function render(line, second, done)
    library.render_toast({ head = library.texts.toast_trade, line = line, second = second, picture = PICTURE, kind = "trade", done = done })
end

local function read_money(copper)
    return copper and copper > 0 and library.read_money_text(copper) or nil
end

local function render_bought(item_id, _, total, way)
    if not BOUGHT[way] then return end
    local name = C_Item.GetItemNameByID and C_Item.GetItemNameByID(item_id) or tostring(item_id)
    render(string.format(library.texts.trade_bought, name), read_money(total), true)
end

function vga.render_repaired(cost)
    render(library.texts.trade_repaired, read_money(cost), true)
end

local function render_sentence(message)
    for _, sentence in ipairs(SENTENCES) do
        local words = vga.read_game_sentence(_G[sentence[1]], message)
        if words then return render(string.format(library.texts[sentence[2]], words[1]), nil, sentence[3]) end
    end
end

local function render_message(_, message)
    if type(ERR_TRADE_COMPLETE) == "string" and type(message) == "string" and not (issecretvalue and issecretvalue(message)) and message == ERR_TRADE_COMPLETE then render(library.texts.trade_done, nil, true) end
end

if vga.write_bought then hooksecurefunc(vga, "write_bought", function(...) library.update_safely("trade toast bought", render_bought, ...) end) end

local HEARD = { CHAT_MSG_SYSTEM = render_sentence, UI_INFO_MESSAGE = render_message }

local events = CreateFrame("Frame")
library.update_events(events, { "CHAT_MSG_SYSTEM", "UI_INFO_MESSAGE" })
events:SetScript("OnEvent", function(_, event, first, second) library.update_safely("trade toast " .. event, HEARD[event], first, second) end)
