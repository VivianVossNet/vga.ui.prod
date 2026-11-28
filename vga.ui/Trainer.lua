-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: vga.ui's trainer, as the accepted draft draws it (manual/view/vga-npc-windows.html, K0830, K0831): LibVGA's list dialog (library.create_list_dialog, K0871) headed with the trainer's name, each service's tooltip, as the game gives it, over its picture and name (K0911), the picture of a service to be learnt only later veiled red as everywhere (K0933), a profession's recipe - its level 0, its skill named by the game - with no second line and, while later, a red chip with the rank it needs, »ab 75«, which GetTrainerServiceSkillReq gives as its second answer (K0939), the player's own rank in the skill, »Kochkunst 12/75«, as a green badge at the foot's left, the chosen skill in the grey note after it (K0938), since Forever gives no rank a recipe needs (K0935, K0936, K0937), a choice of what is shown - Lernbar, Später, Gelernt, what can be learnt now by default -, every skill as LibVGA's item row with its picture, its rank beneath and its cost in our coins; a click chooses a skill; the foot carries »Alles lernen«, which learns every skill that can be learnt now and is paid for, as the adviser proposed and the owner took, and the gold »Lernen« for the chosen one, the chosen skill in the note; above the group the search and the choice, the heads Fähigkeit, Lernbar - »Zustand« until the owner found it unfitting (K0940) -, Kosten, each skill in its cell with rank and level beneath and its state as a chip, the player's gold in the status line (K0836). The game's trainer window is veiled, never hidden, so the visit stays open (K0835). The game's GetTrainerServiceInfo is read in either order - name, rank, kind as the old client answers, or name, kind, picture, level as the new -, its raw answer for the first skill kept once in LibVGASettings.measures.trainer_service_info; the search and the choice are the list dialog's tools, LibVGA's search bar (library.create_search_bar, K0873) fed here, side by side, the search taking the room the choice leaves (K0849). A skill the player cannot pay for yet shows its cost in red, its chip still »Lernbar«, and »Lernen« is off while it is chosen; »Alles lernen« learns what the gold pays for (K0994).

-- {K0994} {K0940} {K0939} {K0938} {K0937} {K0936} {K0933} {K0911} {K0909} {K0873} {K0860} {K0871} {K0849} {K0839} {K0838} {K0836} {K0835} {K0830} {K0831} {K0832}

local _, vga = ...
local library = LibVGA
local colours = library.colours
local WIDTH, HEIGHT = 480, 470
local STATES = { available = "green", unavailable = "grey", used = "gold" }
local KINDS = { "available", "unavailable", "used" }
local SERVICE_KINDS = { available = true, unavailable = true, used = true, header = true }
local window, tools

local function read_service(index)
    local name, second, third, fourth = GetTrainerServiceInfo(index)
    if SERVICE_KINDS[second] then return name, "", second, third, fourth end
    return name, second or "", third
end

local function write_service_measure()
    if not (GetNumTrainerServices and (GetNumTrainerServices() or 0) > 0) then return end
    local answers = { GetTrainerServiceInfo(1) }
    local kinds = {}
    for index = 1, 4 do kinds[index] = type(answers[index]) .. ":" .. tostring(answers[index]) end
    LibVGASettings.measures = LibVGASettings.measures or {}
    LibVGASettings.measures.trainer_service_info = table.concat(kinds, " | ")
end

local function read_skill_rank(name)
    local found = GetProfessions and { GetProfessions() } or {}
    for slot = 1, 6 do
        local rank_name, rank, most
        if found[slot] then rank_name, _, rank, most = GetProfessionInfo(found[slot]) end
        if rank_name == name then return rank, most end
    end
    for index = 1, (GetNumSkillLines and GetNumSkillLines() or 0) do
        local line_name, header, _, rank, _, _, most = GetSkillLineInfo(index)
        if line_name == name and not header then return rank, most end
    end
end

local function read_skill(index)
    if not GetTrainerServiceSkillReq then return nil end
    local name, needed = GetTrainerServiceSkillReq(index)
    if type(name) ~= "string" or name == "" then return nil end
    return name, needed
end

local function read_services()
    local services, wanted = {}, KINDS[tools.choice.chosen or 1]
    local search = (tools.input:GetText() or ""):lower()
    for index = 1, (GetNumTrainerServices and GetNumTrainerServices() or 0) do
        local name, rank, kind, picture, needed_level = read_service(index)
        if name and kind == wanted and (search == "" or name:lower():find(search, 1, true)) then
            local icon = picture or (GetTrainerServiceIcon and GetTrainerServiceIcon(index))
            local skill, needed
            local level = needed_level or (GetTrainerServiceLevelReq and GetTrainerServiceLevelReq(index)) or 0
            if level == 0 then skill, needed = read_skill(index) end
            services[#services + 1] = { index = index, name = name, rank = rank or "", level = level, kind = kind, icon = icon, cost = GetTrainerServiceCost and GetTrainerServiceCost(index) or 0, skill = skill, needed = needed }
        end
    end
    return services
end

local function render_chosen(row)
    window.chosen_index = row.item and row.item.index
    window.chosen_name = row.item and (row.item.rank ~= "" and row.item.name .. " · " .. row.item.rank or row.item.name)
    vga.update_trainer()
end

local function update_service_tip(row, tip)
    if not (row.item and tip.SetTrainerService) then return false end
    tip:SetTrainerService(row.item.index)
    return true
end

local function create_row(parent)
    local row = library.create_item_row(parent, { chosen = true, cell = true, on_click = render_chosen, tip = update_service_tip })
    row.state = library.create_chip(row)
    row.money = library.create_money(row, colours.ink)
    row.money.kind = "small"
    return row
end

local function read_sub(item, texts)
    if item.skill then return nil end
    if item.rank ~= "" then return string.format(texts.rank_level, item.rank, item.level) end
    return string.format(texts.from_level, item.level)
end

local function read_later_word(item, texts)
    if item.needed then return string.format(texts.trainer_needs, item.needed) end
    if item.skill then return texts.trainer_higher end
    return string.format(texts.from_level, item.level)
end

local function check_short(item)
    return item ~= nil and item.kind == "available" and item.cost > (GetMoney and GetMoney() or 0)
end

local function read_chosen_item()
    for _, item in ipairs(window.items or {}) do
        if item.index == window.chosen_index then return item end
    end
    return nil
end

local function update_row(row, item)
    local sheet = window.listing.table
    local columns = sheet.columns
    row.item = item
    local texts = library.texts
    local sub = read_sub(item, texts)
    library.update_item_row(row, { icon = item.icon, name = item.name, quality = 1, sub = sub, unusable = item.kind == "unavailable" }, sheet.pad, sheet.pad + columns.rights[1])
    library.update_item_row_chosen(row, window.chosen_index == item.index)
    local words = { available = texts.learnable, unavailable = read_later_word(item, texts), used = texts.learnt }
    local later_red = item.kind == "unavailable" and item.needed ~= nil
    library.update_chip(row.state, later_red and "red" or STATES[item.kind] or "grey", nil, words[item.kind] or "")
    library.update_money(row.money, item.cost)
    library.update_money_tinted(row.money, check_short(item) and library.read_chip_colour("red") or nil)
    library.update_grid_columns(row, columns, sheet.pad, { { row.state, 2, "right" }, { row.money, 3, "right" } })
end

local function render_learnt()
    if window.chosen_index and BuyTrainerService then BuyTrainerService(window.chosen_index) end
end

local function render_all_learnt()
    local purse = GetMoney and GetMoney() or 0
    for _, item in ipairs(window.items or {}) do
        if item.cost <= purse and BuyTrainerService then
            BuyTrainerService(item.index)
            purse = purse - item.cost
        end
    end
end

local function read_own_skill()
    for index = 1, (GetNumTrainerServices and GetNumTrainerServices() or 0) do
        local skill = read_skill(index)
        if skill then
            local rank, most = read_skill_rank(skill)
            return rank and string.format(library.texts.trainer_skill, skill, rank, most or rank) or skill
        end
    end
end

function vga.update_trainer()
    if not (window and window:IsShown()) then return end
    window.items = read_services()
    local skill = read_own_skill()
    library.update_list_dialog(window, window.items, window.chosen_name, skill and { kind = "green", word = skill } or nil)
    local chosen = read_chosen_item()
    library.update_button_enabled(window.foot.buttons[2], chosen ~= nil and not check_short(chosen))
end

local function render_kind(index)
    tools.choice.chosen = index
    window.chosen_index = nil
    vga.update_trainer()
end

local function render_closed()
    library.render_game_ended(ClassTrainerFrame, CloseTrainer)
end

local STATE_ORDER = { available = 1, unavailable = 2, used = 3 }

local function read_name_sort(item)
    return (item.name or ""):lower()
end

local function read_state_sort(item)
    return (STATE_ORDER[item.kind] or 4) * 1000 + (item.level or 0)
end

local function read_cost_sort(item)
    return item.cost or 0
end

local function create_tools(parent, listing)
    local texts = library.texts
    tools = library.create_search_bar(parent, { hint = texts.skills_search, labels = { texts.learnable, texts.later, texts.learnt }, on_search = vga.update_trainer, on_choose = render_kind, gap = listing.tools_grid.plan.gap })
    return tools
end

local function update_tools(_, width)
    return { library.update_search_bar(tools, width) }
end

local function create_window()
    local texts = library.texts
    local columns = { { key = "head_skill", word = texts.head_skill, sort = read_name_sort }, { key = "head_state", word = texts.head_state, least = 90, x = "right", sort = read_state_sort }, { key = "head_cost", word = texts.head_cost, least = "money", x = "right", sort = read_cost_sort } }
    local buttons = { { texts.learn_all, "plain", render_all_learnt }, { texts.learn, "gold", render_learnt } }
    window = library.create_list_dialog("VGATrainerWindow", { title = texts.trainer, buttons = buttons, width = WIDTH, height = HEIGHT, table = { columns = columns, create_row = create_row, update_row = update_row }, tools = { create = create_tools, update = update_tools } })
    library.update_dialog_closing(window, function() library.update_safely("trainer closed", render_closed) end)
end

local function update_opened()
    if not window then create_window() end
    library.update_game_veiled(ClassTrainerFrame, true)
    window.title:SetText(library.read_figure_title(library.texts.trainer))
    tools.choice.chosen, window.chosen_index = 1, nil
    library.update_dialog_placed(window)
    window:Show()
    library.update_safely("trainer measure", write_service_measure)
    vga.update_trainer()
end

local function update_closed()
    if window and window:IsShown() then window:Hide() end
end

local HEARD = { TRAINER_SHOW = update_opened, TRAINER_CLOSED = update_closed, TRAINER_UPDATE = vga.update_trainer, PLAYER_MONEY = vga.update_trainer }

local events = CreateFrame("Frame")
library.update_events(events, { "TRAINER_SHOW", "TRAINER_CLOSED", "TRAINER_UPDATE", "PLAYER_MONEY" })
events:SetScript("OnEvent", function(_, event) library.update_safely("trainer " .. event, HEARD[event]) end)
