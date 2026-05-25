--[[
    Empire Engine
    Based on CS50 2D Coursework
    BusinessMenu

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    Overlay menu. Shows per-business stats + market state.
    Toggled by TAB in PlayState.
    World pasues while open.
]]

-- buisness portfolio overlay, toggled with TAB key during gameplay
-- shows per buisness stats, live market state, active events, and monthly overhead
-- world pauses while open so the player can review at leisure
BusinessMenu = Class{}

-- panel anchored to the top left of the screen
local BOX_X = 8
local BOX_Y = 5
local BOX_W = 368
local BOX_H = 210       -- extra height to accomodate the active event line below market row
local PAD = 12          -- inner horizontal padding on both sides
-- ================== claude_changes_2026-05-25-1228 ==================
local ENTRY_H = 54      -- expanded from 48 to fit third stats row for selected entry
-- ====================================================================
local MAX_VIS = 2       -- only 2 buisnesses visible at once to leave room for the event line
local LIST_Y = BOX_Y + 60  -- where the scrollable list starts, shifted down past the market row

-- EMA smoothing factor, same value as Business.lua for consistency
local EMA = 0.12

-- formats a cash amount with a sign, negative gets a minus prefix
local function fmt_cash(n)
    if n < 0 then
        return string.format('-$%.0f', math.abs(n))
    end
    return string.format('$%.0f', n)
end

-- formats a per second rate with a plus or minus sign prefix
local function fmt_rate(n)
    if n < 0 then
        return string.format('-$%.2f', math.abs(n))
    end
    return string.format('+$%.2f', n)
end

-- maps market sentimint to a text label and a color for the market row display
-- thresholds are tuned to the 0.3 to 1.5 sentimint range from Market:update
local function market_label(s)
    if s > 1.15 then return 'BOOM', {0.3, 1.0, 0.4, 1}
    elseif s > 1.05 then return 'GROWING', {0.6, 1.0, 0.6, 1}
    elseif s > 0.95 then return 'STABLE', {1.0, 1.0, 1.0, 1}
    elseif s > 0.85 then return 'SLOW', {1.0, 0.75, 0.2, 1}
    else return 'RECESSION', {1.0, 0.3, 0.3, 1}
    end
end

-- shorthand for setColor
local function set(r, g, b, a)
    love.graphics.setColor(r, g, b, a or 1)
end

-- sets active flag and selection index to defaults
function BusinessMenu:init()
    self.active = false
    self.selected = 1
    -- ================== claude_changes_2026-05-25-1228 ==================
    self.scaleFlash  = nil   -- { timer, msg } shown after a successful scale
    self.mergeFlash  = nil   -- { timer, msg } shown after a successful merge
    -- ====================================================================
    -- ================== claude_changes_2026-05-25-1330 ==================
    self.closeConfirm = nil  -- { bus, busIdx, refund } while waiting for X confirm
    self.closeFlash   = nil  -- { timer, msg } after a business is closed
    -- ====================================================================
end

-- flips the active flag when player presses TAB
function BusinessMenu:toggle()
    self.active = not self.active
end

-- handles up/down nav and Enter/E/W/C/S/M hotkeys; opens sub-menus passed from PlayState
function BusinessMenu:update(dt, player, employeeMenu, equipmentMenu, marketplaceMenu, checklistMenu)
    if not self.active then return end

    -- ================== claude_changes_2026-05-25-1330 ==================
    -- close-business confirm swallows all input until resolved
    if self.closeConfirm then
        if love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter')
           or love.keyboard.wasPressed('y') then
            self:doClose(player)
        elseif love.keyboard.wasPressed('escape') or love.keyboard.wasPressed('n') then
            self.closeConfirm = nil
        end
        return
    end
    -- ====================================================================

    local n = #player.businesses
    if n == 0 then return end

    if love.keyboard.wasPressed('up') then
        self.selected = math.max(1, self.selected - 1)
    elseif love.keyboard.wasPressed('down') then
        self.selected = math.min(n, self.selected + 1)

    -- ================== claude_changes_2026-05-25-1228 ==================
    elseif love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter') then
        -- open employee management for the selected business
        if employeeMenu and player.businesses[self.selected] then
            employeeMenu:open(player.businesses[self.selected], player)
        end

    elseif love.keyboard.wasPressed('s') then
        -- scale up the selected business
        local bus = player.businesses[self.selected]
        if bus and bus:canScale(player.cash) then
            bus:doScale(player)
            self.scaleFlash = { timer = 1.5, msg = 'Scaled up!' }
        end

    elseif love.keyboard.wasPressed('m') then
        -- merge selected business with the first same-type sibling
        local bus = player.businesses[self.selected]
        if bus then
            local partnerIdx = nil
            for i, b in ipairs(player.businesses) do
                if b ~= bus and b.type == bus.type then
                    partnerIdx = i
                    break
                end
            end
            if partnerIdx then
                bus:mergeWith(player.businesses[partnerIdx])
                table.remove(player.businesses, partnerIdx)
                -- clamp selection after removal
                self.selected = math.min(self.selected, #player.businesses)
                self.mergeFlash = { timer = 1.5, msg = 'Businesses merged!' }
            end
        end
    end

    -- ================== claude_changes_2026-05-25-1330 ==================
    if love.keyboard.wasPressed('e') then
        local bus = player.businesses[self.selected]
        if equipmentMenu and bus then
            equipmentMenu:open(bus, player)
        end
    elseif love.keyboard.wasPressed('w') then
        local bus = player.businesses[self.selected]
        if marketplaceMenu and bus and bus.type == 'retail' then
            marketplaceMenu:openWholesaleFor(player, bus)
        end
    elseif love.keyboard.wasPressed('c') then
        local bus = player.businesses[self.selected]
        if checklistMenu and bus then
            checklistMenu:open(bus)
        end
    elseif love.keyboard.wasPressed('x') then
        local idx = self.selected
        local bus = player.businesses[idx]
        if bus then
            local refund = math.max(0, bus.cash)
            self.closeConfirm = { bus = bus, busIdx = idx, refund = refund }
        end
    end
    -- ====================================================================

    -- tick flash timers
    if self.scaleFlash then
        self.scaleFlash.timer = self.scaleFlash.timer - dt
        if self.scaleFlash.timer <= 0 then self.scaleFlash = nil end
    end
    if self.mergeFlash then
        self.mergeFlash.timer = self.mergeFlash.timer - dt
        if self.mergeFlash.timer <= 0 then self.mergeFlash = nil end
    end
    -- ================== claude_changes_2026-05-25-1330 ==================
    if self.closeFlash then
        self.closeFlash.timer = self.closeFlash.timer - dt
        if self.closeFlash.timer <= 0 then self.closeFlash = nil end
    end
    -- ====================================================================
end

-- ================== claude_changes_2026-05-25-1330 ==================
-- executes the confirmed business closure: refund cash, remove from list
function BusinessMenu:doClose(player)
    local cf = self.closeConfirm
    self.closeConfirm = nil
    if not cf then return end
    local refund = cf.refund
    player.cash        = player.cash + refund
    player.displayCash = player.cash
    table.remove(player.businesses, cf.busIdx)
    self.selected = math.min(self.selected, math.max(1, #player.businesses))
    local msg = 'Business closed.'
    if refund > 0 then
        msg = msg .. string.format('  Recovered $%d.', math.floor(refund))
    end
    self.closeFlash = { timer = 2.0, msg = msg }
end
-- ====================================================================

-- rendering

-- draws the full portfolio panel including market state, event banner, buisness list, and overhead
function BusinessMenu:render(player, market)
    if not self.active then return end

    local ix = BOX_X + PAD       -- inner left x for all text and rows
    local iw = BOX_W - PAD * 2   -- total usable inner width

    -- outer grey border with dark inner fill, pokemon panel style
    set(0.75, 0.75, 0.75, 0.85)
    love.graphics.rectangle('fill', BOX_X, BOX_Y, BOX_W, BOX_H, 3)
    set(0.04, 0.04, 0.06, 0.92)
    love.graphics.rectangle('fill', BOX_X + 2, BOX_Y + 2, BOX_W - 4, BOX_H - 4, 3)

    -- title row, gold text on the left, player total cash on the right
    love.graphics.setFont(gFonts['gothic-medium'])
    set(1, 0.84, 0, 1)
    -- ================== claude_changes_2026-05-25-1228 ==================
    local portfolioTitle = string.upper(player.name or 'PLAYER') .. "'S PORTFOLIO"
    love.graphics.print(portfolioTitle, ix, BOX_Y + 6)
    -- ====================================================================

    -- player total cash right aligned, red if negative
    love.graphics.setFont(gFonts['small'])
    local cashStr = fmt_cash(player.cash)
    local cashW = gFonts['small']:getWidth(cashStr)
    if player.cash < 0 then set(1, 0.4, 0.4, 1) else set(0.5, 1, 0.5, 1) end
    love.graphics.print(cashStr, BOX_X + BOX_W - PAD - cashW, BOX_Y + 8)

    -- thin horizontal line below the title row
    set(1, 1, 1, 0.2)
    love.graphics.line(ix, BOX_Y + 26, BOX_X + BOX_W - PAD, BOX_Y + 26)

    -- market row shows the sentimint value and a text label with matching color
    local sentiment = market and market.sentiment or 1.0
    local label, lcolor = market_label(sentiment)

    love.graphics.setFont(gFonts['small'])
    set(0.65, 0.85, 1, 1)
    love.graphics.print(string.format('MARKET: %.3f', sentiment), ix, BOX_Y + 30)
    love.graphics.setColor(unpack(lcolor)) -- lcolor is the color matching the label
    love.graphics.print(label, ix + 98, BOX_Y + 30)

    -- interest rate shown on the right side of the market row if availible
    if market and market.interestRate then
        set(0.65, 0.65, 0.65, 1)
        love.graphics.print(
            string.format('INTEREST: %.1f%%', market.interestRate * 100),
            ix + 175, BOX_Y + 30
        )
    end

    -- event banner row below the market row, shows the first active event if any
    -- only one event can be active at a time, so activeEvents[1] is always the right one
    local ae = market and market.activeEvents and market.activeEvents[1]
    if ae then
        local months_left = math.ceil(ae.timeRemaining / SECONDS_PER_MONTH)
        set(1, 0.35, 0.35, 1) -- red for negative events
        love.graphics.print('! ' .. string.upper(ae.event.name), ix, BOX_Y + 42)
        set(0.6, 0.6, 0.6, 1)
        love.graphics.print(
            string.format('(%d mo remaining)', months_left),
            ix + 120, BOX_Y + 42
        )
    else
        -- no event running, show a calm green status message
        set(0.35, 0.5, 0.35, 1)
        love.graphics.print('No active events', ix, BOX_Y + 42)
    end

    -- market divider
    set(1, 1, 1, 0.2)
    love.graphics.line(ix, BOX_Y + 56, BOX_X + BOX_W - PAD, BOX_Y + 56)

    -- ── business list ──
    if #player.businesses == 0 then
        love.graphics.setFont(gFonts['small'])
        set(0.5, 0.5, 0.5, 1)
        love.graphics.printf('No businesses owned.', ix, BOX_Y + 95, iw, 'center')
        love.graphics.printf('Interact with a chest to open your first.', ix, BOX_Y + 108, iw, 'center')
    else
        -- scroll: keep selected in view
        local scroll = math.max(0, self.selected - MAX_VIS)
        local draw_n = math.min(MAX_VIS, #player.businesses - scroll)

        for i = 1, draw_n do
            local idx = i + scroll
            local bus = player.businesses[idx]
            local ey = LIST_Y + (i - 1) * ENTRY_H
            local sel = idx == self.selected

            -- row highlight
            if sel then
                set(1, 1, 1, 0.06)
                love.graphics.rectangle('fill', BOX_X + 3, ey, BOX_W - 6, ENTRY_H - 2)
            end

            -- cursor
            love.graphics.setFont(gFonts['small'])
            set(1, 0.84, 0, 1)
            love.graphics.print(sel and '>' or ' ', ix, ey + 6)

            -- name
            love.graphics.setFont(gFonts['gothic-medium'])
            if sel then set(1, 0.95, 0.55, 1) else set(1, 1, 1, 1) end
            local nameStr = string.upper(bus.displayName or bus.type or 'UNKNOWN')
            love.graphics.print(nameStr, ix + 9, ey + 3)

            -- bankruptcy tag (right side of name row)
            if bus.bankrupt then
                love.graphics.setFont(gFonts['small'])
                set(1, 0.2, 0.2, 1)
                local tag = '[BANKRUPT]'
                local tagW = gFonts['small']:getWidth(tag)
                love.graphics.print(tag, BOX_X + BOX_W - PAD - tagW, ey + 6)
            end

            -- stats row 1: cash | profit/s
            love.graphics.setFont(gFonts['small'])
            local m = bus.trackingMetrics

            -- cash
            if bus.cash < 0 then set(1, 0.45, 0.45, 1) else set(0.5, 1, 0.5, 1) end
            love.graphics.print('Cash: ' .. fmt_cash(bus.cash), ix + 9, ey + 21)

            -- profit/s
            local ps = m.profitPerSec or 0
            if ps < 0 then set(1, 0.45, 0.45, 1) else set(0.5, 1, 0.5, 1) end
            love.graphics.print('P/s: ' .. fmt_rate(ps), ix + 120, ey + 21)

            -- ================== claude_changes_2026-05-25-1330 ==================
            -- right side of row 2: stock level for retail, startup cost for everything else
            if bus.stockLevel ~= nil then
                local stockFrac = bus.stockLevel / (bus.maxStock or 5000)
                local sc = stockFrac > 0.5 and {0.4, 1, 0.4} or
                           stockFrac > 0.15 and {1, 0.85, 0.3} or {1, 0.45, 0.45}
                set(sc[1], sc[2], sc[3], 1)
                local stStr = string.format('Stock: %d', math.floor(bus.stockLevel))
                local stW = gFonts['small']:getWidth(stStr)
                love.graphics.print(stStr, BOX_X + BOX_W - PAD - stW, ey + 21)
            else
                set(0.55, 0.55, 0.55, 1)
                local scStr = 'Startup: ' .. fmt_cash(bus.startupCost or 0)
                local scW = gFonts['small']:getWidth(scStr)
                love.graphics.print(scStr, BOX_X + BOX_W - PAD - scW, ey + 21)
            end
            -- ====================================================================

            -- stats row 2: rev, cost, rep, age
            set(0.72, 0.72, 0.72, 1)
            love.graphics.print(
                string.format('Rev/s: $%.2f', m.revenuePerSec or 0),
                ix + 9, ey + 32
            )
            love.graphics.print(
                string.format('Cost/s: $%.2f', m.costsPerSec or 0),
                ix + 120, ey + 32
            )
            set(0.6, 0.6, 0.85, 1)
            love.graphics.print(
                string.format('Rep: %.2f', bus.reputation or 1),
                ix + 225, ey + 32
            )

            -- ================== claude_changes_2026-05-25-1228 ==================
            -- stats row 3 (selected business only): staff, ops%, tier, age
            if sel then
                local empCount  = #(bus.employees or {})
                local empMax    = bus.maxEmployees or 5
                local tierNum   = bus.scaleTier or 1
                local tierLbls  = {'Normal', 'Large', 'Enterprise'}
                local tierLabel = tierLbls[tierNum] or ('T' .. tierNum)

                set(0.6, 0.85, 0.6, 1)
                local row3 = string.format('Staff:%d/%d', empCount, empMax)
                love.graphics.print(row3, ix + 9, ey + 43)

                -- ================== claude_changes_2026-05-25-1330 ==================
                -- ops multiplier from requirements checklist
                local opMult = bus.getOpMult and bus:getOpMult() or 1.0
                local opPct  = math.floor(opMult * 100)
                local oc = opPct >= 100 and {0.4, 1, 0.4} or
                           opPct >= 60  and {1, 0.85, 0.3} or {1, 0.4, 0.4}
                set(oc[1], oc[2], oc[3], 1)
                love.graphics.print(string.format('Ops:%d%%', opPct), ix + 120, ey + 43)
                -- ====================================================================

                set(0.75, 0.65, 1, 1)
                love.graphics.print('Tier:' .. tierLabel, ix + 210, ey + 43)

                local age_m = math.floor((bus.age or 0) / 60)
                local age_s = math.floor((bus.age or 0) % 60)
                set(0.5, 0.5, 0.5, 1)
                love.graphics.print(string.format('Age:%dm%ds', age_m, age_s), ix + 290, ey + 43)
            end
            -- ====================================================================

            -- entry divider
            set(1, 1, 1, 0.1)
            love.graphics.line(ix, ey + ENTRY_H - 1, BOX_X + BOX_W - PAD, ey + ENTRY_H - 1)
        end

        -- scroll indicator
        if #player.businesses > MAX_VIS then
            love.graphics.setFont(gFonts['small'])
            set(0.4, 0.4, 0.4, 1)
            love.graphics.printf(
                string.format('%d / %d', self.selected, #player.businesses),
                ix, LIST_Y + MAX_VIS * ENTRY_H + 2, iw, 'center'
            )
        end

        -- ================== claude_changes_2026-05-25-1228 ==================
        -- flash messages for scale, merge, and close actions
        local flash = self.scaleFlash or self.mergeFlash or self.closeFlash
        if flash then
            local fc = self.closeFlash and {1, 0.5, 0.5} or {0.4, 1, 0.6}
            set(fc[1], fc[2], fc[3], math.min(1, flash.timer))
            love.graphics.printf(flash.msg, ix, LIST_Y + MAX_VIS * ENTRY_H + 12, iw, 'center')
        end
        -- ====================================================================
    end

    -- living expenses
    set(1, 1, 1, 0.12)
    love.graphics.line(ix, BOX_Y + BOX_H - 42, BOX_X + BOX_W - PAD, BOX_Y + BOX_H - 42)

    love.graphics.setFont(gFonts['small'])
    set(1, 0.75, 0.3, 1)
    love.graphics.print('MONTHLY OVERHEAD', ix, BOX_Y + BOX_H - 37)

    local totalStr = fmt_cash(RENT + UTILS) .. '/mo'
    local totalW = gFonts['small']:getWidth(totalStr)
    if player.cash < RENT + UTILS then set(1, 0.4, 0.4, 1) else set(0.6, 0.6, 0.6, 1) end
    love.graphics.print(totalStr, BOX_X + BOX_W - PAD - totalW, BOX_Y + BOX_H - 37)

    set(0.5, 0.5, 0.5, 1)
    love.graphics.print(
        string.format('Rent: %s   Utilities: %s', fmt_cash(RENT), fmt_cash(UTILS)),
        ix, BOX_Y + BOX_H - 26
    )

    -- bottom hint
    -- ================== claude_changes_2026-05-25-1228 ==================
    love.graphics.setFont(gFonts['small'])
    set(0.38, 0.38, 0.38, 1)
    -- ================== claude_changes_2026-05-25-1330 ==================
    love.graphics.printf(
        '[ENTER] staff  [E] equip  [W] stock  [C] list  [S] scale  [M] merge  [X] close biz',
        ix, BOX_Y + BOX_H - 11, iw, 'center'
    )

    -- close-business confirm overlay
    if self.closeConfirm then
        local cf = self.closeConfirm
        local cw = 210
        local ch = 72
        local cx = math.floor((384 - cw) / 2)
        local cy = math.floor((216 - ch) / 2)
        local yb = { x = cx + 14,  y = cy + 50, w = 60, h = 14 }
        local nb = { x = cx + 136, y = cy + 50, w = 60, h = 14 }

        set(0, 0, 0, 0.55)
        love.graphics.rectangle('fill', 0, 0, 384, 216)
        set(0.1, 0.06, 0.06, 0.97)
        love.graphics.rectangle('fill', cx, cy, cw, ch, 4)
        set(0.7, 0.3, 0.3, 1)
        love.graphics.rectangle('line', cx, cy, cw, ch, 4)

        love.graphics.setFont(gFonts['small'])
        set(1, 0.75, 0.75, 1)
        local busName = string.upper(cf.bus.displayName or cf.bus.type)
        love.graphics.printf('Close ' .. busName .. '?', cx + 8, cy + 8, cw - 16, 'center')
        if cf.refund > 0 then
            set(0.6, 1, 0.6, 1)
            love.graphics.printf('Recover ' .. fmt_cash(math.floor(cf.refund)), cx + 8, cy + 22, cw - 16, 'center')
        else
            set(0.6, 0.6, 0.6, 1)
            love.graphics.printf('No cash recovered.', cx + 8, cy + 22, cw - 16, 'center')
        end
        set(0.5, 0.5, 0.5, 1)
        love.graphics.printf('Staff and equipment lost.', cx + 8, cy + 34, cw - 16, 'center')

        set(0.15, 0.45, 0.15, 1)
        love.graphics.rectangle('fill', yb.x, yb.y, yb.w, yb.h, 3)
        set(0.4, 1, 0.4, 1)
        love.graphics.rectangle('line', yb.x, yb.y, yb.w, yb.h, 3)
        set(1, 1, 1, 1)
        love.graphics.printf('[Y] Close', yb.x, yb.y + 3, yb.w, 'center')

        set(0.45, 0.1, 0.1, 1)
        love.graphics.rectangle('fill', nb.x, nb.y, nb.w, nb.h, 3)
        set(1, 0.35, 0.35, 1)
        love.graphics.rectangle('line', nb.x, nb.y, nb.w, nb.h, 3)
        set(1, 1, 1, 1)
        love.graphics.printf('[N] Keep', nb.x, nb.y + 3, nb.w, 'center')
    end
    -- ====================================================================

    -- reset
    set(1, 1, 1, 1)
end

return BusinessMenu
