-- ================== claude_changes_2026-05-23-2136 ==================
--[[
   Empire Engine
   Based on CS50 2D Coursework

   -- WorldMaker.lua --

   Author: Tim Lumnah
   github.com/timlumnah/empire_engine

   Three fixed rooms in a vertical chain:
       Room 1 (start)   y=3 -- player starts here
       Room 2 (mid)     y=2 -- unlocked by shmoozing in room 1
       Room 3 (endgame) y=1 -- unlocked by shmoozing in room 2

   Each room has one door: top wall only. The door starts locked.
   Shmoozing an NPC to 3 affinity opens it.
]]
-- ====================================================================

WorldMaker = Class{}

function WorldMaker.generate(player)
    local rooms = {}
    rooms[1] = {}
    rooms[2] = {}
    rooms[3] = {}

    local room1 = Room(player, 1, 3, false)
    local room2 = Room(player, 1, 2, false)
    local room3 = Room(player, 1, 1, false)

    -- doorways set before entity generation so valid_spawn() avoids them
    room1.doorways = { Doorway('top', false, room1) }
    room2.doorways = { Doorway('top', false, room2), Doorway('bottom', true, room2) }
    room3.doorways = { Doorway('bottom', true, room3) }

    local function setup(room, biomeKey)
        room.biome = BIOMES[biomeKey]
        room.biomeName = biomeKey
        room:generateWallsAndFloors()
        -- regenerate entities with correct biome and doorways known
        room.entities = {}
        room:generateEntities()
    end

    setup(room1, 'start')
    setup(room2, 'mid')
    setup(room3, 'endgame')

    rooms[3][1] = room1
    rooms[2][1] = room2
    rooms[1][1] = room3

    return World(player, rooms, 1, 3)
end
