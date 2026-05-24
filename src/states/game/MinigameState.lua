-- ================== claude_changes_2026-05-23-2136 ==================
--[[
   Empire Engine
   Based on CS50 2D Coursework

   -- MinigameState.lua --

   Author: Tim Lumnah
   github.com/timlumnah/empire_engine

   Bridge state that loads and runs a Pong or Breakout minigame
   module. Swaps globals into the minigame's context, manages
   minigame music, and retunrs the win/lose result and cash reward
   back to PlayState on exit.
]]
-- ====================================================================

-- bridge state that loads and runs a minigame module by name
-- any minigame in the minigames folder can be launched as long as it
-- exports load, update, draw, and cleanup functions
-- when done, returns to the previous state and optionally passes a cash reward
MinigameState = Class{__includes = BaseState}

-- adding a new minigame requires an entry in Dependencies.lua and in main.lua gStateMachine
-- also needs a MINIGAME_DEFS entry and a GAME_LIST entry in MarketplaceMenu

-- sets safe defualt values before enter is ever called
-- protects against nil errors if something skips enter somehow
function MinigameState:init()
    self.previousState = 'play'     -- which state to return to when the minigame ends
    self.minigameName = 'pong'      -- which minigame to load, overridden in enter
end

-- called by gStateMachine when transitioning into MinigameState
-- params.minigameName picks which minigame to dynamicaly load
-- params.previousState is where we go back when the minigame exits
function MinigameState:enter(params)
    if params then
        self.previousState = params.previousState or self.previousState
        self.minigameName = params.minigameName  or self.minigameName
    end
    -- stop all biome music before starting the minigame track
    for _, key in ipairs({'biome1', 'biome2', 'biome3'}) do gSounds[key]:stop() end
    gSounds['minigame-music']:play()
    -- build the require path from the minigame name and load the module
    -- each minigame lives in its own folder under minigames with a main.lua entry point
    self.module = require('minigames.' .. self.minigameName .. '.main')
    self.module.load() -- load initializes the minigame state
end

function MinigameState:update(dt)
    -- forward the update tick to the minigame module
    if self.module.update then
        local result = self.module.update(dt)

        -- result is nil while game is running, string "exit" on quit, table on game end
        if result == "exit" then
            -- player quit the minigame with no win, go back with no params
            gStateMachine:change(self.previousState)
        elseif type(result) == 'table' then
            -- minigame finished naturaly, table contains win flag and cash reward amount
            gStateMachine:change(self.previousState, { minigameResult = result })
        end
    end

    -- x key always exits immediatley, overrides whatever the minigame module wants
    if love.keyboard.wasPressed('x') then
        gStateMachine:change(self.previousState)
    end
end

-- just forwrads draw calls down to the minigame module
-- minigame is responsible for clearing and drawing its own screen
function MinigameState:render()
    if self.module.draw then
        self.module.draw()
    end
end

-- cleans up the module and stops music when leaving this state
-- called automaticaly by gStateMachine before changing to another state
function MinigameState:exit()
    if self.module and self.module.cleanup then
        self.module.cleanup() -- let minigame free its own resources
    end
    self.module = nil           -- clear the module reference
    gSounds['minigame-music']:stop()
end
