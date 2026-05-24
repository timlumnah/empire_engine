--[[
   Empire Engine
   Based on CS50 2D Coursework

   -- Business Types List --

   Author: Tim Lumnah
   github.com/timlumnah/empire_engine

   Static configuration table for all purchasble business types
   (laundromat, retail, restaurant, car dealer, casino, aerospace).
   Each entry defines startup cost, pricing, capacity, risk, and
   initial financial state used when a Business instance is created.
]]

-- all purchasable buisness types, keyed by type string
-- Business:init copies these fields onto self using a for loop
-- adding a new entry here and to BUSINESS_ORDER in BusinessOpenMenu is all you need
BUSINESS_TYPES = {

    -- cheapest and safest buisness, good first purchace for early game
    -- low capacity but also low risk so demand stays relatvely steady
    ['laundromat'] = {
        type = "laundromat",
        displayName = "Laundromat",
        startupCost = 7000,     -- player pays this amount when confirming purchase
        basePrice = 5,         -- price per unit sold to customers
        fixedCosts = 500,      -- rent and utilities, deducted once per game month
        variableCost = 1,      -- what it costs to produce each unit sold
        capacity = 400,        -- max units this buisness can sell in one game month
        risk = 0.1              -- low risk, demand wont swing much from the random factor
    },

    -- mid range retail shop, higher revenue ceiling but bigger overhead
    -- retail has extra fields set explictly as an example of a more complete def
    ['retail'] = {
        type = "retail",
        displayName = "Retail",
        startupCost = 10000,
        basePrice = 50,          -- price per unit sold
        fixedCosts = 3000,      -- monthly rent, utilities, staff
        unitWholeSaleCost = 4,       -- wholesale cost per unit, maps to variableCost in Business:update
        capacity = 1000,         -- max units per month
        risk = 0.2,             -- moderate risk, demand can fluctuate more than laundromat
        startingCash = 2000,    -- this entry gives the buisness some starting cash unlike others
        startingReputation = 0.8, -- slightly below average rep at start
        marketMultiplier = 1.0, -- no special market bonus or penaly
        employees = {},         -- no starting employees
        products = {},
        services = {},
        transactions = {},
        animations = {},
        callbacks = {},
        -- tracking fields preinitialized here so the nil check in Business:init is skipped
        trackingMetrics = {
            LifeTimeUnitsSold = 0,
            LifeTimeRevenue = 0,
            fixedCostsPerSecond = 0,
            revenueLastFrame = 0,
            profitLastFrame = 0,
            costsLastFrame = 0,
            unitsSoldLastFrame = 0,
        }
    },

    -- restaurant is the mid tier high volume option
    -- more revenue per unit than retail but also higher fixed overhead each month
    ['restaurant'] = {
        type = "restaurant",
        displayName = "Restaurant",
        startupCost = 50000,    -- significanlty more expensive than retail to open
        basePrice = 20,        -- price per meal
        fixedCosts = 5000,     -- kitchen staff and rent, heavy monthly drag
        variableCost = 8,      -- food cost per meal, 40 percent of sale price
        capacity = 1500,       -- meals per month, high volume business
        risk = 0.2              -- same risk as retail
    },

    -- car dealer is the first big ticket item, high revenue per sale but few units
    -- profit per unit is huge but capacity is tiny so monthly volume is low
    ['car_dealer'] = {
        type = "car_dealer",
        displayName = "Car Dealer",
        startupCost = 100000,   -- requires serious savings before the player can afford this
        basePrice = 25000,     -- average sale price per vehicle
        fixedCosts = 20000,    -- showroom lease and staff salaries each month
        variableCost = 15000,  -- wholesale cost per car, leaves 10k gross margin
        capacity = 10,         -- only 10 cars per month max, low volume high margin
        risk = 0.3              -- higher risk than restaurant, demand swings more
    },

    -- endgame tier, only availible in the endgame biome room
    -- aerospace has huge revenue but also huge risk, can swing wildly
    ['aerospace'] = {
        type = "aerospace",
        displayName = "Aerospace Company",
        startupCost = 10000000, -- costs 10 million to open, basically end game only
        basePrice = 1000000,   -- one million per contract when a deal closes
        fixedCosts = 500000,   -- research and developement plus salaries, heavy burn
        variableCost = 700000, -- cost to deliver each contract, 70 percent of revenue
        capacity = 5,          -- only 5 contracts possible per month
        risk = 0.8              -- very high risk, demand is extreamly volatile
    },

    -- casino is also endgame tier, similar cost to aerospace but different economics
    -- high visitor volume means more consistent income than the low capacity aerospace
    ['casino'] = {
        type = "casino",
        displayName = "Casino",
        startupCost = 9000000,  -- slightly cheaper than aerospace to open
        basePrice = 100,       -- average revenue per visitor, house always wins
        fixedCosts = 500000,   -- staff and maintenence, same burn as aerospace
        variableCost = 20,     -- per visitor operating cost, low relative to revenue
        capacity = 10000,      -- 10000 visitors per month, very high volume
        risk = 0.7              -- high risk but not quite as wild as aerospace
    }
}
