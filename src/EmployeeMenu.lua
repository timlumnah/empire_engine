--[[
    Empire Engine
    EmployeeMenu.lua

    Sub-screen for managing a single business's workforce.
    Opened from BusinessMenu (Enter on selected business).
    Shows employee list, total payroll, hire/fire options.
]]

-- ================== claude_changes_2026-05-25-1228 ==================
EmployeeMenu = Class{}

-- panel layout
local BOX_X = 8
local BOX_Y = 5
local BOX_W = 368
local BOX_H = 210
local PAD   = 12
local ENTRY_H = 26     -- pixels per employee row
local MAX_VIS = 5      -- max visible employees at once
local LIST_Y  = BOX_Y + 60

-- confirm popup
local CONF_W = 170
local CONF_H = 66
local CONF_X = math.floor((384 - CONF_W) / 2)
local CONF_Y = math.floor((216 - CONF_H) / 2)
local YES_BTN = { x = CONF_X + 12,  y = CONF_Y + 44, w = 56, h = 14 }
local NO_BTN  = { x = CONF_X + 100, y = CONF_Y + 44, w = 56, h = 14 }

local function set(r, g, b, a) love.graphics.setColor(r, g, b, a or 1) end

local function fmt_cash(n)
    if n < 0 then return string.format('-$%.0f', math.abs(n)) end
    return string.format('$%.0f', n)
end

local function hit(rect, x, y)
    return x >= rect.x and x <= rect.x + rect.w
       and y >= rect.y and y <= rect.y + rect.h
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

function EmployeeMenu:init()
    self.active    = false
    self.business  = nil
    self.player    = nil
    self.selected  = 1      -- 1..#employees+2 (last two rows = Hire Worker, Hire Manager)
    self.scroll    = 0
    self.confirming = false
    self.confirmMsg = ''
    self.confirmAction = nil
end

function EmployeeMenu:open(business, player)
    self.active    = true
    self.business  = business
    self.player    = player
    self.selected  = 1
    self.scroll    = 0
    self.confirming = false
end

function EmployeeMenu:close()
    self.active   = false
    self.business = nil
end

function EmployeeMenu:showConfirm(msg, action)
    self.confirming    = true
    self.confirmMsg    = msg
    self.confirmAction = action
end

function EmployeeMenu:resolveConfirm(yes)
    if yes and self.confirmAction then self.confirmAction() end
    self.confirming    = false
    self.confirmMsg    = ''
    self.confirmAction = nil
end

-- builds the combined list: current employees + hire options filtered by bus.type
-- ================== claude_changes_2026-05-25-1330 ==================
function EmployeeMenu:buildRows()
    local bus    = self.business
    local rows   = {}
    for i, e in ipairs(bus.employees) do
        rows[#rows+1] = { kind = 'employee', index = i, emp = e }
    end
    local atMax   = #bus.employees >= (bus.maxEmployees or 5)
    local busType = bus.type
    if EMPLOYEE_ROLES then
        -- collect roles allowed for this business type, stable-sort by salary range low end
        local hireable = {}
        for role, def in pairs(EMPLOYEE_ROLES) do
            local allowed = false
            if def.allowedTypes then
                for _, t in ipairs(def.allowedTypes) do
                    if t == busType then allowed = true; break end
                end
            else
                allowed = true
            end
            if allowed then
                hireable[#hireable+1] = { role = role, def = def }
            end
        end
        table.sort(hireable, function(a, b)
            return (a.def.salaryRange and a.def.salaryRange[1] or 0)
                 < (b.def.salaryRange and b.def.salaryRange[1] or 0)
        end)
        for _, h in ipairs(hireable) do
            rows[#rows+1] = { kind = 'hire', role = h.role, disabled = atMax }
        end
    end
    return rows
end
-- ====================================================================

function EmployeeMenu:update(dt)
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

    -- keep selected in view
    if self.selected > self.scroll + MAX_VIS then
        self.scroll = self.selected - MAX_VIS
    elseif self.selected <= self.scroll then
        self.scroll = self.selected - 1
    end
end

function EmployeeMenu:selectRow(rows)
    local row = rows[self.selected]
    if not row then return end

    if row.kind == 'employee' then
        -- fire confirmation
        local emp = row.emp
        self:showConfirm(
            string.format('Fire %s?\n(%s, %s/mo)',
                emp.name,
                (EMPLOYEE_ROLES and EMPLOYEE_ROLES[emp.role] and EMPLOYEE_ROLES[emp.role].label) or emp.role,
                fmt_cash(emp.salary)),
            function()
                self.business:fireEmployee(row.index)
                self.selected = math.max(1, self.selected - 1)
            end
        )

    elseif row.kind == 'hire' then
        if row.disabled then return end
        local roleDef = EMPLOYEE_ROLES and EMPLOYEE_ROLES[row.role]
        if not roleDef then return end
        local lo, hi = roleDef.salaryRange[1], roleDef.salaryRange[2]
        local avgSalary = math.floor((lo + hi) / 2)
        self:showConfirm(
            string.format('Hire %s?\n~%s/mo salary',
                roleDef.label, fmt_cash(avgSalary)),
            function()
                self.business:hireEmployee(row.role)
            end
        )
    end
end

function EmployeeMenu:render()
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
        string.upper(bus.displayName or bus.type) .. ' - EMPLOYEES',
        ix, BOX_Y + 6
    )

    -- employee count and payroll
    love.graphics.setFont(gFonts['small'])
    set(0.65, 0.65, 0.65, 1)
    love.graphics.print(
        string.format('%d / %d staff   Payroll: %s/mo',
            #bus.employees,
            bus.maxEmployees or 5,
            fmt_cash(bus:getMonthlyPayroll())),
        ix, BOX_Y + 26
    )

    -- divider
    set(1, 1, 1, 0.2)
    love.graphics.line(ix, BOX_Y + 38, BOX_X + BOX_W - PAD, BOX_Y + 38)

    -- column headers
    love.graphics.setFont(gFonts['small'])
    set(0.45, 0.45, 0.55, 1)
    love.graphics.print('NAME', ix + 9, BOX_Y + 42)
    love.graphics.print('ROLE', ix + 100, BOX_Y + 42)
    love.graphics.print('SALARY/MO', ix + 200, BOX_Y + 42)
    love.graphics.print('CAPACITY+', ix + 290, BOX_Y + 42)

    -- employee and hire rows
    local rows = self:buildRows()
    local drawN = math.min(MAX_VIS, #rows - self.scroll)

    for i = 1, drawN do
        local idx = i + self.scroll
        local row = rows[idx]
        local ey  = LIST_Y + (i - 1) * ENTRY_H
        local sel = (idx == self.selected)

        if sel then
            set(1, 1, 1, 0.06)
            love.graphics.rectangle('fill', BOX_X + 3, ey, BOX_W - 6, ENTRY_H - 1)
        end

        set(1, 0.84, 0, 1)
        love.graphics.print(sel and '>' or ' ', ix, ey + 4)

        if row.kind == 'employee' then
            local e       = row.emp
            local roleLbl = (EMPLOYEE_ROLES and EMPLOYEE_ROLES[e.role] and EMPLOYEE_ROLES[e.role].label) or e.role
            if sel then set(1, 0.95, 0.55, 1) else set(0.9, 0.9, 0.9, 1) end
            love.graphics.print(e.name,            ix + 9,  ey + 4)
            love.graphics.print(roleLbl,           ix + 100, ey + 4)
            love.graphics.print(fmt_cash(e.salary), ix + 200, ey + 4)
            set(0.5, 0.9, 0.5, 1)
            love.graphics.print(tostring(e.capacityBonus or 0), ix + 302, ey + 4)
            -- fire hint on selected row
            if sel then
                set(0.55, 0.35, 0.35, 1)
                love.graphics.print('[ENTER] fire', ix + BOX_W - 80, ey + 4)
            end

        elseif row.kind == 'hire' then
            local roleDef = EMPLOYEE_ROLES and EMPLOYEE_ROLES[row.role]
            local lbl     = roleDef and roleDef.label or row.role
            local lo, hi  = (roleDef and roleDef.salaryRange[1] or 0), (roleDef and roleDef.salaryRange[2] or 0)
            if row.disabled then
                set(0.38, 0.38, 0.38, 1)
                love.graphics.print('+ Hire ' .. lbl .. ' (MAX STAFF)', ix + 9, ey + 4)
            else
                if sel then set(0.45, 1, 0.55, 1) else set(0.35, 0.75, 0.4, 1) end
                love.graphics.print(
                    string.format('+ Hire %s  (%s - %s/mo)',
                        lbl, fmt_cash(lo), fmt_cash(hi)),
                    ix + 9, ey + 4
                )
            end
        end

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
    love.graphics.printf('[ESC] back   [UP/DN] select   [ENTER] hire/fire',
        ix, BOX_Y + BOX_H - 11, iw, 'center')

    if self.confirming then render_confirm(self.confirmMsg) end
    set(1, 1, 1, 1)
end
-- ====================================================================

return EmployeeMenu
