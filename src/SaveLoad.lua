--[[
    Empire Engine
    Based on CS50 2D Coursework

    SaveLoad.lua

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    JSON-based persistence layer. Serailizes player stats, inventory,
    owned businesses, and loan data to love.filesystem on save, and
    restores the full game state from that file on load.
]]



-- json library lives in lib folder, used for encode and decode
local json = require 'lib.json'

-- plain table, not a class, just a namespace for save and load functions
SaveLoad = {}

-- save file goes into love.filesystem which is the OS app data directory
-- NOT the project folder, so the file survives game updates
local FILE = 'save.json'

-- check whether a save file exists without reading it
-- used by PauseMenu to enable or disable the Load option
function SaveLoad.hasSave()
    return love.filesystem.getInfo(FILE) ~= nil
end

-- serializes the current game state to JSON and writes it to disk
-- player and world are the live PlayState instances
function SaveLoad.save(player, world)
    -- strip each buisness down to just what we need to reconstruct it on load
    -- employees, transactions, and animations are not saved, they reset each run
    local buses = {}
    for _, b in ipairs(player.businesses) do
        buses[#buses+1] = {
            type = b.type,          -- used to look up the def in BUSINESS_TYPES on load
            cash = b.cash,          -- accumulated cash balance including startup debt
            reputation = b.reputation, -- carry over earned reputation between sessions
            age = b.age,            -- how long the buisness has been running in seconds
        }
    end

    -- pack everything we want to persist into one flat table
    local data = {
        version = 1,            -- version field for future migration support
        world_time = world.time, -- total elapsed game seconds, used for display
        player = {
            cash = player.cash,
            health = player.health,
            hasBoomerang = player.hasBoomerang or false, -- equipment flag
        },
        market = {
            -- persist market state so the economic cycle continues from where it left off
            -- active events are not saved, they will reset on load
            sentiment = world.market.sentiment,
            gdpGrowth = world.market.gdpGrowth,
            interestRate = world.market.interestRate,
            volatility = world.market.volatility,
        },
        businesses = buses,
    }

    -- encode the table to JSON and write it to the love filesystem
    return love.filesystem.write(FILE, json.encode(data))
end

-- reads and decodes the save file from disk
-- returns the decoded data table on success, nil on failure or missing file
function SaveLoad.load()
    -- bail early if no save file, common on first launch
    if not SaveLoad.hasSave() then return nil end
    local str = love.filesystem.read(FILE)
    if not str then return nil end
    -- pcall prevents corrupt or malformed JSON from crashing teh game
    -- if decode fails we just return nil and the game starts fresh
    local ok, data = pcall(json.decode, str)
    if not ok then return nil end
    return data
end
