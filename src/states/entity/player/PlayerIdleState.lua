--[[
    Empire Engine
    Based on CS50 2D Coursework

    PlayerIdleState.lua

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    Player idle behaviour. Waits for directional input to transition
    to PlayerWalkState. Also polls for the Enter key to open NPC
    interaction menus when standing near a friendly entity.
]]

PlayerIdleState = Class{__includes = EntityIdleState}

function PlayerIdleState:enter(params)
    
    -- render offset for spaced character sprite (negated in render function of state)
    self.entity.offsetY = 5
    self.entity.offsetX = 0
end

function PlayerIdleState:update(dt)
    if love.keyboard.isDown('left') or love.keyboard.isDown('right') or
       love.keyboard.isDown('up') or love.keyboard.isDown('down') then
        self.entity:changeState('walk')
    end

    -- ============== Tim Lumnah Edits =============
    if love.keyboard.wasPressed('return') then
        -- goes directly into liftState which and 
        -- lift state checks for pot otherwise returns
        -- back here to idle state
        self.entity:attempt_interact()
    end
    
    if love.keyboard.wasPressed('space') then
        self.entity:changeState('swing-sword')
    end
    -- =============================================
end