--[[
    Empire Engine
    Based on CS50 2D Coursework

    LoanMenu.lua

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    Banker NPC interaction overlay. Lets the player take out or repay
    loans; updates player cash and tracks the outstandign debt balance.
]]

-- banker NPC overlay, shown when player picks LOAN from the NpcMenu
-- offers four fixed loan tiers, each with a different interest rate
-- interest is deducted monthly by PlayState reading player.loans
LoanMenu = Class{}

-- four loan tiers from cheapest to most expensive
-- annualRate is the yearly interest rate as a decimal
local LOAN_OPTIONS = {
    { label = 'Small Loan', amount = 5000, annualRate = 0.08 }, -- 8 percent annual
    { label = 'Standard Loan', amount = 10000, annualRate = 0.10 },
    { label = 'Business Loan', amount = 25000, annualRate = 0.12 },
    { label = 'Large Loan', amount = 50000, annualRate = 0.15 }, -- 15 percent annual, expensive
}

-- precompute monthly interest payment for each tier at startup
-- monthlyPayment = amount * annualRate / 12, rounded to nearest dollar
for _, opt in ipairs(LOAN_OPTIONS) do
    opt.monthlyPayment = math.floor(opt.amount * opt.annualRate / 12 + 0.5)
end

-- layout
local BOX_W = 260
local BOX_H = 162
local BOX_X = math.floor((384 - BOX_W) / 2)
local BOX_Y = math.floor((216 - BOX_H) / 2)
local PAD = 10
local ENTRY_H = 26
local LIST_Y = BOX_Y + 46

-- confirm popup (reuse same dims as PauseMenu)
local CONF_W = 168
local CONF_H = 66
local CONF_X = math.floor((384 - CONF_W) / 2)
local CONF_Y = math.floor((216 - CONF_H) / 2)
local YES_BTN = { x = CONF_X + 12,  y = CONF_Y + 44, w = 56, h = 14 }
local NO_BTN = { x = CONF_X + 100, y = CONF_Y + 44, w = 56, h = 14 }

local function set(r, g, b, a) love.graphics.setColor(r, g, b, a or 1) end

local function hit(rect, x, y)
    return x >= rect.x and x <= rect.x + rect.w
       and y >= rect.y and y <= rect.y + rect.h
end

local function fmt_money(n)
    if n >= 1000000 then return string.format('$%.1fm', n / 1000000)
    elseif n >= 1000 then return string.format('$%.0fk', n / 1000)
    else return string.format('$%d', n) end
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


-- sets all state fields to defualt values on startup
function LoanMenu:init()
    self.active = false
    self.player = nil
    self.selected = 1
    self.confirming = false
    self.confirmMsg = ''
    self.confirmAction = nil
    self.errTimer = 0   -- how long to show the error message in seconds
    self.errMsg = ''
end

-- activates the menu for a player, resets all state fresh each open
function LoanMenu:open(player)
    self.active = true
    self.player = player
    self.selected = 1
    self.confirming = false
    self.confirmMsg = ''
    self.confirmAction = nil
    self.errTimer = 0
    self.errMsg = ''
end

-- deactivates the menu and clears the player reference
function LoanMenu:close()
    self.active = false
    self.player = nil
end

-- shows the confirm popup with a message and stores the action to run on yes
function LoanMenu:showConfirm(msg, action)
    self.confirming = true
    self.confirmMsg = msg
    self.confirmAction = action
    self.errTimer = 0   -- clear any error message when confirm opens
end

-- runs the stored action if yes was pressed, then clears confirm state
function LoanMenu:resolveConfirm(yes)
    if yes and self.confirmAction then self.confirmAction() end
    self.confirming = false
    self.confirmMsg = ''
    self.confirmAction = nil
end

function LoanMenu:update(dt)
    if not self.active then return end
    if self.errTimer > 0 then self.errTimer = self.errTimer - dt end

    if self.confirming then
        if love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter')
           or love.keyboard.wasPressed('y') then
            self:resolveConfirm(true)
        elseif love.keyboard.wasPressed('escape') or love.keyboard.wasPressed('n') then
            self:resolveConfirm(false)
        end
        return
    end

    local n = #LOAN_OPTIONS
    if love.keyboard.wasPressed('up') then
        self.selected = self.selected > 1 and self.selected - 1 or n
        self.errTimer = 0
    elseif love.keyboard.wasPressed('down') then
        self.selected = self.selected < n and self.selected + 1 or 1
        self.errTimer = 0
    elseif love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter') then
        self:promptLoan(self.selected)
    elseif love.keyboard.wasPressed('escape') then
        self:close()
    end
end

-- builds and shows the confirm dialog for a selected loan option
-- shows the amount and monthly interest cost so player knows what theyre commiting to
function LoanMenu:promptLoan(idx)
    local opt = LOAN_OPTIONS[idx]
    local msg = string.format(
        'Take out %s?\n%s/mo interest',
        fmt_money(opt.amount),
        fmt_money(opt.monthlyPayment)
    )
    self:showConfirm(msg, function() self:takeLoan(idx) end)
end

-- adds the loan amount to player cash and appends the loan record to player.loans
-- PlayState reads player.loans each game month and deducts the monthly payment
function LoanMenu:takeLoan(idx)
    local opt = LOAN_OPTIONS[idx]
    self.player.cash = self.player.cash + opt.amount     -- immediate cash injection
    self.player.displayCash = self.player.cash           -- keep display in sync
    -- loan record lives in player.loans, PlayState deducts monthlyPayment each month
    table.insert(self.player.loans, {
        label = opt.label,
        amount = opt.amount,
        monthlyPayment = opt.monthlyPayment,
    })
    self:close()
end

function LoanMenu:mousepressed(x, y, button)
    if not self.active or button ~= 1 then return end

    if self.confirming then
        if hit(YES_BTN, x, y) then self:resolveConfirm(true)
        elseif hit(NO_BTN, x, y) then self:resolveConfirm(false) end
        return
    end

    for i, _ in ipairs(LOAN_OPTIONS) do
        local ey = LIST_Y + (i - 1) * ENTRY_H
        if x >= BOX_X and x <= BOX_X + BOX_W and y >= ey and y < ey + ENTRY_H then
            self.selected = i
            self:promptLoan(i)
            return
        end
    end
end


function LoanMenu:render()
    if not self.active then return end

    local ix = BOX_X + PAD
    local iw = BOX_W - PAD * 2

    -- panel
    set(0.75, 0.75, 0.75, 0.9)
    love.graphics.rectangle('fill', BOX_X, BOX_Y, BOX_W, BOX_H, 3)
    set(0.04, 0.04, 0.06, 0.96)
    love.graphics.rectangle('fill', BOX_X + 2, BOX_Y + 2, BOX_W - 4, BOX_H - 4, 3)

    -- title
    love.graphics.setFont(gFonts['gothic-medium'])
    set(0.4, 0.8, 1, 1)
    love.graphics.print('FIRST NATIONAL BANK', ix, BOX_Y + 6)

    -- player cash right-aligned
    love.graphics.setFont(gFonts['small'])
    local cashStr = string.format('Cash: $%.0f', self.player.cash)
    local cashW = gFonts['small']:getWidth(cashStr)
    if self.player.cash < 0 then set(1, 0.4, 0.4, 1) else set(0.5, 1, 0.5, 1) end
    love.graphics.print(cashStr, BOX_X + BOX_W - PAD - cashW, BOX_Y + 8)

    -- subtitle
    set(0.6, 0.6, 0.6, 1)
    love.graphics.print('Select a loan amount:', ix, BOX_Y + 26)

    -- divider
    set(1, 1, 1, 0.2)
    love.graphics.line(ix, BOX_Y + 38, BOX_X + BOX_W - PAD, BOX_Y + 38)

    -- loan entries
    for i, opt in ipairs(LOAN_OPTIONS) do
        local ey = LIST_Y + (i - 1) * ENTRY_H
        local sel = i == self.selected

        if sel then
            set(1, 1, 1, 0.06)
            love.graphics.rectangle('fill', BOX_X + 3, ey, BOX_W - 6, ENTRY_H - 2)
        end

        -- cursor
        love.graphics.setFont(gFonts['small'])
        set(0.4, 0.8, 1, 1)
        love.graphics.print(sel and '>' or ' ', ix, ey + 5)

        -- label + amount
        love.graphics.setFont(gFonts['gothic-medium'])
        set(sel and 1 or 0.9, sel and 0.95 or 0.9, sel and 0.55 or 0.9, 1)
        love.graphics.print(opt.label, ix + 9, ey + 3)

        -- amount right side
        love.graphics.setFont(gFonts['small'])
        set(0.5, 1, 0.5, 1)
        local amtStr = fmt_money(opt.amount)
        local amtW = gFonts['small']:getWidth(amtStr)
        love.graphics.print(amtStr, BOX_X + BOX_W - PAD - amtW, ey + 5)

        -- rate + monthly payment below
        love.graphics.setFont(gFonts['small'])
        set(0.55, 0.55, 0.55, 1)
        love.graphics.print(
            string.format('%.0f%% annual  |  %s/mo interest',
                opt.annualRate * 100,
                fmt_money(opt.monthlyPayment)
            ),
            ix + 9, ey + 15
        )

        set(1, 1, 1, 0.1)
        love.graphics.line(ix, ey + ENTRY_H - 1, BOX_X + BOX_W - PAD, ey + ENTRY_H - 1)
    end

    -- active loans summary
    if self.player.loans and #self.player.loans > 0 then
        local totalMonthly = 0
        for _, loan in ipairs(self.player.loans) do
            totalMonthly = totalMonthly + loan.monthlyPayment
        end
        local loanY = LIST_Y + #LOAN_OPTIONS * ENTRY_H + 2
        love.graphics.setFont(gFonts['small'])
        set(1, 0.55, 0.2, 1)
        love.graphics.printf(
            string.format('Active loans: %d  |  Total payments: %s/mo',
                #self.player.loans, fmt_money(totalMonthly)),
            ix, loanY, iw, 'left'
        )
    end

    -- footer hint / error
    if self.errTimer > 0 then
        set(1, 0.25, 0.25, 1)
        love.graphics.setFont(gFonts['small'])
        love.graphics.printf(self.errMsg, ix, BOX_Y + BOX_H - 12, iw, 'center')
    else
        set(0.38, 0.38, 0.38, 1)
        love.graphics.setFont(gFonts['small'])
        love.graphics.printf(
            '[UP/DN] select   [ENTER] take loan   [ESC] cancel',
            ix, BOX_Y + BOX_H - 12, iw, 'center'
        )
    end

    if self.confirming then
        render_confirm(self.confirmMsg)
    end

    set(1, 1, 1, 1)
end

return LoanMenu
