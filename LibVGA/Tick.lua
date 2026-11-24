-- Copyright 2026 Vivian Voss. Code by Vivian Voss. Licensed under the BSD-3-Clause.
-- SPDX-License-Identifier: BSD-3-Clause
-- Scope: LibVGA's applied tick, as the accepted catalogue draws it (manual/view/vga-catalogue.html »Übernommen«, K0772, K0775): a small green check, a picture never a glyph (K0763), in a room of fourteen draft pixels at the right of a row's control, shown at once when a change made in that control was applied, kept a second and a half, then fading; at rest its room stays, transparent, so nothing in the row moves (rule 29). Every row of LibVGA's dialogs keeps one; a control in such a row reports its change by library.render_control_changed, so every setting shows it without its user doing anything (K0794). A tick may also be kept shown, never fading, where it marks a done thing in a line of its own - the conversation's »Quest angenommen« (library.update_tick_kept, K0840), there in the dark green its green bubble asks for (K0859).

-- {K0859} {K0840} {K0794} {K0772} {K0775}

local library = LibVGA
local GREEN = library.colours.green
local ROOM = 14
local PICTURE = 12
local STAY = 1.5
local FADE = 0.5

local function update_faded(tick, elapsed)
    tick.time = tick.time + elapsed
    local left = STAY + FADE - tick.time
    tick.picture:SetAlpha(math.max(0, math.min(1, left / FADE)))
    if left <= 0 then tick:SetScript("OnUpdate", nil) end
end

function library.create_tick(row)
    local tick = CreateFrame("Frame", nil, row)
    tick.picture = tick:CreateTexture(nil, "OVERLAY")
    tick.picture:SetTexture(library.media .. "Tick")
    tick.picture:SetVertexColor(GREEN[1], GREEN[2], GREEN[3], 1)
    tick.picture:SetPoint("CENTER")
    tick.picture:SetAlpha(0)
    return tick
end

function library.read_tick_room()
    return library.read_draft_size(ROOM)
end

function library.update_tick(tick)
    local room, picture = library.read_tick_room(), library.read_draft_size(PICTURE)
    tick:SetSize(room, room)
    tick.picture:SetSize(picture, picture)
end

function library.update_tick_kept(tick, colour)
    local tint = colour or GREEN
    tick.picture:SetVertexColor(tint[1], tint[2], tint[3], 1)
    tick:SetScript("OnUpdate", nil)
    tick.picture:SetAlpha(1)
end

function library.render_tick(tick)
    tick.time = 0
    tick.picture:SetAlpha(1)
    tick:SetScript("OnUpdate", update_faded)
end

function library.render_control_changed(control)
    local row = control and control:GetParent()
    if row and row.tick then library.render_tick(row.tick) end
end
