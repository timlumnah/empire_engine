--[[
   Empire Engine
   Based on CS50 2D Coursework

   -- Biomes Defs

   Author: Tim Lumnah
   github.com/timlumnah/empire_engine

   Static data table defining the three world biomes: start, mid,
   and endgame. Each entry lists available business types, NPC pools,
   floor tile variants, and a base demand multipiler for that region.
]]

-- each biome maps to a room in the world
-- start is the first room, endgame is the last
-- demand scales up as the player progresses through biomes
-- biome key must match what WorldMaker assigns to each room
BIOMES = {

    -- first room the player starts in, only cheap buisnesses availible here
    -- no demand bonus, this is the starting area, meant to be a bit harder
	['start'] = {
		businesses = {"retail", "laundromat"},  -- cheap buisnesses only in the start room
		entities = {"dude", "dudette", "banker"}, -- which NPCs can spawn in this biome
		objects = {"chest", "pot", "switch"},   -- world objects that can appear here
		floor = {1},    -- tile variant index for this biome, used by Room when rendering tiles
		demand = 1,     -- base demand mulitplier, no bonus in start room
	},

    -- second room, unlocked after getting affinity from a start room NPC
    -- mid tier buisnesses only, demand slightly better than start
	['mid'] = {
		businesses = {"car_dealer", "restaurant"},   -- mid tier options, more expensive to open
		entities = {"dude", "dudette", "banker"},
		objects = {"chest", "pot", "switch"},
		floor = {2},                            -- different tile set so rooms look distinct
		demand = 1.1,   -- 10 percent demand bonus, buisnesses earn more here
	},

    -- final room, only reachable after unlocking from the mid room
    -- the big ticket buisnesses are locked here on purpose, natural progression gate
	['endgame'] = {
		businesses = {"aerospace", "casino"},   -- only the big expensive endgame ones here
		entities = {"dude", "dudette", "banker"},
		objects = {"chest", "pot", "switch"},
		floor = {3},                            -- third tile variant for visual variety
		demand = 1.2,   -- best demand mulitplier in the game, 20 percent bonus
	}
}
