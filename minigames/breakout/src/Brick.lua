--[[
    CS50 2D
    Breakout Remake

    -- Brick Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents a brick in the world space that the ball can collide with;
    differently colored bricks have different point values. On collision,
    the ball will bounce away depending on the angle of collision. When all
    bricks are cleared in the current map, the player should be taken to a new
    layout of bricks.
]]

Brick = Class{}

-- some of the colors in our palette (to be used with particle systems)
paletteColors = {
    -- blue
    [1] = {
        ['r'] = 99,
        ['g'] = 155,
        ['b'] = 255
    },
    -- green
    [2] = {
        ['r'] = 106,
        ['g'] = 190,
        ['b'] = 47
    },
    -- red
    [3] = {
        ['r'] = 217,
        ['g'] = 87,
        ['b'] = 99
    },
    -- purple
    [4] = {
        ['r'] = 215,
        ['g'] = 123,
        ['b'] = 186
    },
    -- gold
    [5] = {
        ['r'] = 251,
        ['g'] = 242,
        ['b'] = 54
    }
}

function Brick:init(x, y, isLocked)
    -- used for coloring and score calculation
    self.tier = 0
    self.color = 1

    self.x = x
    self.y = y
    self.width = 32
    self.height = 16

    -- used to determine whether this brick should be rendered
    self.inPlay = true

    -- particle system belonging to the brick, emitted on hit
    self.psystem = love.graphics.newParticleSystem(gTextures['particle'], 64)

    -- various behavior-determining functions for the particle system
    -- https://love2d.org/wiki/ParticleSystem

    -- lasts between 0.5-1 seconds seconds
    self.psystem:setParticleLifetime(0.5, 1)

    -- give it an acceleration of anywhere between X1,Y1 and X2,Y2 (0, 0) and (80, 80) here
    -- gives generally downward
    self.psystem:setLinearAcceleration(-15, 0, 15, 80)

    -- spread of particles; normal looks more natural than uniform
    self.psystem:setEmissionArea('normal', 10, 10)


    -- ====================== TIM LUMNAH'S EDITS ======================
    -- locked brick flag
    self.isLocked = isLocked or false

    -- add a self.skin var but only assign it for locked bricks
    -- normal bricks still use normal color/tier logic
    if self.isLocked then
        self.skin = gFrames['locked']
    else
        self.skin = nil
    end
    -- ================================================================

end

--[[
    Triggers a hit on the brick, taking it out of play if at 0 health or
    changing its color otherwise.
]]
function Brick:hit(keyPowerup)
    -- set the particle system to interpolate between two colors; in this case, we give
    -- it our self.color but with varying alpha; brighter for higher tiers, fading to 0
    -- over the particle's lifetime (the second color)
    self.psystem:setColors(
        paletteColors[self.color].r / 255,
        paletteColors[self.color].g / 255,
        paletteColors[self.color].b / 255,
        55 * (self.tier + 1) / 255,
        paletteColors[self.color].r / 255,
        paletteColors[self.color].g / 255,
        paletteColors[self.color].b / 255,
        0
    )
    self.psystem:emit(64)

    -- sound on hit
    gSounds['brick-hit-2']:stop()
    gSounds['brick-hit-2']:play()

    -- ====================== TIM LUMNAH'S EDITS ======================
    -- check if the brick is locked and if the key Powerup is active 
    -- based on a param passed through by PlayState
    -- make sure locked bricks default to tier 0 so that 1 hit when the
    -- key powerup is active will destroy it, preventing excess bonus points
    -- from inadvertantly being awarded.

    if self.isLocked and not keyPowerup then
        -- do nothing
        return 'locked'
    end
    if self.isLocked and keyPowerup then
        self.tier = 0
        self.color = 1
        self.isLocked = false
    end
    -- ================================================================

    -- if we're at a higher tier than the base, we need to go down a tier
    -- if we're already at the lowest color, else just go down a color
    if self.tier > 0 then
        if self.color == 1 then
            self.tier = self.tier - 1
            self.color = 5
        else
            self.color = self.color - 1
        end
    else
        -- if we're in the first tier and the base color, remove brick from play
        if self.color == 1 then
            self.inPlay = false
        else
            self.color = self.color - 1
        end
    end

    -- play a second layer sound if the brick is destroyed
    if not self.inPlay then
        gSounds['brick-hit-1']:stop()
        gSounds['brick-hit-1']:play()
    end

    -- return nil for normal brick hits to decipher between
    -- normal and locked bricks
    return nil
end

function Brick:update(dt)
    self.psystem:update(dt)
end

function Brick:render()
    if self.inPlay then
        -- ====================== TIM LUMNAH'S EDITS ======================
        -- add a conditional to draw the locked skin 
        -- and bypass normal color/tier logic
        if self.isLocked and self.skin then
            love.graphics.draw(gTextures['main'], self.skin, self.x, self.y)
        else
            love.graphics.draw(gTextures['main'],
                gFrames['bricks'][1 + ((self.color - 1) * 4) + self.tier],
                self.x, self.y)
        end
        -- ================================================================
    end
end

    

--[[
    Need a separate render function for our particles so it can be called after all bricks are drawn;
    otherwise, some bricks would render over other bricks' particle systems.
]]
function Brick:renderParticles()
    love.graphics.draw(self.psystem, self.x + 16, self.y + 8)
end
