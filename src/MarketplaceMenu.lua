--[[
    Empire Engine
    Based on CS50 2D Coursework

    MarketplaceMenu.lua

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    Business management overlay opened with 'c'. Lets the player view
    owned businesses, purchase new ones, and manage inventroy orders
    and deliveries across all held business types.
]]



-- three page marketplace UI, opened with C when player owns a computer or phone
-- page 1 is the landing screen, page 2 is the store, page 3 is the games launcher
-- purchases queue a delivery in player.pendingDeliveries, PlayState spawns the chest
MarketplaceMenu = Class{}

-- panel dimensions, centered on the virtual screen
local BOX_W = 300
-- ================== claude_changes_2026-05-23-2157 ==================
local BOX_H = 210  -- was 180; expanded to fit 3 landing buttons
-- ====================================================================
local BOX_X = math.floor((VIRTUAL_WIDTH - BOX_W) / 2)
local BOX_Y = math.floor((VIRTUAL_HEIGHT - BOX_H) / 2)
local PAD = 10

-- store page layout constants
local VISIBLE = 5       -- how many store rows fit without scrolling
local ENTRY_H = 22      -- pixels per store row
local LIST_Y = BOX_Y + 44  -- where the store list starts below the header

-- standard confirm popup dimensions, shared with other menus for consistency
local CONF_W = 200
local CONF_H = 72
local CONF_X = math.floor((VIRTUAL_WIDTH - CONF_W) / 2)
local CONF_Y = math.floor((VIRTUAL_HEIGHT - CONF_H) / 2)
local YES_BTN = { x = CONF_X + 20, y = CONF_Y + 52, w = 56, h = 14 }
local NO_BTN = { x = CONF_X + 124, y = CONF_Y + 52, w = 56, h = 14 }

-- buy confirm popup is taller than the standard one because it has a qty selector row
local BUYCONF_H = 94
local BUYCONF_Y = math.floor((VIRTUAL_HEIGHT - BUYCONF_H) / 2)
local BUYYES_BTN = { x = CONF_X + 20, y = BUYCONF_Y + BUYCONF_H - 20, w = 56, h = 14 }
local BUYNO_BTN = { x = CONF_X + 124, y = BUYCONF_Y + BUYCONF_H - 20, w = 56, h = 14 }

-- ================== claude_changes_2026-05-23-2157 ==================
-- three landing page options; businesses signals PlayState to open businessMenu
local LANDING_OPTIONS = {
    { id = 'store',      label = 'STORE',      desc = 'Browse & purchase items' },
    { id = 'businesses', label = 'BUSINESSES', desc = 'Manage your portfolio'   },
    { id = 'games',      label = 'GAMES',      desc = 'Play minigames'          },
}
-- landing button layout
local BTN_H = 40
local BTN_W = BOX_W - PAD * 2 - 4
local BTN_X = BOX_X + PAD + 2
local BTN1_Y = BOX_Y + 44
local BTN2_Y = BTN1_Y + BTN_H + 8
local BTN3_Y = BTN2_Y + BTN_H + 8
-- ====================================================================

-- available minigames shown on the games page
-- id must match the folder name under minigames and the MINIGAME_DEFS key
local GAME_LIST = {
    { id = 'pong', displayName = 'PONG', description = '1P vs CPU  |  Up/Down keys' },
    { id = 'breakout', displayName = 'BREAKOUT', description = 'Clear level 1  |  Left/Right paddle' },
}

-- product list is nil until first open, built lazily so startup stays fast
local PRODUCT_LIST = nil


-- shorthand for setColor
local function set(r, g, b, a) love.graphics.setColor(r, g, b, a or 1) end

-- point in rect test for mouse click detection
local function hit(rect, x, y)
    return x >= rect.x and x <= rect.x + rect.w
       and y >= rect.y and y <= rect.y + rect.h
end

-- formats a number as a compact dollar string for display in tight UI spaces
local function fmt_money(n)
    if n >= 1000000 then return string.format('$%.1fm', n / 1000000)
    elseif n >= 1000 then return string.format('$%.0fk', n / 1000)
    else return string.format('$%d', n) end
end

-- builds the flat sorted product list from PRODUCTS and VENDORS at first open
-- each entry is one vendor and product combination, price includes the vendor surcharge
-- sorted by type first so food groups together, then alphabetically by name
local function build_product_list()
    local list = {}
    for productKey, product in pairs(PRODUCTS) do
        -- ================== claude_changes_2026-05-25-1228 ==================
        if product.playerBuyable ~= false then
        -- ====================================================================
        for _, vendorKey in ipairs(product.vendors) do
            local vendor = VENDORS[vendorKey]
            if vendor then
                -- apply vendor surcharge on top of the base product price
                local price = math.floor(product.price * (1 + vendor.priceSurcharge))
                -- apply vendor speed multiplier to the global delivery speed constant
                local delivery = math.floor(VENDOR_DELIVERY_SPEED * vendor.delivery_speed_multiplier)
                list[#list + 1] = {
                    productKey = productKey,
                    vendorKey = vendorKey,
                    displayName = product.displayName,
                    vendorName = vendor.displayName,
                    price = price,
                    deliveryTime = delivery,
                    ptype = product.type,  -- used for sorting and the type tag in the store row
                }
            end
        end
        -- ================== claude_changes_2026-05-25-1228 ==================
        end
        -- ====================================================================
    end
    -- sort by type first so food and beverage group together, alphabetically within each type
    table.sort(list, function(a, b)
        if a.ptype ~= b.ptype then return a.ptype < b.ptype end
        return a.displayName < b.displayName
    end)
    return list
end

local function render_panel()
    set(0.7, 0.75, 0.7, 0.9)
    love.graphics.rectangle('fill', BOX_X, BOX_Y, BOX_W, BOX_H, 3)
    set(0.04, 0.06, 0.04, 0.96)
    love.graphics.rectangle('fill', BOX_X + 2, BOX_Y + 2, BOX_W - 4, BOX_H - 4, 3)
end

local function render_confirm(msg)
    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle('fill', 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
    set(0.08, 0.08, 0.13, 0.97)
    love.graphics.rectangle('fill', CONF_X, CONF_Y, CONF_W, CONF_H, 4)
    set(0.45, 0.45, 0.6, 1)
    love.graphics.rectangle('line', CONF_X, CONF_Y, CONF_W, CONF_H, 4)
    love.graphics.setFont(gFonts['small'])
    set(1, 1, 1, 1)
    love.graphics.printf(msg, CONF_X + 8, CONF_Y + 8, CONF_W - 16, 'center')
    set(0.15, 0.45, 0.15, 1)
    love.graphics.rectangle('fill', YES_BTN.x, YES_BTN.y, YES_BTN.w, YES_BTN.h, 3)
    set(0.4, 1, 0.4, 1)
    love.graphics.rectangle('line', YES_BTN.x, YES_BTN.y, YES_BTN.w, YES_BTN.h, 3)
    set(1, 1, 1, 1)
    love.graphics.printf('YES', YES_BTN.x, YES_BTN.y + 3, YES_BTN.w, 'center')
    set(0.45, 0.1, 0.1, 1)
    love.graphics.rectangle('fill', NO_BTN.x, NO_BTN.y, NO_BTN.w, NO_BTN.h, 3)
    set(1, 0.35, 0.35, 1)
    love.graphics.rectangle('line', NO_BTN.x, NO_BTN.y, NO_BTN.w, NO_BTN.h, 3)
    set(1, 1, 1, 1)
    love.graphics.printf('NO', NO_BTN.x, NO_BTN.y + 3, NO_BTN.w, 'center')
    set(1, 1, 1, 1)
end


-- sets all state to safe defaults at startup
function MarketplaceMenu:init()
    self.active = false
    self.player = nil
    self.page = 'landing'       -- current page, "landing", "store", or "games"
    self.landingSelected = 1    -- which landing button is highlighted
    -- store page state
    self.selected = 1           -- which product row is selected
    self.scroll = 0             -- scroll offset for the product list
    self.confirming = false     -- whether the buy confirm popup is open
    self.confirmMsg = ''
    self.confirmAction = nil
    self.errTimer = 0           -- how long the error message lingers
    self.errMsg = ''
    self.pendingBuyIdx = nil    -- which product index is being confirmed for purchase
    self.buyQty = 1             -- quantity selected in the buy confirm dialog
    self.qtyRepeatDir = 0       -- direction being held for qty repeat, -1, 0, or 1
    self.qtyRepeatTimer = 0     -- accumulator for the hold to repeat logic
    -- games page state
    self.gameSelected = 1
    self.pendingMinigame = nil  -- set when player picks a game, PlayState reads and launches it
-- ================== claude_changes_2026-05-23-2157 ==================
    self.pendingBusinessMenu = false  -- set when player picks businesses, PlayState opens businessMenu
-- ====================================================================
-- ================== claude_changes_2026-05-25-1228 ==================
    self.storeTab = 'personal'      -- 'personal' or 'wholesale'
    self.wholesaleBusIdx = 1        -- index into player's retail business list
    self.wholesaleQty = 100         -- units to order
    self.wholesaleConfirm = false
    self.wQtyRepeatDir = 0
    self.wQtyRepeatTimer = 0
-- ====================================================================
-- ================== claude_changes_2026-05-25-1330 ==================
    self.wholesaleRow = 1           -- active row: 1=business, 2=qty, 3=toggle, 4=threshold, 5=reorder%
-- ====================================================================
end

-- activates the menu and builds the product list if not already built
-- called when player presses C with a computer or phone in inventory
function MarketplaceMenu:open(player)
    -- only build the product list once across all opens, its expensive to sort
    if not PRODUCT_LIST then
        PRODUCT_LIST = build_product_list()
    end
    self.active = true
    self.player = player
    self.page = 'landing'       -- always start on the landing page
    self.landingSelected = 1
    self.selected = 1
    self.scroll = 0
    self.confirming = false
    self.errTimer = 0
    self.errMsg = ''
    self.pendingBuyIdx = nil
    self.buyQty = 1
    self.qtyRepeatDir = 0
    self.qtyRepeatTimer = 0
    self.gameSelected = 1
    self.pendingMinigame = nil
-- ================== claude_changes_2026-05-23-2157 ==================
    self.pendingBusinessMenu = false
-- ====================================================================
-- ================== claude_changes_2026-05-25-1228 ==================
    self.storeTab = 'personal'
    self.wholesaleBusIdx = 1
    self.wholesaleQty = 100
    self.wholesaleConfirm = false
    self.wQtyRepeatDir = 0
    self.wQtyRepeatTimer = 0
-- ====================================================================
-- ================== claude_changes_2026-05-25-1330 ==================
    self.wholesaleRow = 1
-- ====================================================================
end

-- deactivates the menu and clears the player reference
function MarketplaceMenu:close()
    self.active = false
    self.player = nil
end

-- ================== claude_changes_2026-05-25-1330 ==================
-- open directly into wholesale mode pre-selected to targetBus (called from BusinessMenu W key)
function MarketplaceMenu:openWholesaleFor(player, targetBus)
    self:open(player)
    self.page     = 'store'
    self.storeTab = 'wholesale'
    -- find targetBus position in the retail list
    local idx = 1
    local i   = 0
    for _, b in ipairs(player.businesses or {}) do
        if b.type == 'retail' then
            i = i + 1
            if b == targetBus then idx = i; break end
        end
    end
    self.wholesaleBusIdx = idx
    self.wholesaleRow    = 2  -- start on the qty row so player can act immediately
end
-- ====================================================================


function MarketplaceMenu:showError(msg)
    self.errMsg = msg
    self.errTimer = 2.5
end

function MarketplaceMenu:showConfirm(msg, action)
    self.confirming = true
    self.confirmMsg = msg
    self.confirmAction = action
    self.errTimer = 0
end

function MarketplaceMenu:resolveConfirm(yes)
    if yes and self.confirmAction then self.confirmAction() end
    self.confirming = false
    self.confirmMsg = ''
    self.confirmAction = nil
end

function MarketplaceMenu:promptBuy(idx)
    self.pendingBuyIdx = idx
    self.buyQty = 1
    self.qtyRepeatDir = 0
    self.qtyRepeatTimer = 0
    self.confirming = true
    self.errTimer = 0
end

-- validates funds, deducts the total cost, and queues a delivery
-- delivery entry goes into player.pendingDeliveries, PlayState ticks the timer and spawns a chest
function MarketplaceMenu:buy(idx, qty)
    qty = qty or 1
    local entry = PRODUCT_LIST[idx]
    local total = entry.price * qty
    -- check if player can afford the total before deducting anything
    if self.player.cash < total then
        self.confirming = false
        self.pendingBuyIdx = nil
        self:showError('not enough cash')
        return
    end
    self.player.cash = self.player.cash - total     -- deduct the full purchase cost
    self.player.displayCash = self.player.cash      -- keep the HUD cash display in sync
    -- queue the delivery, PlayState ticks timer down each frame and spawns a chest when it hits zero
    table.insert(self.player.pendingDeliveries, {
        timer = entry.deliveryTime,
        items = { [entry.productKey] = qty },   -- items table maps product key to quantity
    })
    self:close() -- close the menu after a successful purchase
end


function MarketplaceMenu:update(dt)
    if not self.active then return end
    if self.errTimer > 0 then self.errTimer = self.errTimer - dt end

    if self.page == 'landing' then
        self:updateLanding()
    elseif self.page == 'store' then
        self:updateStore(dt)
    elseif self.page == 'games' then
        self:updateGames()
    end
end

function MarketplaceMenu:updateLanding()
    local n = #LANDING_OPTIONS
    if love.keyboard.wasPressed('up') then
        self.landingSelected = self.landingSelected > 1 and self.landingSelected - 1 or n
    elseif love.keyboard.wasPressed('down') then
        self.landingSelected = self.landingSelected < n and self.landingSelected + 1 or 1
    elseif love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter') then
-- ================== claude_changes_2026-05-23-2157 ==================
        local opt = LANDING_OPTIONS[self.landingSelected]
        if opt.id == 'businesses' then
            self.pendingBusinessMenu = true
            self:close()
        else
            self.page = opt.id
        end
-- ====================================================================
    elseif love.keyboard.wasPressed('escape') then
        self:close()
    end
end

-- handles store page input including the buy confirm dialog with qty selection
function MarketplaceMenu:updateStore(dt)
    -- ================== claude_changes_2026-05-25-1228 ==================
    if self.storeTab == 'wholesale' then
        self:updateWholesale(dt)
        return
    end
    -- ====================================================================
    if self.confirming then
        -- hold to repeat qty adjustment: first press fires immediately
        -- then 0.30 second delay before repeating every 0.07 seconds
        local dir = 0
        if love.keyboard.isDown('left') then dir = -1
        elseif love.keyboard.isDown('right') then dir = 1
        end

        if dir ~= self.qtyRepeatDir then
            -- direction changed or started, apply first press immediately
            self.qtyRepeatDir = dir
            if dir ~= 0 then
                self.buyQty = math.max(1, math.min(99, self.buyQty + dir))
                self.qtyRepeatTimer = -0.30 -- negative timer gives the initial delay
            else
                self.qtyRepeatTimer = 0
            end
        elseif dir ~= 0 then
            -- still holding, accumulate time and fire when threshold is hit
            self.qtyRepeatTimer = self.qtyRepeatTimer + dt
            while self.qtyRepeatTimer >= 0.07 do
                self.qtyRepeatTimer = self.qtyRepeatTimer - 0.07
                self.buyQty = math.max(1, math.min(99, self.buyQty + dir))
            end
        end

        -- confirm or cancel the buy confirm dialog
        if love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter')
            or love.keyboard.wasPressed('y') then
            self:buy(self.pendingBuyIdx, self.buyQty)
        elseif love.keyboard.wasPressed('escape') or love.keyboard.wasPressed('n') then
            self.confirming = false
            self.pendingBuyIdx = nil
        end
        return -- confirm dialog eats all input while open
    end

    local n = #PRODUCT_LIST
    if love.keyboard.wasPressed('up') then
        if self.selected > 1 then
            self.selected = self.selected - 1
            if self.selected < self.scroll + 1 then self.scroll = self.selected - 1 end
        else
            self.selected = n
            self.scroll = math.max(0, n - VISIBLE)
        end
        self.errTimer = 0
    elseif love.keyboard.wasPressed('down') then
        if self.selected < n then
            self.selected = self.selected + 1
            if self.selected > self.scroll + VISIBLE then self.scroll = self.selected - VISIBLE end
        else
            self.selected = 1
            self.scroll = 0
        end
        self.errTimer = 0
    elseif love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter') then
        self:promptBuy(self.selected)
    elseif love.keyboard.wasPressed('escape') then
        self.page = 'landing'
    -- ================== claude_changes_2026-05-25-1228 ==================
    elseif love.keyboard.wasPressed('w') then
        for _, b in ipairs(self.player.businesses or {}) do
            if b.type == 'retail' then
                self.storeTab = 'wholesale'
                self.wholesaleBusIdx = 1
                self.wholesaleQty = 100
                self.wholesaleConfirm = false
                break
            end
        end
    -- ====================================================================
    end
end

function MarketplaceMenu:updateGames()
    local n = #GAME_LIST
    if love.keyboard.wasPressed('up') then
        self.gameSelected = self.gameSelected > 1 and self.gameSelected - 1 or n
    elseif love.keyboard.wasPressed('down') then
        self.gameSelected = self.gameSelected < n and self.gameSelected + 1 or 1
    elseif love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter') then
        self.pendingMinigame = GAME_LIST[self.gameSelected].id
        self:close()
    elseif love.keyboard.wasPressed('escape') then
        self.page = 'landing'
    end
end


-- ================== claude_changes_2026-05-25-1228 ==================
-- returns all retail businesses in player.businesses (or empty table)
local function get_retail_businesses(player)
    local list = {}
    for _, b in ipairs(player.businesses or {}) do
        if b.type == 'retail' then list[#list+1] = b end
    end
    return list
end

-- ================== claude_changes_2026-05-25-1330 ==================
function MarketplaceMenu:updateWholesale(dt)
    local retails = get_retail_businesses(self.player)
    if #retails == 0 then self.storeTab = 'personal'; return end

    self.wholesaleBusIdx = math.max(1, math.min(#retails, self.wholesaleBusIdx))
    local bus = retails[self.wholesaleBusIdx]
    local cap = math.max(0, (bus.maxStock or 5000) - (bus.stockLevel or 0))

    -- confirm overlay intercepts all input while open
    if self.wholesaleConfirm then
        local dir = 0
        if love.keyboard.isDown('left') then dir = -1
        elseif love.keyboard.isDown('right') then dir = 1
        end
        if dir ~= self.wQtyRepeatDir then
            self.wQtyRepeatDir = dir
            if dir ~= 0 then
                self.wholesaleQty = math.max(1, math.min(cap, self.wholesaleQty + dir * 10))
                self.wQtyRepeatTimer = -0.30
            else
                self.wQtyRepeatTimer = 0
            end
        elseif dir ~= 0 then
            self.wQtyRepeatTimer = self.wQtyRepeatTimer + dt
            while self.wQtyRepeatTimer >= 0.07 do
                self.wQtyRepeatTimer = self.wQtyRepeatTimer - 0.07
                self.wholesaleQty = math.max(1, math.min(cap, self.wholesaleQty + dir * 10))
            end
        end
        if love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter')
           or love.keyboard.wasPressed('y') then
            self:buyWholesale(bus, self.wholesaleQty)
        elseif love.keyboard.wasPressed('escape') or love.keyboard.wasPressed('n') then
            self.wholesaleConfirm = false
        end
        return
    end

    -- clamp active row to valid range (auto-reorder rows only when enabled)
    local maxRow = bus.autoReorderEnabled and 5 or 3
    self.wholesaleRow = math.max(1, math.min(maxRow, self.wholesaleRow))

    -- ESC / W: back to personal tab
    if love.keyboard.wasPressed('escape') or love.keyboard.wasPressed('w') then
        self.storeTab = 'personal'; return
    end

    -- up/down: navigate rows
    if love.keyboard.wasPressed('up') then
        self.wholesaleRow = math.max(1, self.wholesaleRow - 1)
        self.wQtyRepeatDir = 0; self.wQtyRepeatTimer = 0
    elseif love.keyboard.wasPressed('down') then
        self.wholesaleRow = math.min(maxRow, self.wholesaleRow + 1)
        self.wQtyRepeatDir = 0; self.wQtyRepeatTimer = 0
    end

    local row = self.wholesaleRow

    if row == 1 then
        -- left/right: switch which retail business to restock
        if love.keyboard.wasPressed('left') then
            self.wholesaleBusIdx = math.max(1, self.wholesaleBusIdx - 1)
            self.wholesaleQty = math.min(100, math.max(1, cap))
        elseif love.keyboard.wasPressed('right') then
            self.wholesaleBusIdx = math.min(#retails, self.wholesaleBusIdx + 1)
            self.wholesaleQty = math.min(100, math.max(1, cap))
        end

    elseif row == 2 then
        -- left/right: adjust qty (hold to repeat); enter: open buy confirm
        local dir = 0
        if love.keyboard.isDown('left') then dir = -1
        elseif love.keyboard.isDown('right') then dir = 1
        end
        if dir ~= self.wQtyRepeatDir then
            self.wQtyRepeatDir = dir
            if dir ~= 0 then
                self.wholesaleQty = math.max(1, math.min(math.max(1, cap), self.wholesaleQty + dir * 10))
                self.wQtyRepeatTimer = -0.30
            else
                self.wQtyRepeatTimer = 0
            end
        elseif dir ~= 0 then
            self.wQtyRepeatTimer = self.wQtyRepeatTimer + dt
            while self.wQtyRepeatTimer >= 0.07 do
                self.wQtyRepeatTimer = self.wQtyRepeatTimer - 0.07
                self.wholesaleQty = math.max(1, math.min(math.max(1, cap), self.wholesaleQty + dir * 10))
            end
        end
        if love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter') then
            if cap > 0 then
                self.wholesaleQty = math.max(1, math.min(cap, self.wholesaleQty))
                self.wholesaleConfirm = true
            end
        end

    elseif row == 3 then
        -- left/right or enter: toggle auto-reorder on/off
        if love.keyboard.wasPressed('left') or love.keyboard.wasPressed('right')
           or love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter') then
            bus.autoReorderEnabled = not bus.autoReorderEnabled
            if not bus.autoReorderEnabled then
                self.wholesaleRow = math.min(3, self.wholesaleRow)
            end
        end

    elseif row == 4 then
        -- left/right: adjust trigger threshold in 5% steps (5% to 50%)
        if love.keyboard.wasPressed('left') then
            bus.autoReorderThreshold = math.max(0.05, (bus.autoReorderThreshold or 0.10) - 0.05)
        elseif love.keyboard.wasPressed('right') then
            bus.autoReorderThreshold = math.min(0.50, (bus.autoReorderThreshold or 0.10) + 0.05)
        end

    elseif row == 5 then
        -- left/right: adjust reorder quantity in 5% steps (10% to 100%)
        if love.keyboard.wasPressed('left') then
            bus.autoReorderQuantity = math.max(0.10, (bus.autoReorderQuantity or 0.50) - 0.05)
        elseif love.keyboard.wasPressed('right') then
            bus.autoReorderQuantity = math.min(1.00, (bus.autoReorderQuantity or 0.50) + 0.05)
        end
    end
end
-- ====================================================================

function MarketplaceMenu:buyWholesale(bus, qty)
    local unitCost = bus.unitWholeSaleCost or 4
    local total = qty * unitCost
    if self.player.cash < total then
        self.wholesaleConfirm = false
        self:showError('not enough cash')
        self.storeTab = 'personal'
        return
    end
    self.player.cash = self.player.cash - total
    self.player.displayCash = self.player.cash
    bus.stockLevel = math.min((bus.stockLevel or 0) + qty, bus.maxStock or 5000)
    self.wholesaleConfirm = false
    self:close()
end
-- ====================================================================

function MarketplaceMenu:mousepressed(x, y, button)
    if not self.active or button ~= 1 then return end

    if self.page == 'landing' then
-- ================== claude_changes_2026-05-23-2157 ==================
        local btn_ys = { BTN1_Y, BTN2_Y, BTN3_Y }
        for i, by in ipairs(btn_ys) do
            if x >= BTN_X and x <= BTN_X + BTN_W and y >= by and y <= by + BTN_H then
                self.landingSelected = i
                local opt = LANDING_OPTIONS[i]
                if opt.id == 'businesses' then
                    self.pendingBusinessMenu = true
                    self:close()
                else
                    self.page = opt.id
                end
                return
            end
        end
-- ====================================================================

    elseif self.page == 'store' then
        -- ================== claude_changes_2026-05-25-1228 ==================
        if self.storeTab == 'wholesale' then
            if self.wholesaleConfirm then
                local retails = get_retail_businesses(self.player)
                local bus = retails[math.max(1, math.min(#retails, self.wholesaleBusIdx))]
                if bus and hit(YES_BTN, x, y) then
                    self:buyWholesale(bus, self.wholesaleQty)
                elseif hit(NO_BTN, x, y) then
                    self.wholesaleConfirm = false
                end
            end
            return
        end
        -- ====================================================================
        if self.confirming then
            if hit(BUYYES_BTN, x, y) then
                self:buy(self.pendingBuyIdx, self.buyQty)
            elseif hit(BUYNO_BTN, x, y) then
                self.confirming = false
                self.pendingBuyIdx = nil
            end
            return
        end
        for i = 1, VISIBLE do
            local idx = self.scroll + i
            if idx > #PRODUCT_LIST then break end
            local ey = LIST_Y + (i - 1) * ENTRY_H
            if x >= BOX_X and x <= BOX_X + BOX_W and y >= ey and y < ey + ENTRY_H then
                self.selected = idx
                self:promptBuy(idx)
                return
            end
        end

    elseif self.page == 'games' then
        for i, _ in ipairs(GAME_LIST) do
            local ey = LIST_Y + (i - 1) * ENTRY_H
            if x >= BOX_X and x <= BOX_X + BOX_W and y >= ey and y < ey + ENTRY_H then
                self.gameSelected = i
                self.pendingMinigame = GAME_LIST[i].id
                self:close()
                return
            end
        end
    end
end


function MarketplaceMenu:render()
    if not self.active then return end
    if self.page == 'landing' then
        self:renderLanding()
    elseif self.page == 'store' then
        self:renderStore()
    elseif self.page == 'games' then
        self:renderGames()
    end
end

function MarketplaceMenu:renderLanding()
    render_panel()

    local ix = BOX_X + PAD
    local iw = BOX_W - PAD * 2

    -- title
    love.graphics.setFont(gFonts['gothic-medium'])
    set(0.4, 1, 0.55, 1)
    love.graphics.printf('MARKETPLACE', ix, BOX_Y + 10, iw, 'center')

    -- subtitle: device name from inventory
    love.graphics.setFont(gFonts['small'])
    set(0.35, 0.35, 0.35, 1)
    love.graphics.printf('select an app', ix, BOX_Y + 26, iw, 'center')

    -- divider
    set(1, 1, 1, 0.12)
    love.graphics.line(ix, BOX_Y + 38, BOX_X + BOX_W - PAD, BOX_Y + 38)

    -- option buttons
-- ================== claude_changes_2026-05-23-2157 ==================
    local btn_ys = { BTN1_Y, BTN2_Y, BTN3_Y }
    local btn_colors = {
        { bg = {0.1, 0.28, 0.12}, border = {0.3, 0.75, 0.35}, label = {0.4, 1, 0.5}    },  -- green  (store)
        { bg = {0.28, 0.16, 0.05}, border = {0.85, 0.55, 0.2}, label = {1, 0.78, 0.35}  },  -- amber  (businesses)
        { bg = {0.1, 0.18, 0.38}, border = {0.3, 0.5, 0.9},   label = {0.5, 0.75, 1}   },  -- blue   (games)
    }
-- ====================================================================

    for i, opt in ipairs(LANDING_OPTIONS) do
        local by = btn_ys[i]
        local sel = i == self.landingSelected
        local col = btn_colors[i]

        -- button bg
        local r, g, b = col.bg[1], col.bg[2], col.bg[3]
        if sel then
            set(r * 1.6, g * 1.6, b * 1.6, 1)
        else
            set(r, g, b, 1)
        end
        love.graphics.rectangle('fill', BTN_X, by, BTN_W, BTN_H, 4)

        -- border
        set(col.border[1], col.border[2], col.border[3], sel and 1 or 0.5)
        love.graphics.rectangle('line', BTN_X, by, BTN_W, BTN_H, 4)

        -- label
        love.graphics.setFont(gFonts['gothic-medium'])
        set(col.label[1], col.label[2], col.label[3], 1)
        love.graphics.printf(opt.label, BTN_X, by + 6, BTN_W, 'center')

        -- description
        love.graphics.setFont(gFonts['small'])
        set(0.65, 0.65, 0.65, 1)
        love.graphics.printf(opt.desc, BTN_X, by + 23, BTN_W, 'center')
    end

    -- footer
    set(0.3, 0.3, 0.3, 1)
    love.graphics.setFont(gFonts['small'])
    love.graphics.printf('[UP/DN] select   [ENTER] open   [ESC] close',
        ix, BOX_Y + BOX_H - 12, iw, 'center')

    set(1, 1, 1, 1)
end

function MarketplaceMenu:renderStore()
    -- ================== claude_changes_2026-05-25-1228 ==================
    if self.storeTab == 'wholesale' then
        self:renderWholesale()
        return
    end
    -- ====================================================================
    render_panel()

    local ix = BOX_X + PAD
    local iw = BOX_W - PAD * 2

    -- title + back hint
    love.graphics.setFont(gFonts['gothic-medium'])
    set(0.4, 1, 0.55, 1)
    love.graphics.print('STORE', ix, BOX_Y + 6)

    love.graphics.setFont(gFonts['small'])
    set(0.35, 0.35, 0.35, 1)
    love.graphics.print('[ESC] back', BOX_X + BOX_W - PAD - gFonts['small']:getWidth('[ESC] back'), BOX_Y + 8)

    -- player cash
    local cashStr = string.format('$%.0f', self.player.cash)
    local cashW = gFonts['small']:getWidth(cashStr)
    if self.player.cash < 0 then set(1, 0.4, 0.4, 1) else set(0.5, 1, 0.5, 1) end
    love.graphics.print(cashStr, BOX_X + BOX_W - PAD - cashW, BOX_Y + 18)

    -- page indicator
    local n = #PRODUCT_LIST
    local total_pages = math.ceil(n / VISIBLE)
    local cur_page = math.floor(self.scroll / VISIBLE) + 1
    set(0.4, 0.4, 0.4, 1)
    love.graphics.print(string.format('pg %d/%d', cur_page, total_pages), ix, BOX_Y + 26)

    set(1, 1, 1, 0.2)
    love.graphics.line(ix, BOX_Y + 38, BOX_X + BOX_W - PAD, BOX_Y + 38)

    -- product entries
    for i = 1, VISIBLE do
        local idx = self.scroll + i
        if idx > n then break end
        local entry = PRODUCT_LIST[idx]
        local ey = LIST_Y + (i - 1) * ENTRY_H
        local sel = idx == self.selected

        if sel then
            set(1, 1, 1, 0.06)
            love.graphics.rectangle('fill', BOX_X + 3, ey, BOX_W - 6, ENTRY_H - 1)
        end

        love.graphics.setFont(gFonts['small'])
        set(0.4, 1, 0.55, 1)
        love.graphics.print(sel and '>' or ' ', ix, ey + 7)

        love.graphics.setFont(gFonts['gothic-medium'])
        set(sel and 1 or 0.85, sel and 1 or 0.85, sel and 0.6 or 0.85, 1)
        love.graphics.print(entry.displayName, ix + 8, ey + 3)

        love.graphics.setFont(gFonts['small'])
        set(0.35, 0.6, 0.35, 1)
        love.graphics.print('[' .. entry.ptype .. ']', ix + 8, ey + 13)

        local sellerStr = 'Seller: ' .. entry.vendorName
        local sw = gFonts['small']:getWidth(sellerStr)
        set(0.5, 0.75, 1, 1)
        love.graphics.print(sellerStr, BOX_X + BOX_W - PAD - 44 - sw, ey + 4)

        local delivStr = string.format('Delivery: %ds', entry.deliveryTime)
        local dw = gFonts['small']:getWidth(delivStr)
        set(0.4, 0.4, 0.4, 1)
        love.graphics.print(delivStr, BOX_X + BOX_W - PAD - 44 - dw, ey + 13)

        local priceStr = fmt_money(entry.price)
        local pw = gFonts['small']:getWidth(priceStr)
        set(0.5, 1, 0.5, 1)
        love.graphics.print(priceStr, BOX_X + BOX_W - PAD - pw, ey + 7)

        set(1, 1, 1, 0.07)
        love.graphics.line(ix, ey + ENTRY_H - 1, BOX_X + BOX_W - PAD, ey + ENTRY_H - 1)
    end

    -- pending deliveries
    local pending = self.player.pendingDeliveries and #self.player.pendingDeliveries or 0
    if pending > 0 then
        set(1, 0.8, 0.2, 1)
        love.graphics.setFont(gFonts['small'])
        love.graphics.printf(
            string.format('%d delivery%s en route', pending, pending == 1 and '' or 's'),
            ix, BOX_Y + BOX_H - 22, iw, 'center'
        )
    end

    local footY = BOX_Y + BOX_H - 12
    if self.errTimer > 0 then
        set(1, 0.3, 0.3, 1)
        love.graphics.setFont(gFonts['small'])
        love.graphics.printf(self.errMsg, ix, footY, iw, 'center')
    else
        -- ================== claude_changes_2026-05-25-1228 ==================
        local hasRetail = false
        for _, b in ipairs(self.player.businesses or {}) do
            if b.type == 'retail' then hasRetail = true; break end
        end
        local footHint = hasRetail
            and '[UP/DN] scroll  [ENTER] buy  [W] wholesale  [ESC] back'
            or  '[UP/DN] scroll   [ENTER] buy   [ESC] back'
        -- ====================================================================
        set(0.35, 0.35, 0.35, 1)
        love.graphics.setFont(gFonts['small'])
        love.graphics.printf(footHint, ix, footY, iw, 'center')
    end

    if self.confirming then self:renderBuyConfirm() end

    set(1, 1, 1, 1)
end

function MarketplaceMenu:renderBuyConfirm()
    local entry = PRODUCT_LIST[self.pendingBuyIdx]
    local qty = self.buyQty
    local total = entry.price * qty
    local canAfford = self.player.cash >= total

    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle('fill', 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)

    set(0.08, 0.08, 0.13, 0.97)
    love.graphics.rectangle('fill', CONF_X, BUYCONF_Y, CONF_W, BUYCONF_H, 4)
    set(0.45, 0.45, 0.6, 1)
    love.graphics.rectangle('line', CONF_X, BUYCONF_Y, CONF_W, BUYCONF_H, 4)

    local iw = CONF_W - 16
    local ix = CONF_X + 8

    love.graphics.setFont(gFonts['gothic-medium'])
    set(1, 1, 1, 1)
    love.graphics.printf(entry.displayName, ix, BUYCONF_Y + 8, iw, 'center')

    love.graphics.setFont(gFonts['small'])
    set(0.5, 0.75, 1, 1)
    love.graphics.printf(entry.vendorName, ix, BUYCONF_Y + 22, iw, 'center')

    -- qty selector
    set(0.5, 0.5, 0.5, 1)
    love.graphics.printf('<', ix, BUYCONF_Y + 38, iw, 'left')
    love.graphics.printf('>', ix, BUYCONF_Y + 38, iw, 'right')
    set(1, 1, 1, 1)
    love.graphics.printf(tostring(qty), ix, BUYCONF_Y + 38, iw, 'center')

    -- total price
    if canAfford then set(0.4, 1, 0.4, 1) else set(1, 0.35, 0.35, 1) end
    love.graphics.printf(string.format('%s total', fmt_money(total)), ix, BUYCONF_Y + 54, iw, 'center')

    -- yes button
    set(0.15, 0.45, 0.15, 1)
    love.graphics.rectangle('fill', BUYYES_BTN.x, BUYYES_BTN.y, BUYYES_BTN.w, BUYYES_BTN.h, 3)
    set(0.4, 1, 0.4, 1)
    love.graphics.rectangle('line', BUYYES_BTN.x, BUYYES_BTN.y, BUYYES_BTN.w, BUYYES_BTN.h, 3)
    set(1, 1, 1, 1)
    love.graphics.printf('YES', BUYYES_BTN.x, BUYYES_BTN.y + 3, BUYYES_BTN.w, 'center')

    -- no button
    set(0.45, 0.1, 0.1, 1)
    love.graphics.rectangle('fill', BUYNO_BTN.x, BUYNO_BTN.y, BUYNO_BTN.w, BUYNO_BTN.h, 3)
    set(1, 0.35, 0.35, 1)
    love.graphics.rectangle('line', BUYNO_BTN.x, BUYNO_BTN.y, BUYNO_BTN.w, BUYNO_BTN.h, 3)
    set(1, 1, 1, 1)
    love.graphics.printf('NO', BUYNO_BTN.x, BUYNO_BTN.y + 3, BUYNO_BTN.w, 'center')

    set(1, 1, 1, 1)
end

-- ================== claude_changes_2026-05-25-1228 ==================
function MarketplaceMenu:renderWholesale()
    render_panel()

    local ix = BOX_X + PAD
    local iw = BOX_W - PAD * 2

    -- title + back hint
    love.graphics.setFont(gFonts['gothic-medium'])
    set(1, 0.78, 0.35, 1)
    love.graphics.print('WHOLESALE', ix, BOX_Y + 6)

    love.graphics.setFont(gFonts['small'])
    set(0.35, 0.35, 0.35, 1)
    local backHint = '[W/ESC] back'
    love.graphics.print(backHint, BOX_X + BOX_W - PAD - gFonts['small']:getWidth(backHint), BOX_Y + 8)

    -- player cash
    local cashStr = string.format('$%.0f', self.player.cash)
    local cashW = gFonts['small']:getWidth(cashStr)
    if self.player.cash < 0 then set(1, 0.4, 0.4, 1) else set(0.5, 1, 0.5, 1) end
    love.graphics.print(cashStr, BOX_X + BOX_W - PAD - cashW, BOX_Y + 20)

    set(1, 1, 1, 0.2)
    love.graphics.line(ix, BOX_Y + 34, BOX_X + BOX_W - PAD, BOX_Y + 34)

    local retails = get_retail_businesses(self.player)
    if #retails == 0 then
        love.graphics.setFont(gFonts['small'])
        set(0.5, 0.5, 0.5, 1)
        love.graphics.printf('No retail businesses owned.', ix, BOX_Y + 80, iw, 'center')
        set(1, 1, 1, 1)
        return
    end

    self.wholesaleBusIdx = math.max(1, math.min(#retails, self.wholesaleBusIdx))
    local bus = retails[self.wholesaleBusIdx]
    local stock    = bus.stockLevel or 0
    local maxStock = bus.maxStock   or 5000
    local cap      = math.max(0, maxStock - stock)
    local unitCost = bus.unitWholeSaleCost or 4
    local row      = self.wholesaleRow

    -- row 1: business selector
    local r1y = BOX_Y + 42
    love.graphics.setFont(gFonts['small'])
    if row == 1 then set(1, 0.95, 0.55, 1) else set(0.55, 0.55, 0.55, 1) end
    love.graphics.print((row == 1 and '> ' or '  ') .. 'Restocking:', ix, r1y)

    local busLabel = (bus.displayName or bus.type)
    if #retails > 1 then
        busLabel = string.format('< %s (%d/%d) >', busLabel, self.wholesaleBusIdx, #retails)
        if row == 1 then set(1, 1, 1, 1) else set(0.75, 0.75, 0.6, 1) end
    else
        set(0.9, 0.9, 0.75, 1)
    end
    love.graphics.setFont(gFonts['gothic-medium'])
    love.graphics.printf(busLabel, ix, r1y, iw, 'right')

    -- stock level row (display only, not selectable)
    local r_stock_y = r1y + 16
    love.graphics.setFont(gFonts['small'])
    set(0.45, 0.45, 0.45, 1)
    love.graphics.print('Stock:', ix, r_stock_y)
    local stockColor = stock / maxStock > 0.5 and {0.4, 1, 0.4} or
                       stock / maxStock > 0.15 and {1, 0.85, 0.3} or {1, 0.4, 0.4}
    set(stockColor[1], stockColor[2], stockColor[3], 1)
    love.graphics.printf(string.format('%d / %d', stock, maxStock), ix, r_stock_y, iw, 'right')

    -- stock progress bar
    local barW = iw
    local barH = 6
    local barY = r_stock_y + 14
    set(0.15, 0.15, 0.15, 1)
    love.graphics.rectangle('fill', ix, barY, barW, barH, 2)
    local fillW = math.floor(barW * (stock / maxStock))
    set(stockColor[1], stockColor[2], stockColor[3], 0.85)
    if fillW > 0 then love.graphics.rectangle('fill', ix, barY, fillW, barH, 2) end
    set(0.4, 0.4, 0.4, 1)
    love.graphics.rectangle('line', ix, barY, barW, barH, 2)

    set(1, 1, 1, 0.15)
    love.graphics.line(ix, barY + 10, BOX_X + BOX_W - PAD, barY + 10)

    -- row 2: manual order qty
    local r2y = barY + 18
    love.graphics.setFont(gFonts['small'])
    if row == 2 then set(1, 0.95, 0.55, 1) else set(0.55, 0.55, 0.55, 1) end
    love.graphics.print((row == 2 and '> ' or '  ') .. 'Order Qty:', ix, r2y)

    if cap == 0 then
        set(0.45, 0.45, 0.45, 1)
        love.graphics.printf('FULL', ix, r2y, iw, 'right')
    else
        local qty = self.wholesaleQty
        if row == 2 then set(0.6, 0.6, 0.6, 1) else set(0.4, 0.4, 0.4, 1) end
        love.graphics.printf('<', ix, r2y, iw - 30, 'right')
        love.graphics.printf('>', ix + 30, r2y, iw - 30, 'right')
        if row == 2 then set(1, 1, 0.8, 1) else set(0.8, 0.8, 0.65, 1) end
        love.graphics.setFont(gFonts['gothic-medium'])
        love.graphics.printf(tostring(qty), ix, r2y, iw, 'right')

        love.graphics.setFont(gFonts['small'])
        set(0.4, 0.4, 0.45, 1)
        love.graphics.print(string.format('$%d/unit', unitCost), ix, r2y + 12)
        local total = qty * unitCost
        local canAfford = self.player.cash >= total
        if canAfford then set(0.4, 1, 0.4, 1) else set(1, 0.35, 0.35, 1) end
        love.graphics.printf(string.format('Total: $%d', total), ix, r2y + 12, iw, 'right')
    end

    set(1, 1, 1, 0.15)
    local divY = r2y + 26
    love.graphics.line(ix, divY, BOX_X + BOX_W - PAD, divY)

    -- ================== claude_changes_2026-05-25-1330 ==================
    -- auto-reorder section (rows 3-5)
    local arY = divY + 6  -- top of auto-reorder section

    -- row 3: enable / disable toggle
    local r3y = arY
    love.graphics.setFont(gFonts['small'])
    if row == 3 then set(1, 0.95, 0.55, 1) else set(0.55, 0.55, 0.55, 1) end
    love.graphics.print((row == 3 and '> ' or '  ') .. 'Auto-reorder:', ix, r3y)

    if bus.autoReorderEnabled then
        set(0.3, 1, 0.45, 1)
        love.graphics.printf('[ON]', ix, r3y, iw, 'right')
    else
        set(0.5, 0.5, 0.5, 1)
        love.graphics.printf('[OFF]', ix, r3y, iw, 'right')
    end

    -- rows 4 and 5: threshold and qty (dimmed when auto-reorder is off)
    local enabled = bus.autoReorderEnabled
    local dimAlpha = enabled and 1 or 0.35

    -- row 4: trigger threshold %
    local r4y = r3y + 13
    local thrPct = math.floor((bus.autoReorderThreshold or 0.10) * 100 + 0.5)
    local thrUnits = math.floor(maxStock * (bus.autoReorderThreshold or 0.10))
    if row == 4 and enabled then set(1, 0.95, 0.55, 1)
    else set(0.55 * dimAlpha, 0.55 * dimAlpha, 0.55 * dimAlpha, 1) end
    love.graphics.print((row == 4 and enabled and '> ' or '  ') .. 'Trigger at:', ix, r4y)
    if enabled then
        if row == 4 then set(0.6, 0.6, 0.6, 1) else set(0.35, 0.35, 0.35, 1) end
        love.graphics.printf('<', ix, r4y, iw - 60, 'right')
        love.graphics.printf('>', ix + 30, r4y, iw - 60, 'right')
    end
    if row == 4 and enabled then set(1, 1, 0.8, 1) else set(0.7 * dimAlpha, 0.7 * dimAlpha, 0.55 * dimAlpha, 1) end
    love.graphics.printf(string.format('%d%%  (%d units)', thrPct, thrUnits), ix, r4y, iw, 'right')

    -- row 5: reorder quantity %
    local r5y = r4y + 13
    local buyPct = math.floor((bus.autoReorderQuantity or 0.50) * 100 + 0.5)
    local buyUnits = math.floor(maxStock * (bus.autoReorderQuantity or 0.50))
    if row == 5 and enabled then set(1, 0.95, 0.55, 1)
    else set(0.55 * dimAlpha, 0.55 * dimAlpha, 0.55 * dimAlpha, 1) end
    love.graphics.print((row == 5 and enabled and '> ' or '  ') .. 'Reorder qty:', ix, r5y)
    if enabled then
        if row == 5 then set(0.6, 0.6, 0.6, 1) else set(0.35, 0.35, 0.35, 1) end
        love.graphics.printf('<', ix, r5y, iw - 60, 'right')
        love.graphics.printf('>', ix + 30, r5y, iw - 60, 'right')
    end
    if row == 5 and enabled then set(1, 1, 0.8, 1) else set(0.7 * dimAlpha, 0.7 * dimAlpha, 0.55 * dimAlpha, 1) end
    love.graphics.printf(string.format('%d%%  (%d units)', buyPct, buyUnits), ix, r5y, iw, 'right')
    -- ====================================================================

    -- footer
    set(0.35, 0.35, 0.35, 1)
    love.graphics.setFont(gFonts['small'])
    love.graphics.printf('[UP/DN] row   [LFT/RT] adjust   [ENTER] buy   [W/ESC] back',
        ix, BOX_Y + BOX_H - 12, iw, 'center')

    -- wholesale confirm overlay
    if self.wholesaleConfirm then
        local qty   = self.wholesaleQty
        local total = qty * unitCost
        local msg   = string.format('Buy %d units of stock?\nCost: $%d', qty, total)
        love.graphics.setColor(0, 0, 0, 0.55)
        love.graphics.rectangle('fill', 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
        set(0.08, 0.08, 0.13, 0.97)
        love.graphics.rectangle('fill', CONF_X, CONF_Y, CONF_W, CONF_H, 4)
        set(0.7, 0.6, 0.2, 1)
        love.graphics.rectangle('line', CONF_X, CONF_Y, CONF_W, CONF_H, 4)
        love.graphics.setFont(gFonts['small'])
        set(1, 1, 1, 1)
        love.graphics.printf(msg, CONF_X + 8, CONF_Y + 8, CONF_W - 16, 'center')
        set(0.15, 0.45, 0.15, 1)
        love.graphics.rectangle('fill', YES_BTN.x, YES_BTN.y, YES_BTN.w, YES_BTN.h, 3)
        set(0.4, 1, 0.4, 1)
        love.graphics.rectangle('line', YES_BTN.x, YES_BTN.y, YES_BTN.w, YES_BTN.h, 3)
        set(1, 1, 1, 1)
        love.graphics.printf('YES', YES_BTN.x, YES_BTN.y + 3, YES_BTN.w, 'center')
        set(0.45, 0.1, 0.1, 1)
        love.graphics.rectangle('fill', NO_BTN.x, NO_BTN.y, NO_BTN.w, NO_BTN.h, 3)
        set(1, 0.35, 0.35, 1)
        love.graphics.rectangle('line', NO_BTN.x, NO_BTN.y, NO_BTN.w, NO_BTN.h, 3)
        set(1, 1, 1, 1)
        love.graphics.printf('NO', NO_BTN.x, NO_BTN.y + 3, NO_BTN.w, 'center')
    end

    set(1, 1, 1, 1)
end
-- ====================================================================

function MarketplaceMenu:renderGames()
    render_panel()

    local ix = BOX_X + PAD
    local iw = BOX_W - PAD * 2

    -- title + back hint
    love.graphics.setFont(gFonts['gothic-medium'])
    set(0.5, 0.75, 1, 1)
    love.graphics.print('GAMES', ix, BOX_Y + 6)

    love.graphics.setFont(gFonts['small'])
    set(0.35, 0.35, 0.35, 1)
    love.graphics.print('[ESC] back', BOX_X + BOX_W - PAD - gFonts['small']:getWidth('[ESC] back'), BOX_Y + 8)

    set(1, 1, 1, 0.2)
    love.graphics.line(ix, BOX_Y + 28, BOX_X + BOX_W - PAD, BOX_Y + 28)

    -- game entries
    for i, game in ipairs(GAME_LIST) do
        local ey = BOX_Y + 38 + (i - 1) * 36
        local sel = i == self.gameSelected

        if sel then
            set(0.1, 0.18, 0.38, 1)
            love.graphics.rectangle('fill', BOX_X + 3, ey, BOX_W - 6, 32, 3)
            set(0.3, 0.5, 0.9, 0.6)
            love.graphics.rectangle('line', BOX_X + 3, ey, BOX_W - 6, 32, 3)
        end

        love.graphics.setFont(gFonts['small'])
        set(0.5, 0.75, 1, 1)
        love.graphics.print(sel and '>' or ' ', ix, ey + 10)

        love.graphics.setFont(gFonts['gothic-medium'])
        set(sel and 1 or 0.75, sel and 1 or 0.75, sel and 1 or 0.85, 1)
        love.graphics.print(game.displayName, ix + 10, ey + 4)

        love.graphics.setFont(gFonts['small'])
        set(0.5, 0.5, 0.55, 1)
        love.graphics.print(game.description, ix + 10, ey + 18)
    end

    set(0.35, 0.35, 0.35, 1)
    love.graphics.setFont(gFonts['small'])
    love.graphics.printf('[UP/DN] select   [ENTER] play   [ESC] back',
        ix, BOX_Y + BOX_H - 12, iw, 'center')

    set(1, 1, 1, 1)
end

return MarketplaceMenu
