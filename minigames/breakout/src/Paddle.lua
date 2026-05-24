--[[
    CS50 2D
    Breakout Remake

    -- Paddle Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents a paddle that can move left and right. Used in the main
    program to deflect the ball toward the bricks; if the ball passes
    the paddle, the player loses one heart. The Paddle can have a skin,
    which the player gets to choose upon starting the game.
]]

Paddle = Class{}

--[[
    Our Paddle will initialize at the same spot every time, in the middle
    of the world horizontally, toward the bottom.
]]
function Paddle:init(skin)
    -- x is placed in the middle
    self.x = VIRTUAL_WIDTH / 2 - 32

    -- y is placed a little above the bottom edge of the screen
    self.y = VIRTUAL_HEIGHT - 32

    -- start us off with no velocity
    self.dx = 0

    -- starting dimensions
    self.width = 64
    self.height = 16

    -- the skin only has the effect of changing our color, used to offset us
    -- into the gPaddleSkins table later
    self.skin = skin

    -- the variant is which of the four paddle sizes we currently are; 2
    -- is the starting size, as the smallest is too tough to start with
    self.size = 2

    -- ====================== TIM LUMNAH'S EDITS ======================
    -- use helper to assign a quad based on size & skin
    self:updateQuad()
    -- ================================================================

end

function Paddle:update(dt)
    -- keyboard input
    if love.keyboard.isDown('left') then
        self.dx = -PADDLE_SPEED
    elseif love.keyboard.isDown('right') then
        self.dx = PADDLE_SPEED
    else
        self.dx = 0
    end

    -- math.max here ensures that we're the greater of 0 or the player's
    -- current calculated Y position when pressing up so that we don't
    -- go into the negatives; the movement calculation is simply our
    -- previously-defined paddle speed scaled by dt
    if self.dx < 0 then
        self.x = math.max(0, self.x + self.dx * dt)
    -- similar to before, this time we use math.min to ensure we don't
    -- go any farther than the bottom of the screen minus the paddle's
    -- height (or else it will go partially below, since position is
    -- based on its top left corner)
    else
        self.x = math.min(VIRTUAL_WIDTH - self.width, self.x + self.dx * dt)
    end
end



-- ====================== TIM LUMNAH'S EDITS ======================
-- create helpers to transition between paddle sizes
local PADDLE_WIDTHS = {32, 64, 96, 128}

function Paddle:grow()
    -- grow the paddle 
    if self.size < 4 then
        self.size = self.size + 1
        self:updateQuad()
    end
end

function Paddle:shrink()
    -- shrink the paddle 
    if self.size > 1 then
        self.size = self.size - 1
        self:updateQuad()
    end
end

function Paddle:updateQuad()
    -- update paddle skin/quad based on self.size
    -- assumes self.size has changed and is accurate

    -- update width collision
    self.width = PADDLE_WIDTHS[self.size]

    -- ensure paddle can't go off screen
    if self.x + self.width > VIRTUAL_WIDTH then
        self.x = VIRTUAL_WIDTH - self.width
    end

    self.frame = (self.skin - 1) * 4 + self.size
    self.quad = gFrames['paddles'][self.frame]

end

function Paddle:render()
    -- simplified render function that uses the quad
    -- as defined by init params and new helper functions above
    love.graphics.draw(gTextures['main'], self.quad, self.x, self.y)
end

-- ================================================================