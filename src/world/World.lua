--[[
   Empire Engine
   Based on CS50 2D Coursework

   -- World --

   Author: Tim Lumnah
   github.com/timlumnah/empire_engine

   The 2D grid of Rooms plus the global Market simulation. Manages
   the camera-shift animation between adjacent rooms, dispatches
   shift events, tracks in-game time, and owns the Market instance.
]]

World = Class{}

function World:init(player, rooms, startX, startY)
    self.player = player
    self.market = Market()
    self.time = 0

    -- container for all rooms in the world grid
    self.rooms = rooms or {}

    -- current room we're operating in
    self.currentRoom = rooms[startY][startX]

    -- room we're moving camera to during a shift; becomes active room afterwards
    self.nextRoom = nil

    -- love.graphics.translate values, only when shifting screens and reset to 0 afterwards
    self.cameraX = 0
    self.cameraY = 0
    self.shifting = false

    -- trigger camera translation and adjustment of rooms whenever the player triggers a shift
    -- via a doorway collision, triggered in PlayerWalkState
    self.shiftHandlers = {
        Event.on('shift-left', function()
            self:beginShifting(-VIRTUAL_WIDTH, 0)
            return false
        end),
        Event.on('shift-right', function()
            self:beginShifting(VIRTUAL_WIDTH, 0)
            return false
        end),
        Event.on('shift-up', function()
            self:beginShifting(0, -VIRTUAL_HEIGHT)
            return false
        end),
        Event.on('shift-down', function()
            self:beginShifting(0, VIRTUAL_HEIGHT)
            return false
        end)
    }
end


function World:buildMarketContext(bus)
    local room = self.currentRoom
    local biomeDemand = (room.biome and room.biome.demand) or 1.0
    local sameType = 0
    for _, entity in ipairs(room.entities) do
        if entity.isCompetitor and not entity.dead and entity.businesses then
            for _, cb in ipairs(entity.businesses) do
                if cb.type == bus.type then
                    sameType = sameType + 1
                end
            end
        end
    end
    local compFactor = 1 / (1 + sameType * COMPETITION_WEIGHT)
    local priceMult = 1 + SCARCITY_BONUS / (1 + sameType)
    return { demandMult = biomeDemand * compFactor, priceMult = priceMult }
end

function World:update(dt)
    self.time = self.time + dt

    -- always update global simulation
    self.market:update(dt)

    local totalProfit = 0

    for _, bus in ipairs(self.player.businesses) do
        local ctx = self:buildMarketContext(bus)
        local profit = bus:update(dt, self.market, ctx)
        totalProfit = totalProfit + (profit or 0)
    end

    -- deduct loan interest payments (interest-only, per-second rate)
    if self.player.loans then
        for _, loan in ipairs(self.player.loans) do
            totalProfit = totalProfit - (loan.monthlyPayment / SECONDS_PER_MONTH) * dt
        end
    end

    -- apply net profit/loss to player
    self.player.cash = self.player.cash + totalProfit

    -- pause room updates if shifting
    if not self.shifting then
        self.currentRoom:update(dt)
    else
        -- still update the player animation if we're shifting rooms
        if self.player.currentAnimation then
            self.player.currentAnimation:update(dt)
        end
    end
end



--[[
    Destroys the world, removing any event handlers that were active for shifting.
    Otherwise, we can run into an issue where the next world will trigger stale
    handlers and potentially crash the game.
]]
function World:destroy()
    if not self.shiftHandlers then
        return
    end

    for _, handler in ipairs(self.shiftHandlers) do
        handler:remove()
    end

    self.shiftHandlers = nil
end

-- re-register shift event handlers after a destroy() call
function World:reattach()
    if self.shiftHandlers then return end
    self.shiftHandlers = {
        Event.on('shift-left',  function() self:beginShifting(-VIRTUAL_WIDTH, 0) return false end),
        Event.on('shift-right', function() self:beginShifting(VIRTUAL_WIDTH, 0)  return false end),
        Event.on('shift-up',    function() self:beginShifting(0, -VIRTUAL_HEIGHT) return false end),
        Event.on('shift-down',  function() self:beginShifting(0, VIRTUAL_HEIGHT)  return false end),
    }
end

--[[
    Prepares for the camera shifting process, kicking off a tween of the camera position.
]]
function World:beginShifting(shiftX, shiftY)
    if self.shifting or not self.currentRoom then
        return
    end

    local nextRoomX = self.currentRoom.x + (shiftX > 0 and 1 or (shiftX < 0 and -1 or 0))
    local nextRoomY = self.currentRoom.y + (shiftY > 0 and 1 or (shiftY < 0 and -1 or 0))
    local nextRoom = self.rooms[nextRoomY] and self.rooms[nextRoomY][nextRoomX]

    if not nextRoom then
        return
    end

    -- ensure boomerang despawns if in flight
    self.currentRoom:clearProjectiles()

    -- commence shifting and load room we're transitioning to
    self.shifting = true
    self.nextRoom = nextRoom

    -- offset set depending on which direction we generate the room
    self.nextRoom.adjacentOffsetX = shiftX
    self.nextRoom.adjacentOffsetY = shiftY

    -- tween the player position so they move through the doorway
    local playerX, playerY = self.player.x, self.player.y

    -- figure out where player's X or Y should end up in the next room off screen
    if shiftX > 0 then
        playerX = VIRTUAL_WIDTH + (MAP_RENDER_OFFSET_X + TILE_SIZE)
    elseif shiftX < 0 then
        playerX = -VIRTUAL_WIDTH + (MAP_RENDER_OFFSET_X + (MAP_WIDTH * TILE_SIZE) - TILE_SIZE - self.player.width)
    elseif shiftY > 0 then
        playerY = VIRTUAL_HEIGHT + (MAP_RENDER_OFFSET_Y + self.player.height / 2)
    else
        playerY = -VIRTUAL_HEIGHT + MAP_RENDER_OFFSET_Y + (MAP_HEIGHT * TILE_SIZE) - TILE_SIZE - self.player.height
    end

    -- tween the camera in whichever direction the new room is in, as well as the player to be
    -- at the opposite door in the next room, walking through the wall (which is stenciled)
    Timer.tween(1, {
        [self] = {cameraX = shiftX, cameraY = shiftY},
        [self.player] = {x = playerX, y = playerY}
    }):finish(function()

        -- set everything back to 0, with next room now the current room
        self:finishShifting()

        -- reset player to the correct location in this room, negating off-screen offsets
        if shiftX < 0 then
            self.player.x = MAP_RENDER_OFFSET_X + (MAP_WIDTH * TILE_SIZE) - TILE_SIZE - self.player.width
            self.player.direction = 'left'
        elseif shiftX > 0 then
            self.player.x = MAP_RENDER_OFFSET_X + TILE_SIZE
            self.player.direction = 'right'
        elseif shiftY < 0 then
            self.player.y = MAP_RENDER_OFFSET_Y + (MAP_HEIGHT * TILE_SIZE) - TILE_SIZE - self.player.height
            self.player.direction = 'up'
        else
            self.player.y = MAP_RENDER_OFFSET_Y + self.player.height / 2
            self.player.direction = 'down'
        end

    end)
end

--[[
    Resets a few variables needed to perform a camera shift and swaps the next and
    current room.
]]
function World:finishShifting()

    -- reset camera and deactivate shifting to avoid translation
    self.cameraX = 0
    self.cameraY = 0
    self.shifting = false

    -- point to transitioned room as the new active room, pointing to an empty room next
    self.currentRoom = self.nextRoom
    self.nextRoom = nil

    -- this room (previously the off-screen room) should now be in the center, not offset
    self.currentRoom.adjacentOffsetX = 0
    self.currentRoom.adjacentOffsetY = 0

    -- ensure the player's room updates
    self.player.room = self.currentRoom

    -- ================== claude_changes_2026-05-23-1033 ==================
    -- snap all entities to room center on room entry so none block the doorway.
    -- NPCs wander freely during gameplay and can drift to doorway positions;
    -- resetting here prevents the player from spawning into a blocked threshold.
    -- ================== claude_changes_2026-05-23-1228 ==================
    -- scatter entities to 4 quadrant positions around center so they don't
    -- all stack on the same pixel and get stuck. 24px gap clears 16px entity width.
    local cx = MAP_RENDER_OFFSET_X + (MAP_WIDTH * TILE_SIZE) / 2 - 8
    local cy = MAP_RENDER_OFFSET_Y + (MAP_HEIGHT * TILE_SIZE) / 2 - 8
    local offsets = { {-24, -24}, {24, -24}, {-24, 24}, {24, 24} }
    local i = 1
    for _, entity in ipairs(self.currentRoom.entities) do
        if not entity.dead then
            local off = offsets[((i - 1) % 4) + 1]
            entity.x = cx + off[1]
            entity.y = cy + off[2]
            i = i + 1
        end
    end
    -- ====================================================================
end

function World:render()

    -- translate the camera if we're actively shifting
    if self.shifting then
        love.graphics.translate(-math.floor(self.cameraX), -math.floor(self.cameraY))
    end

    self.currentRoom:render()

    if self.nextRoom then
        self.nextRoom:render()
    end
end
