-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's item row, as the accepted catalogue draws it (manual/view/vga-catalogue.html »Liste mit Kopf und Gegenstandszeile«, K0775) after the auction house's rows (manual/view/vga-auctions.html .results .r; K0632): a row of LibVGA's list showing one item - its picture 26 draft pixels square at the row's left, veiled where the player cannot use it (library.create_unusable), its name beside it in LibVGA's one quality colour - rare and epic a shade brighter so they read on the dark ground (K0700) -, held to its column and ended in »…«; a row that can be chosen is a button and, chosen, lies on a faint gold ground in a fine gold ring. The item's tooltip opens only over its picture and its name, following the pointer sixteen pixels to its right and thirty-two above it (library.update_item_tip_owner, K0787), never over the rest of the row, so the row's other parts stay usable (library.create_item_hover, K0786). A row may show its picture in a cell - the ground, the edge in the item's quality colour from uncommon up, else the slot's grey, the count at its lower right (plan.cell) - and a second, quiet line under the name (item.sub), the name then bold, as the windows of the game's figures draw them (K0836). Its user fills the columns after the name and says what hovering and clicking do (K0785). library.read_quality_colour is every item name's colour. The comparison tooltips the game hangs beside an item row's tooltip - »Ausgerüstet«, at a merchant shown at once - end with it at its bottom, on the side the game chose, so they too stay above the pointer and the rows beneath stay readable (K0842). A row may carry a tag after its name - a chip with a picture and a word (item.tag, K0848), or LibVGA's sign (library.create_sign, K0857), its word as its tooltip and a click on it the row's, as the merchant's answer in the talk carries the gold anvil for »Reparatur« (item.tag.sign, K0855) -, the name giving way to it. A row asked for more lines (item.lines) breaks its name over up to that many, ending only the last in »…«, and library.read_item_row_height gives the height that holds it, six draft pixels above and below, never less than the row's own (K0866). A row given a click is a button, and a row asked to (plan.lit) lies on a faint gold ground while the mouse is over it, its tooltip's part too; its cell rims a quest item in gold with a small gold question mark at its lower left (item.quest, library.create_cell_quest), a fixed item with the two blue rounded corners of the bags (item.pinned, library.create_cell_pinned, K0901), its second line may take a colour of its own (item.sub_colour), money stands in its name's place in LibVGA's money, bold (item.money, in copper), and a row taken is greyed - the cell's picture, edge, count and mark without colour and darkened, the name, its second line and the money in LibVGA's grey - in its place, as the loot's rows show it (item.taken, manual/view/vga-loot.html C, K0874).

-- {K0901} {K0874} {K0866} {K0857} {K0855} {K0848} {K0842} {K0836} {K0787} {K0786} {K0785} {K0700} {K0632} {K0775}

local library = LibVGA
local WRAP_ROOM = 6
local colours = library.colours
local ICON = 26
local CELL_EDGE = 2
local SLOT_EDGE = { 0.18, 0.192, 0.22 }
local UNCOMMON = 2
local CHOSEN_ALPHA = 0.08
local LIT_ALPHA = 0.08
local DIMMED = 0.6
local LUMA = { 0.2126, 0.7152, 0.0722 }
local RADIUS = 8
local TIP_ASIDE = 16
local TIP_ABOVE = 32
local COMPARES = { "ShoppingTooltip1", "ShoppingTooltip2" }
local compare_heard = {}
local BRIGHT = { [3] = { 0.31, 0.56, 0.91 }, [4] = { 0.69, 0.36, 0.91 } }

function library.read_quality_colour(quality)
    if BRIGHT[quality] then return BRIGHT[quality] end
    local colour = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality or 1]
    return colour and { colour.r, colour.g, colour.b } or colours.ink
end

local function update_compare_above()
    local tip = GameTooltip
    if not (tip.vga_above and tip:IsShown()) then return end
    local first = _G[COMPARES[1]]
    if not (first and first:IsShown()) then return end
    local _, _, toward = first:GetPoint(1)
    local left = type(toward) ~= "string" or toward:find("LEFT") ~= nil
    local beside = tip
    for _, name in ipairs(COMPARES) do
        local compare = _G[name]
        if compare and compare:IsShown() then
            compare:ClearAllPoints()
            if left then compare:SetPoint("BOTTOMRIGHT", beside, "BOTTOMLEFT") else compare:SetPoint("BOTTOMLEFT", beside, "BOTTOMRIGHT") end
            beside = compare
        end
    end
end

local function update_compare_soon()
    update_compare_above()
    C_Timer.After(0, update_compare_above)
end

local function update_above_ended(tip)
    tip.vga_above = nil
end

local function update_compare_heard()
    for _, name in ipairs(COMPARES) do
        if _G[name] and not compare_heard[name] then
            compare_heard[name] = true
            _G[name]:HookScript("OnShow", update_compare_soon)
        end
    end
    if compare_heard.game then return end
    compare_heard.game = true
    if TooltipComparisonManager and TooltipComparisonManager.AnchorShoppingTooltips then hooksecurefunc(TooltipComparisonManager, "AnchorShoppingTooltips", update_compare_above) end
    if GameTooltip_AnchorComparisonTooltips then hooksecurefunc("GameTooltip_AnchorComparisonTooltips", update_compare_above) end
    GameTooltip:HookScript("OnHide", update_above_ended)
end

function library.update_item_tip_owner(tip, owner)
    update_compare_heard()
    tip:SetOwner(owner, "ANCHOR_CURSOR_RIGHT", TIP_ASIDE, TIP_ABOVE)
    tip.vga_above = true
end

local function update_line_lit(line)
    line.light:Show()
end

local function update_line_unlit(line)
    if not (line.IsMouseOver and line:IsMouseOver()) then line.light:Hide() end
end

local function render_hover_entered(hover)
    if hover.line.light then update_line_lit(hover.line) end
    if hover.on_enter then hover.on_enter(hover.line) end
end

local function render_hover_left(hover)
    if hover.line.light then update_line_unlit(hover.line) end
    if hover.on_leave then hover.on_leave(hover.line) end
end

local function render_hover_clicked(hover, button)
    if hover.line.Click then hover.line:Click(button) end
end

function library.create_item_hover(line, on_enter, on_leave)
    local hover = CreateFrame("Frame", nil, line)
    hover.line, hover.on_enter, hover.on_leave = line, on_enter, on_leave
    hover:EnableMouse(true)
    if hover.SetPropagateMouseClicks then hover:SetPropagateMouseClicks(true) else hover:SetScript("OnMouseUp", render_hover_clicked) end
    hover:SetScript("OnEnter", render_hover_entered)
    hover:SetScript("OnLeave", render_hover_left)
    line.hover = hover
    return hover
end

function library.update_item_hover(line, picture, name, size)
    local gap, words, room = library.read_size(-4), library.read_string_width(name), name:GetWidth()
    if room and room > 1 then words = math.min(words, room) end
    line.hover:ClearAllPoints()
    line.hover:SetPoint("LEFT", picture, "LEFT")
    line.hover:SetSize(size + gap + words, size)
end

local function create_chosen_look(line)
    line.fill = library.create_surface(line, "BACKGROUND", 0)
    line.ring = library.create_ring(line, "OVERLAY", 0)
end

local function create_lit_look(line)
    line.light = line:CreateTexture(nil, "BACKGROUND")
    line.light:SetAllPoints()
    line.light:SetColorTexture(colours.gold[1], colours.gold[2], colours.gold[3], LIT_ALPHA)
    line.light:Hide()
    line:SetScript("OnEnter", update_line_lit)
    line:SetScript("OnLeave", update_line_unlit)
end

function library.create_item_row(parent, plan)
    local line = CreateFrame((plan.chosen or plan.on_click) and "Button" or "Frame", nil, parent)
    line:EnableMouse(true)
    if plan.chosen then create_chosen_look(line) end
    if plan.lit then create_lit_look(line) end
    if plan.cell then
        line.cell = library.create_cell_dress(CreateFrame("Frame", nil, line), { ground = 0 })
        line.count = library.create_text(line.cell, "figures_small", colours.ink)
    end
    line.icon = (line.cell or line):CreateTexture(nil, "ARTWORK")
    line.unusable = library.create_unusable(line, line.icon)
    line.name = library.create_text(line, "body", colours.ink)
    line.name:SetJustifyH("LEFT")
    line.name:SetWordWrap(false)
    if plan.on_click then line:SetScript("OnClick", plan.on_click) end
    library.create_item_hover(line, plan.on_enter, plan.on_leave)
    return line
end

local function create_sub(line)
    local text = library.create_text(line, "small", colours.quiet)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    return text
end

local function read_cell_ink(colour, taken)
    if not taken then return colour end
    local grey = (colour[1] * LUMA[1] + colour[2] * LUMA[2] + colour[3] * LUMA[3]) * DIMMED
    return { grey, grey, grey }
end

local function read_rim(item)
    if item.quest then return colours.gold end
    if (item.quality or 1) >= UNCOMMON then return library.read_quality_colour(item.quality) end
    return SLOT_EDGE
end

local function update_quest_mark(line, item)
    if item.quest and not line.quest then line.quest = library.create_cell_quest(line.cell) end
    if line.quest then library.update_cell_quest(line.quest, line.cell, item.quest == true, read_cell_ink(colours.gold, item.taken)) end
end

local function update_cell_look(line, item, size)
    local cell, edge = line.cell, library.read_draft_size(CELL_EDGE)
    cell:SetSize(size, size)
    library.update_surface(cell.vga_ground, 0, library.read_draft_size(6), colours.ground, colours.ground)
    library.update_ring(cell.vga_edge, edge, read_cell_ink(read_rim(item), item.taken), 1)
    library.update_cell_inside(cell, line.icon, line.count, edge + 1)
    local ink = read_cell_ink(colours.ink, item.taken)
    line.count:SetFontObject(library.read_font("figures_small"))
    line.count:SetTextColor(ink[1], ink[2], ink[3], 1)
    line.count:SetText(item.count and item.count > 1 and item.count or "")
    update_quest_mark(line, item)
    if item.pinned and not line.pinned then line.pinned = library.create_cell_pinned(line.cell) end
    if line.pinned then library.update_cell_pinned(line.pinned, line.cell, item.pinned == true) end
end

local function update_picture_taken(picture, taken)
    local light = taken and DIMMED or 1
    picture:SetDesaturated(taken == true)
    picture:SetVertexColor(light, light, light)
end

local function update_words(line, item, holder, gap, width)
    local colour = item.taken and colours.greyed or library.read_quality_colour(item.quality)
    line.name:SetWordWrap((item.lines or 1) > 1)
    line.name:SetMaxLines(item.lines or 1)
    line.name:SetText(item.money and "" or item.name)
    line.name:SetTextColor(colour[1], colour[2], colour[3], 1)
    line.name:ClearAllPoints()
    line.name:SetWidth(width)
    if line.sub then line.sub:SetShown(item.sub ~= nil) end
    if not item.sub then return line.name:SetPoint("LEFT", holder, "RIGHT", gap, 0) end
    local ink = item.taken and colours.greyed or item.sub_colour or colours.quiet
    line.sub:SetText(item.sub)
    line.sub:SetTextColor(ink[1], ink[2], ink[3], 1)
    line.sub:SetWidth(width)
    line.sub:ClearAllPoints()
    line.name:SetPoint("BOTTOMLEFT", holder, "RIGHT", gap, 0)
    line.sub:SetPoint("TOPLEFT", holder, "RIGHT", gap, -1)
end

local function render_sign_clicked(sign)
    local line = sign:GetParent()
    local click = line:GetScript("OnClick")
    if click then click(line, "LeftButton") end
end

local function read_tag(line, tag)
    if tag.sign then
        line.sign = line.sign or library.create_sign(line, render_sign_clicked)
        library.update_sign(line.sign, tag.sign, tag.colour, tag.word)
        return line.sign
    end
    line.tag = line.tag or library.create_chip(line)
    library.update_chip(line.tag, tag.kind, tag.picture, tag.word)
    return line.tag
end

local function update_tag(line, item, gap, width)
    if line.tag then line.tag:Hide() end
    if line.sign then line.sign:Hide() end
    if not item.tag then return end
    local tag = read_tag(line, item.tag)
    tag:Show()
    local room = math.max(1, width - tag:GetWidth() - gap)
    line.name:SetWidth(room)
    local said = math.min(math.ceil(library.read_string_width(line.name)), room)
    tag:ClearAllPoints()
    tag:SetPoint("LEFT", line.name, "LEFT", said + gap, 0)
end

local function update_money_name(line, item, holder, gap)
    if item.money and not line.money_name then
        line.money_name = library.create_money(line, colours.ink)
        line.money_name.kind = "bold"
    end
    if line.money_name then line.money_name:SetShown(item.money ~= nil) end
    if not item.money then return end
    library.update_money(line.money_name, item.money)
    library.update_money_greyed(line.money_name, item.taken == true)
    line.money_name:ClearAllPoints()
    line.money_name:SetPoint(item.sub and "BOTTOMLEFT" or "LEFT", holder, "RIGHT", gap, 0)
    line.hover:SetWidth(holder:GetWidth() + gap + line.money_name.vga_width)
end

function library.update_item_row(line, item, left, right)
    local size, gap = library.read_draft_size(ICON), library.read_size(-4)
    line.icon:SetTexture(item.icon)
    update_picture_taken(line.icon, item.taken)
    library.update_unusable(line.unusable, item.id)
    local holder = line.cell or line.icon
    holder:SetSize(size, size)
    holder:ClearAllPoints()
    holder:SetPoint("LEFT", line, "LEFT", left, 0)
    if line.cell then update_cell_look(line, item, size) end
    line.name:SetFontObject(library.read_font(item.sub and "bold" or "body"))
    if item.sub and not line.sub then line.sub = create_sub(line) end
    if line.sub then line.sub:SetFontObject(library.read_font("small")) end
    update_words(line, item, holder, gap, math.max(1, right - left - size - gap))
    update_tag(line, item, gap, math.max(1, right - left - size - gap))
    library.update_item_hover(line, holder, line.name, size)
    update_money_name(line, item, holder, gap)
end

function library.read_item_row_height(line, least)
    local said = math.ceil(library.read_string_height(line.name)) + 2 * library.read_draft_size(WRAP_ROOM)
    return math.max(least, said)
end

function library.update_item_row_chosen(line, chosen)
    if not line.fill then create_chosen_look(line) end
    library.update_surface(line.fill, 0, library.read_draft_size(RADIUS), colours.gold, colours.gold, chosen and CHOSEN_ALPHA or 0)
    library.update_ring(line.ring, 1, colours.gold, chosen and 1 or 0)
end
