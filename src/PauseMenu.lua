--[[
    Empire Engine
    Based on CS50 2D Coursework
    PauseMenu

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    Pause overlay. Two views: main list and sleep sub-menu.
    Main:  Resume | Sleep... | Save | Load | Quit
    Sleep: 1 Week | 1 Month | 3 Months | 1 Year | Back

    Sets self.sleepRequested (game-seconds) when player comfirms a sleep duration.
    PlayState reads that value to start the fast-forward simulation.
]]

-- pause overlay shown when player presses P during gameplay
-- two views: main list and the sleep duration sub menu
-- main list: Resume, Sleep, Save, Load, Quit
-- sleep list: duration options that set sleepRequested for PlayState to read
PauseMenu = Class{}

-- layout constants, panel centered on the virtual screen
local BOX_W = 150
local BOX_H = 134
local BOX_X = math.floor((384 - BOX_W) / 2)
local BOX_Y = math.floor((216 - BOX_H) / 2)
local PAD = 10
local ITEM_H = 16   -- pixels per menu item row

-- confirm popup dimensions, same size used across all menus for visual consistency
local CONF_W = 168
local CONF_H = 66
local CONF_X = math.floor((384 - CONF_W) / 2)
local CONF_Y = math.floor((216 - CONF_H) / 2)
local YES_BTN = { x = CONF_X + 12, y = CONF_Y + 44, w = 56, h = 14 }
local NO_BTN = { x = CONF_X + 100, y = CONF_Y + 44, w = 56, h = 14 }

-- five main pause menu options, Load starts disabled until a save exists
local MAIN_ITEMS = {
    { label = 'Resume' },
    { label = 'Sleep... (warp)' },  -- opens the sleep sub menu
    { label = 'Save' },
    { label = 'Load', disabled = true, whenDisabled = 'no save' }, -- enabled dynamicaly each frame
    { label = 'Quit' },
}

-- sleep duration options, secs is the game time to fast forward in seconds
-- values are multiples of SECONDS_PER_MONTH from constants.lua
local SLEEP_ITEMS = {
    { label = '1 Week', secs = math.floor(SECONDS_PER_MONTH / 4) }, -- quarter of a game month
    { label = '1 Month',secs = SECONDS_PER_MONTH },
    { label = '3 Months', secs = SECONDS_PER_MONTH * 3 },
    { label = '1 Year', secs = SECONDS_PER_MONTH * 12 },
    { label = 'Back' },  -- no secs field, just goes back to main menu
}

local function set(r, g, b, a) love.graphics.setColor(r, g, b, a or 1) end

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


-- sets all state fields to defualts on startup
function PauseMenu:init()
    self.active = false
    self.mode = 'main'          -- either "main" or "sleep" depending on which view is showing
    self.mainSel = 1            -- which main menu item is highlighted
    self.sleepSel = 1           -- which sleep duration is highlighted
    self.sleepRequested = nil   -- PlayState reads this to start the fast forward, then clears it
    self.confirming = false
    self.confirmMsg = ''
    self.confirmAction = nil
end

-- resets all state to main mode each time the menu opens
-- called by PlayState when player presses P
function PauseMenu:open()
    self.active = true
    self.mode = 'main'
    self.mainSel = 1
    self.sleepSel = 1
    self.sleepRequested = nil
    self.saveRequested = nil    -- PlayState reads and clears this to trigger the actual save
    self.loadRequested = nil    -- same pattern for load
    self.confirming = false
    self.confirmMsg = ''
    self.confirmAction = nil
end

-- deactivates the menu
function PauseMenu:close()
    self.active = false
end

-- pops the confirm dialog with a message, stores the action to run if player says yes
function PauseMenu:showConfirm(msg, action)
    self.confirming = true
    self.confirmMsg = msg
    self.confirmAction = action -- closure that runs when player confirms
end

-- runs the stored action if player pressed yes, then resets confirm state
function PauseMenu:resolveConfirm(yes)
    if yes and self.confirmAction then self.confirmAction() end
    self.confirming = false
    self.confirmMsg = ''
    self.confirmAction = nil
end

-- skips disabled items when navigating with arrow keys
-- wraps around the list in the given direction until a non disabled item is found
local function next_enabled(items, cur, dir)
    local n = #items
    local i = cur
    for _ = 1, n do
        i = ((i - 1 + dir) % n) + 1
        if not items[i].disabled then return i end
    end
    return cur -- no enabled items found, stay on current
end

-- update

-- handles input for both the main menu and the sleep sub menu
-- confirm popup takes all input while it is open so nothing else fires
function PauseMenu:update(dt)
    if not self.active then return end

    -- check every frame whether a save file exists, enables or disables the Load option
    MAIN_ITEMS[4].disabled = not SaveLoad.hasSave()

    -- confirm popup eats all input, nothing else gets processed while its showing
    if self.confirming then
        if love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter')
           or love.keyboard.wasPressed('y') then
            self:resolveConfirm(true)
        elseif love.keyboard.wasPressed('escape') or love.keyboard.wasPressed('n') then
            self:resolveConfirm(false)
        end
        return
    end

    if self.mode == 'main' then
        -- navigation skips disabled items, so Load is skipped when no save exists
        if love.keyboard.wasPressed('up') then
            self.mainSel = next_enabled(MAIN_ITEMS, self.mainSel, -1)
        elseif love.keyboard.wasPressed('down') then
            self.mainSel = next_enabled(MAIN_ITEMS, self.mainSel, 1)
        elseif love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter') then
            self:selectMain()
        elseif love.keyboard.wasPressed('escape') then
            self:close() -- escape from main menu closes the whole pause menu
        end
    else
        -- sleep sub menu, no disabled items so plain wrap navigation
        if love.keyboard.wasPressed('up') then
            self.sleepSel = self.sleepSel > 1 and self.sleepSel - 1 or #SLEEP_ITEMS
        elseif love.keyboard.wasPressed('down') then
            self.sleepSel = self.sleepSel < #SLEEP_ITEMS and self.sleepSel + 1 or 1
        elseif love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter') then
            self:selectSleep()
        elseif love.keyboard.wasPressed('escape') then
            self.mode = 'main'  -- escape from sleep sub menu goes back to main menu
            self.mainSel = 2    -- restore cursor to the Sleep item
        end
    end
end

-- dispatches the selected main menu action
-- disabled items are guarded against here as a second safety check
function PauseMenu:selectMain()
    local item = MAIN_ITEMS[self.mainSel]
    if item.disabled then return end -- shouldnt happen but guard anyway

    if item.label == 'Resume' then
        self:close()
    elseif item.label == 'Sleep... (warp)' then
        -- switch to the sleep sub menu
        self.mode = 'sleep'
        self.sleepSel = 1
    elseif item.label == 'Save' then
        -- confirm before saving, then set flag for PlayState to handle the actual write
        self:showConfirm('Save game?', function()
            self.saveRequested = true
            self:close()
        end)
    elseif item.label == 'Load' then
        -- warn player that current progress will be lost before loading
        self:showConfirm('Load saved game?\nCurrent progress lost.', function()
            self.loadRequested = true
            self:close()
        end)
    elseif item.label == 'Quit' then
        self:showConfirm('Quit game?', function()
            love.event.quit()
        end)
    end
end

-- dispatches the selected sleep duration
-- Back returns to the main menu, any duration with secs sets sleepRequested
function PauseMenu:selectSleep()
    local item = SLEEP_ITEMS[self.sleepSel]

    if item.label == 'Back' then
        self.mode = 'main'
        self.mainSel = 2    -- return cursor to the Sleep item in main menu
    elseif item.secs then
        -- confirm the duration then set sleepRequested, PlayState reads and clears it
        self:showConfirm('Sleep for ' .. item.label .. '?', function()
            self.sleepRequested = item.secs
        end)
    end
end

function PauseMenu:mousepressed(x, y, button)
    if not self.active or button ~= 1 then return end

    if self.confirming then
        if hit(YES_BTN, x, y) then
            self:resolveConfirm(true)
        elseif hit(NO_BTN, x, y) then
            self:resolveConfirm(false)
        end
        return
    end

    -- only respond to clicks inside the box
    if x < BOX_X or x > BOX_X + BOX_W then return end

    if self.mode == 'main' then
        for i, item in ipairs(MAIN_ITEMS) do
            local iy = BOX_Y + 32 + (i - 1) * ITEM_H
            if y >= iy and y < iy + ITEM_H then
                if not item.disabled then
                    self.mainSel = i
                    self:selectMain()
                end
                return
            end
        end
    else
        for i, item in ipairs(SLEEP_ITEMS) do
            local iy = BOX_Y + 40 + (i - 1) * ITEM_H
            if y >= iy and y < iy + ITEM_H then
                self.sleepSel = i
                self:selectSleep()
                return
            end
        end
    end
end

-- render

function PauseMenu:render()
    if not self.active then return end

    set(0.75, 0.75, 0.75, 0.9)
    love.graphics.rectangle('fill', BOX_X, BOX_Y, BOX_W, BOX_H, 3)
    set(0.04, 0.04, 0.06, 0.96)
    love.graphics.rectangle('fill', BOX_X + 2, BOX_Y + 2, BOX_W - 4, BOX_H - 4, 3)

    local ix = BOX_X + PAD
    local iw = BOX_W - PAD * 2

    if self.mode == 'main' then
        love.graphics.setFont(gFonts['gothic-medium'])
        set(1, 0.84, 0, 1)
        love.graphics.printf('PAUSED', ix, BOX_Y + 6, iw, 'center')

        set(1, 1, 1, 0.2)
        love.graphics.line(ix, BOX_Y + 26, BOX_X + BOX_W - PAD, BOX_Y + 26)

        love.graphics.setFont(gFonts['small'])
        for i, item in ipairs(MAIN_ITEMS) do
            local iy = BOX_Y + 32 + (i - 1) * ITEM_H

            set(1, 0.84, 0, 1)
            love.graphics.print(
                (i == self.mainSel and not item.disabled) and '>' or ' ',
                ix, iy
            )

            if item.disabled then
                set(0.38, 0.38, 0.38, 1)
                local suffix = item.whenDisabled and '  (' .. item.whenDisabled .. ')' or ''
                love.graphics.print(item.label .. suffix, ix + 9, iy)
            elseif i == self.mainSel then
                set(1, 0.95, 0.55, 1)
                love.graphics.print(item.label, ix + 9, iy)
            else
                set(0.9, 0.9, 0.9, 1)
                love.graphics.print(item.label, ix + 9, iy)
            end
        end

        set(0.35, 0.35, 0.35, 1)
        love.graphics.printf('[ESC] resume', ix, BOX_Y + BOX_H - 11, iw, 'center')

    else
        love.graphics.setFont(gFonts['gothic-medium'])
        set(0.6, 0.8, 1, 1)
        love.graphics.printf('SLEEP', ix, BOX_Y + 6, iw, 'center')

        love.graphics.setFont(gFonts['small'])
        set(0.55, 0.55, 0.55, 1)
        love.graphics.printf('Wake up in...', ix, BOX_Y + 24, iw, 'center')

        set(1, 1, 1, 0.2)
        love.graphics.line(ix, BOX_Y + 34, BOX_X + BOX_W - PAD, BOX_Y + 34)

        for i, item in ipairs(SLEEP_ITEMS) do
            local iy = BOX_Y + 40 + (i - 1) * ITEM_H

            set(1, 0.84, 0, 1)
            love.graphics.print(i == self.sleepSel and '>' or ' ', ix, iy)

            if i == self.sleepSel then
                set(1, 0.95, 0.55, 1)
            elseif item.label == 'Back' then
                set(0.55, 0.55, 0.55, 1)
            else
                set(0.9, 0.9, 0.9, 1)
            end
            love.graphics.print(item.label, ix + 9, iy)
        end

        set(0.35, 0.35, 0.35, 1)
        love.graphics.printf('[ESC] back', ix, BOX_Y + BOX_H - 11, iw, 'center')
    end

    -- confirm popup on top of everything
    if self.confirming then
        render_confirm(self.confirmMsg)
    end

    set(1, 1, 1, 1)
end

return PauseMenu
