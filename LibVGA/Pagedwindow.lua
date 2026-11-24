-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's window with pages, as the accepted catalogue draws it (manual/view/vga-catalogue.html »Fenster mit Seiten«, K0775) after the settings (manual/view/vga-settings-apple.html, K0565): LibVGA's dialog with its head, pin, close and, where named, its foot (K0783); at its left the menu bar, LibVGA's sidebar of groups and entries (K0565); at its right the chosen page under its title; one page shown at a time. Its user names the title, the groups, the pages - each a key, a title and the maker that fills it - and, where it must, what follows a choice, where its pages begin and how far they keep from the edges; it lays the window by library.update_paged_window with its width and, where not the tallest page's, its height; the settings and the auction window are made so (K0790). The page keeps the gap on its right as on its left, so a list's group and the controls above it end short of the window's edge (K0839).

-- {K0839} {K0790} {K0565} {K0783} {K0775}

local library = LibVGA

local function create_pages(window, pages)
    window.pages, window.order, window.titles = {}, {}, {}
    for index, entry in ipairs(pages) do
        local page = CreateFrame("Frame", nil, window.body)
        entry.build(page)
        window.pages[entry.key] = page
        window.order[index] = entry.key
        window.titles[entry.key] = entry.title
    end
end

function library.update_paged_window_page(window, key)
    local plan = window.plan
    if plan.on_redirect and plan.on_redirect(window, key) then return end
    window.chosen = key
    window.heading:SetText(window.titles[key] or "")
    for name, page in pairs(window.pages) do page:SetShown(name == key) end
    library.update_sidebar(window.sidebar, key)
    if plan.on_page then plan.on_page(window, key) end
    if window.tallest then window:SetHeight(window.tallest) end
end

function library.create_paged_window(name, plan)
    local window = library.create_dialog(name, plan.title, plan.foot)
    window.vga_paged, window.plan = true, plan
    create_pages(window, plan.pages)
    window.heading = library.create_text(window.body, "title", library.colours.ink)
    window.sidebar = library.create_sidebar(window.body, plan.groups, function(key) library.update_paged_window_page(window, key) end)
    return window
end

local function read_band(window)
    if window.plan.page_top then return window.plan.page_top() end
    return math.ceil(window.heading:GetStringHeight()) + 2 * library.read_size(-2)
end

local function update_pages_placed(window, side, gap)
    local band, inset = read_band(window), window.plan.page_inset and window.plan.page_inset() or 0
    for _, page in pairs(window.pages) do
        page:ClearAllPoints()
        page:SetPoint("TOPLEFT", window.body, "TOPLEFT", side + gap, -band)
        page:SetPoint("BOTTOMRIGHT", window.body, "BOTTOMRIGHT", -inset, inset)
    end
    return band
end

local function read_tallest(window, band, side_height)
    local tallest = 0
    for _, page in pairs(window.pages) do tallest = math.max(tallest, page.wanted and math.max(page.wanted + band, side_height) or 0) end
    return tallest > 0 and library.read_dialog_frame_height(window) + tallest or nil
end

function library.update_paged_window(window, width, height)
    library.update_dialog(window)
    local side, gap = library.read_sidebar_width(window.sidebar), library.read_size(0)
    local side_height = library.update_sidebar(window.sidebar, window.chosen)
    window.sidebar:ClearAllPoints()
    window.sidebar:SetPoint("TOPLEFT", window.body, "TOPLEFT")
    window.sidebar:SetPoint("BOTTOMLEFT", window.body, "BOTTOMLEFT")
    window.sidebar:SetWidth(side)
    window.heading:SetFontObject(library.read_font("title"))
    window.heading:ClearAllPoints()
    window.heading:SetPoint("TOPLEFT", window.body, "TOPLEFT", side + gap, -library.read_size(-2))
    local band = update_pages_placed(window, side, gap)
    window.tallest = height or read_tallest(window, band, side_height)
    window:SetWidth(width)
    if window.tallest then window:SetHeight(window.tallest) end
    window.page_width = width - side - 2 * gap - 2 * library.read_size(-4)
    return side, gap, band
end
