--[[
   Empire Engine
   Based on CS50 2D Coursework

   -- Market Class --

   Author: Tim Lumnah
   github.com/timlumnah/empire_engine

   Simulates economy & market fluctuations.
   Negative events shift the mean-reversion target so sentiment drifts
   toward a depressed equilbirium for the event duration, then recovers.
   No jump shocks on apply or remove.
]]

-- global market simulation, one instance lives in PlayState
-- buisnesses read market.sentiment directly in their update calls
-- events shift the mean reversion target so sentimint drifts toward a new equilibrium
Market = Class{}

-- sets up the initial market conditions
-- all values start at neutral, events will push them around during gameplay
function Market:init()
    self.gdpGrowth = 0.02   -- baseline upward drift applied every frame, economy naturaly grows
    self.sentiment = 1.0    -- demand multiplier, 1.0 is neutral, above 1.0 is boom, below is bust
    self.interestRate = 0.05   -- set but not wired to loan costs yet, reserved for future use
    self.volatility = 0.01   -- base noise scale per frame, events can make this much higher

    -- list of currently active events, each entry has event def and timeRemaining in seconds
    self.activeEvents = {}

    -- aggregate deltas from all active events combined
    -- when an event is added its deltas are summed here, removed when event expires
    self.eventGdpDelta = 0
    self.eventVolatilityDelta = 0
    self.eventSentimentTarget = 0   -- shifts the mean reversion target below 1.0 during bad events

    -- timer fires every 2 game months to check whether a new event should start
    self.eventCheckTimer = 0
    self.eventCheckInterval = SECONDS_PER_MONTH * 2
    self.eventChance = 0.20  -- 20 percent chance of a new event each time the check fires

    -- set by triggerRandomEvent when a new event starts, PlayState reads and shows the banner
    self.pendingNotification = nil
end

-- called every frame from PlayState, ticks events and updates sentiment
function Market:update(dt)
    -- tick down all active events, remove expired ones and revert their delta contributions
    -- iterate backwards so removing mid loop doesnt skip entries
    for i = #self.activeEvents, 1, -1 do
        local ae = self.activeEvents[i]
        ae.timeRemaining = ae.timeRemaining - dt
        if ae.timeRemaining <= 0 then
            -- subtract this events contribution from the running aggregates
            self.eventGdpDelta = self.eventGdpDelta        - ae.event.gdpGrowth
            self.eventVolatilityDelta = self.eventVolatilityDelta - ae.event.volatility
            self.eventSentimentTarget = self.eventSentimentTarget - ae.event.sentiment
            table.remove(self.activeEvents, i)
        end
    end

    -- tick the event check timer, fire a new event check when interval is reached
    self.eventCheckTimer = self.eventCheckTimer + dt
    if self.eventCheckTimer >= self.eventCheckInterval then
        self.eventCheckTimer = 0
        if math.random() < self.eventChance then
            self:triggerRandomEvent() -- may or may not succeed depending on active events
        end
    end

    -- effective gdp and volatility combine the base values with all active event deltas
    local effectiveGdp = self.gdpGrowth + self.eventGdpDelta
    local effectiveVolatility = math.max(0.001, self.volatility + self.eventVolatilityDelta)

    -- add small random noise each frame, scaled by volatility and delta time
    local shock = (math.random() - 0.5) * effectiveVolatility * dt
    self.sentiment = self.sentiment + shock + effectiveGdp * dt

    -- mean reversion pulls sentimint toward the target value over time
    -- events shift the target below 1.0 so recovery doesnt happen instantly
    local target = 1.0 + self.eventSentimentTarget
    local pull = (target - self.sentiment) * 0.05 * dt
    self.sentiment = self.sentiment + pull

    -- clamp to a wider range than usual so events can really depress the economy
    -- 0.3 floor is the worst possible market state, 1.5 ceiling is the boom ceiling
    self.sentiment = math.max(0.3, math.min(1.5, self.sentiment))
end

-- picks a random event from MARKET_EVENTS using weighted probablity
-- only fires if no event is currently active, one at a time design
function Market:triggerRandomEvent()
    -- bail if something is already running, we dont stack events
    if #self.activeEvents > 0 then return end

    -- build the weighted pool from MARKET_EVENTS
    local pool = {}
    local totalWeight = 0
    for _, event in ipairs(MARKET_EVENTS) do
        table.insert(pool, event)
        totalWeight = totalWeight + event.weight
    end

    if #pool == 0 or totalWeight == 0 then return end -- nothing to pick from

    -- standard weighted random selection, roll against cumulative weight
    local roll = math.random() * totalWeight
    local cumulative = 0
    local chosen = pool[#pool] -- default to last entry if roll lands exactly on total
    for _, event in ipairs(pool) do
        cumulative = cumulative + event.weight
        if roll <= cumulative then
            chosen = event
            break
        end
    end

    self:applyEvent(chosen) -- apply the selected event
end

-- applies a market event by adding its deltas to the running aggregates
-- no instant jump to sentiment, events shift the mean reversion target instead
-- this makes them feel like a gradual trend change rather than a sudden spike
function Market:applyEvent(event)
    -- add this events contribution to the running delta totals
    self.eventGdpDelta = self.eventGdpDelta        + event.gdpGrowth
    self.eventVolatilityDelta = self.eventVolatilityDelta + event.volatility
    self.eventSentimentTarget = self.eventSentimentTarget + event.sentiment

    -- record the active event with its remaining time
    table.insert(self.activeEvents, {
        event = event,
        timeRemaining = event.duration, -- counts down to zero then the event expires
    })

    -- signal PlayState to show the event banner on screen
    -- PlayState reads and clears this so it only shows once
    self.pendingNotification = event
end

return Market
