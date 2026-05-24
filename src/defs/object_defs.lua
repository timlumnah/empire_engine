-- ================== claude_changes_2026-05-23-2136 ==================
--[[
   Empire Engine
   Based on CS50 2D Coursework

   -- object_defs.lua --

   Author: Tim Lumnah
   github.com/timlumnah/empire_engine

   Definitions for interactive world objects: switch, chest, and pot.
   Each entry specifies texture, frame index, collision dimensions,
   and the spawn callback used by Room:generateObjects().
]]
-- ====================================================================

GAME_OBJECT_DEFS = {
    ['switch'] = {
        type = 'switch',
        texture = 'switches',
        frame = 2,
        width = 16,
        height = 16,
        solid = false,
        defaultState = 'unpressed',
        callbacks = {
            onCollide = 'switch_onCollide',
        },
        states = {
            ['unpressed'] = {
                frame = 2
            },
            ['pressed'] = {
                frame = 1
            }
        },
    },
    
    ['chest'] = {
        type = 'chest',
        texture = 'chest',
        frame = 1,
        width = 16,
        height = 16,
        solid = true,
        defaultState = 'closed',
        states = {
            ['closed'] = {
                frame = 1
            },
            ['open'] = {
                frame = 2
            }
        },
    },

    ['pot'] = {
        type = 'pot',
        texture = 'pot',
        frame = 1,
        width = 16,
        height = 16,
        solid = true,       -- must be true per office hours
        collidable = true,
        defaultState = 'unbroken',
        callbacks = {
            onHitEntity = 'pot_onHitEntity',
            onHitWall = 'pot_onHitWall',
            onMaxDistance = 'pot_onMaxDistance',
            onUpdate = 'pot_onUpdate',
            onInteract = 'pot_onInteract',
        },
        states = {
            ['unbroken'] = {
                frame = 1
            },
        },
        animations = {
            ['break'] = {
                frames = {2, 3, 4},
                interval = 0.155,
                -- texture = 'pot'
            },
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
        consumable = true,
        callbacks = {
            onConsume = 'heart_onConsume',
        },
        states = {
            ['_'] = {
                frame = 5
            },
        },
    },
}