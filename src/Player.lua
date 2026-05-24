-- ================== claude_changes_2026-05-23-2136 ==================
--[[
   Empire Engine
   Based on CS50 2D Coursework

   -- Player.lua --

   Author: Tim Lumnah
   github.com/timlumnah/empire_engine

   Player-specific subclass of Entity. Routes keyboard input to the
   player state machine, wires interaction prompts, and triggers
   inventory and NPC menu overlays during gameplay.
]]
-- ====================================================================

Player = Class{__includes = Entity}

function Player:init(def)
    Entity.init(self, def)
end

function Player:update(dt)
    Entity.update(self, dt)
end

function Player:render()
    Entity.render(self)
end


function Player:collides(target, tempHitbox)
    -- updated to default to normal "feet"-style collision
    -- but use hitbox if provided (as in the case of interactions)

    local hitbox = tempHitbox

    if not hitbox then
        hitbox = {
            x = self.x,
            y = self.y + self.height / 2,
            width = self.width,
            height = self.height / 2
        }
    end

    return Entity.collides(self, target, hitbox)
end


function Player:createDirectionalHitbox(width, height)
    -- reusable hitbox helper for SwingSwordState and LiftState

    local direction = self.direction
    local hitboxX, hitboxY

    if direction == 'left' then
        hitboxX = self.x - width
        hitboxY = self.y + 2
    elseif direction == 'right' then
        hitboxX = self.x + self.width
        hitboxY = self.y + 2
    elseif direction == 'up' then
        width = height
        height = width / 2
        hitboxX = self.x
        hitboxY = self.y - height
    else -- down
        width = height
        height = width / 2
        hitboxX = self.x
        hitboxY = self.y + self.height
    end

    return Hitbox(hitboxX, hitboxY, width, height)
end
