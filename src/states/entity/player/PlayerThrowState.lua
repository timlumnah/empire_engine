--[[
    Empire Engine
    Based on CS50 2D Coursework

    -- Player Throw State --

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    Implementation of PlayerThrowState per project spec
    Handles pot-throwing logic.
    A parallel state exists to throw boomerang,
    though in a hypothetical future production-intent implementation,
    these two states may be combined.
    
]]

PlayerThrowState = Class{__includes = BaseState}

function PlayerThrowState:init(player, world)
    self.player = player
    self.world = world
end


function PlayerThrowState:enter(params)
    local player = self.player
    local object = player.carriedObject

    -- throwing animation uses lifting animation in reverse
    --      (copied & renamed it in entity_defs )
    self.player:changeAnimation('throw-' .. self.player.direction)

    -- guard against edge cases with no object
    if not object then
        player:changeState('idle')
        return
    end

    local projectileType = object.type

    -- projectile-specific parameters
    local dx, dy = 0, 0
    local speed = 120
    if player.direction == 'left' then dx = -speed
    elseif player.direction == 'right' then dx = speed
    elseif player.direction == 'up' then dy = -speed
    else dy = speed
    end

    -- spawn projectile
    CALLBACKS.spawn_projectile({
        type = projectileType,
        x = player.x,
        y = player.y,
        dx = dx,
        dy = dy,
        texture = object.texture,
        frame = object.frame,
        room = self.world.currentRoom,
        owner = player
    })

    -- remove carried object
    object:despawn()
    player.carriedObject = nil
end


function PlayerThrowState:update(dt)
    -- if we've fully elapsed through one cycle of animation, change back to idle state
    if self.player.currentAnimation.timesPlayed > 0 then
        self.player.currentAnimation.timesPlayed = 0
        self.player:changeState('idle')
    end
end

function PlayerThrowState:render()
    local anim = self.player.currentAnimation
    love.graphics.draw(gTextures[anim.texture], gFrames[anim.texture][anim:getCurrentFrame()],
        math.floor(self.player.x), math.floor(self.player.y - self.player.offsetY))
end