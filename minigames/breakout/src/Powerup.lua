--[[
    CS50 2D
    Breakout Remake

    -- Brick Class --

    Author: Tim Lumnah
    til980@g.harvard.edu

    Represents a powerup in the world space that the paddle can catch/collide with;
    Powerups are spawned from PlayState when a ball breaks a brick (with a certain likelihood)
    
    In future versions, this class may be expanded to include a dict / table defining multiple powerups and their
    associated benefits.  For the purposes of this assignment, this logic has been omitted, but other downstream
    elements have been hard coded in the PlayState.  PlayState currently assumes that any powerup by default
    spawns 2 new balls unless that powerup has been flagged as a key powerup. Key powerups enable locked
    bricks to be destroyed.   PlayState.lua uses a table, "activePowerups", to keep track of any/all powerups
    the player has caught with their paddle.  PlayState:enter() automatically defines these tables as empty
    so any benefits resulting from powerups, such as extra balls, keys, -- and in our case paddle size --
    are automatically reset when gStateMachine switches between victory > serve > PlayState, or other states, etc.
]]

Powerup = Class{}


POWERUP_FRAMES = {
    normal = 9,
    key = 10
}

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


function Powerup:init(x, y, type)
    self.x = x
    self.y = y
    self.width = 16
    self.height = 16
    self.dy = 50

    self.type = type or 'normal'

    -- assign frame from dictionary
    self.frame = POWERUP_FRAMES[self.type]

    self.quad = gFrames['powerups'][self.frame]

end

function Powerup:collides(target)
    -- copies the Ball:collides logic

    -- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end

    -- if the above aren't true, they're overlapping
    return true
end


function Powerup:update(dt)
    self.y = self.y + self.dy * dt
end


function Powerup:render()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(gTextures['main'], self.quad, self.x, self.y)
end
