--[[
    Empire Engine
    Based on CS50 2D Coursework

    PLAYER LIFT STATE

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine
    
    Per project spec, this state is unique to lifting pots.
    However, in real life prod, it might be a generic 'interact' state
    to handle other object types, ie chest, bombs, loot, etc.
]]

PlayerLiftState = Class{__includes = BaseState}

function PlayerLiftState:init(player, world)
    self.player = player
    self.world = world

    -- render offset for spaced character sprite
    self.player.offsetY = 5
    self.player.offsetX = 8

    self.liftHitbox = self.player:createDirectionalHitbox(8, 16)

    self.player:changeAnimation('pot-lift-' .. self.player.direction)
end

function PlayerLiftState:enter(params)
    -- use a hitbox similar to swordState to detect pickup collisions

    self.liftHitbox = self.player:createDirectionalHitbox(8, 16)
    
    self.player:changeAnimation('pot-lift-' .. self.player.direction)
    self.player.currentAnimation:refresh()

    self.grabbedObject = nil
end


function PlayerLiftState:update(dt)
    -- checks for pots only but could be expanded to check for other object types

    self.liftHitbox = self.player:createDirectionalHitbox(8, 16)

    -- check if hitbox collides with any pots in the scene
    if not self.grabbedObject then
        for _, object in pairs(self.world.currentRoom.objects) do
            

            if object.type == 'pot' and self.player:collides(object, self.liftHitbox) then
                self.grabbedObject = object
                object.isHeld = true
                object.solid = false
                object.dx = 0
                object.dy = 0

                self.player.carriedObject = object
                break
            end
        end
    end

    -- if we've fully elapsed through one cycle of animation, change back to idle state
    if self.player.currentAnimation.timesPlayed > 0 then
        self.player.currentAnimation.timesPlayed = 0

        if self.grabbedObject then
            self.player:changeState('carrying', {
                object = self.grabbedObject
            })
        else
            self.player:changeState('idle')
        end
    end
end

function PlayerLiftState:render()
    local anim = self.player.currentAnimation
    love.graphics.draw(gTextures[anim.texture], gFrames[anim.texture][anim:getCurrentFrame()],
        math.floor(self.player.x), math.floor(self.player.y - self.player.offsetY))
end