--[[
    Empire Engine
    Based on CS50 2D Coursework

    MinigameState.lua

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    Bridge state that loads and runs a Pong or Breakout minigame
    module. Swaps globals into the minigame's context, manages
    minigame music, and retunrs the win/lose result and cash reward
    back to PlayState on exit.
]]

MinigameState = Class{__includes = BaseState}

-- make sure to include any new class in Dependencies.lua 
-- and 
-- main.lua gStateMachine

function MinigameState:init()
    self.previousState = 'play'
    self.minigameName = 'pong'
end

function MinigameState:enter(params)
    if params then
        self.previousState = params.previousState or self.previousState
        self.minigameName = params.minigameName  or self.minigameName
    end
    for _, key in ipairs({'biome1', 'biome2', 'biome3'}) do gSounds[key]:stop() end
    gSounds['minigame-music']:play()
    self.module = require('minigames.' .. self.minigameName .. '.main')
    self.module.load()
end

function MinigameState:update(dt)

    -- forward update
    if self.module.update then
        local result = self.module.update(dt)

        if result == "exit" then
            gStateMachine:change(self.previousState)
        elseif type(result) == 'table' then
            -- minigame returned structured result (e.g. win + reward)
            gStateMachine:change(self.previousState, { minigameResult = result })
        end
    end

    -- manual exit key (no reward)
    if love.keyboard.wasPressed('x') then
        gStateMachine:change(self.previousState)
    end
end

function MinigameState:render()
    if self.module.draw then
        self.module.draw()
    end
end

function MinigameState:exit()
    if self.module and self.module.cleanup then
        self.module.cleanup()
    end
    self.module = nil
    gSounds['minigame-music']:stop()
end