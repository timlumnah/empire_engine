--[[
   Empire Engine
   Based on CS50 2D Coursework

   -- WinState --

   Author: Tim Lumnah
   github.com/timlumnah/empire_engine

   Shown when player reahces WIN_CASH_GOAL.
   Options: keep playing (free play), restart, quit.
]]

-- win screen, shown when player.cash reaches WIN_CASH_GOAL
-- three post win options, keep playing in free mode, restart, or quit
WinState = Class{__includes = BaseState}

-- three post win menu options shown at the bottom of the win screen
local MENU = {
    { label = 'Keep Playing  (Free Play)', action = 'freeplay'}, -- continue with no win condition
    { label = 'Restart', action = 'restart'}, -- go back to the title screen
    { label = 'Quit', action = 'quit' }, -- close the game
}

-- formats an integer with comma separators for large numbers
-- example, 1234567 becomes "1,234,567"
local function commify(n)
    local s = tostring(math.floor(math.abs(n)))
    local result = s:reverse():gsub('(%d%d%d)', '%1,'):reverse()
    result = result:gsub('^,', '')
    return (n < 0 and '-' or '') .. result
end

-- called by gStateMachine when the win condition triggers
-- stores final stats passed from PlayState and starts the win sound
function WinState:enter(params)
    params = params or {}
    self.finalCash = params.finalCash or 0         -- cash the player ended with
    self.businessCount = params.businessCount or 0 -- how many buisnesses they owned
    self.worldTime = params.worldTime or 0         -- total real seconds elapsed in game
    self.saveData = params.saveData or nil          -- kept in case free play needs it for loading
    self.selected = 1                               -- start with first menu option selected
    -- stop all biome tracks before playing the win sound
    for _, key in ipairs({'biome1', 'biome2', 'biome3'}) do gSounds[key]:stop() end
    gSounds['win']:play()
end

-- handles up and down navigation through the three post win options
function WinState:update(dt)
    if love.keyboard.wasPressed('up') then
        self.selected = math.max(1, self.selected - 1)
    end
    if love.keyboard.wasPressed('down') then
        self.selected = math.min(#MENU, self.selected + 1)
    end
    if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
        self:selectOption(self.selected)
    end
end

-- dispatches the selected menu action to the right state transition
function WinState:selectOption(i)
    local action = MENU[i].action
    if action == 'freeplay' then
        -- free play passes freePlay flag so PlayState skips the win check
        gStateMachine:change('play', { freePlay = true, saveData = self.saveData })
    elseif action == 'restart' then
        gStateMachine:change('start')
    elseif action == 'quit' then
        love.event.quit()
    end
end

function WinState:render()
    local cx = VIRTUAL_WIDTH / 2 -- cx not used but kept in case its needed later

    -- main narrative heading, golden color to feel triumphant
    love.graphics.setFont(gFonts['zelda-small'])
    love.graphics.setColor(1, 0.85, 0.1, 1)
    love.graphics.printf('SHE MADE IT', 0, 8, VIRTUAL_WIDTH, 'center')

    -- three line resolution of the grandmothers story
    love.graphics.setFont(gFonts['small'])
    love.graphics.setColor(0.88, 0.88, 0.88, 1)
    love.graphics.printf(
        "Grandma received her treatment for Varendorf's Syndrome.\nThe doctors say she will make a full recovery.\nShe is going to live.",
        0, 30, VIRTUAL_WIDTH, 'center'
    )

    -- convert world time from seconds to game months for display
    local months = math.floor(self.worldTime / SECONDS_PER_MONTH)
    love.graphics.setFont(gFonts['medium'])

    -- final cash shown in green with comma formatting
    love.graphics.setColor(0.3, 1, 0.4, 1)
    love.graphics.printf(
        'Cash: $' .. commify(self.finalCash),
        0, 72, VIRTUAL_WIDTH, 'center'
    )

    -- buisness count and time played shown in white below the cash line
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(
        'Businesses Owned: ' .. self.businessCount,
        0, 92, VIRTUAL_WIDTH, 'center'
    )
    love.graphics.printf(
        'Time Played: ' .. months .. ' months',
        0, 112, VIRTUAL_WIDTH, 'center'
    )

    -- thin horizontal line separating stats from the menu options below
    love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
    love.graphics.line(50, 134, VIRTUAL_WIDTH - 50, 134)

    -- menu options, selected one highlighted in gold with cursor arrow
    love.graphics.setFont(gFonts['medium'])
    for i, item in ipairs(MENU) do
        local y = 142 + (i - 1) * 20
        if i == self.selected then
            love.graphics.setColor(1, 0.85, 0.1, 1) -- gold for selected
            love.graphics.printf('> ' .. item.label, 0, y, VIRTUAL_WIDTH, 'center')
        else
            love.graphics.setColor(0.65, 0.65, 0.65, 1) -- grey for unselected
            love.graphics.printf(item.label, 0, y, VIRTUAL_WIDTH, 'center')
        end
    end

    -- small control hint at the very bottom of the screen
    love.graphics.setFont(gFonts['small'])
    love.graphics.setColor(0.45, 0.45, 0.45, 1)
    love.graphics.printf(
        'Up/Down: navigate    Enter: select',
        0, VIRTUAL_HEIGHT - 11, VIRTUAL_WIDTH, 'center'
    )

    love.graphics.setColor(1, 1, 1, 1)
end
