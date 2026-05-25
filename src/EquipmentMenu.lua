--[[
    Empire Engine
    EquipmentMenu.lua

    Sub-screen for purchasing equipment for a single business.
    Opened from BusinessMenu (E on selected business).
    Lists EQUIPMENT_DEFS items filtered by bus.type; one-time
    purchases tracked in bus.equipment = { key = count }.
]]

-- ================== claude_changes_2026-05-25-1330 ==================
EquipmentMenu = Class{}

local BOX_X   = 8
local BOX_Y   = 5
local BOX_W   = 368
local BOX_H   = 210
local PAD     = 12
local ENTRY_H = 26
local MAX_VIS = 5
local LIST_Y  = BOX_Y + 60

local CONF_W = 180
local CONF_H = 66
local CONF_X = math.floor((384 - CONF_W) / 2)
local CONF_Y = math.floor((216 - CONF_H) / 2)
local YES_BTN = { x = CONF_X + 12,  y = CONF_Y + 44, w = 56, h = 14 }
local NO_BTN  = { x = CONF_X + 110, y = CONF_Y + 44, w = 56, h = 14 }

local function set(r, g, b, a) love.graphics.setColor(r, g, b, a or 1) end

local function fmt_cash(n)
    if n >= 1000000 then return string.format('$%.1fM', n / 1000000) end
    if n >= 1000    then return string.format('$%.0fK', n / 1000)    end
    return string.format('$%.0f', n)
end

local function render_confirm(msg)
    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle('fill', 0, 0, 384, 216)
    love.graphics.setColor(0.08, 0.08, 0.13, 0.97)
    love.graphics.rectangle('fill', CONF_X, CONF_Y, CONF_W, CONF_H, 4)
    love.graphics.setColor(0.45, 0.45, 0.6, 1)
    love.graphics.rectangle('line', CONF_X, CONF_Y, CONF_W, CONF_H, 4)
    love.graphics.setFont(gFonts['small'])
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(msg, CONF_X + 8, CONF_Y + 10, CONF_W - 16, 'center')
    love.graphics.setColor(0.15, 0.45, 0.15, 1)
    love.graphics.rectangle('fill', YES_BTN.x, YES_BTN.y, YES_BTN.w, YES_BTN.h, 3)
    love.graphics.setColor(0.4, 1, 0.4, 1)
    love.graphics.rectangle('line', YES_BTN.x, YES_BTN.y, YES_BTN.w, YES_BTN.h, 3)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('YES', YES_BTN.x, YES_BTN.y + 3, YES_BTN.w, 'center')
    love.graphics.setColor(0.45, 0.1, 0.1, 1)
    love.graphics.rectangle('fill', NO_BTN.x, NO_BTN.y, NO_BTN.w, NO_BTN.h, 3)
    love.graphics.setColor(1, 0.35, 0.35, 1)
    love.graphics.rectangle('line', NO_BTN.x, NO_BTN.y, NO_BTN.w, NO_BTN.h, 3)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('NO', NO_BTN.x, NO_BTN.y + 3, NO_BTN.w, 'center')
    love.graphics.setColor(1, 1, 1, 1)
end

function EquipmentMenu:init()
    self.active        = false
    self.business      = nil
    self.player        = nil
    self.selected      = 1
    self.scroll        = 0
    self.confirming    = false
    self.confirmMsg    = ''
    self.confirmAction = nil
end

function EquipmentMenu:open(business, player)
    self.active        = true
    self.business      = business
    self.player        = player
    self.selected      = 1
    self.scroll        = 0
    self.confirming    = false
end

function EquipmentMenu:close()
    self.active   = false
    self.business = nil
end

function EquipmentMenu:showConfirm(msg, action)
    self.confirming    = true
    self.confirmMsg    = msg
    self.confirmAction = action
end

function EquipmentMenu:resolveConfirm(yes)
    if yes and self.confirmAction then self.confirmAction() end
    self.confirming    = false
    self.confirmMsg    = ''
    self.confirmAction = nil
end

-- returns equipment rows for this business's type, sorted by price ascending
function EquipmentMenu:buildRows()
    if not EQUIPMENT_DEFS then return {} end
    local busType = self.business.type
    local rows = {}
    for key, def in pairs(EQUIPMENT_DEFS) do
        local allowed = false
        if def.allowedTypes then
            for _, t in ipairs(def.allowedTypes) do
                if t == busType then allowed = true; break end
            end
        end
        if allowed then
            rows[#rows+1] = { key = key, def = def }
        end
    end
    table.sort(rows, function(a, b) return a.def.price < b.def.price end)
    return rows
end

function EquipmentMenu:update(dt)
    if not self.active then return end

    if self.confirming then
        if love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter')
           or love.keyboard.wasPressed('y') then
            self:resolveConfirm(true)
        elseif love.keyboard.wasPressed('escape') or love.keyboard.wasPressed('n') then
            self:resolveConfirm(false)
        end
        return
    end

    local rows = self:buildRows()
    local n    = #rows

    if love.keyboard.wasPressed('up') then
        self.selected = math.max(1, self.selected - 1)
    elseif love.keyboard.wasPressed('down') then
        self.selected = math.min(n, self.selected + 1)
    elseif love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter') then
        self:selectRow(rows)
    elseif love.keyboard.wasPressed('escape') then
        self:close()
    end

    if self.selected > self.scroll + MAX_VIS then
        self.scroll = self.selected - MAX_VIS
    elseif self.selected <= self.scroll then
        self.scroll = self.selected - 1
    end
end

function EquipmentMenu:selectRow(rows)
    local row = rows[self.selected]
    if not row then return end
    local def  = row.def
    local key  = row.key
    local bus  = self.business
    local note = def.note and ('\n' .. def.note) or ''
    self:showConfirm(
        string.format('Buy %s?\n%s%s', def.displayName, fmt_cash(def.price), note),
        function()
            if self.player.cash < def.price then return end
            self.player.cash        = self.player.cash - def.price
            self.player.displayCash = self.player.cash
            bus.equipment[key]      = (bus.equipment[key] or 0) + 1
        end
    )
end

function EquipmentMenu:render()
    if not self.active then return end

    local bus = self.business
    local ix  = BOX_X + PAD
    local iw  = BOX_W - PAD * 2

    -- panel
    set(0.75, 0.75, 0.75, 0.85)
    love.graphics.rectangle('fill', BOX_X, BOX_Y, BOX_W, BOX_H, 3)
    set(0.04, 0.04, 0.06, 0.92)
    love.graphics.rectangle('fill', BOX_X + 2, BOX_Y + 2, BOX_W - 4, BOX_H - 4, 3)

    -- title
    love.graphics.setFont(gFonts['gothic-medium'])
    set(1, 0.84, 0, 1)
    love.graphics.print(
        string.upper(bus.displayName or bus.type) .. ' - EQUIPMENT',
        ix, BOX_Y + 6
    )

    -- balance
    love.graphics.setFont(gFonts['small'])
    local canAfford = self.player.cash >= 0
    if canAfford then set(0.55, 0.9, 0.55, 1) else set(1, 0.45, 0.45, 1) end
    love.graphics.print(
        string.format('Balance: %s', fmt_cash(self.player.cash)),
        ix, BOX_Y + 26
    )

    -- divider
    set(1, 1, 1, 0.2)
    love.graphics.line(ix, BOX_Y + 38, BOX_X + BOX_W - PAD, BOX_Y + 38)

    -- column headers
    love.graphics.setFont(gFonts['small'])
    set(0.45, 0.45, 0.55, 1)
    love.graphics.print('ITEM',     ix + 9,   BOX_Y + 42)
    love.graphics.print('PRICE',    ix + 190, BOX_Y + 42)
    love.graphics.print('OWNED',    ix + 270, BOX_Y + 42)

    local rows  = self:buildRows()
    local drawN = math.min(MAX_VIS, #rows - self.scroll)

    for i = 1, drawN do
        local idx   = i + self.scroll
        local row   = rows[idx]
        local def   = row.def
        local ey    = LIST_Y + (i - 1) * ENTRY_H
        local sel   = (idx == self.selected)
        local owned = (bus.equipment and bus.equipment[row.key]) or 0
        local afford = self.player.cash >= def.price

        if sel then
            set(1, 1, 1, 0.06)
            love.graphics.rectangle('fill', BOX_X + 3, ey, BOX_W - 6, ENTRY_H - 1)
        end

        set(1, 0.84, 0, 1)
        love.graphics.print(sel and '>' or ' ', ix, ey + 4)

        -- item name (dim if can't afford)
        if sel then
            if afford then set(1, 0.95, 0.55, 1) else set(0.75, 0.55, 0.55, 1) end
        else
            if afford then set(0.9, 0.9, 0.9, 1) else set(0.5, 0.5, 0.5, 1) end
        end
        love.graphics.print(def.displayName, ix + 9, ey + 4)

        -- price (red if can't afford)
        if afford then set(0.7, 0.95, 0.7, 1) else set(0.85, 0.4, 0.4, 1) end
        love.graphics.print(fmt_cash(def.price), ix + 190, ey + 4)

        -- owned count
        if owned > 0 then set(0.5, 0.85, 1, 1) else set(0.4, 0.4, 0.45, 1) end
        love.graphics.print(tostring(owned), ix + 280, ey + 4)

        -- row divider
        set(1, 1, 1, 0.08)
        love.graphics.line(ix, ey + ENTRY_H - 1, BOX_X + BOX_W - PAD, ey + ENTRY_H - 1)
    end

    -- scroll indicator
    if #rows > MAX_VIS then
        set(0.4, 0.4, 0.4, 1)
        love.graphics.setFont(gFonts['small'])
        love.graphics.printf(
            string.format('%d / %d', self.selected, #rows),
            ix, LIST_Y + MAX_VIS * ENTRY_H + 2, iw, 'center'
        )
    end

    -- hint bar
    set(0.35, 0.35, 0.35, 1)
    love.graphics.printf('[ESC] back   [UP/DN] select   [ENTER] buy',
        ix, BOX_Y + BOX_H - 11, iw, 'center')

    if self.confirming then render_confirm(self.confirmMsg) end
    set(1, 1, 1, 1)
end
-- ====================================================================

return EquipmentMenu
