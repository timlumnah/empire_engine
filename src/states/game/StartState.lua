--[[
    Empire Engine
    Based on CS50 2D Coursework

    -- StartState --

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    Title screen and opening narrative. Displays the main menu,
    runs the intro plot dialogue, and transitions into PlayState
    when the player confirms they are ready to begin.
]]

StartState = Class{__includes = BaseState}

local MENU_ITEMS = {
    { label = 'New Game'    },
    { label = 'Continue',   disabled = true },
    { label = 'How to Play' },
    { label = 'Quit'        },
}

local function next_enabled(cur, dir)
    local n = #MENU_ITEMS
    local i = cur
    for _ = 1, n do
        i = ((i - 1 + dir) % n) + 1
        if not MENU_ITEMS[i].disabled then return i end
    end
    return cur
end

function StartState:init()
    self.showHelp = false
    self.sel = 1
    MENU_ITEMS[2].disabled = not SaveLoad.hasSave()
    for _, key in ipairs({'biome2', 'biome3'}) do
        if gSounds[key] then gSounds[key]:stop() end
    end
    if gSounds['biome1'] and not gSounds['biome1']:isPlaying() then
        gSounds['biome1']:play()
    end
end

function StartState:update(dt)
    if self.showHelp then
        if love.keyboard.wasPressed('escape') or love.keyboard.wasPressed('h') then
            self.showHelp = false
        end
        return
    end

    if love.keyboard.wasPressed('up') then
        self.sel = next_enabled(self.sel, -1)
    elseif love.keyboard.wasPressed('down') then
        self.sel = next_enabled(self.sel, 1)
    elseif love.keyboard.wasPressed('escape') then
        love.event.quit()
    elseif love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
        self:selectItem()
    end
end

function StartState:selectItem()
    local item = MENU_ITEMS[self.sel]
    if item.disabled then return end

    if item.label == 'New Game' then
        gStateMachine:change('play')
    elseif item.label == 'Continue' then
        local data = SaveLoad.load()
        if data then
            gStateMachine:change('play', { saveData = data })
        end
    elseif item.label == 'How to Play' then
        self.showHelp = true
    elseif item.label == 'Quit' then
        love.event.quit()
    end
end

function StartState:render()
    love.graphics.draw(gTextures['background'], 0, 0, 0,
        VIRTUAL_WIDTH / gTextures['background']:getWidth(),
        VIRTUAL_HEIGHT / gTextures['background']:getHeight())

    love.graphics.setFont(gFonts['zelda'])
    love.graphics.setColor(34/255, 34/255, 34/255, 1)
-- ================== claude_changes_2026-05-23-2140 ==================
    love.graphics.printf('Empire Engine', 2, VIRTUAL_HEIGHT / 2 - 70, VIRTUAL_WIDTH, 'center')

    love.graphics.setColor(175/255, 53/255, 42/255, 1)
    love.graphics.printf('Empire Engine', 0, VIRTUAL_HEIGHT / 2 - 72, VIRTUAL_WIDTH, 'center')
-- ====================================================================

    -- menu
    love.graphics.setFont(gFonts['zelda-small'])
    local menu_top = VIRTUAL_HEIGHT / 2 - 10
    local item_h = 22
    for i, item in ipairs(MENU_ITEMS) do
        local y = menu_top + (i - 1) * item_h
        if item.disabled then
            love.graphics.setColor(0.38, 0.38, 0.38, 1)
        elseif i == self.sel then
            love.graphics.setColor(1, 0.95, 0.55, 1)
        else
            love.graphics.setColor(0.9, 0.9, 0.9, 1)
        end
        local prefix = (i == self.sel and not item.disabled) and '> ' or '  '
        love.graphics.printf(prefix .. item.label, 0, y, VIRTUAL_WIDTH, 'center')
    end

    love.graphics.setColor(1, 1, 1, 1)

    if self.showHelp then
        renderHelpPopup()
    end
end
