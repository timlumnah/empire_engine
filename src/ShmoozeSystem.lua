--[[
    Empire Engine
    Based on CS50 2D Coursework

    ShmoozeSystem.lua

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    Manages NPC walk-to-door choreography after a successful shmooze.
    Tracks per-NPC walker state machines (walking -> particles -> done),
    finds nearest locked doorways, and renders the unlock particle burst.
]]

ShmoozeSystem = Class{}

function ShmoozeSystem:init()
    self.walkers = {}
    self.lastRoom = nil
end

local function findNearestLockedDoorway(entity, room)
    -- returns closest doorway with open=false, or nil
    local best, bestDist = nil, math.huge
    local cx = entity.x + entity.width / 2
    local cy = entity.y + entity.height / 2
    for _, door in pairs(room.doorways) do
        if not door.open then
            local dx = door.x + door.width / 2 - cx
            local dy = door.y + door.height / 2 - cy
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist < bestDist then
                bestDist = dist
                best = door
            end
        end
    end
    return best
end

local function getDoorApproachPos(doorway)
    -- target doorway center; closed wall stops NPC at the arch
    return {
        x = doorway.x + doorway.width / 2,
        y = doorway.y + doorway.height / 2,
    }
end

function ShmoozeSystem:update(dt, room)
    -- clear walkers on room change
    if room ~= self.lastRoom then
        for _, w in ipairs(self.walkers) do
            if w.entity then w.entity.walkTarget = nil end
        end
        self.walkers = {}
        self.lastRoom = room
    end

    -- pick up walkToDoor requests set by NpcMenu on any NPC
    for _, entity in ipairs(room.entities) do
        if entity.walkToDoor then
            entity.walkToDoor = false
            local doorway = findNearestLockedDoorway(entity, room)
            if doorway then
                entity.walkTarget = getDoorApproachPos(doorway)
                table.insert(self.walkers, {
                    entity = entity,
                    doorway = doorway,
                    phase = 'walking',
                    walkTimer = 0,
                    psystem = nil,
                    psTimer = 0,
                })
            end
        end
    end

    -- advance each walker's phase
    for i = #self.walkers, 1, -1 do
        local w = self.walkers[i]

        if w.phase == 'walking' then
            w.walkTimer = w.walkTimer + dt
            local tx = w.entity.walkTarget.x
            local ty = w.entity.walkTarget.y
            local cx = w.entity.x + w.entity.width / 2
            local cy = w.entity.y + w.entity.height / 2
            local dist = math.sqrt((cx - tx)^2 + (cy - ty)^2)
            -- arrived or 8s failsafe
            if dist < 20 or w.walkTimer > 8 then
                w.entity.walkTarget = nil
                w.entity:changeState('idle')
                w.phase = 'particles'
                w.psTimer = 0
                local ps = love.graphics.newParticleSystem(gTextures['particle'], 80)
                ps:setParticleLifetime(0.5, 1.0)
                ps:setLinearAcceleration(-40, -90, 40, 10)
                ps:setEmissionArea('normal', 10, 6)
                ps:setColors(1, 1, 0.4, 1, 1, 0.55, 0.1, 0)
                ps:emit(80)
                w.psystem = ps
            end

        elseif w.phase == 'particles' then
            w.psTimer = w.psTimer + dt
            w.psystem:update(dt)
            if w.psTimer >= 0.6 and not w.doorway.open then
                w.doorway.open = true
                gSounds['door-open-1']:play()
                w.door2Timer = gSounds['door-open-1']:getDuration()
            end
            if w.door2Timer then
                w.door2Timer = w.door2Timer - dt
                if w.door2Timer <= 0 then
                    w.door2Timer = nil
                    gSounds['door-open-2']:play()
                end
            end
            if w.psystem:getCount() == 0 then
                w.phase = 'done'
            end

        elseif w.phase == 'done' then
            table.remove(self.walkers, i)
        end
    end
end

function ShmoozeSystem:render()
    love.graphics.setColor(1, 1, 1, 1)
    for _, w in ipairs(self.walkers) do
        if w.psystem and w.phase == 'particles' then
            local px = w.doorway.x + w.doorway.width / 2
            local py = w.doorway.y + w.doorway.height / 2
            love.graphics.draw(w.psystem, px, py)
        end
    end
end
