--[[
   Empire Engine
   Based on CS50 2D Coursework

   -- Market Events --

   Author: Tim Lumnah
   github.com/timlumnah/empire_engine

   All market events in one table. Sign of sentiment/gdpGrowth encodes
   whether an event is a boom or a shock -- no seperate polarity field needed.

   Fields per event:
     id: unique string key
     name: display name shown to player
     description: one-line flavor text for the notification
     duration: how long the effect lasts in game-seconds
     sentiment: flat change applied to market.sentiment
     gdpGrowth: flat change applied to market.gdpGrowth
     volatility: flat change applied to market.volatility (positive = more chaos)
     weight: relative probability weight for random selection (higher = more common)
]]

-- all market events in one flat table, both negative and positive
-- Market:triggerRandomEvent does a weighted random pick from this list
-- only one event can be active at a time, see Market:triggerRandomEvent
-- sentiment field shifts the mean reversion target in Market:update
-- duration is in real seconds, each game month is SECONDS_PER_MONTH seconds
-- weight controls how often each event gets picked, higher weight means more likely
MARKET_EVENTS = {

    -- bad events below, negative sentiment and gdpGrowth values
    -- weight 3 means these show up 3 times as often as weight 1 events

    {
        id = 'recession',
        name = 'Recession',
        description = 'Consumer spending collapses. Businesses feel the squeeze.',
        duration = 90,          -- 3 game months of pain
        sentiment = -0.25,      -- large negative shift to the mean reversion target
        gdpGrowth = -0.03,      -- slows the upward drift
        volatility = 0.005,     -- modest increase in noise during recession
        weight = 3,             -- fairly common, most likely negative event
    },

    {
        id = 'natural_disaster',
        name = 'Natural Disaster',
        description = 'A major disaster disrupts supply chains and kills foot traffic.',
        duration = 60,          -- 2 game months, shorter than recession
        sentiment = -0.20,      -- significant but not as bad as recession
        gdpGrowth = -0.01,
        volatility = 0.015,     -- more chaotic than recession, supply shock causes swings
        weight = 2,
    },

    {
        id = 'tariff_war',
        name = 'Tariff War',
        description = 'Trade tariffs spike costs. Import-dependent businesses take a hit.',
        duration = 120,         -- 4 game months, longest of the mid tier events
        sentiment = -0.10,      -- milder sentiment hit than recession
        gdpGrowth = -0.015,
        volatility = 0.008,
        weight = 3,             -- common event, trade disputes happen often
    },

    {
        id = 'war',
        name = 'War',
        description = 'Armed conflict disrupts global trade and rattles investor confidence.',
        duration = 150,         -- 5 game months, second longest event in the game
        sentiment = -0.30,      -- very bad for consumer spending
        gdpGrowth = -0.025,
        volatility = 0.02,      -- high chaos, lots of market swings during war
        weight = 1,             -- rare event, only shows up one third as often as weight 3
    },

    {
        id = 'banking_crisis',
        name = 'Banking Crisis',
        description = 'Credit dries up. Loans are called. Business expansion halts.',
        duration = 90,
        sentiment = -0.20,
        gdpGrowth = -0.02,
        volatility = 0.012,
        weight = 2,
    },

    {
        id = 'pandemic',
        name = 'Pandemic',
        description = 'A disease outbreak forces lockdowns and wipes out consumer demand.',
        duration = 180,         -- 6 game months, the longest event in the game
        sentiment = -0.35,      -- second worst sentiment hit after war
        gdpGrowth = -0.04,      -- worst gdp hit in the game
        volatility = 0.025,     -- very chaotic, hardest event to survive
        weight = 1,             -- rarest event, same low odds as war
    },

    {
        id = 'energy_crisis',
        name = 'Energy Crisis',
        description = 'Fuel and power costs surge. Operating expenses rise across the board.',
        duration = 60,
        sentiment = -0.12,      -- mild sentiment hit
        gdpGrowth = -0.01,
        volatility = 0.01,
        weight = 3,             -- most common negative event alongside recession and tariffs
    },

    -- positive events below, sentiment and gdpGrowth are positive values
    -- these help the player recover after bad events

    {
        id = 'tech_boom',
        name = 'Technology Breakthrough',
        description = 'A new technology launches. Consumer confidence and spending surge.',
        duration = 90,
        sentiment = 0.20,       -- positive shift raises the mean reversion target above 1.0
        gdpGrowth = 0.025,      -- boosts the upward drift
        volatility = 0.005,     -- tech booms are relatively stable, low noise
        weight = 2,
    },

    {
        id = 'trade_deal',
        name = 'Trade Deal',
        description = 'A major political agreement cuts tariffs. New markets open up.',
        duration = 120,
        sentiment = 0.15,
        gdpGrowth = 0.02,
        volatility = 0.003,     -- very stable event, good news with no chaos
        weight = 3,             -- most common positive event
    },

    {
        id = 'bull_market',
        name = 'Bull Market',
        description = 'Investor confidence spikes. Consumer spending and profits soar.',
        duration = 60,          -- shorter than tech boom but stronger sentiment boost
        sentiment = 0.25,       -- best single sentiment boost of any random event
        gdpGrowth = 0.03,
        volatility = 0.008,
        weight = 2,
    },

}
