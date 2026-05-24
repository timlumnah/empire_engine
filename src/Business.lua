
--[[
   Empire Engine
   Based on CS50 2D Coursework

   -- Business Class --

   Author: Tim Lumnah
   github.com/timlumnah/empire_engine

   Core business entity. Manages revenue, expenses, employes,
   products, and monthly profit simulation. Supports child businesses
   and applies market-driven price and demand modifiers each update.
]]

-- one instance per buisness the player owns
-- created by BusinessOpenMenu:tryPurchase when the player confirms a purchase
Business = Class{}
-- SECONDS_PER_MONTH defined in constants.lua, controls how fast time passes

-- init builds a buisness from a def table entry from BUSINESS_TYPES
-- copies every field in the def onto self so no field needs to be named explictly
function Business:init(def)
    -- copy all fields from the def table onto self
    -- this means any new field added to a def automaticaly shows up here
    for k, v in pairs(def) do
        self[k] = v
    end

    -- callbacks in defs are stored as string names to avoid circular refs
    -- resolve them to actual functions here using the CALLBACKS global table
    if def.callbacks then
        for field, cb_name in pairs(def.callbacks) do
            self[field] = self:resolveCallback(cb_name)
        end
    end

    -- only build animation table if the def actualy has animation entries
    if def.animations and #def.animations > 0 then
        self.animations = self:createAnimations(def.animations)
    end

    -- if no callbacks were set in the def, stub them out as empty functions
    -- prevents nil errors when code calls self.onUpdate or self.onSpawn
    self.onUpdate = self.onUpdate or function() end
    self.onSpawn = self.onSpawn or function() end

    -- safe defaults for tables that may not be in the def
    -- without these, ipairs and pairs calls on these fields would crash
    self.employees = self.employees or {}
    self.children = self.children or {}
    self.products = self.products or {}
    self.services = self.services or {}
    self.transactions = self.transactions or {}

    -- tracking metrics table, used by BusinessMenu to display live stats
    -- preinitialized here so no nil checks are needed in update
    self.trackingMetrics = self.trackingMetrics or {
        LifeTimeUnitsSold = 0,
        LifeTimeRevenue = 0,
        fixedCostsPerSecond = 0,
        revenueLastFrame = 0,
        profitLastFrame = 0,
        costsLastFrame = 0,
        unitsSoldLastFrame = 0,
    }

    -- numeric fallbacks for buisness types that dont specify every field
    -- prevents divide by zero and nil math errors in update
    self.startupCost = self.startupCost or 1000
    self.basePrice = self.basePrice or 10
    self.fixedCosts = self.fixedCosts or 0
    self.capacity = self.capacity or 100
    self.risk = self.risk or 0.2
    -- variableCost is the old field name from earlier defs, unify to unitWholeSaleCost
    self.unitWholeSaleCost = self.unitWholeSaleCost or self.variableCost or 0
    self.marketMultiplier = self.marketMultiplier or 1.0

    -- reputation starts at the def value if set, otherwise 1.0 meaning perfectly neutral
    self.reputation = def.startingReputation or def.reputation or 1.0
    -- buisness starts in the red by its startup cost, earns its way back to zero
    self.cash = -self.startupCost
    self.age = 0                -- age in real seconds, converted to months for display
    self.in_remove_queue = false -- flag for future removal, not currently used
end

-- resolves a callback field from a def
-- defs store callback names as strings to avoid circular dep between CALLBACKS and BUSINESS_TYPES
-- if the field is already a function just return it directly
function Business:resolveCallback(cb)
    if type(cb) == 'string' then
        return CALLBACKS[cb] or function() end -- look up by name, fallback to empty func
    else
        return cb or function() end -- already a function, just guard against nil
    end
end

-- attaches a child buisness to this one
-- child profits get rolled into parent cash in update
function Business:addChild(childBusiness)
    childBusiness.parent = self  -- child knows its parent for rep and price modifiers
    table.insert(self.children, childBusiness)
end

-- main per frame update, called every frame from PlayState
-- market is the global Market instance, context carries biome demand and price mults
-- returns the profit earned this frame so parent buisnesses and PlayState can use it
function Business:update(dt, market, context)
    self.age = self.age + dt -- accumulate age in real seconds

    -- demand and price multipliers come from the biome context, default to 1.0 if missing
    local demandMult = context and context.demandMult or 1.0
    local priceMult = context and context.priceMult or 1.0

    -- effective capacity grows if employees have been hired
    local effectiveCapacity = self:getEffectiveCapacity()

    -- demandBase is how many units this buisness can sell per second at full capacity
    local demandBase = effectiveCapacity / SECONDS_PER_MONTH

    -- priceRatio scales demand down if effective price is above base price
    -- higher reputation raises effective price which slightly cuts demand
    local priceRatio = self.basePrice / self:getEffectivePrice()

    -- final demand mixes all the multipliers together plus random noise from risk
    -- market.sentiment is the main economic health indicator, below 1.0 hurts demand
    local demand = demandBase
        * priceRatio
        * market.sentiment
        * demandMult
        * self:getEffectiveReputation()
        * (1 + (math.random() - 0.5) * self.risk) -- random shock scaled by risk value

    -- clamp to demandBase so buisness never sells more than teh capacity allows
    local quantitySold = math.min(demand, demandBase) * dt

    -- revenue is units sold times base price, biome price multiplier applied on top
    local revenue = quantitySold * self.basePrice * priceMult
    -- wholesale cost is what it actualy cost to produce the units we sold
    local unitWholeSaleAquisitionCosts = quantitySold * self.unitWholeSaleCost

    -- spread the monthly fixed cost evenly accross every second
    local fixedCostsPerSecond = self.fixedCosts / SECONDS_PER_MONTH
    local totalCosts = unitWholeSaleAquisitionCosts + (fixedCostsPerSecond * dt)

    -- add each employees salary prorated to this frame
    for _, e in ipairs(self.employees) do
        totalCosts = totalCosts + e.salary * dt
    end

    local profit = revenue - totalCosts
    self.cash = self.cash + profit -- accumulate profit into the buisness cash balance

    -- recurse into child buisnesses and roll their profit into this buisnesses cash too
    if self.children then
        for _, child in ipairs(self.children) do
            local childProfit = child:update(dt, market)
            self.cash = self.cash + childProfit
        end
    end

    -- reputation creeps up when profitable and down when losing money
    -- the division by startupCost normalizes the effect accross buisness sizes
    self.reputation = math.min(2.0, math.max(0.1, self.reputation + (profit / (self.startupCost + 1e-6)) * 0.01 * dt))

    -- buisness goes bankrupt if its accumulated deficit is twice the startup cost
    self.bankrupt = self.cash < -self.startupCost * 2

    -- store raw last frame values, used by some debug displays
    self.trackingMetrics.revenueLastFrame = revenue
    self.trackingMetrics.profitLastFrame = profit
    self.trackingMetrics.costsLastFrame = totalCosts
    self.trackingMetrics.unitSoldLastFrame = quantitySold

    -- exponential moving average smooths per second rates so the portfolio display doesnt flicker
    -- alpha 0.12 gives a noticeable but not jerky response to changes
    if dt > 0 then
        local alpha = 0.12
        local iProfit = profit / dt   -- instantaneous rate this frame
        local iRev = revenue / dt
        local iCosts = totalCosts / dt
        local m = self.trackingMetrics
        -- first frame: no prior EMA, just use the raw value
        m.profitPerSec = m.profitPerSec  and (1-alpha)*m.profitPerSec  + alpha*iProfit  or iProfit
        m.revenuePerSec = m.revenuePerSec and (1-alpha)*m.revenuePerSec + alpha*iRev     or iRev
        m.costsPerSec = m.costsPerSec   and (1-alpha)*m.costsPerSec   + alpha*iCosts   or iCosts
    end

    return profit -- returned so PlayState can add it to player.cash
end


-- computes the final effective sale price including parent and reputation modifiers
-- higher reputation lets the buisness charge more, which boosts revenue but cuts demand slightly
function Business:getEffectivePrice()
    -- as of 4-13-26, one product per buisness type is assumed
    -- defined in BUSINESS_TYPES basePrice, defaults to 10 if missing

    local price = self.basePrice or 10         -- base price from the def
    local parentModifier = 1.0

    -- if owned by a parent company, that companys reputation can inflate price
    if self.parent then
        parentModifier = self.parent:getPriceModifier() or 1.0
    end

    -- higher reputation means customers accept a higher price
    local reputationModifier = self.reputation or 1.0

    -- multiply all the factors together to get the final price
    return price * parentModifier * reputationModifier
end

-- legacy demand calculation function, not used by the main update loop anymore
-- kept here for reference, the real demand calc lives inside Business:update
function Business:calculateDemand(market)
    local baseDemand = 100
    local priceEffect = 1 / self.price      -- higher price means fewer buyers
    local marketEffect = market.sentiment
    local reputationEffect = self.reputation
    local randomShock = 1 + (math.random() - 0.5) * self.risk
    local demand = baseDemand * priceEffect * marketEffect * reputationEffect * randomShock
    return demand
end

-- returns total capacity including bonus from any hired employees
-- employees add productivity * 10 to the base capacity
function Business:getEffectiveCapacity()
    local extraCapacity = 0
    for _, e in ipairs(self.employees) do
        extraCapacity = extraCapacity + e.productivity * 10  -- arbitrary scalling factor
    end
    return self.capacity + extraCapacity
end

-- returns the effective reputation including employee and parent company bonuses
-- clamped to 0.1 to 2.0 so it never goes extreme in either direction
function Business:getEffectiveReputation()
    local rep = self.reputation or 1.0

    -- employees with a reputationBoost field add to the base rep
    local employeeEffect = 0
    for _, e in ipairs(self.employees) do
        employeeEffect = employeeEffect + (e.reputationBoost or 0)
    end

    -- parent company gives a 10 percent rep bonus to child buisnesses
    local parentEffect = 0
    if self.parent then
        parentEffect = self.parent:getEffectiveReputation() * 0.1
    end

    local effectiveRep = rep + employeeEffect + parentEffect

    -- clamp to 0.1 minimum so a bad buisness never fully dies on reputation alone
    return math.min(2.0, math.max(0.1, effectiveRep))
end

-- price modifier used when this buisness is a parent of another buisness
-- rep above 1.0 lets the parent apply a small price boost to its children
function Business:getPriceModifier()
    -- maps reputation range 0 to 2 onto a price multiplier range of 0.8 to 1.2
    return 1.0 + (self.reputation - 1.0) * 0.2
end


return Business