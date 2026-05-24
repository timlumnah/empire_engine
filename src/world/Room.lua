--[[
    Empire Engine
    Based on CS50 2D Coursework

    -- constants --

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    A single screen-sized room in the world grid. Generates wall and
    floor tiles, spawns entities and objects, updates all actors each
    frame, and renders the room with stencil-masked doorway arches.
]]

Room = Class{}

function Room:init(player, x, y, chest)

    self.width = MAP_WIDTH
    self.height = MAP_HEIGHT
    self.x = x or 1
    self.y = y or 1

    -- assigned by WorldMaker after construction
    self.biome = nil

    self.tiles = {}


    -- game objects in the room
    self.chest = chest or false
    self.objects = {}
    self:generateObjects()
    
    -- entities in the room
    self.entities = {}
    self:generateEntities()

    -- projectiles in the room
    self.projectiles = {}

    -- reference to player for collisions, etc.
    self.player = player

    -- used for centering the world rendering
    self.renderOffsetX = MAP_RENDER_OFFSET_X
    self.renderOffsetY = MAP_RENDER_OFFSET_Y

    -- used for drawing when this room is the next room, adjacent to the active
    self.adjacentOffsetX = 0
    self.adjacentOffsetY = 0


end



--[[
    Generates the walls and floors of the room, randomizing the various varieties
    of said tiles for visual variety.
]]
function Room:generateWallsAndFloors()
    -- NOTES: tile graphics are defined in constants.lua
    -- they reference quads in graphics/tilesheet.png

    -- pick floor tile: biome.floor holds TILE_FLOORS indices; fallback picks index directly
    if self.biome and self.biome.floor then
        floor_tile = TILE_FLOORS[self.biome.floor[math.random(#self.biome.floor)]]
    else
        floor_tile = TILE_FLOORS[math.random(#TILE_FLOORS)]
    end

    for y = 1, self.height do
        table.insert(self.tiles, {})

        for x = 1, self.width do
            local id = TILE_EMPTY

            if x == 1 and y == 1 then
                id = TILE_TOP_LEFT_CORNER
            elseif x == 1 and y == self.height then
                id = TILE_BOTTOM_LEFT_CORNER
            elseif x == self.width and y == 1 then
                id = TILE_TOP_RIGHT_CORNER
            elseif x == self.width and y == self.height then
                id = TILE_BOTTOM_RIGHT_CORNER
            
            -- random left-hand walls, right walls, top, bottom, and floors
            elseif x == 1 then
                id = TILE_LEFT_WALLS[math.random(#TILE_LEFT_WALLS)]
            elseif x == self.width then
                id = TILE_RIGHT_WALLS[math.random(#TILE_RIGHT_WALLS)]
            elseif y == 1 then
                id = TILE_TOP_WALLS[math.random(#TILE_TOP_WALLS)]
            elseif y == self.height then
                id = TILE_BOTTOM_WALLS[math.random(#TILE_BOTTOM_WALLS)]
            else
                -- id = TILE_FLOORS[math.random(#TILE_FLOORS)]
                id = floor_tile
            end
            
            table.insert(self.tiles[y], {
                id = id
            })
        end
    end
end





function Room:update(dt)
    
    -- don't update anything if we are sliding to another room (we have offsets)
    if self.adjacentOffsetX ~= 0 or self.adjacentOffsetY ~= 0 then return end

    self.player:update(dt)


    for i = #self.entities, 1, -1 do
        local entity = self.entities[i]

        -- friendly entities cannot be killed; killable flag overrides for competitors
        if entity.health <= 0 and not entity.dead and (not entity.friendly or entity.killable) then
            entity:die(self)
        end

        if not entity.dead then
            entity:processAI({room = self}, dt)
            entity:update(dt)
        end


        if entity.in_remove_queue then
            -- remove the entity from the table so it doesn't keep getting iterated over
            table.remove(self.entities, i)
        end
    end

    for i = #self.objects, 1, -1 do
        local object = self.objects[i]
        
        object:update(dt)

        -- initialize cooldown timer if missing
        object._collideCooldown = object._collideCooldown or 0

        -- reduce cooldown
        if object._collideCooldown > 0 then
            object._collideCooldown = object._collideCooldown - dt
        end

        -- check collision only if cooldown expired
        if self.player:collides(object) and object._collideCooldown <= 0 then

            -- trigger collision callback on object
            if object.consumable then
                object.onConsume(self.player, object, self)
            
            -- elseif object.solid then
            else
                object.onCollide(self.player, object, self)
            end

            object._collideCooldown = 0.5
        end

        if object.in_remove_queue then
            table.remove(self.objects, i)
        end
    end

    for i = #self.projectiles, 1, -1 do
        local projectile = self.projectiles[i]

        projectile:update(dt)

        -- collision with entities; skip friendly NPCs and invulnerable targets
        for _, entity in pairs(self.entities) do
            if not entity.friendly and not entity.invulnerable and entity:collides(projectile) then
                projectile:onHitEntity(entity)
            end
        end

        if projectile.in_remove_queue then
            table.remove(self.projectiles, i)
        end
    end
end

function Room:render()
    -- draw walls & floor
    for y = 1, self.height do
        for x = 1, self.width do
            local tile = self.tiles[y][x]
            love.graphics.draw(gTextures['tiles'], gFrames['tiles'][tile.id],
                (x - 1) * TILE_SIZE + self.renderOffsetX + self.adjacentOffsetX, 
                (y - 1) * TILE_SIZE + self.renderOffsetY + self.adjacentOffsetY)
        end
    end

    -- render doorways; stencils are placed where the arches are after so the player can
    -- move through them convincingly
    for k, doorway in pairs(self.doorways) do
        doorway:render(self.adjacentOffsetX, self.adjacentOffsetY)
    end

    for k, object in pairs(self.objects) do
        if not object.isHeld then
            object:render(self.adjacentOffsetX, self.adjacentOffsetY)
        end
    end

    for _, projectile in pairs(self.projectiles) do
        projectile:render()
    end

    for k, entity in pairs(self.entities) do
        if not entity.dead then entity:render(self.adjacentOffsetX, self.adjacentOffsetY) end
    end

    --[[
        LÖVE 11 VERSION
    ]]
    -- stencil out the door arches so it looks like the player is going through
    love.graphics.stencil(function()
        
        -- left
        love.graphics.rectangle('fill', -TILE_SIZE - 6, MAP_RENDER_OFFSET_Y + (MAP_HEIGHT / 2) * TILE_SIZE - TILE_SIZE,
            TILE_SIZE * 2 + 6, TILE_SIZE * 2)
        
        -- right
        love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH * TILE_SIZE),
            MAP_RENDER_OFFSET_Y + (MAP_HEIGHT / 2) * TILE_SIZE - TILE_SIZE, TILE_SIZE * 2 + 6, TILE_SIZE * 2)
        
        -- top
        love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH / 2) * TILE_SIZE - TILE_SIZE,
            -TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)
        
        --bottom
        love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH / 2) * TILE_SIZE - TILE_SIZE,
            VIRTUAL_HEIGHT - TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)
    end, 'replace', 1)

    love.graphics.setStencilTest('less', 1)
    
    if self.player then
        self.player:render()
    end

    love.graphics.setStencilTest()

end



function Room:generateEntities()
    -- Spawns 2 random NPC entities (dude/dudette) + 1 guaranteed banker.
    -- Uses valid_spawn() to avoid overlap with objects and other entities.

    -- build random pool: biome entities minus banker (banker always spawns separately)
    local pool = {}
    local rawTypes = (self.biome and self.biome.entities) or {'dude', 'dudette'}
    for _, t in ipairs(rawTypes) do
        if t ~= 'banker' then pool[#pool + 1] = t end
    end
    if #pool == 0 then pool = {'dude', 'dudette'} end

    -- helper: find a valid spawn position
    local function find_spawn()
        local x, y
        local attempts = 0
        repeat
            x = math.random(MAP_RENDER_OFFSET_X + TILE_SIZE, VIRTUAL_WIDTH - TILE_SIZE * 2 - 16)
            y = math.random(
                MAP_RENDER_OFFSET_Y + TILE_SIZE,
                VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE)
                    + MAP_RENDER_OFFSET_Y - TILE_SIZE - 16
            )
            attempts = attempts + 1
        until self:valid_spawn(x, y, 16, 16) or attempts > 50
        if attempts <= 50 then return x, y end
        return nil, nil
    end

    -- spawn 2 random dude/dudette NPCs
    for i = 1, 2 do
        local npcType = pool[math.random(#pool)]
        local x, y = find_spawn()
        if x then
            local entity = Entity {
                animations = ENTITY_DEFS[npcType].animations,
                walkSpeed = ENTITY_DEFS[npcType].walkSpeed or 20,
                x = x, y = y, width = 16, height = 16,
                health = 999, room = self
            }
            entity.friendly = true
            entity.solid = true
            entity.displayName = npcType
            entity.affinity = 0
            entity.onInteract = function(player)
                player.wantsNpcMenu = { npc = entity, isBanker = false }
            end
            entity.stateMachine = StateMachine {
                ['walk'] = function() return EntityWalkState(entity) end,
                ['idle'] = function() return EntityIdleState(entity) end
            }
            entity:changeState('walk')
            table.insert(self.entities, entity)
        end
    end

    -- spawn 1 banker NPC
    local bx, by = find_spawn()
    if bx then
        local banker = Entity {
            animations = ENTITY_DEFS['banker'].animations,
            walkSpeed = ENTITY_DEFS['banker'].walkSpeed or 20,
            x = bx, y = by, width = 16, height = 16,
            health = 999, room = self
        }
        banker.friendly = true
        banker.isBanker = true
        banker.solid = true
        banker.displayName = 'banker'
        banker.affinity = 0
        banker.onInteract = function(player)
            player.wantsNpcMenu = { npc = banker, isBanker = true }
        end
        banker.stateMachine = StateMachine {
            ['walk'] = function() return EntityWalkState(banker) end,
            ['idle'] = function() return EntityIdleState(banker) end
        }
        banker:changeState('walk')
        table.insert(self.entities, banker)
    end

    -- spawn 1 competitor (walks around, not shmoozable, owns biome businesses)
    local cx, cy = find_spawn()
    if cx then
        local competitor = Entity {
            animations = ENTITY_DEFS['competitor'].animations,
            walkSpeed = ENTITY_DEFS['competitor'].walkSpeed or 18,
            x = cx, y = cy, width = 16, height = 16,
            health = 3, room = self
        }
        competitor.killable = true
        competitor.solid = true
        competitor.isCompetitor = true
        competitor.onDeath = function() Event.dispatch('competitor-killed') end
        competitor.displayName = 'competitor'
        competitor.onInteract = function(player)
            player.wantsCompetitorInteract = true
        end
        -- pre-load one of each business type available in this biome
        competitor.businesses = {}
        local biomeBusinesses = (self.biome and self.biome.businesses) or {}
        for _, bizType in ipairs(biomeBusinesses) do
            if BUSINESS_TYPES[bizType] then
                table.insert(competitor.businesses, Business(BUSINESS_TYPES[bizType]))
            end
        end
        competitor.stateMachine = StateMachine {
            ['walk'] = function() return EntityWalkState(competitor) end,
            ['idle'] = function() return EntityIdleState(competitor) end
        }
        competitor:changeState('walk')
        table.insert(self.entities, competitor)
    end
end


function Room:generateObjects(spawn_queue, clear_objects)
    -- Randomly creates an assortment of obstacles for the player to navigate around.
    -- uses a default spawn_queue of 1 switch  and a random number of pots between 3-6.
    -- Optional params spawn_queue & clear_objects
        -- enable WorldMaker to place a chest after other objects have already been placed.

    if clear_objects then
        self.objects = {}
    end

    spawn_queue = spawn_queue or {}

    for name, count in pairs(spawn_queue) do
        for i = 1, count do

            local attempts = 0
            local maxAttempts = 50

            local x, y

            repeat
                x = math.random(
                    MAP_RENDER_OFFSET_X + TILE_SIZE,
                    VIRTUAL_WIDTH - TILE_SIZE * 2 - 16
                )

                y = math.random(
                    MAP_RENDER_OFFSET_Y + TILE_SIZE,
                    VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE)
                        + MAP_RENDER_OFFSET_Y - TILE_SIZE - 16
                )

                attempts = attempts + 1

            until self:valid_spawn(x, y, 16, 16) or attempts > maxAttempts

            if attempts <= maxAttempts then
                local obj = CALLBACKS.spawn_object{
                    name = name,
                    x = x,
                    y = y,
                    room = self
                }

                table.insert(self.objects, obj)
            else
            end
        end
    end
end

function Room:valid_spawn(x, y, width, height)
    -- Returns true if a rectangle can be placed at (x, y) without overlapping
    -- the player spawn area, existing objects, or doorway bounds.
    -- Used to ensure safe, non-blocking object placement.

    local padding = 4  -- small buffer

    -- avoid center of the room for the player
    local playerX = VIRTUAL_WIDTH / 2 - width / 2
    local playerY = VIRTUAL_HEIGHT / 2 - height / 2

    if check_overlap(x, y, width, height,
            playerX, playerY, width, height) then
        return false
    end

    -- avoid any locations where previous objects have been spawned
    for _, obj in ipairs(self.objects or {}) do
        if check_overlap(x, y, width, height,
                obj.x, obj.y, obj.width, obj.height) then
            return false
        end
    end

    -- avoid entities
    for _, entity in ipairs(self.entities or {}) do
        if check_overlap(x, y, width, height,
                entity.x, entity.y, entity.width, entity.height) then
            return false
        end
    end

    -- don't block doorways
    for _, door in ipairs(self.doorways or {}) do
        -- expand doorway hitbox slightly so we block space in front too
        local dx = door.x - padding
        local dy = door.y - padding
        local dw = door.width + padding * 2
        local dh = door.height + padding * 2

        if check_overlap(x, y, width, height, dx, dy, dw, dh) then
            return false
        end
    end

    return true
end

function check_overlap(x1, y1, w1, h1, x2, y2, w2, h2)
    -- Checks if two tiles overlap in the room.
    -- Returns true if collisions would overlap, othrewise  false.

    return x1 < x2 + w2 and
           x2 < x1 + w1 and
           y1 < y2 + h2 and
           y2 < y1 + h1
end

function Room:wall_probe(x, y)
    -- Checks whether the tile at the given world position is solid.
    -- Returns false for floor/empty tiles or out-of-bounds positions.
    -- Called in Projectile class to detect walls.

    local tile = self:getTileFromCoords(x, y)

    if not tile then
        return false
    end

    local id = tile.id

    -- floors and empty are NOT solid
    if id == TILE_EMPTY then
        return false
    end

    for _, floorId in ipairs(TILE_FLOORS) do
        if id == floorId then
            return false
        end
    end

    return true
end

function Room:clearProjectiles()
    -- utility to clear room of any projectiles when shifting to another room

    for i = #self.projectiles, 1, -1 do
        local projectile = self.projectiles[i]

        projectile:despawn()

        if projectile.in_remove_queue then
            table.remove(self.projectiles, i)
        end
    end
end

function Room:getTileFromCoords(x, y)
    -- Converts world coordinates into tile grid indices.
    -- Returns tile or nil if coords lie outside the room.

    local tileX = math.floor((x - MAP_RENDER_OFFSET_X) / TILE_SIZE) + 1
    local tileY = math.floor((y - MAP_RENDER_OFFSET_Y) / TILE_SIZE) + 1

    if tileX < 1 or tileX > self.width or tileY < 1 or tileY > self.height then
        return nil
    end

    return self.tiles[tileY][tileX]
end

