--[[
    Empire Engine
    Based on CS50 2D Coursework

    SaveLoad.lua

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    JSON-based persistence layer. Supports 3 named save slots plus
    one autosave slot. Each slot is a separate JSON file. Backward
    compatible with the legacy single save.json file.
]]

local json = require 'lib.json'

SaveLoad = {}

-- ================== claude_changes_2026-05-25-1228 ==================
-- slot file map; 1-3 are manual saves, 'auto' is the autosave slot
local SLOT_FILES = {
    [1]      = 'save_1.json',
    [2]      = 'save_2.json',
    [3]      = 'save_3.json',
    ['auto'] = 'autosave.json',
}
-- legacy single-file name; kept so old saves can still be detected
local LEGACY_FILE = 'save.json'

-- shared serializer: packs player + world into a data table for any slot
local function buildSaveData(player, world, slotId)
    local buses = {}
    for _, b in ipairs(player.businesses) do
        buses[#buses+1] = {
            type       = b.type,
            cash       = b.cash,
            reputation = b.reputation,
            age        = b.age,
            scaleTier  = b.scaleTier,      -- scale tier; nil on older saves (ok)
            stockLevel = b.stockLevel,     -- retail stock; nil on non-retail (ok)
            employees  = (function()
                local out = {}
                for _, e in ipairs(b.employees or {}) do
                    out[#out+1] = { name = e.name, role = e.role, salary = e.salary, capacityBonus = e.capacityBonus }
                end
                return out
            end)(),
            -- ================== claude_changes_2026-05-25-1330 ==================
            autoReorderEnabled   = b.autoReorderEnabled,
            autoReorderThreshold = b.autoReorderThreshold,
            autoReorderQuantity  = b.autoReorderQuantity,
            equipment            = b.equipment or {},
            -- ====================================================================
        }
    end

    return {
        version    = 2,
        savedAt    = os.date('%Y-%m-%d %H:%M'),
        slotId     = slotId,
        world_time = world.time,
        player = {
            cash        = player.cash,
            health      = player.health,
            hasBoomerang = player.hasBoomerang or false,
            name        = player.name or 'PLAYER',
        },
        market = {
            sentiment   = world.market.sentiment,
            gdpGrowth   = world.market.gdpGrowth,
            interestRate = world.market.interestRate,
            volatility  = world.market.volatility,
        },
        businesses = buses,
    }
end

-- write a save to a specific slot (1, 2, 3, or 'auto')
function SaveLoad.save(player, world, slotId)
    slotId = slotId or 1
    local file = SLOT_FILES[slotId]
    if not file then return false end
    local data = buildSaveData(player, world, slotId)
    return love.filesystem.write(file, json.encode(data))
end

-- shorthand for autosave
function SaveLoad.autoSave(player, world)
    return SaveLoad.save(player, world, 'auto')
end

-- read and decode a slot; returns data table or nil
function SaveLoad.load(slotId)
    slotId = slotId or 1
    local file = SLOT_FILES[slotId]
    if not file then return nil end
    if not love.filesystem.getInfo(file) then return nil end
    local str = love.filesystem.read(file)
    if not str then return nil end
    local ok, data = pcall(json.decode, str)
    if not ok then return nil end
    return data
end

-- returns true if at least one manual slot (1-3) has a save file
-- also checks the legacy save.json for backward compat
-- pass slotId to check a specific slot
function SaveLoad.hasSave(slotId)
    if slotId then
        return love.filesystem.getInfo(SLOT_FILES[slotId] or '') ~= nil
    end
    for id = 1, 3 do
        if love.filesystem.getInfo(SLOT_FILES[id]) then return true end
    end
    return love.filesystem.getInfo(LEGACY_FILE) ~= nil
end

-- returns a table of 4 slot descriptors for the slot picker UI
-- each entry: { id, label, empty, savedAt, playerName, cash }
function SaveLoad.listSlots()
    local defs = {
        { id = 1,      label = 'Save 1'   },
        { id = 2,      label = 'Save 2'   },
        { id = 3,      label = 'Save 3'   },
        { id = 'auto', label = 'AUTOSAVE' },
    }
    local slots = {}
    for _, def in ipairs(defs) do
        local file = SLOT_FILES[def.id]
        local exists = love.filesystem.getInfo(file) ~= nil
        if exists then
            local str = love.filesystem.read(file)
            local ok, data = pcall(json.decode, str or '')
            if ok and data and data.player then
                slots[#slots+1] = {
                    id         = def.id,
                    label      = def.label,
                    empty      = false,
                    savedAt    = data.savedAt or '---',
                    playerName = data.player.name or 'PLAYER',
                    cash       = data.player.cash or 0,
                }
            else
                slots[#slots+1] = { id = def.id, label = def.label, empty = true }
            end
        else
            -- check legacy file for slot 1 only
            if def.id == 1 and love.filesystem.getInfo(LEGACY_FILE) then
                local str = love.filesystem.read(LEGACY_FILE)
                local ok, data = pcall(json.decode, str or '')
                if ok and data and data.player then
                    slots[#slots+1] = {
                        id         = def.id,
                        label      = 'Save 1 (legacy)',
                        empty      = false,
                        savedAt    = '(old save)',
                        playerName = data.player.name or 'PLAYER',
                        cash       = data.player.cash or 0,
                        legacyLoad = true,
                    }
                else
                    slots[#slots+1] = { id = def.id, label = def.label, empty = true }
                end
            else
                slots[#slots+1] = { id = def.id, label = def.label, empty = true }
            end
        end
    end
    return slots
end

-- load a legacy save.json (for backward compat migration)
function SaveLoad.loadLegacy()
    if not love.filesystem.getInfo(LEGACY_FILE) then return nil end
    local str = love.filesystem.read(LEGACY_FILE)
    if not str then return nil end
    local ok, data = pcall(json.decode, str)
    if not ok then return nil end
    return data
end
-- ====================================================================
