--[[
   Empire Engine
   Based on CS50 2D Coursework

   -- Plot Beats --

   Author: Tim Lumnah
   github.com/timlumnah/empire_engine

   Narative beats shown as modal dialogue popups during play.

   Fields per beat:
     id: unique key; tracked in plotBeatsSeen to prevent replay
     trigger: 'start' fires immediately on init; number fires when player.cash >= value
     title: heading text (zelda-small font)
     text: body text; supports \n for line breaks; printf wraps the rest
     marketEvent: optional inline event applied when this beat fires
]]

-- PlayState checks these each update and fires them when the trigger condition is met
-- once seen they go into plotBeatsSeen so they never fire again
-- trigger "start" fires once at game init, a number fires when player.cash reaches that value
-- marketEvent field is optional, fires an inline market event at the same time as the beat
PLOT_BEATS = {

    -- intro beat fires right away when the game starts
    -- explains the core narrative and the grandmothers situation
    -- also doubles as a tutorial hint since new players wont know the controls yet
    {
        id = 'intro',
        trigger = 'start',  -- fires right at the begining of the game on first run
        title = 'A DESPERATE SITUATION',
        -- ================== claude_changes_2026-05-23-1243 ==================
        -- reference WIN_CASH_GOAL instead of hardcoding $1,000,000
        text = "Your grandmother has been diagnosed with Varendorf's Syndrome, a rare degenerative condition with no known cure.\n\nThe only experimental treatment costs $" .. commify(WIN_CASH_GOAL) .. ". She has months left.\n\nBuild businesses. Earn money. Save her.\n\nPress Enter near an NPC to open a business or get a loan.\nTAB: portfolio   P: pause / sleep   C: marketplace",
        -- ====================================================================
    },

    -- midgame beat fires at 50 percent of the win goal
    -- also triggers a scripted market crash to ramp up difficulty mid game
    -- this is the hardest part of the game, designed to stress test the players portfolio
    {
        id = 'midgame',
        trigger = WIN_CASH_GOAL * 0.5,  -- fires when player cash reaches half the win goal
        title = 'MARKET CRISIS',
        text = "You are halfway to your goal.\n\nA sudden financial crisis has shaken the economy. Consumer confidence is collapsing. Your profits will suffer.\n\nKeep going. Grandma is counting on you.",
        -- this event gets aplied to the market when the beat fires
        -- its much stronger than any random market event, designed to really hurt
        marketEvent = {
            id = 'midgame_crisis',
            name = 'Financial Crisis',
            description = 'A sudden financial crisis shakes the economy.',
            duration = 210, -- 7 game months, a long scripted recession built into the narative
            sentiment = -0.45,  -- stronger than any random event in MARKET_EVENTS
            gdpGrowth = -0.06,
            volatility = 0.03,
        },
    },

    -- endgame beat fires at 90 percent of the win goal
    -- no market event, just narative tension to push the player through the final stretch
    {
        id = 'endgame',
        trigger = WIN_CASH_GOAL * 0.9,  -- fires when player is close to the win condition
        title = 'ALMOST THERE',
        text = "Your grandmother is still holding on.\n\nYou are $100,000 away from paying for her treatment. She is counting on you. Do not stop now.",
    },

}
