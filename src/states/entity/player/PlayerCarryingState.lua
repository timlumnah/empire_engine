 --[[
    Empire Engine
    Based on CS50 2D Coursework

    -- Player Carrying State --

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    CarryingState implementation per project spec.
    Mirrors PlayerWalkingState but uses carrying animations.
    Sword Swinging is disabled by mapping 'space' key to 
    throwing the carried object (pot).
]]

PlayerCarryingState = Class{__includes = EntityWalkState}

function PlayerCarryingState:init(player, world)
    self.entity = player
    self.player = player
    self.world = world

    -- render offset for spaced character sprite; negated in render function of state
    self.entity.offsetY = 5
    self.entity.offsetX = 0
end

function PlayerCarryingState:update(dt)
    -- handle movement input
    if love.keyboard.isDown('left') then
        self.entity.direction = 'left'
        self.entity:changeAnimation('pot-walk-left')
    elseif love.keyboard.isDown('right') then
        self.entity.direction = 'right'
        self.entity:changeAnimation('pot-walk-right')
    elseif love.keyboard.isDown('up') then
        self.entity.direction = 'up'
        self.entity:changeAnimation('pot-walk-up')
    elseif love.keyboard.isDown('down') then
        self.entity.direction = 'down'
        self.entity:changeAnimation('pot-walk-down')
    else
        self.entity:changeState('carrying-idle')
    end

    -- throw the pot
    if love.keyboard.wasPressed('space') then
        self.entity:changeState('throw')
    end

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

            -- allow player to carry pot to new room
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

function PlayerCarryingState:render()
    local anim = self.player.currentAnimation
    love.graphics.draw(gTextures[anim.texture], gFrames[anim.texture][anim:getCurrentFrame()],
        math.floor(self.player.x), math.floor(self.player.y - self.player.offsetY))

end
