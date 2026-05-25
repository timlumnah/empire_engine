
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

    -- ================== claude_changes_2026-05-25-1228 ==================
    -- scale tier: 1 = normal, 2 = large, 3 = enterprise
    -- scaleTiers defined per type in business_defs; capacity multiplied by tier mult
    self.scaleTier = self.scaleTier or 1
    self.maxEmployees = self.maxEmployees or 5
    -- retail stock; nil on non-retail types (checked before use in update)
    if self.stockLevel == nil and def.stockLevel ~= nil then
        self.stockLevel = def.stockLevel
    end
    self.maxStock = self.maxStock or nil
    -- ====================================================================
    -- ================== claude_changes_2026-05-25-1330 ==================
    -- auto-reorder: fires once when stock drops to or below threshold, re-arms when stock recovers
    self.autoReorderEnabled   = (def.autoReorderEnabled ~= nil) and def.autoReorderEnabled or false
    self.autoReorderThreshold = self.autoReorderThreshold or 0.10
    self.autoReorderQuantity  = self.autoReorderQuantity  or 0.50
    self.reorderArmed         = true  -- false after a reorder fires; reset when stock recovers
    -- equipment: one-time purchases tracked as { key = count }; never consumed
    self.equipment = self.equipment or {}
    -- ====================================================================
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
    local rawSold = math.min(demand, demandBase) * dt

    -- ================== claude_changes_2026-05-25-1228 ==================
    -- retail businesses cap sales by physical stock on hand
    local quantitySold = rawSold
    if self.stockLevel ~= nil then
        quantitySold = math.min(rawSold, self.stockLevel)
        self.stockLevel = math.max(0, self.stockLevel - quantitySold)
    end
    -- ====================================================================

    -- revenue is units sold times base price, biome price multiplier applied on top
    local revenue = quantitySold * self.basePrice * priceMult
    -- wholesale cost is what it actualy cost to produce the units we sold
    local unitWholeSaleAquisitionCosts = quantitySold * self.unitWholeSaleCost

    -- spread the monthly fixed cost evenly accross every second
    local fixedCostsPerSecond = self.fixedCosts / SECONDS_PER_MONTH
    local totalCosts = unitWholeSaleAquisitionCosts + (fixedCostsPerSecond * dt)

    -- ================== claude_changes_2026-05-25-1228 ==================
    -- salary is monthly; prorate to this frame's dt
    for _, e in ipairs(self.employees) do
        totalCosts = totalCosts + (e.salary / SECONDS_PER_MONTH) * dt
    end
    -- ====================================================================

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

-- returns total capacity including scale tier multiplier, employee bonuses, and opMult
function Business:getEffectiveCapacity()
    -- ================== claude_changes_2026-05-25-1228 ==================
    -- scale tier multiplier applied first (1.0 / 1.5 / 2.5)
    local tierMult = 1.0
    if self.scaleTiers and self.scaleTier then
        local tier = self.scaleTiers[self.scaleTier]
        if tier then tierMult = tier.mult end
    end
    local base = self.capacity * tierMult

    -- each employee adds their role's capacityBonus
    local extra = 0
    for _, e in ipairs(self.employees) do
        extra = extra + (e.capacityBonus or (e.productivity and e.productivity * 10) or 0)
    end
    -- ====================================================================
    -- ================== claude_changes_2026-05-25-1330 ==================
    -- opMult from requirements checklist (0.10 floor when REQUIRED unmet, up to 1.40 with BONUS)
    return (base + extra) * self:getOpMult()
    -- ====================================================================
end

-- returns a flat list of requirement check results for the requirements checklist
-- each entry: { id, label, tier, met, key, minCount }
function Business:getChecklistStatus()
    if not self.requirements then return {} end
    local status = {}
    for _, req in ipairs(self.requirements) do
        local met = false
        if req.type == 'equipment' then
            local count = (self.equipment and self.equipment[req.key]) or 0
            met = count >= (req.minCount or 1)
        elseif req.type == 'employee' then
            local count = 0
            for _, e in ipairs(self.employees) do
                if e.role == req.key then count = count + 1 end
            end
            met = count >= (req.minCount or 1)
        elseif req.type == 'stock' then
            met = self.stockLevel ~= nil and self.stockLevel > 0
        end
        table.insert(status, {
            id       = req.id,
            label    = req.label,
            tier     = req.tier,
            met      = met,
            key      = req.key,
            minCount = req.minCount,
        })
    end
    return status
end

-- returns the operational multiplier based on the requirements checklist
-- 0.10 if any REQUIRED unmet; 0.60 baseline; scales to 1.00 with RECOMMENDED; 1.40 with BONUS
function Business:getOpMult()
    if not self.requirements or #self.requirements == 0 then return 1.0 end
    local status   = self:getChecklistStatus()
    local reqMet   = true
    local recTotal, recMet = 0, 0
    local bonTotal, bonMet = 0, 0
    for _, item in ipairs(status) do
        if item.tier == 'required' and not item.met then
            reqMet = false
        elseif item.tier == 'recommended' then
            recTotal = recTotal + 1
            if item.met then recMet = recMet + 1 end
        elseif item.tier == 'bonus' then
            bonTotal = bonTotal + 1
            if item.met then bonMet = bonMet + 1 end
        end
    end
    if not reqMet then return 0.10 end
    local recPct = recTotal > 0 and (recMet / recTotal) or 1.0
    local bonPct = bonTotal > 0 and (bonMet / bonTotal) or 0.0
    return math.min(1.40, 0.60 + recPct * 0.40 + bonPct * 0.40)
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


-- ================== claude_changes_2026-05-25-1228 ==================

-- hire a new employee; role is a key from EMPLOYEE_ROLES
-- returns the new employee table or nil if business is at max capacity
function Business:hireEmployee(role)
    local max = self.maxEmployees or 5
    if #self.employees >= max then return nil end
    local roleDef = EMPLOYEE_ROLES and EMPLOYEE_ROLES[role]
    if not roleDef then return nil end

    -- enforce allowedTypes so wrong-type roles can't be hired
    if roleDef.allowedTypes then
        local allowed = false
        for _, t in ipairs(roleDef.allowedTypes) do
            if t == self.type then allowed = true; break end
        end
        if not allowed then return nil end
    end

    local pool = EMPLOYEE_NAME_POOL or {'Worker'}
    local name = pool[math.random(#pool)]
    local lo, hi = roleDef.salaryRange[1], roleDef.salaryRange[2]
    local salary = math.random(lo, hi)

    local emp = {
        name         = name,
        role         = role,
        salary       = salary,
        capacityBonus = roleDef.capacityBonus,
    }
    table.insert(self.employees, emp)
    return emp
end

-- fire employee at position index in self.employees
function Business:fireEmployee(index)
    if index >= 1 and index <= #self.employees then
        table.remove(self.employees, index)
    end
end

-- total monthly payroll across all employees
function Business:getMonthlyPayroll()
    local total = 0
    for _, e in ipairs(self.employees) do
        total = total + (e.salary or 0)
    end
    return total
end

-- returns true if the business can be scaled up (tier < 3) and player has cash
function Business:canScale(playerCash)
    if not self.scaleTiers then return false end
    local nextTier = (self.scaleTier or 1) + 1
    local tierDef = self.scaleTiers[nextTier]
    if not tierDef then return false end
    return playerCash >= tierDef.cost
end

-- returns the cost and mult for the next scale tier, or nil if maxed
function Business:nextScaleInfo()
    if not self.scaleTiers then return nil end
    local nextTier = (self.scaleTier or 1) + 1
    return self.scaleTiers[nextTier]
end

-- upgrade to the next scale tier; deduct cost from playerCash (passed as table ref)
-- returns true on success
function Business:doScale(player)
    local info = self:nextScaleInfo()
    if not info or player.cash < info.cost then return false end
    player.cash = player.cash - info.cost
    player.displayCash = player.cash
    self.scaleTier = (self.scaleTier or 1) + 1
    return true
end

-- merge another business of the same type into this one; other is removed by caller
-- combined capacity, cash, averaged reputation, employees up to maxEmployees
function Business:mergeWith(other)
    -- capacity: take the higher base capacity of the two then add a merge bonus
    local myEff  = self.capacity  * ((self.scaleTiers  and self.scaleTiers[self.scaleTier  or 1] and self.scaleTiers[self.scaleTier  or 1].mult) or 1.0)
    local othEff = other.capacity * ((other.scaleTiers and other.scaleTiers[other.scaleTier or 1] and other.scaleTiers[other.scaleTier or 1].mult) or 1.0)
    self.capacity = math.floor(math.max(myEff, othEff) * 1.4)
    self.scaleTier = 1              -- reset tier; new capacity already baked in
    self.scaleTiers = nil           -- no further tier scaling after a merge

    -- cash: combine balances
    self.cash = self.cash + other.cash

    -- reputation: weighted average
    self.reputation = (self.reputation + other.reputation) / 2

    -- absorb employees up to maxEmployees
    local max = self.maxEmployees or 5
    for _, e in ipairs(other.employees or {}) do
        if #self.employees < max then
            table.insert(self.employees, e)
        end
    end

    -- absorb retail stock if applicable
    if self.stockLevel ~= nil and other.stockLevel ~= nil then
        local cap = self.maxStock or 9999999
        self.stockLevel = math.min(self.stockLevel + other.stockLevel, cap)
    end
end

-- ================== claude_changes_2026-05-25-1330 ==================
-- fires once when stock drops to or below the threshold fraction of maxStock
-- re-arms automatically when stock recovers above the threshold
-- returns a display string on successful reorder, nil otherwise
function Business:checkAutoReorder(player)
    if not self.autoReorderEnabled then return nil end
    if self.stockLevel == nil then return nil end

    local maxS        = self.maxStock or 5000
    local triggerAmt  = math.floor(maxS * (self.autoReorderThreshold or 0.10))
    local reorderQty  = math.floor(maxS * (self.autoReorderQuantity  or 0.50))

    -- re-arm when stock climbs back above the threshold
    if self.stockLevel > triggerAmt then
        self.reorderArmed = true
        return nil
    end

    -- at or below threshold but already fired this depletion cycle
    if not self.reorderArmed then return nil end

    -- fire the reorder
    local unitCost  = self.unitWholeSaleCost or 4
    local totalCost = reorderQty * unitCost
    if player.cash < totalCost then return nil end  -- can't afford; skip silently

    player.cash          = player.cash - totalCost
    player.displayCash   = player.cash
    self.stockLevel      = math.min((self.stockLevel or 0) + reorderQty, maxS)
    self.reorderArmed    = false  -- disarm until stock recovers above threshold

    return string.format('Auto-restocked: +%d units  ($%d)', reorderQty, totalCost)
end
-- ====================================================================

return Business