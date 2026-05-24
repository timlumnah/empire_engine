--[[
    Empire Engine
    Based on CS50 2D Coursework

    PlayerWalkState.lua

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    Player walk behaviour. Reads directional input, moves the player,
    enforces room-boundary collision, and fires shift events when the
    player steps into a doorway to trigger a room transition.
]]

PlayerWalkState = Class{__includes = EntityWalkState}

function PlayerWalkState:init(player, world)
    self.entity = player
    self.world = world

    -- render offset for spaced character sprite; negated in render function of state
    self.entity.offsetY = 5
    self.entity.offsetX = 0
end

function PlayerWalkState:update(dt)
    -- handle movement input
    if love.keyboard.isDown('left') then
        self.entity.direction = 'left'
        self.entity:changeAnimation('walk-left')
    elseif love.keyboard.isDown('right') then
        self.entity.direction = 'right'
        self.entity:changeAnimation('walk-right')
    elseif love.keyboard.isDown('up') then
        self.entity.direction = 'up'
        self.entity:changeAnimation('walk-up')
    elseif love.keyboard.isDown('down') then
        self.entity.direction = 'down'
        self.entity:changeAnimation('walk-down')
    else
        self.entity:changeState('idle')
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

    -- perform base movement and collision
    EntityWalkState.update(self, dt)

    for _, doorway in pairs(self.world.currentRoom.doorways) do
        if doorway.open and self.entity:collides(doorway) then
            
            -- center player in doorway
            if self.entity.direction == 'left' or self.entity.direction == 'right' then
                self.entity.y = doorway.y + 4
            else
                self.entity.x = doorway.x + 8
            end

            -- dispatch event
            if doorway.direction == 'left' then
                Event.dispatch('shift-left')
            elseif doorway.direction == 'right' then
                Event.dispatch('shift-right')
            elseif doorway.direction == 'top' then
                Event.dispatch('shift-up')
            else
                Event.dispatch('shift-down')
            end
            break
        end
    end
end
