-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's pop-up menu as manual/view/vga-settings-apple.html draws it (K0565), in the way of macOS: a button on a dark rounded ground with the chosen value's word and a small chevron; a click opens beneath it a menu on the dialog's ground, its values in sections under small quiet headings in capitals, the chosen one in gold on a faint ground, the elite's gold chevron turned to the left beside it at the right, pointing at it, the entries with room before and after them (K0571); a click on a value takes it and closes the menu, a click anywhere else closes it unchanged; the menu hangs from the screen, not from the dialog, which clips what reaches past it, so its entries always take the mouse, and it closes when its button hides (K0572). Its sections may be given anew while it stands, as the damage meter's recent fights change (K0721).

-- {K0565} {K0571} {K0572} {K0721}

local library = LibVGA
local colours = library.colours
local GROUND = { 0.031, 0.035, 0.043 }
local MENU = { 0.102, 0.11, 0.129 }
local CHEVRON_TOP, CHEVRON_FOOT = 0.25, 0.75

local function read_label(popup, value)
    for _, section in ipairs(popup.sections) do
        for _, item in ipairs(section.items) do
            if item[1] == value then return item[2] end
        end
    end
    return ""
end

local function update_closed(popup)
    popup.menu:Hide()
    popup.catcher:Hide()
end

local function render_item(item)
    local popup = item.popup
    popup.value = item.value
    update_closed(popup)
    library.update_popup(popup)
    popup.on_choose(item.value)
end

local function create_item(popup, value, label)
    local item = CreateFrame("Button", nil, popup.menu)
    item.popup, item.value = popup, value
    item.ground = library.create_surface(item, "BACKGROUND", 0)
    item.tick = item:CreateTexture(nil, "ARTWORK")
    item.tick:SetTexture(library.media .. "Chevron")
    item.tick:SetRotation(math.pi / 2)
    item.tick:SetVertexColor(colours.gold[1], colours.gold[2], colours.gold[3], 1)
    item.text = library.create_text(item, "small", colours.ink)
    item.text:SetText(label)
    item:SetScript("OnClick", render_item)
    return item
end

local function update_menu(popup)
    popup.menu:SetScale(popup:GetEffectiveScale() / UIParent:GetEffectiveScale())
    local pad, height, mark = library.read_size(-4), library.read_size(2), library.read_size(-4)
    local inner = 3 * pad
    local top, width = pad, math.max(popup:GetWidth(), popup.widest + 2 * inner + mark + 3 * pad)
    for _, made in ipairs(popup.made) do
        if made.heading then
            made.heading:SetFontObject(library.read_font("caption"))
            made.heading:ClearAllPoints()
            made.heading:SetPoint("TOPLEFT", popup.menu, "TOPLEFT", 2 * pad, -top - pad)
            top = top + pad + math.ceil(made.heading:GetStringHeight()) + pad / 2
        end
        for _, item in ipairs(made.items) do
            local on = item.value == popup.value
            local ink = on and colours.gold or colours.ink
            item:ClearAllPoints()
            item:SetPoint("TOPLEFT", popup.menu, "TOPLEFT", pad, -top)
            item:SetSize(width - 2 * pad, height)
            library.update_surface(item.ground, 0, library.read_size(-6), { 1, 1, 1 }, { 1, 1, 1 }, on and 0.06 or 0)
            item.tick:SetShown(on)
            item.tick:SetSize(mark, mark)
            item.tick:ClearAllPoints()
            item.tick:SetPoint("RIGHT", item, "RIGHT", -inner, 0)
            item.text:SetFontObject(library.read_font(on and "caption" or "small"))
            item.text:SetTextColor(ink[1], ink[2], ink[3], 1)
            item.text:ClearAllPoints()
            item.text:SetPoint("LEFT", item, "LEFT", inner, 0)
            top = top + height + 1
        end
    end
    popup.menu:SetSize(width, top + pad)
    popup.menu:ClearAllPoints()
    popup.menu:SetPoint("TOPRIGHT", popup, "BOTTOMRIGHT", 0, -2)
    library.update_surface(popup.menu.ground, 0, library.read_size(-4), MENU, MENU)
end

local function render_opened(popup)
    if popup.menu:IsShown() then
        update_closed(popup)
        return
    end
    update_menu(popup)
    popup.catcher:Show()
    popup.menu:Show()
end

local function update_caught(catcher)
    update_closed(catcher.popup)
end

local function create_sections(popup, sections)
    popup.made = {}
    for index, section in ipairs(sections) do
        local made = { items = {} }
        if section.title then
            made.heading = library.create_text(popup.menu, "caption", colours.quiet)
            made.heading:SetText(section.title:upper())
        end
        for _, entry in ipairs(section.items) do made.items[#made.items + 1] = create_item(popup, entry[1], entry[2]) end
        popup.made[index] = made
    end
end

function library.update_popup_sections(popup, sections, value)
    for _, made in ipairs(popup.made) do
        if made.heading then made.heading:Hide() end
        for _, item in ipairs(made.items) do item:Hide() end
    end
    popup.sections, popup.value = sections, value
    create_sections(popup, sections)
end

function library.create_popup(parent, sections, value, on_choose)
    local popup = CreateFrame("Button", nil, parent)
    popup.popup, popup.sections, popup.value, popup.on_choose = true, sections, value, on_choose
    popup.ground = library.create_surface(popup, "BACKGROUND", 0)
    popup.text = library.create_text(popup, "small", colours.ink)
    popup.chevron = popup:CreateTexture(nil, "ARTWORK")
    popup.chevron:SetTexture(library.media .. "NaviChevron")
    popup.chevron:SetTexCoord(0, 1, CHEVRON_TOP, CHEVRON_FOOT)
    popup.chevron:SetRotation(math.pi)
    popup.catcher = CreateFrame("Button", nil, UIParent)
    popup.catcher:SetAllPoints(UIParent)
    popup.catcher:SetFrameStrata("FULLSCREEN")
    popup.catcher.popup = popup
    popup.catcher:SetScript("OnClick", update_caught)
    popup.catcher:Hide()
    popup.menu = CreateFrame("Frame", nil, UIParent)
    popup.menu:SetFrameStrata("FULLSCREEN_DIALOG")
    popup.menu:SetToplevel(true)
    popup.menu:EnableMouse(true)
    popup.menu.ground = library.create_surface(popup.menu, "BACKGROUND", 0)
    popup.menu:Hide()
    create_sections(popup, sections)
    popup:SetScript("OnClick", render_opened)
    popup:SetScript("OnHide", update_closed)
    return popup
end

function library.read_popup_width(popup)
    local pad, widest = library.read_size(-4), 0
    for _, made in ipairs(popup.made) do
        for _, item in ipairs(made.items) do
            item.text:SetFontObject(library.read_font("caption"))
            widest = math.max(widest, math.ceil(item.text:GetStringWidth()))
        end
    end
    popup.widest = widest
    return widest + 3 * pad + library.read_size(-2)
end

function library.update_popup(popup)
    local pad, height, chevron = library.read_size(-4), library.read_size(2), library.read_size(-4)
    popup:SetSize(library.read_popup_width(popup), height)
    library.update_surface(popup.ground, 0, library.read_size(-4), GROUND, GROUND)
    popup.text:SetFontObject(library.read_font("small"))
    popup.text:SetText(read_label(popup, popup.value))
    popup.text:ClearAllPoints()
    popup.text:SetPoint("LEFT", popup, "LEFT", pad * 2, 0)
    popup.chevron:SetSize(chevron, math.floor(chevron / 2 + 0.5))
    popup.chevron:SetVertexColor(colours.quiet[1], colours.quiet[2], colours.quiet[3], 1)
    popup.chevron:ClearAllPoints()
    popup.chevron:SetPoint("RIGHT", popup, "RIGHT", -pad * 2, 0)
end
