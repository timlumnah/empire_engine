--[[
    Empire Engine
    Based on CS50 2D Coursework

    -- Player Boomerang State --

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    Handles boomerang-throwing logic.
    Similar to PlayerThrowState, but calls a boomerang projectile object.
    Uses parallel logic to PlayerThrowState.
    In future production-intent code, this state may be combined with ThowState
]]


PlayerBoomerangState = Class{__includes = BaseState}

function PlayerBoomerangState:init(player, world)
    self.player = player
    self.world = world
end

function PlayerBoomerangState:enter()
    -- mirror ThrowState to spawn a projectile
    
    local player = self.player

    local dx, dy = 0, 0
    local speed = 120
    if player.direction == 'left' then dx = -speed
    elseif player.direction == 'right' then dx = speed
    elseif player.direction == 'up' then dy = -speed
    else dy = speed
    end

    local projectile = CALLBACKS.spawn_projectile({
        type = "boomerang",
        x = player.x,
        y = player.y,
        dx = dx,
        dy = dy,
        texture = "boomerang",
        frame = 1,    -- fixed frame for init() but will be overridden
        room = self.world.currentRoom,
        owner = player
    })

    -- set flag on player
    player.activeBoomerang = projectile

    -- set a timer for any animations
    self.timer = 0.15
end

function PlayerBoomerangState:update(dt)
    self.timer = self.timer - dt

    -- change back to normal idle state
    if self.timer <= 0 then
        self.player:changeState('idle')
    end
end

function PlayerBoomerangState:render()
    local anim = self.player.currentAnimation
    love.graphics.draw(gTextures[anim.texture], gFrames[anim.texture][anim:getCurrentFrame()],
        math.floor(self.player.x), math.floor(self.player.y - self.player.offsetY))
end