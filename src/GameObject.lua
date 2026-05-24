--[[
    Empire Engine
    Based on CS50 2D Coursework

    -- GameObject --

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    Standard class object for objects in Zelda.
    Projectiles & Carried objects inherit from this class.
    Standard defs are defined in src/game_objects.lua.
    Callbacks & behaviors defined in src/CallBacks.lua.
    All collision logic is handled by Entity() for consistency.
        The Entity must detect collisions with an object, except for projectiles > walls
]]

GameObject = Class{}

function GameObject:init(def)
    
    -- iterate through def rather than 
    -- hard-coding each variable.
    -- Improves future-proofing.
    for k, v in pairs(def) do
        self[k] = v
    end
    
    -- resolve callbacks with helper function
    if def.callbacks then
        for field, cb_name in pairs(def.callbacks) do
            self[field] = self:resolveCallback(cb_name)
        end
    end

    if def.animations then
        self.animations = self:createAnimations(def.animations)
    end
    
    -- fallback to empty functions
    self.onCollide = self.onCollide or function() end
    self.onConsume = self.onConsume or function() end
    self.onInteract = self.onInteract or function() end
    self.onHitEntity = self.onHitEntity or function() end
    self.onHitWall = self.onHitWall or function() end
    self.onMaxDistance = self.onMaxDistance or function() end
    self.onUpdate = self.onUpdate or function() end
    self.onSpawn = self.onSpawn or function() end


    self.in_remove_queue = false

end

function GameObject:createAnimations(animations)
    -- re-use Entity:createAnimations()

    local animationsReturned = {}

    for k, animationDef in pairs(animations) do
        animationsReturned[k] = Animation {
            texture = animationDef.texture or self.texture,
            frames = animationDef.frames,
            interval = animationDef.interval
        }
    end

    return animationsReturned
end

function GameObject:changeAnimation(name)
    -- re-use Entity:changeAnimation()
    self.currentAnimation = self.animations[name]
end

function GameObject:resolveCallback(cb)
    -- helper to resolve strings into callback functions
    -- without this, a circular dependency would be created
    -- between CALLBACKS and GAME_OBJECT_DEFS
    if type(cb) == 'string' then
        return CALLBACKS[cb] or function() end
    else
        return cb or function() end
    end
end


function GameObject:update(dt)
    if self.hitbox then
        self.hitbox.x = self.x
        self.hitbox.y = self.y
    end
    if self.currentAnimation then
        self.currentAnimation:update(dt)
    end
    self.onUpdate(self, dt)
end


function GameObject:render(adjacentOffsetX, adjacentOffsetY)
    if self.isHeld and self.owner then return end

    -- allow objects to supply their own draw logic (e.g. delivery boxes)
    if self.customRender then
        self.customRender(self, adjacentOffsetX, adjacentOffsetY)
        return
    end

    love.graphics.draw(
        gTextures[self.texture],
        gFrames[self.texture][self.states[self.state].frame or self.frame],
        self.x + (adjacentOffsetX or 0),
        self.y + (adjacentOffsetY or 0)
    )
end



function GameObject:destroy()
    -- despawn/destroy helper to safely remove from any/all tables
    self.in_remove_queue = true
end
function GameObject:despawn()
    -- backwards compatibility / readability wrapper
    self:destroy()
end