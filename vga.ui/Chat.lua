-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: Blizzard's chat in the accepted draft's look (manual/view/vga-probe.html .chat, .tabs2, .msgs, .in): Blizzard's background, border, tab and input art cleared; vga.ui's widget laid beneath tabs, lines and input, its ground the frames' setting, the small gold corner; the tabs quiet, the chosen one gold with a gold line beneath, always at full strength - the game's fading of the tabs while the mouse is away set to none (K0558) -; the lines in Geologica at the player's own size, spaced by three tenths of it; the lines at 12 pixels by default, set once, the player's own size kept after (K0510); the widget's left edge the chat's own, never a docked tab's, so a docked window - the combat log with its quick buttons too - lies wholly inside it; the input let into the ground, dark, with a fine line, as wide as the lines above it, its line turning gold and its ground a shade lighter while it is typed into, a gold caret blinking where the game's own cursor stands, as the game tells it on every move (OnCursorChanged), so with a long entry, whose text the game scrolls, it stays inside the input (K0739); once, a default size after the draft (420 by 150 at a 13-pixel base), the player's own resizing kept after. Blizzard's chat itself - channels, links, history, input - is untouched.

-- {K0264} {K0266} {K0358} {K0359} {K0362} {K0363} {K0510} {K0558} {K0739}

local library = LibVGA
local colours = library.colours
local BORDERS = { "Background", "TopLeftTexture", "BottomLeftTexture", "TopRightTexture", "BottomRightTexture", "LeftTexture", "RightTexture", "BottomTexture", "TopTexture" }
local INPUT_GROUND = { 0.031, 0.035, 0.043 }
local INPUT_LINE = { 0.18, 0.192, 0.22 }
local INPUT_LIT = { 0.071, 0.078, 0.094 }
local BLINK = 0.5
local TAB_QUIET = { 0.604, 0.588, 0.549 }
local TAB_CHOSEN = { 0.945, 0.812, 0.431 }
local LINE_SPACING = 0.3
local FONT_SIZE = 12
local TAB_FADES = { "CHAT_FRAME_TAB_SELECTED_NOMOUSE_ALPHA", "CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA", "CHAT_FRAME_TAB_ALERTING_NOMOUSE_ALPHA" }
local skins = {}

local function update_cleared(region)
    if region and region.SetTexture then region:SetTexture(nil) end
end

local function update_input_look(input, skin)
    local radius, typing = library.read_size(-4), input:HasFocus()
    local line, ground = typing and colours.gold or INPUT_LINE, typing and INPUT_LIT or INPUT_GROUND
    library.update_surface(skin.input.ring, -1, radius + 1, line, line)
    library.update_surface(skin.input.ground, 0, radius, ground, ground, 0.8)
    skin.input.caret:SetShown(typing)
end

local function update_caret(input, skin, elapsed)
    local caret = skin.input.caret
    if not input:HasFocus() then return end
    caret.time = (caret.time or 0) + elapsed
    caret:SetAlpha(math.floor(caret.time / BLINK) % 2 == 0 and 1 or 0)
    local face, size = input:GetFont()
    if not face then return end
    local left, right = input:GetTextInsets()
    local width = math.max(2, math.floor(size / 8 + 0.5))
    local x = skin.input.cursor_x
    if not x then
        skin.input.measure:SetFont(face, size, "")
        skin.input.measure:SetText((input:GetText() or ""):sub(1, input:GetCursorPosition()))
        x = skin.input.measure:GetStringWidth() + 1
    end
    local most = input:GetWidth() - (right or 0) - width
    caret:SetSize(width, size)
    caret:ClearAllPoints()
    caret:SetPoint("LEFT", input, "LEFT", math.max(left or 0, math.min((left or 0) + x, most)), 0)
end

local function update_cursor_seen(input, x)
    local skin = input.vga_caret_skin
    if skin then skin.cursor_x = x end
end

local function create_caret(input, skin)
    skin.input.caret = skin.input:CreateTexture(nil, "OVERLAY")
    skin.input.caret:SetColorTexture(colours.gold[1], colours.gold[2], colours.gold[3], 1)
    skin.input.caret:Hide()
    skin.input.measure = skin.input:CreateFontString(nil, "OVERLAY")
    skin.input.measure:SetFont(library.read_font("body"):GetFont(), 12, "")
    skin.input.measure:Hide()
    input.vga_caret_skin = skin.input
    input:HookScript("OnCursorChanged", update_cursor_seen)
    skin.input:SetScript("OnUpdate", function(_, elapsed) library.update_safely("chat caret", update_caret, input, skin, elapsed) end)
    input:HookScript("OnEditFocusGained", function() skin.input.caret.time = 0 update_input_look(input, skin) end)
    input:HookScript("OnEditFocusLost", function() update_input_look(input, skin) end)
end

local function create_skin(chat)
    local name = chat:GetName()
    local skin = library.create_frame(nil, chat)
    skin:SetFrameLevel(math.max(chat:GetFrameLevel() - 1, 0))
    skin:EnableMouse(false)
    skin.corner:EnableMouse(false)
    local input = _G[name .. "EditBox"]
    if input then
        skin.input = CreateFrame("Frame", nil, input)
        skin.input:SetAllPoints()
        skin.input:SetFrameLevel(math.max(input:GetFrameLevel() - 1, 0))
        skin.input.ring = library.create_surface(skin.input, "BACKGROUND", 0)
        skin.input.ground = library.create_surface(skin.input, "BACKGROUND", 1)
        create_caret(input, skin)
    end
    skin.line = CreateFrame("Frame", nil, _G[name .. "Tab"] or chat)
    skin.line.mark = skin.line:CreateTexture(nil, "OVERLAY")
    skin.line.mark:SetAllPoints()
    skin.line.mark:SetColorTexture(colours.gold[1], colours.gold[2], colours.gold[3], 1)
    skins[chat] = skin
    return skin
end

local function update_art(chat)
    local name = chat:GetName()
    for _, part in ipairs(BORDERS) do update_cleared(_G[name .. part]) end
    local input = _G[name .. "EditBox"]
    if input then
        for _, region in ipairs({ input:GetRegions() }) do
            if region:GetObjectType() == "Texture" then update_cleared(region) end
        end
    end
    local tab = _G[name .. "Tab"]
    if tab then
        for _, region in ipairs({ tab:GetRegions() }) do
            if region:GetObjectType() == "Texture" then update_cleared(region) end
        end
    end
end

local function update_tab(chat, skin)
    local tab = _G[chat:GetName() .. "Tab"]
    if not tab then return end
    tab:SetAlpha(1)
    local text = tab:GetFontString() or tab.Text
    local chosen = SELECTED_CHAT_FRAME == chat or (GENERAL_CHAT_DOCK and FCFDock_GetSelectedWindow and FCFDock_GetSelectedWindow(GENERAL_CHAT_DOCK) == chat)
    local colour = chosen and TAB_CHOSEN or TAB_QUIET
    if text then
        text:SetFontObject(library.read_font(chosen and "caption" or "small"))
        text:SetTextColor(colour[1], colour[2], colour[3])
    end
    skin.line:ClearAllPoints()
    skin.line:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", library.read_size(-4), 0)
    skin.line:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -library.read_size(-4), 0)
    skin.line:SetHeight(2)
    skin.line:SetShown(chosen and true or false)
end

local function update_chat(chat)
    local skin = skins[chat] or create_skin(chat)
    update_art(chat)
    local name, pad = chat:GetName(), library.read_size(-2)
    local tab, input = _G[name .. "Tab"], _G[name .. "EditBox"]
    skin:ClearAllPoints()
    skin:SetPoint("LEFT", chat, "LEFT", -pad, 0)
    skin:SetPoint("TOP", tab or chat, "TOP", 0, pad)
    skin:SetPoint("RIGHT", chat, "RIGHT", pad, 0)
    skin:SetPoint("BOTTOM", input and input:IsShown() and input or chat, "BOTTOM", 0, -pad)
    library.update_frame(skin)
    if input and skin.input then
        input:ClearAllPoints()
        input:SetPoint("TOPLEFT", chat, "BOTTOMLEFT", 0, -pad)
        input:SetPoint("TOPRIGHT", chat, "BOTTOMRIGHT", 0, -pad)
        update_input_look(input, skin)
    end
    local face = library.read_font("body"):GetFont()
    local _, size, flags = chat:GetFont()
    if face and size then
        chat:SetFont(face, size, flags or "")
        if chat.SetSpacing then chat:SetSpacing(math.floor(size * LINE_SPACING + 0.5)) end
    end
    update_tab(chat, skin)
end

local function update_tabs_kept()
    for _, name in ipairs(TAB_FADES) do _G[name] = 1 end
end

local function update_chats()
    for index = 1, NUM_CHAT_WINDOWS or 0 do
        local chat = _G["ChatFrame" .. index]
        if chat then library.update_safely("chat " .. index, update_chat, chat) end
    end
end

local function update_default_size()
    if InCombatLockdown() or LibVGASettings.chat_sized or not ChatFrame1 then return end
    local large = library.read_size(6)
    ChatFrame1:SetSize(math.floor(large * 7.5 + 0.5), math.floor(large * 2.7 + 0.5))
    if FCF_SavePositionAndDimensions then FCF_SavePositionAndDimensions(ChatFrame1) end
    LibVGASettings.chat_sized = true
end

local function update_default_font()
    if LibVGASettings.chat_font_set then return end
    for index = 1, NUM_CHAT_WINDOWS or 0 do
        local chat = _G["ChatFrame" .. index]
        if chat and FCF_SetChatWindowFontSize then FCF_SetChatWindowFontSize(nil, chat, FONT_SIZE) end
    end
    LibVGASettings.chat_font_set = true
end

local function update_chats_safely()
    library.update_safely("chats", update_chats)
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("UPDATE_CHAT_WINDOWS")
events:RegisterEvent("UPDATE_FLOATING_CHAT_WINDOWS")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        update_tabs_kept()
        library.create_element("chat", { update = update_chats })
        library.update_safely("chat size", update_default_size)
        library.update_safely("chat font", update_default_font)
        for _, hook in ipairs({ "FCF_Tab_OnClick", "FCFDock_SelectWindow", "FCF_OpenTemporaryWindow", "ChatEdit_ActivateChat", "ChatEdit_DeactivateChat" }) do
            if _G[hook] then hooksecurefunc(hook, update_chats_safely) end
        end
    end
    update_chats_safely()
end)
