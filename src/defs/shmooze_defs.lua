--[[
    Empire Engine
    Based on CS50 2D Coursework

    shmooze_defs.lua

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    Keyword list and affinity-score table for the NPC shmoozing
    mechanic. The player types complimetns to raise NPC affinity,
    which unlocks purchase discounts when buying businesses.
]]

-- NpcMenu checks player input against these keywords
-- any substring match counts, so "nice hair day" still triggers "nice hair"
-- keywords are all lowercase, input gets lowercased before matching
-- adding a keyword here is all you need to make it work in game
SHMOOZE_DEFS = {

    -- list of accepted compliment phrases and words
    -- player types one of these into the shmooze text box and hits enter
    -- each successful match raises NPC affinity by 1, max is 3
    -- reaching max affinity on any NPC in the room unlocks the top door
    keywords = {
        -- hair compliments
        'nice hair', 'great hair', 'love your hair',
        -- smile compliments
        'nice smile', 'great smile', 'love your smile',
        -- style compliments
        'love your style', 'nice style', 'great style',
        -- general appearance
        'looking good', 'you look great', 'you look amazing',
        -- outfit
        'love your outfit', 'nice outfit', 'great outfit',
        -- personality and energy
        'love your energy', 'great energy',
        'you are amazing', 'you are brilliant', 'you are incredible',
        'love your vibe', 'great vibe', 'nice vibe',
        -- single word matches, any of these in the input counts as a hit
        'impressive', 'amazing', 'wonderful', 'fantastic',
        'brilliant', 'incredible', 'inspiring', 'beautiful',
        'outstanding', 'excellent', 'remarkable', 'stunning',
        'genius', 'legend', 'icon', 'visionary',
        'love it', 'love that', 'love this',
        -- short positive words also work fine
        'awesome', 'cool', 'smart', 'nice', 'great',
        'charming', 'elegant', 'classy', 'sharp', 'dapper',
        -- phrases the player might naturaly type
        'you rock', 'you rule', 'you slay', 'you shine',
        -- ultra short words that still trigger a match
        'wow', 'wowza', 'stunning',
    }
}
