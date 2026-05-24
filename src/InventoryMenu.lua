--[[
    Empire Engine
    Based on CS50 2D Coursework

    InventoryMenu.lua

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    Overlay menu opened with 'i'. Displays the player's carried
    items and lets them consume food, bevreages, and bandages to
    restore hunger, thirst, and health stats.
]]

-- inventory overlay, opened with I key, shows all items player currently carries
-- food and beverages can be consumed to restore hunger, thirst, and health
-- non consumable types like computer and phone just show as "owned"
InventoryMenu = Class{}

-- layout constants, panel centered on virtual screen
local VISIBLE = 6       -- how many items are visible without scrolling
local BOX_W = 280
local BOX_H = 168
local BOX_X = math.floor((VIRTUAL_WIDTH - BOX_W) / 2)
local BOX_Y = math.floor((VIRTUAL_HEIGHT - BOX_H) / 2)
local PAD = 10
local ENTRY_H = 22      -- pixels per item row
local LIST_Y = BOX_Y + 38  -- where the item list starts below the header

-- only these two types can be consumed from the inventory
local CONSUMABLE = { food = true, beverage = true }

-- shorthand for setColor
local function set(r, g, b, a) love.graphics.setColor(r, g, b, a or 1) end

-- builds a sorted flat list of non empty inventory slots for rendering
-- skips any product key that doesnt have a matching entry in PRODUCTS
local function build_item_list(inventory)
    local list = {}
    for productKey, qty in pairs(inventory) do
        if qty > 0 and PRODUCTS[productKey] then
            list[#list + 1] = {
                productKey = productKey,
                product = PRODUCTS[productKey],
                qty = qty,
            }
        end
    end
    -- sort consumables first, then alphabetically within each group
    -- non consumables go at the bottom since they cant be used from here
    table.sort(list, function(a, b)
        local ac = CONSUMABLE[a.product.type] and 0 or 1
        local bc = CONSUMABLE[b.product.type] and 0 or 1
        if ac ~= bc then return ac < bc end
        return a.product.displayName < b.product.displayName
    end)
    return list
end

-- builds the short effect description shown below each consumable item name
-- healthScore is divided by 2 because consume only applies half the score
local function effect_str(product)
    local parts = {}
    if product.type == 'food' then
        parts[#parts + 1] = 'Hunger +1'    -- all food restores one hunger level
    elseif product.type == 'beverage' then
        parts[#parts + 1] = 'Thirst +1'    -- all beverages restore one thirst level
    end
    if product.healthScore and product.healthScore ~= 0 then
        local delta = product.healthScore / 2  -- halved on consume
        parts[#parts + 1] = string.format('Health %+.0f', delta)
    end
    return table.concat(parts, '  ')
end


-- sets all state fields to safe defaults, called once at startup
function InventoryMenu:init()
    self.active = false
    self.player = nil
    self.selected = 1
    self.scroll = 0
    self.items = {}         -- flat list built from player.inventory each open
    self.flashMsg = ''      -- temporary message shown at the bottom of the panel
    self.flashTimer = 0     -- how many seconds the flash message stays visible
end

-- activates the inventory and builds the item list from the current player inventory
function InventoryMenu:open(player)
    self.active = true
    self.player = player
    self.selected = 1
    self.scroll = 0
    self.flashMsg = ''
    self.flashTimer = 0
    self.items = build_item_list(player.inventory) -- snapshot the inventory at open time
end

-- deactivates the menu and clears the player reference
function InventoryMenu:close()
    self.active = false
    self.player = nil
end

-- rebuilds the item list after a consume and clamps the selection index
-- needed because the list can shrink when an item hits zero qty
function InventoryMenu:refresh()
    self.items = build_item_list(self.player.inventory)
    -- clamp selection so it doesnt point past the end of the new shorter list
    if self.selected > #self.items then
        self.selected = math.max(1, #self.items)
    end
    self.scroll = math.max(0, math.min(self.scroll, #self.items - VISIBLE))
end

-- shows a temporary message at the bottom of the panel for 1.8 seconds
function InventoryMenu:flash(msg)
    self.flashMsg = msg
    self.flashTimer = 1.8
end

-- applies the item effects to the player and decrements the inventory count
-- only works for food and beverage types, everthing else shows an error flash
function InventoryMenu:consume(idx)
    local entry = self.items[idx]
    if not entry then return end
    local product = entry.product

    -- guard against consuming non consumable types like computer or car
    if not CONSUMABLE[product.type] then
        self:flash('cannot consume this item')
        return
    end

    -- food restores 33 percent of the max hunger value
    if product.type == 'food' then
        self.player.hunger = math.min(HUNGER_MAX, self.player.hunger + HUNGER_MAX * 0.33)
    -- beverage restores 33 percent of the max thirst value
    elseif product.type == 'beverage' then
        self.player.thirst = math.min(THIRST_MAX, self.player.thirst + THIRST_MAX * 0.33)
    end
    -- healthScore is halved before applying, max player health is 6
    if product.healthScore and product.healthScore ~= 0 then
        self.player.health = math.min(6, self.player.health + product.healthScore / 2)
    end

    -- decrement the qty, remove the key entirely when it hits zero
    self.player.inventory[entry.productKey] = entry.qty - 1
    if self.player.inventory[entry.productKey] <= 0 then
        self.player.inventory[entry.productKey] = nil
    end

    self:flash('consumed ' .. product.displayName)
    self:refresh() -- rebuild the list since qty changed
end

function InventoryMenu:update(dt)
    if not self.active then return end
    if self.flashTimer > 0 then self.flashTimer = self.flashTimer - dt end

    local n = #self.items
    if n == 0 then
        if love.keyboard.wasPressed('escape') or love.keyboard.wasPressed('i') then
            self:close()
        end
        return
    end

    if love.keyboard.wasPressed('up') then
        if self.selected > 1 then
            self.selected = self.selected - 1
            if self.selected < self.scroll + 1 then
                self.scroll = self.selected - 1
            end
        else
            self.selected = n
            self.scroll = math.max(0, n - VISIBLE)
        end
    elseif love.keyboard.wasPressed('down') then
        if self.selected < n then
            self.selected = self.selected + 1
            if self.selected > self.scroll + VISIBLE then
                self.scroll = self.selected - VISIBLE
            end
        else
            self.selected = 1
            self.scroll = 0
        end
    elseif love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter') then
        self:consume(self.selected)
    elseif love.keyboard.wasPressed('escape') then
        self:close()
    end
end

function InventoryMenu:mousepressed(x, y, button)
    if not self.active or button ~= 1 then return end
    for i = 1, VISIBLE do
        local idx = self.scroll + i
        if idx > #self.items then break end
        local ey = LIST_Y + (i - 1) * ENTRY_H
        if x >= BOX_X and x <= BOX_X + BOX_W and y >= ey and y < ey + ENTRY_H then
            if idx == self.selected then
                self:consume(idx)
            else
                self.selected = idx
            end
            return
        end
    end
end


function InventoryMenu:render()
    if not self.active then return end

    local ix = BOX_X + PAD
    local iw = BOX_W - PAD * 2

    -- panel
    set(0.7, 0.7, 0.75, 0.9)
    love.graphics.rectangle('fill', BOX_X, BOX_Y, BOX_W, BOX_H, 3)
    set(0.05, 0.05, 0.08, 0.96)
    love.graphics.rectangle('fill', BOX_X + 2, BOX_Y + 2, BOX_W - 4, BOX_H - 4, 3)

    -- title
    love.graphics.setFont(gFonts['gothic-medium'])
    set(0.9, 0.85, 1, 1)
    love.graphics.print('INVENTORY', ix, BOX_Y + 6)

    -- item count (top right)
    love.graphics.setFont(gFonts['small'])
    local n = #self.items
    set(0.4, 0.4, 0.4, 1)
    local countStr = string.format('%d item%s', n, n == 1 and '' or 's')
    local cw = gFonts['small']:getWidth(countStr)
    love.graphics.print(countStr, BOX_X + BOX_W - PAD - cw, BOX_Y + 8)

    -- header divider
    set(1, 1, 1, 0.18)
    love.graphics.line(ix, BOX_Y + 32, BOX_X + BOX_W - PAD, BOX_Y + 32)

    -- empty state
    if n == 0 then
        set(0.4, 0.4, 0.4, 1)
        love.graphics.setFont(gFonts['small'])
        love.graphics.printf('inventory is empty', ix, BOX_Y + BOX_H / 2 - 4, iw, 'center')
        set(0.3, 0.3, 0.3, 1)
        love.graphics.printf('[ESC] close', ix, BOX_Y + BOX_H - 12, iw, 'center')
        set(1, 1, 1, 1)
        return
    end

    -- item entries
    for i = 1, VISIBLE do
        local idx = self.scroll + i
        if idx > n then break end

        local entry = self.items[idx]
        local product = entry.product
        local ey = LIST_Y + (i - 1) * ENTRY_H
        local sel = idx == self.selected
        local consumable = CONSUMABLE[product.type]

        if sel then
            set(1, 1, 1, 0.07)
            love.graphics.rectangle('fill', BOX_X + 3, ey, BOX_W - 6, ENTRY_H - 1)
        end

        -- cursor
        love.graphics.setFont(gFonts['small'])
        set(0.75, 0.6, 1, 1)
        love.graphics.print(sel and '>' or ' ', ix, ey + 7)

        -- item name
        love.graphics.setFont(gFonts['gothic-medium'])
        if consumable then
            set(sel and 1 or 0.85, sel and 1 or 0.85, sel and 1 or 0.85, 1)
        else
            set(0.55, 0.55, 0.55, 1)
        end
        love.graphics.print(product.displayName, ix + 8, ey + 4)

        -- effect preview (below name, only for consumables)
        love.graphics.setFont(gFonts['small'])
        if consumable then
            set(0.45, 0.7, 0.45, 1)
            love.graphics.print(effect_str(product), ix + 8, ey + 13)
        else
            set(0.35, 0.35, 0.35, 1)
            love.graphics.print('owned', ix + 8, ey + 13)
        end

        -- quantity (right side)
        local qtyStr = 'x' .. entry.qty
        local qw = gFonts['small']:getWidth(qtyStr)
        set(sel and 0.9 or 0.55, sel and 0.9 or 0.55, sel and 0.9 or 0.55, 1)
        love.graphics.print(qtyStr, BOX_X + BOX_W - PAD - qw, ey + 7)

        -- row divider
        set(1, 1, 1, 0.06)
        love.graphics.line(ix, ey + ENTRY_H - 1, BOX_X + BOX_W - PAD, ey + ENTRY_H - 1)
    end

    -- footer: flash message or hint
    local footY = BOX_Y + BOX_H - 12
    if self.flashTimer > 0 then
        set(0.6, 1, 0.6, 1)
        love.graphics.setFont(gFonts['small'])
        love.graphics.printf(self.flashMsg, ix, footY, iw, 'center')
    else
        set(0.35, 0.35, 0.35, 1)
        love.graphics.setFont(gFonts['small'])
        love.graphics.printf('[UP/DN] select   [ENTER] consume   [ESC] close', ix, footY, iw, 'center')
    end

    set(1, 1, 1, 1)
end

return InventoryMenu
