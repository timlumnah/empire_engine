--[[
    Empire Engine
    Based on CS50 2D Coursework

    minigame_defs.lua

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    Configuration for each playable minigame (Pong, Breakout).
    Specifies display name, win-condition score, and the cash reward
    granted to the player by MinigameState on a succesful run.
]]

-- keyed by the minigame id string, must match what MarketplaceMenu puts in GAME_LIST
-- MinigameState reads reward and passes it back to PlayState on a win result
-- pong reads winScore from here to know when to end the match
MINIGAME_DEFS = {

    -- 1 player vs cpu pong, first to winScore points wins
    -- reward is small, minigames are not meant to be a primary cash source
    ['pong'] = {
        displayName = 'PONG',
        winScore = 3,       -- first player or cpu to reach this score wins
        reward = 95,        -- cash paid to player if they win, not much but its somthing
    },

    -- breakout clone, player clears level 1 to win
    -- no winScore field needed, breakout handles win condition internaly
    ['breakout'] = {
        displayName = 'BREAKOUT',
        reward = 150,       -- slightly better reward than pong, harder to win
    },
}
