--[[
    Empire Engine
    Based on CS50 2D Coursework

    -- StartState --

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    Base class for all in-world actors (player, NPCs, competitors).
    Manages position, health, cash, inventory, collision detection,
    directional animation, and the per-entity state machine.
]]

Entity = Class{}

function Entity:init(def)

    -- in top-down games, there are four directions instead of two
    self.direction = 'down'

    self.animations = self:createAnimations(def.animations)

    -- dimensions
    self.x = def.x
    self.y = def.y
    self.width = def.width
    self.height = def.height

    -- drawing offsets for padded sprites
    self.offsetX = def.offsetX or 0
    self.offsetY = def.offsetY or 0

    self.walkSpeed = def.walkSpeed

    self.health = def.health

    self.invulnerable = false
    self.invulnerableDuration = 0
    self.invulnerableTimer = 0
    self.flashTimer = 0

    self.dead = false
    self.in_remove_queue = false
    self.room = def.room
    self.carriedObject = nil

    self.cash = def.cash or STARTING_CASH
    self.displayCash = self.cash    -- a smoothed variation of self.cash for rendering on screen
    self.businesses = {}
end

function Entity:createAnimations(animations)
    local animationsReturned = {}

    for k, animationDef in pairs(animations) do
        animationsReturned[k] = Animation {
            texture = animationDef.texture or 'entities',
            frames = animationDef.frames,
            interval = animationDef.interval
        }
    end

    return animationsReturned
end


function Entity:damage(dmg)
    self.health = self.health - dmg
end

function Entity:goInvulnerable(duration)
    self.invulnerable = true
    self.invulnerableDuration = duration
    self.invulnerableTimer = 0
    self.flashTimer = 0
end

function Entity:changeState(name)
    if self.dead then return end
    self.stateMachine:change(name)
end

function Entity:changeAnimation(name)
    self.currentAnimation = self.animations[name]
end


function Entity:processAI(params, dt)
    self.stateMachine:processAI(params, dt)
end

function Entity:render(adjacentOffsetX, adjacentOffsetY)

    if self.invulnerable and self.flashTimer > 0.06 then
        self.flashTimer = 0
        love.graphics.setColor(1, 1, 1, 64/255)
    end

    self.x, self.y = self.x + (adjacentOffsetX or 0), self.y + (adjacentOffsetY or 0)
    self.stateMachine:render()
    love.graphics.setColor(1, 1, 1, 1)

    -- affinity bar above head (shown when NPC is shmooze-able)
    if self.affinity ~= nil then
        local bw = self.width
        local bh = 2
        local bx = math.floor(self.x)
        local by = math.floor(self.y - (self.offsetY or 0) - bh - 2)
        love.graphics.setColor(0.15, 0.15, 0.15, 0.85)
        love.graphics.rectangle('fill', bx, by, bw, bh)
        if self.affinity > 0 then
            love.graphics.setColor(0.25, 0.9, 0.45, 1)
            love.graphics.rectangle('fill', bx, by, math.floor(bw * self.affinity / 3), bh)
        end
        love.graphics.setColor(1, 1, 1, 1)
    end

    self.x, self.y = self.x - (adjacentOffsetX or 0), self.y - (adjacentOffsetY or 0)

    -- if a carriedObject is present, then the entity will hold the object above its head
    if self.carriedObject then
        local obj = self.carriedObject

        love.graphics.draw(
            gTextures[obj.texture],
            gFrames[obj.texture][obj.frame],
            math.floor(self.x + self.width / 2 - 8),
            math.floor(self.y - 12) -- ofset above head
        )
    end
end


function Entity:openBusiness(name, type, startingCash)
    if not type then type = 'retail' end
    if not startingCash then startingCash = 2000 end

    print("Entity:openBusiness() called!")
    business = Business(BUSINESS_TYPES[type])

    table.insert(self.businesses, business)
end


function Entity:printBusinesses()
    printHeader("Businesses")

    if #self.businesses == 0 then
        print("None")
        return
    end

    for i, bus in ipairs(self.businesses) do
        print(string.format(
            "[%d] %s (%s) | Cash: %.2f | Age (seconds): %.2f",
            i,
            bus.name or "Unknown",
            bus.type or "Unknown",
            bus.cash or 0,
            bus.age or 0
        ))

        print(string.format(
            "--- P & L last frame ---\nRevenue: | Profit: %f | Costs: %f | Units sold: %f | Unit price: %.2f | Unit cost of aquisition: %.2f",
            bus.trackingMetrics.profitLastFrame or 0,
            bus.trackingMetrics.costsLastFrame or 0,
            bus.trackingMetrics.unitsSoldLastFrame or 0,
            bus.basePrice or 0,
            bus.unitWholeSaleCost or 0
        ))
    end
end

function printHeader(title, width)
    -- Utility function to print a terminal-style header
    width = width or 40  -- default width if not specified
    local padding = math.floor((width - #title) / 2)
    local line = string.rep("=", padding)
    print("\n" .. line .. " " .. title .. " " .. line)
end


function Entity:collides(target, tempHitbox)
    -- Use tempHitbox if provided, otherwise fall back to self
    local a = tempHitbox or self

    -- Target is always treated as a box
    local b = {
        x = target.x,
        y = target.y,
        width = target.width,
        height = target.height
    }

    return not (
        a.x + a.width < b.x or
        a.x > b.x + b.width or
        a.y + a.height < b.y or
        a.y > b.y + b.height
    )
end

function Entity:checkObjectCollisions()
    -- since all entities need to be blocked by solid objects
    -- we will detect collisions from here in Entity.

    local collided = {}

    -- return early if no room
    if not self.room then return collided end

    for i = 1, #self.room.objects do
        local object = self.room.objects[i]

        if self:collides(object) and not self.ignoreCollisions then
            if object.solid and not object.open then
                table.insert(collided, object)
            end
        end
    end

    return collided
end

function Entity:checkEntityCollisions()
    -- returns solid, living entities in the room that overlap self (excluding self)

    local collided = {}
    if not self.room then return collided end

    for _, entity in ipairs(self.room.entities) do
        if entity ~= self and entity.solid and not entity.dead then
            if self:collides(entity) then
                table.insert(collided, entity)
            end
        end
    end

    -- player is stored separately from room.entities; check it too
    local player = self.room.player
    if player and player ~= self and not player.dead then
        if self:collides(player) then
            table.insert(collided, player)
        end
    end

    return collided
end

function Entity:attempt_interact()
    -- checks objects then entities for onInteract callback
    -- objects: pots, chests, switches
    -- entities: banker NPCs, etc.

    if not self.room then return false end

    local hitbox = self:createDirectionalHitbox(8, 16)

    for _, object in pairs(self.room.objects) do
        if object.onInteract and self:collides(object, hitbox) then
            object.onInteract(self, object, self.room)
            return true
        end
    end

    -- also check entities (friendly NPCs)
    for _, entity in pairs(self.room.entities) do
        if entity.onInteract and not entity.dead and self:collides(entity, hitbox) then
            entity.onInteract(self, entity, self.room)
            return true
        end
    end

    return false
end


function Entity:moveAndCollide(dx, dy)
    -- wrapper method to be used in entityWalkState for readability

    local allCollisions = {}

    -- move X
    local oldX = self.x
    self.x = self.x + dx

    -- world bounds (X)
    if self.x <= MAP_RENDER_OFFSET_X + TILE_SIZE then
        if not self:isEnteringOpenDoorway('left') then
            self.x = MAP_RENDER_OFFSET_X + TILE_SIZE
        end
    elseif self.x + self.width >= VIRTUAL_WIDTH - TILE_SIZE * 2 then
        if not self:isEnteringOpenDoorway('right') then
            self.x = VIRTUAL_WIDTH - TILE_SIZE * 2 - self.width
        end
    end

    -- object collisions (X)
    for _, object in ipairs(self:checkObjectCollisions()) do
        if object.solid then
            self.x = oldX
            table.insert(allCollisions, object)
            break
        end
    end

    -- entity collisions (X)
    for _, entity in ipairs(self:checkEntityCollisions()) do
        self.x = oldX
        table.insert(allCollisions, entity)
        break
    end

    -- move Y
    local oldY = self.y
    self.y = self.y + dy

    local bottomEdge = VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE)
        + MAP_RENDER_OFFSET_Y - TILE_SIZE

    -- world bounds (Y)
    if self.y <= MAP_RENDER_OFFSET_Y + TILE_SIZE - self.height / 2 then
        if not self:isEnteringOpenDoorway('top') then
            self.y = MAP_RENDER_OFFSET_Y + TILE_SIZE
        end
    elseif self.y + self.height >= bottomEdge then
        if not self:isEnteringOpenDoorway('bottom') then
            self.y = bottomEdge - self.height
        end
    end

    -- object collisions (Y)
    for _, object in ipairs(self:checkObjectCollisions()) do
        if object.solid then
            self.y = oldY
            table.insert(allCollisions, object)
            break
        end
    end

    -- entity collisions (Y)
    for _, entity in ipairs(self:checkEntityCollisions()) do
        self.y = oldY
        table.insert(allCollisions, entity)
        break
    end

    return allCollisions
end


function Entity:update(dt)
    if self.invulnerable then
        self.flashTimer = self.flashTimer + dt
        self.invulnerableTimer = self.invulnerableTimer + dt
        if self.invulnerableTimer > self.invulnerableDuration then
            self.invulnerable = false
            self.invulnerableTimer = 0
            self.invulnerableDuration = 0
            self.flashTimer = 0
        end
    end

    self.stateMachine:update(dt)

    -- update animations
    if self.currentAnimation then
        self.currentAnimation:update(dt)
    end


    -- limit cash display to update only once per second
    self.cashDisplayTimer = (self.cashDisplayTimer or 0) + dt

    if self.cashDisplayTimer > 1.0 then
        self.cashDisplayTimer = 0
        self.displayCash = self.cash
    end
end


function Entity:die(room)
    -- small helper to modularize enemies dying
    
    -- ensure this function only runs once
    if self.dead then
        return
    end

    self.dead = true
    self.stateMachine = nil
    self.in_remove_queue = true

    if self.onDeath then self.onDeath(self) end

    gSounds['scream']:play()

    if math.random(2) == 1 then
        CALLBACKS.spawn_object{
            name = 'heart',
            x = self.x,
            y = self.y,
            room = room
        }
    end
end

function Entity:destroy()
    self.in_remove_queue = true
end

function Entity:isEnteringOpenDoorway(direction)
    -- helper to enable other methods to detect doorways
    -- with the same syntatical patterns as objects detection

    for _, doorway in pairs(self.room.doorways) do
        if doorway.open and doorway.direction == direction then
            if self:collides(doorway) then
                return true
            end
        end
    end
    return false
end

function Entity:getHitbox()
    -- helper to create a hitbox for collision/interaction detection
    
    local offsetX, offsetY, width, height = 0, 0, self.width, self.height

    if self.hitboxOffset then
        offsetX = self.hitboxOffset.x or 0
        offsetY = self.hitboxOffset.y or 0
        width = self.hitboxOffset.width or self.width
        height = self.hitboxOffset.height or self.height
    end

    return Hitbox(self.x + offsetX, self.y + offsetY, width, height)
end
