--[[
    Empire Engine
    Based on CS50 2D Coursework

    EntityWalkState.lua

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    NPC walk behaviour. Moves the entity in a randomly chosen
    direction, reflects off room walls, and randomly transitions
    back to EntityIdleState after a short randomised timer.
]]

EntityWalkState = Class{__includes = BaseState}

function EntityWalkState:init(entity, world)
    self.entity = entity
    self.entity:changeAnimation('walk-down')

    self.world = world

    -- used for AI control
    self.moveDuration = 0
    self.movementTimer = 0

    -- keeps track of whether we just hit a wall
    self.bumped = false

    self.hitbox = Hitbox(hitboxX, hitboxY, hitboxWidth, hitboxHeight)
end


function EntityWalkState:processAI(params, dt)
    if self.entity.walkTarget then
        local tx = self.entity.walkTarget.x
        local ty = self.entity.walkTarget.y
        local cx = self.entity.x + self.entity.width / 2
        local cy = self.entity.y + self.entity.height / 2
        local dx = tx - cx
        local dy = ty - cy
        local newDir
        if math.abs(dx) >= math.abs(dy) then
            newDir = dx > 0 and 'right' or 'left'
        else
            newDir = dy > 0 and 'down' or 'up'
        end
        if newDir ~= self.entity.direction then
            self.entity.direction = newDir
            self.entity:changeAnimation('walk-' .. newDir)
        end
        return
    end

    local room = params.room
    local directions = {'left', 'right', 'up', 'down'}

    if self.moveDuration == 0 or self.bumped then
        
        -- set an initial move duration and direction
        self.moveDuration = math.random(5)
        self.entity.direction = directions[math.random(#directions)]
        self.entity:changeAnimation('walk-' .. tostring(self.entity.direction))
    elseif self.movementTimer > self.moveDuration then
        self.movementTimer = 0

        -- chance to go idle
        if math.random(3) == 1 then
            self.entity:changeState('idle')
        else
            self.moveDuration = math.random(5)
            self.entity.direction = directions[math.random(#directions)]
            self.entity:changeAnimation('walk-' .. tostring(self.entity.direction))
        end
    end

    self.movementTimer = self.movementTimer + dt
end

function EntityWalkState:render()
    local anim = self.entity.currentAnimation
    love.graphics.draw(gTextures[anim.texture], gFrames[anim.texture][anim:getCurrentFrame()],
        math.floor(self.entity.x - self.entity.offsetX), math.floor(self.entity.y - self.entity.offsetY))
end



-- =================== Tim Lumnah Edits ===================

function EntityWalkState:update(dt)

    local dx = 0
    local dy = 0

    if self.entity.direction == 'left' then
        dx = -self.entity.walkSpeed * dt
    elseif self.entity.direction == 'right' then
        dx = self.entity.walkSpeed * dt
    elseif self.entity.direction == 'up' then
        dy = -self.entity.walkSpeed * dt
    elseif self.entity.direction == 'down' then
        dy = self.entity.walkSpeed * dt
    end

    local collisions = self.entity:moveAndCollide(dx, dy)

    self.bumped = false
    for _, object in ipairs(collisions) do
        if object.solid then
            self.bumped = true
            break
        end
    end
end

-- ========================================================