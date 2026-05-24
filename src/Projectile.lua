-- ================== claude_changes_2026-05-23-2136 ==================
--[[
   Empire Engine
   Based on CS50 2D Coursework

   -- Projectile.lua --

   Author: Tim Lumnah
   github.com/timlumnah/empire_engine

   Class object to handle projectiles.
   Inherits most behaviour from GameObject.
   Projectile-specific behaviours, such as animations or sounds
       are defined in CallBacks.
   Projectiles standard defs are defined in src/game_objects.lua
       although further expansion may require a dedicated global PROJECTILES table.
]]
-- ====================================================================

Projectile = Class{__includes = GameObject}

function Projectile:init(def)
    GameObject.init(self, def)

    self.x = def.x
    self.y = def.y
    self.dx = def.dx or 0
    self.dy = def.dy or 0
    self.owner = def.owner
    self.type = def.type
    self.distanceTravelled = 0
    self.maxDistance = (def.type == "pot") and 4*TILE_SIZE or 4*TILE_SIZE
    self:onSpawn()  -- run onSpawn() callback, if there is one.

end


function Projectile:update(dt)
    -- use projectile-specific behaviors
    -- defined in object_defs > Callbacks
    -- passed through during spawning

    if self.currentAnimation then
        self.currentAnimation:update(dt)
    end

    -- example: callbacks:pot_onUpdate()
    self:onUpdate(dt)
    self:move(dt)

    if self.distanceTravelled >= self.maxDistance then
        self:onMaxDistance()
    end
end

function Projectile:move(dt)

    local oldX, oldY = self.x, self.y

    local nextX = oldX + self.dx * dt
    local nextY = oldY + self.dy * dt

    -- X collision
    if self:checkWallCollision(nextX, oldY) then
        self:onHitWall('x')
        return
    end

    -- Y collision
    if self:checkWallCollision(oldX, nextY) then
        self:onHitWall('y')
        return
    end

    self.x = nextX
    self.y = nextY

    local dx = self.x - oldX
    local dy = self.y - oldY

    self.distanceTravelled = self.distanceTravelled + math.sqrt(dx*dx + dy*dy)
end


function Projectile:render()
    local frame = self.frame

    if self.currentAnimation then
        frame = self.currentAnimation:getCurrentFrame()
    end

    love.graphics.draw(
        gTextures[self.texture],
        gFrames[self.texture][frame],
        math.floor(self.x),
        math.floor(self.y)
    )
end

function Projectile:despawn()
    -- helper to ensure any projectile-specific despawning logic
    -- runs that GameObject:despawn() wouldn't normally catch
    -- aka: stopping boomerang sound and resetting flag 

    if self.loopSound then
        self.loopSound:stop()
    end

    if self.owner and self.owner.activeBoomerang == self then
        self.owner.activeBoomerang = nil
    end

    self.in_remove_queue = true
end

function Projectile:checkWallCollision(x, y)
    -- Small collision helper to check for wall collisions in room.
    -- Although the codebase avoides using separate collision logic
    -- between classes in favor of delegating all collisions to Entity,
    -- doing this is impossible here because potential collisions
    -- do not involve entities.  
    return self.room:wall_probe(
        x + self.width / 2,
        y + self.height / 2
    )
end

