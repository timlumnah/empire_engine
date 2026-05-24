--[[
    CS50 2D
    Final Project

    Author: Tim Lumnah
    til980@g.harvard.edu
]]

STATE_DEFS = {
    ['PlayState'] = {
        PaddleGrowthThreshold = 1000,
        PaddleGrowthInterval = 2000,
        lockedBrickExists = params.lockedBrickExists or false,
    },

    ['pot'] = {
        type = 'pot',
        texture = 'pot',
        frame = 1,
        width = 16,
        height = 16,
        solid = true,       -- must be true per office hours
        defaultState = 'unbroken',
        callbacks = {
            onCollide = 'pot_onCollide',
            onInteract = 'pot_onInteract',
        },
        states = {
            ['unbroken'] = {
                frame = 1
            },
            -- ['broken'] = {
            --     frame = 1
            -- }
        },
    },

    ['heart'] = {
        type = 'heart',
        texture = 'hearts',
        frame = 5,
        width = 16,
        height = 16,
        solid = false,
        defaultState = '_',
        callbacks = {
            onConsume = 'heart_onConsume',
        },
        states = {
            ['_'] = {
                frame = 2
            },
        },
    },

    ['chest'] = {
        type = 'chest',
        texture = 'chest',
        frame = 5,
        width = 16,
        height = 16,
        solid = true,
        defaultState = 'closed',
        callbacks = {
            onCollide = 'chest_onCollide',
            onInteract = 'chest_onInteract',
        },
        states = {
            ['closed'] = {
                frame = 2
            },
            ['open'] = {
                frame = 1
            }
        },
        onInteract = CALLBACKS.chest_onInteract
    },
}