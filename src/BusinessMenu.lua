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
local ENTRY_H = 48      -- pixels per buisness row, tall enough for two stat rows
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
end

-- flips the active flag when player presses TAB
function BusinessMenu:toggle()
    self.active = not self.active
end

-- handles up and down navigation through the owned buisness list
-- clamped so selection cant go below 1 or above the buisness count
function BusinessMenu:update(dt, player)
    if not self.active then return end

    local n = #player.businesses
    if n == 0 then return end -- nothing to navigate if no buisnesses owned

    if love.keyboard.wasPressed('up') then
        self.selected = math.max(1, self.selected - 1)
    elseif love.keyboard.wasPressed('down') then
        self.selected = math.min(n, self.selected + 1)
    end
end

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
    love.graphics.print('BUSINESS PORTFOLIO', ix, BOX_Y + 6)

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

            -- startup cost (right side)
            set(0.55, 0.55, 0.55, 1)
            local scStr = 'Startup: ' .. fmt_cash(bus.startupCost or 0)
            local scW = gFonts['small']:getWidth(scStr)
            love.graphics.print(scStr, BOX_X + BOX_W - PAD - scW, ey + 21)

            -- stats row 2: rev, cost, rep,  age
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

            local age_m = math.floor((bus.age or 0) / 60)
            local age_s = math.floor((bus.age or 0) % 60)
            set(0.5, 0.5, 0.5, 1)
            love.graphics.print(
                string.format('Age: %dm%ds', age_m, age_s),
                ix + 295, ey + 32
            )

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
    love.graphics.setFont(gFonts['small'])
    set(0.38, 0.38, 0.38, 1)
    love.graphics.printf(
        '[TAB] close   [UP/DN] select',
        ix, BOX_Y + BOX_H - 11, iw, 'center'
    )

    -- reset
    set(1, 1, 1, 1)
end

return BusinessMenu
