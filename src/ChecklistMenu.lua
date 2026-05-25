--[[
    Empire Engine
    ChecklistMenu.lua

    Read-only requirements checklist overlay. Opened with C from BusinessMenu.
    Shows all requirements for the selected business grouped by tier with
    met/unmet status and the current ops multiplier.
]]

-- ================== claude_changes_2026-05-25-1330 ==================
ChecklistMenu = Class{}

local BOX_X  = 8
local BOX_Y  = 5
local BOX_W  = 368
local BOX_H  = 210
local PAD    = 12
local ROW_H  = 13     -- compact row height so 15-item lists fit with scrolling

local function set(r, g, b, a) love.graphics.setColor(r, g, b, a or 1) end

-- builds a flat draw list mixing section headers and requirement rows
-- sections appear in tier order: required → recommended → bonus
local TIER_ORDER = { 'required', 'recommended', 'bonus' }
local TIER_LABELS = { required = 'REQUIRED', recommended = 'RECOMMENDED', bonus = 'BONUS' }

local function build_draw_list(status)
    local by_tier = { required = {}, recommended = {}, bonus = {} }
    for _, item in ipairs(status) do
        local t = by_tier[item.tier]
        if t then t[#t+1] = item end
    end

    local list = {}
    for _, tier in ipairs(TIER_ORDER) do
        local items = by_tier[tier]
        if items and #items > 0 then
            -- section header row
            local met = 0
            for _, it in ipairs(items) do if it.met then met = met + 1 end end
            list[#list+1] = {
                kind  = 'header',
                tier  = tier,
                label = TIER_LABELS[tier],
                met   = met,
                total = #items,
            }
            for _, it in ipairs(items) do
                list[#list+1] = { kind = 'req', item = it }
            end
        end
    end
    return list
end

function ChecklistMenu:init()
    self.active   = false
    self.business = nil
    self.scroll   = 0
end

function ChecklistMenu:open(business)
    self.active   = true
    self.business = business
    self.scroll   = 0
end

function ChecklistMenu:close()
    self.active   = false
    self.business = nil
end

function ChecklistMenu:update(dt)
    if not self.active then return end

    local status = self.business.getChecklistStatus and self.business:getChecklistStatus() or {}
    local list   = build_draw_list(status)
    local maxScroll = math.max(0, #list - self:maxVisible())

    if love.keyboard.wasPressed('up') then
        self.scroll = math.max(0, self.scroll - 1)
    elseif love.keyboard.wasPressed('down') then
        self.scroll = math.min(maxScroll, self.scroll + 1)
    elseif love.keyboard.wasPressed('escape') or love.keyboard.wasPressed('c') then
        self:close()
    end
end

function ChecklistMenu:maxVisible()
    -- header=30 divider=4 ops footer=24 hint=11 padding=6 → usable ≈ 135px / ROW_H
    return math.floor(135 / ROW_H)
end

function ChecklistMenu:render()
    if not self.active then return end

    local bus  = self.business
    local ix   = BOX_X + PAD
    local iw   = BOX_W - PAD * 2
    local status = bus.getChecklistStatus and bus:getChecklistStatus() or {}
    local list   = build_draw_list(status)
    local maxVis = self:maxVisible()

    -- panel
    set(0.75, 0.75, 0.75, 0.92)
    love.graphics.rectangle('fill', BOX_X, BOX_Y, BOX_W, BOX_H, 3)
    set(0.05, 0.05, 0.08, 0.96)
    love.graphics.rectangle('fill', BOX_X + 2, BOX_Y + 2, BOX_W - 4, BOX_H - 4, 3)

    -- title
    love.graphics.setFont(gFonts['gothic-medium'])
    set(1, 0.84, 0, 1)
    love.graphics.print(
        string.upper(bus.displayName or bus.type) .. ' - REQUIREMENTS',
        ix, BOX_Y + 6
    )

    -- ops multiplier summary line
    local opMult = bus.getOpMult and bus:getOpMult() or 1.0
    local opPct  = math.floor(opMult * 100)
    love.graphics.setFont(gFonts['small'])
    local oc = opPct >= 100 and {0.4, 1.0, 0.4} or
               opPct >= 60  and {1.0, 0.85, 0.3} or {1.0, 0.4, 0.4}
    set(oc[1], oc[2], oc[3], 1)
    love.graphics.print(
        string.format('Ops Multiplier: %d%%  (%.2fx)', opPct, opMult),
        ix, BOX_Y + 24
    )

    -- divider
    set(1, 1, 1, 0.2)
    love.graphics.line(ix, BOX_Y + 38, BOX_X + BOX_W - PAD, BOX_Y + 38)

    -- scrollable list
    local listY  = BOX_Y + 43
    local drawN  = math.min(maxVis, #list - self.scroll)

    for i = 1, drawN do
        local idx  = i + self.scroll
        local row  = list[idx]
        local ry   = listY + (i - 1) * ROW_H

        if row.kind == 'header' then
            -- section label: REQUIRED (3/4) in appropriate color
            local allMet = row.met == row.total
            local hc = row.tier == 'required' and (allMet and {0.55, 0.9, 0.55} or {1, 0.45, 0.45}) or
                       row.tier == 'recommended' and {0.85, 0.75, 0.35} or
                       {0.55, 0.75, 1}
            set(hc[1], hc[2], hc[3], 1)
            love.graphics.print(
                string.format('%s  (%d/%d)', row.label, row.met, row.total),
                ix, ry
            )
        else
            local item = row.item
            -- checkbox
            if item.met then
                set(0.3, 0.9, 0.3, 1)
                love.graphics.print('[x]', ix + 4, ry)
            else
                set(0.55, 0.2, 0.2, 1)
                love.graphics.print('[ ]', ix + 4, ry)
            end
            -- label + count if minCount > 1
            local lbl = item.label
            if item.minCount and item.minCount > 1 then
                lbl = lbl .. string.format('  (need %d)', item.minCount)
            end
            if item.met then set(0.85, 0.95, 0.85, 1) else set(0.75, 0.6, 0.6, 1) end
            love.graphics.print(lbl, ix + 24, ry)
        end
    end

    -- scroll indicator
    local maxScroll = math.max(0, #list - maxVis)
    if maxScroll > 0 then
        set(0.4, 0.4, 0.4, 1)
        love.graphics.printf(
            string.format('[UP/DN]  %d/%d', self.scroll + 1, maxScroll + 1),
            ix, listY + maxVis * ROW_H + 2, iw, 'center'
        )
    end

    -- hint bar
    set(0.35, 0.35, 0.35, 1)
    love.graphics.printf('[ESC / C] close', ix, BOX_Y + BOX_H - 11, iw, 'center')

    set(1, 1, 1, 1)
end
-- ====================================================================

return ChecklistMenu
