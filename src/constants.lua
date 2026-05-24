--[[
    Empire Engine
    Based on CS50 2D Coursework

    -- constants --

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    Global vars--most inherited from Zelda
    New vars added at the bottom for business sim
]]

VIRTUAL_WIDTH = 384
VIRTUAL_HEIGHT = 216

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

TILE_SIZE = 16

-- entity constants
PLAYER_WALK_SPEED = 60

-- map constants
MAP_WIDTH = VIRTUAL_WIDTH / TILE_SIZE - 2
MAP_HEIGHT = math.floor(VIRTUAL_HEIGHT / TILE_SIZE) - 2

MAP_RENDER_OFFSET_X = (VIRTUAL_WIDTH - (MAP_WIDTH * TILE_SIZE)) / 2
MAP_RENDER_OFFSET_Y = (VIRTUAL_HEIGHT - (MAP_HEIGHT * TILE_SIZE)) / 2

-- tile IDs
TILE_TOP_LEFT_CORNER = 4
TILE_TOP_RIGHT_CORNER = 5
TILE_BOTTOM_LEFT_CORNER = 23
TILE_BOTTOM_RIGHT_CORNER = 24

TILE_EMPTY = 19

TILE_FLOORS = {
    7, 8, 9, 10, 11, 12, 13, 14, 15
}

-- simulation time scale
SECONDS_PER_MONTH = 30     -- 1 game-month = 30 real seconds at 1x
SLEEP_MULTIPLIER = 10     -- sim runs at 10x during sleep
VENDOR_DELIVERY_SPEED = 15  -- 15 seconds for standard delivery.

-- player vitals
HUNGER_MAX = 10
THIRST_MAX = 10
HUNGER_DECAY_RATE = 10 / 150      -- empties in 150 real seconds (~5 game-months)
THIRST_DECAY_RATE = 10 / 120      -- empties in 120 real seconds (~4 game-months)
VITAL_HEALTH_DRAIN_SLOW = 6 / 60  -- 1 heart/minute when one vital is empty
VITAL_HEALTH_DRAIN_FAST = 6 / 20  -- 1 heart/~7s when both are empty

-- player living costs (deducted every game-month)
RENT = 1500
UTILS = 350

-- supply & demand tuning
COMPETITION_WEIGHT = 0.25   -- demand penalty per same-type competitor in room
SCARCITY_BONUS = 0.25       -- max price premium when no competition exists

-- police response tuning
POLICE_DURATION = 20        -- seconds the police response lasts
POLICE_VISION_RADIUS = 27   -- radius of player's lit circle during police blackout
RED_SPOT_RADIUS = 44        -- radius of the instant-kill police spotlight
RED_SPOT_LIFETIME = 1.0     -- seconds each red spot stays visible
RED_SPOT_GAP = 0.6          -- seconds between spots

STARTING_CASH = 2000

-- game loop conditions
WIN_CASH_GOAL = 50000000   -- reach this cash to win
BANKRUPTCY_THRESHOLD = 50000    -- (negative) debt BELOW this triggers game over

TILE_TOP_WALLS = {58, 59, 60}
TILE_BOTTOM_WALLS = {79, 80, 81}
TILE_LEFT_WALLS = {77, 96, 115}
TILE_RIGHT_WALLS = {78, 97, 116}