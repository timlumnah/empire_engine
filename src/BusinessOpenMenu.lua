--[[
    Empire Engine
    Based on CS50 2D Coursework
    BusinessOpenMenu

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    Pokemon BattleMenu-style panel.
    Triggered when player interacts with a banker NPC.
    Shows selectalbe list of BUSINESS_TYPES filtered by current room biome.
    Deducts startup cost from player.cash on confirmed purchase.
]]

-- franchise broker UI, triggered when player picks BUSINESS from the NpcMenu
-- shows buisness types filtered to the current rooms biome
-- deducts startup cost from player cash on confirmed purchase
BusinessOpenMenu = Class{}

-- master display order, cheapest to most expensive
-- biome filtering preserves this order while removing types not available here
local BUSINESS_ORDER = {
    'laundromat', 'retail', 'restaurant', 'car_dealer', 'casino', 'aerospace'
}

-- panel layout constants
local BOX_X = 44
local BOX_Y = 26
local BOX_W = 296
local BOX_H = 164
local PAD = 10
local ENTRY_H = 38      -- pixels per buisness row
local MAX_VIS = 3       -- max rows visible at once before scrolling kicks in
local LIST_Y = BOX_Y + 46  -- where the buisness list starts below the header

-- confirm popup
local CONF_W = 168
local CONF_H = 66
local CONF_X = math.floor((384 - CONF_W) / 2)
local CONF_Y = math.floor((216 - CONF_H) / 2)
local YES_BTN = { x = CONF_X + 12,  y = CONF_Y + 44, w = 56, h = 14 }
local NO_BTN = { x = CONF_X + 100, y = CONF_Y + 44, w = 56, h = 14 }

-- helpers

-- Maps a risk float to a display label and color. Input is 0 to 1.
local function risk_label(r)
    if r < 0.15 then return 'Low', {0.4, 1, 0.4, 1}
    elseif r < 0.35 then return 'Low-Med', {0.8, 1, 0.4, 1}
    elseif r < 0.55 then return 'Medium', {1, 0.9, 0.2, 1}
    elseif r < 0.75 then return 'High', {1, 0.5, 0.2, 1}
    else return 'Very High',{1, 0.2, 0.2, 1}
    end
end

-- Formats a number as a compact dollar string.
local function fmt_k(n)
    -- compact dollar format: $7,000 -> "$7k"
    if n >= 1000000 then
        return string.format('$%.0fm', n / 1000000)
    elseif n >= 1000 then
        return string.format('$%.0fk', n / 1000)
    else
        return string.format('$%.0f', n)
    end
end

-- Shorthand for love.graphics.setColor with optional alpha.
local function set(r, g, b, a) love.graphics.setColor(r, g, b, a or 1) end

-- Returns true if point x,y falls inside rect. Rect needs x, y, w, h fields.
local function hit(rect, x, y)
    return x >= rect.x and x <= rect.x + rect.w
       and y >= rect.y and y <= rect.y + rect.h
end

-- Draws a yes or no confirm popup over the full screen.
local function render_confirm(msg)
    -- dim world behind popup
    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle('fill', 0, 0, 384, 216)

    -- box
    love.graphics.setColor(0.08, 0.08, 0.13, 0.97)
    love.graphics.rectangle('fill', CONF_X, CONF_Y, CONF_W, CONF_H, 4)
    love.graphics.setColor(0.45, 0.45, 0.6, 1)
    love.graphics.rectangle('line', CONF_X, CONF_Y, CONF_W, CONF_H, 4)

    -- message
    love.graphics.setFont(gFonts['small'])
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(msg, CONF_X + 8, CONF_Y + 10, CONF_W - 16, 'center')

    -- YES button
    love.graphics.setColor(0.15, 0.45, 0.15, 1)
    love.graphics.rectangle('fill', YES_BTN.x, YES_BTN.y, YES_BTN.w, YES_BTN.h, 3)
    love.graphics.setColor(0.4, 1, 0.4, 1)
    love.graphics.rectangle('line', YES_BTN.x, YES_BTN.y, YES_BTN.w, YES_BTN.h, 3)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('YES', YES_BTN.x, YES_BTN.y + 3, YES_BTN.w, 'center')

    -- NO button
    love.graphics.setColor(0.45, 0.1, 0.1, 1)
    love.graphics.rectangle('fill', NO_BTN.x, NO_BTN.y, NO_BTN.w, NO_BTN.h, 3)
    love.graphics.setColor(1, 0.35, 0.35, 1)
    love.graphics.rectangle('line', NO_BTN.x, NO_BTN.y, NO_BTN.w, NO_BTN.h, 3)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('NO', NO_BTN.x, NO_BTN.y + 3, NO_BTN.w, 'center')

    love.graphics.setColor(1, 1, 1, 1)
end

-- class

-- sets all state fields to defualt values, called once at startup
function BusinessOpenMenu:init()
    self.active = false
    self.player = nil
    self.selected = 1
    self.errTimer = 0       -- how long to show the error message
    self.errMsg = ''
    self.businessList = BUSINESS_ORDER  -- full list by default, filtered on open
    self.confirming = false
    self.confirmMsg = ''
    self.confirmAction = nil
end

-- activates the menu for a player in a specific biome
-- filters the buisness list to only types the biome allows, preserving BUSINESS_ORDER sort
function BusinessOpenMenu:open(player, biome)
    self.active = true
    self.player = player
    self.selected = 1
    self.errTimer = 0
    self.errMsg = ''
    self.confirming = false
    self.confirmMsg = ''
    self.confirmAction = nil

    -- filter to biomes allowed buisness types, keeping BUSINESS_ORDER sort intact
    if biome and biome.businesses then
        local allowed = {}
        for _, k in ipairs(biome.businesses) do allowed[k] = true end
        self.businessList = {}
        for _, k in ipairs(BUSINESS_ORDER) do
            if allowed[k] then table.insert(self.businessList, k) end
        end
    else
        -- no biome provided, show all buisnesses unfiltered
        self.businessList = BUSINESS_ORDER
    end
end

-- deactivates the menu and clears the player reference
function BusinessOpenMenu:close()
    self.active = false
    self.player = nil
end

-- shows the confirm popup with a message and stores the action to run if yes is picked
function BusinessOpenMenu:showConfirm(msg, action)
    self.confirming = true
    self.confirmMsg = msg
    self.confirmAction = action
    self.errTimer = 0   -- clear any error when confirm opens
end

-- runs the stored action if yes was chosen, then clears the confirm state
function BusinessOpenMenu:resolveConfirm(yes)
    if yes and self.confirmAction then self.confirmAction() end
    self.confirming = false
    self.confirmMsg = ''
    self.confirmAction = nil
end

-- Handles keyboard navigation, confirm popup input, and escape.
function BusinessOpenMenu:update(dt)
    if not self.active then return end
    if self.errTimer > 0 then self.errTimer = self.errTimer - dt end

    -- confirm popup eats all input while active
    if self.confirming then
        if love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter')
           or love.keyboard.wasPressed('y') then
            self:resolveConfirm(true)
        elseif love.keyboard.wasPressed('escape') or love.keyboard.wasPressed('n') then
            self:resolveConfirm(false)
        end
        return
    end

    local n = #self.businessList

    if love.keyboard.wasPressed('up') then
        self.selected = self.selected > 1 and self.selected - 1 or n
        self.errTimer = 0
    elseif love.keyboard.wasPressed('down') then
        self.selected = self.selected < n and self.selected + 1 or 1
        self.errTimer = 0
    elseif love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter') then
        local key = self.businessList[self.selected]
        local def = BUSINESS_TYPES[key]
        if def then
            self:showConfirm(
                'Open ' .. string.upper(def.displayName or key) .. '?\nCost: ' .. fmt_k(def.startupCost),
                function() self:tryPurchase() end
            )
        end
    elseif love.keyboard.wasPressed('escape') then
        self:close()
    end
end

-- Routes click input to list row selection or confirm popup buttons.
function BusinessOpenMenu:mousepressed(x, y, button)
    if not self.active or button ~= 1 then return end

    if self.confirming then
        if hit(YES_BTN, x, y) then
            self:resolveConfirm(true)
        elseif hit(NO_BTN, x, y) then
            self:resolveConfirm(false)
        end
        return
    end

    -- detect row clicks, account for current scroll offset
    local scroll = math.max(0, self.selected - MAX_VIS)
    local draw_n = math.min(MAX_VIS, #self.businessList - scroll)

    for i = 1, draw_n do
        local ey = LIST_Y + (i - 1) * ENTRY_H
        local idx = i + scroll
        if x >= BOX_X and x <= BOX_X + BOX_W and y >= ey and y < ey + ENTRY_H then
            self.selected = idx
            local key = self.businessList[idx]
            local def = BUSINESS_TYPES[key]
            if def then
                self:showConfirm(
                    'Open ' .. string.upper(def.displayName or key) .. '?\nCost: ' .. fmt_k(def.startupCost),
                    function() self:tryPurchase() end
                )
            end
            return
        end
    end
end

-- validates player funds, deducts startup cost, creates the Business instance, and adds it to player
-- this is the function called by the confirm dialog action on a yes answer
function BusinessOpenMenu:tryPurchase()
    local key = self.businessList[self.selected]
    local def = BUSINESS_TYPES[key]
    if not def then return end -- guard against missing def, shouldnt happen in normal play

    -- check funds before doing anything, show error and bail if cant afford
    if self.player.cash < def.startupCost then
        self.errMsg = 'Insufficient funds!'
        self.errTimer = 2.0 -- error message lingers for 2 seconds
        return
    end

    -- deduct the startup cost and sync the display cash
    self.player.cash = self.player.cash - def.startupCost
    self.player.displayCash = self.player.cash

    -- create the buisness from the def, then zero its cash field
    local bus = Business(def)
    -- Business:init sets cash to negative startupCost, override that here
    -- the player already paid the startup cost, so the buisness starts at zero
    bus.cash = 0

    table.insert(self.player.businesses, bus)

    self:close() -- close menu after successful purchase
end

-- rendering

-- Draws the panel, entry list, scroll indicator, and confirm popup if active.
function BusinessOpenMenu:render()
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
    set(1, 0.84, 0, 1)
    love.graphics.print('FRANCHISE BROKER', ix, BOX_Y + 6)

    -- player cash right aligned
    love.graphics.setFont(gFonts['small'])
    local cashStr = string.format('Cash: $%.0f', self.player.cash)
    local cashW = gFonts['small']:getWidth(cashStr)
    if self.player.cash < 0 then set(1, 0.4, 0.4, 1) else set(0.5, 1, 0.5, 1) end
    love.graphics.print(cashStr, BOX_X + BOX_W - PAD - cashW, BOX_Y + 8)

    -- subtitle
    set(0.6, 0.6, 0.6, 1)
    love.graphics.print('Select a business to open:', ix, BOX_Y + 26)

    -- title divider
    set(1, 1, 1, 0.2)
    love.graphics.line(ix, BOX_Y + 38, BOX_X + BOX_W - PAD, BOX_Y + 38)

    -- error message or bottom hint
    if self.errTimer > 0 then
        love.graphics.setFont(gFonts['small'])
        set(1, 0.25, 0.25, 1)
        love.graphics.printf(self.errMsg, ix, BOX_Y + BOX_H - 22, iw, 'center')
    else
        set(0.38, 0.38, 0.38, 1)
        love.graphics.printf(
            '[UP/DN] browse   [ENTER] open   [ESC] cancel',
            ix, BOX_Y + BOX_H - 12, iw, 'center'
        )
    end

    -- entry list
    local scroll = math.max(0, self.selected - MAX_VIS)
    local draw_n = math.min(MAX_VIS, #self.businessList - scroll)

    for i = 1, draw_n do
        local idx = i + scroll
        local key = self.businessList[idx]
        local def = BUSINESS_TYPES[key]
        local ey = LIST_Y + (i - 1) * ENTRY_H
        local sel = idx == self.selected
        local canAfford = self.player.cash >= def.startupCost

        if sel then
            set(1, 1, 1, 0.06)
            love.graphics.rectangle('fill', BOX_X + 3, ey, BOX_W - 6, ENTRY_H - 2)
        end

        love.graphics.setFont(gFonts['small'])
        set(1, 0.84, 0, 1)
        love.graphics.print(sel and '>' or ' ', ix, ey + 5)

        love.graphics.setFont(gFonts['gothic-medium'])
        if not canAfford then
            set(0.5, 0.5, 0.5, 1)
        elseif sel then
            set(1, 0.95, 0.55, 1)
        else
            set(1, 1, 1, 1)
        end
        love.graphics.print(string.upper(def.displayName or key), ix + 9, ey + 3)

        love.graphics.setFont(gFonts['small'])
        if not canAfford then set(1, 0.35, 0.35, 1)
        else set(0.5, 1, 0.5, 1) end
        local costStr = 'Cost: ' .. fmt_k(def.startupCost)
        local costW = gFonts['small']:getWidth(costStr)
        love.graphics.print(costStr, BOX_X + BOX_W - PAD - costW, ey + 6)

        local riskLabel, riskColor = risk_label(def.risk or 0.2)
        set(0.65, 0.65, 0.65, 1)
        love.graphics.print('Risk: ', ix + 9, ey + 20)
        love.graphics.setColor(unpack(riskColor))
        love.graphics.print(riskLabel, ix + 9 + gFonts['small']:getWidth('Risk: '), ey + 20)

        set(0.65, 0.65, 0.65, 1)
        love.graphics.print(string.format('Fixed: %s/mo', fmt_k(def.fixedCosts or 0)), ix + 105, ey + 20)
        love.graphics.print(string.format('Cap: %s units/mo', fmt_k(def.capacity or 0)), ix + 9, ey + 29)

        set(1, 1, 1, 0.1)
        love.graphics.line(ix, ey + ENTRY_H - 1, BOX_X + BOX_W - PAD, ey + ENTRY_H - 1)
    end

    -- scroll indicator
    if #self.businessList > MAX_VIS then
        love.graphics.setFont(gFonts['small'])
        set(0.38, 0.38, 0.38, 1)
        love.graphics.printf(
            string.format('%d / %d', self.selected, #self.businessList),
            ix, LIST_Y + MAX_VIS * ENTRY_H + 2, iw, 'center'
        )
    end

    -- confirm popup on top of everything
    if self.confirming then
        render_confirm(self.confirmMsg)
    end

    set(1, 1, 1, 1)
end

return BusinessOpenMenu
