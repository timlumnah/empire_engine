--[[
    Empire Engine
    Based on CS50 2D Coursework

    GameOverState.lua

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    Dispalyed when the player dies or goes bankrupt. Shows a
    reason-specific loss message and offers restart or quit options.
]]

-- game over screen, shown when player dies, goes bankrupt, or gets arrested
-- inherits from BaseState so it works with the gStateMachine system
GameOverState = Class{__includes = BaseState}

-- called by gStateMachine when transitioning into this state
-- params.reason tells us why the player lost
-- three possible reasons: "death", "bankrupt", "arrested"
function GameOverState:enter(params)
    self.reason = params and params.reason or 'death' -- default to death if no reason given
    -- stop all biome music before playing the game over sound
    -- all three biome tracks need to be stopped since we dont track which one is playing
    for _, key in ipairs({'biome1', 'biome2', 'biome3'}) do gSounds[key]:stop() end
    gSounds['game-over']:play()
end

-- no menu needed on the game over screen, any key does something
-- enter goes back to the start screen to begin a new game
function GameOverState:update(dt)
    -- enter goes back to start screen so player can restart
    if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
        gStateMachine:change('start')
    end

    -- escape quits the whole game without restarting
    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function GameOverState:render()
    -- pick heading and subtext based on how the player lost
    -- three different outcomes have three different messages to make the loss feel distinct
    local heading = self.reason == 'bankrupt' and 'BANKRUPT'
        or self.reason == 'arrested' and 'BUSTED'
        or 'GAME OVER'
    local subtext = self.reason == 'bankrupt' and 'You ran out of money.'
        or self.reason == 'arrested' and 'You were caught by the police.'
        or 'You died.'

    -- big dark red heading using the zelda display font
    love.graphics.setFont(gFonts['zelda'])
    love.graphics.setColor(175/255, 53/255, 42/255, 1)
    love.graphics.printf(heading, 0, VIRTUAL_HEIGHT / 2 - 48, VIRTUAL_WIDTH, 'center')

    -- smaller subtext below the heading says what actualy happened
    love.graphics.setFont(gFonts['small'])
    love.graphics.setColor(0.75, 0.75, 0.75, 1)
    love.graphics.printf(subtext, 0, VIRTUAL_HEIGHT / 2 - 4, VIRTUAL_WIDTH, 'center')

    -- press enter prompt, centered below the subtext
    love.graphics.setFont(gFonts['zelda-small'])
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('Press Enter', 0, VIRTUAL_HEIGHT / 2 + 16, VIRTUAL_WIDTH, 'center')
end
