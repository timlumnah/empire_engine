--[[
    Empire Engine
    Based on CS50 2D Coursework

    PlayerSwingSwordState.lua

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    Player attack state. Plays the sword-swing animation, spawns a
    projectile hitbox in the current facing direction, then returns
    to idle once the animation completes.
]]

PlayerSwingSwordState = Class{__includes = BaseState}

function PlayerSwingSwordState:init(player, world)
    self.player = player
    self.world = world

    -- render offset for spaced character sprite
    self.player.offsetY = 5
    self.player.offsetX = 8

    -- ============== Tim Lumnah Edits =============
    -- create hitbox based on where the player is and facing
    self.swordHitbox = self.player:createDirectionalHitbox(8, 16)
    -- =============================================

    -- sword-left, sword-up, etc
    self.player:changeAnimation('sword-' .. self.player.direction)
end

function PlayerSwingSwordState:enter(params)

    -- restart sword swing sound for rapid swinging
    gSounds['sword']:stop()
    gSounds['sword']:play()

    -- restart sword swing animation
    self.player.currentAnimation:refresh()
end

function PlayerSwingSwordState:update(dt)
    
    -- check if hitbox collides with any entities in the scene
    for k, entity in pairs(self.world.currentRoom.entities) do
        if not entity.friendly and not entity.invulnerable and entity:collides(self.swordHitbox) then
            entity:damage(1)
            entity:goInvulnerable(1.5)
            gSounds['hit-enemy']:play()
        end
    end

    -- if we've fully elapsed through one cycle of animation, change back to idle state
    if self.player.currentAnimation.timesPlayed > 0 then
        self.player.currentAnimation.timesPlayed = 0
        self.player:changeState('idle')
    end

    -- allow us to change into this state afresh if we swing within it, rapid swinging
    if love.keyboard.wasPressed('space') then
        self.player:changeState('swing-sword')
    end
end

function PlayerSwingSwordState:render()
    local anim = self.player.currentAnimation
    love.graphics.draw(gTextures[anim.texture], gFrames[anim.texture][anim:getCurrentFrame()],
        math.floor(self.player.x - self.player.offsetX), math.floor(self.player.y - self.player.offsetY))
end