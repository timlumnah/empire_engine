--[[
    CS50 2D
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.level = params.level
    self.recoverPoints = params.recoverPoints


    -- ====================== TIM LUMNAH'S EDITS ======================
    -- create tables to hold multiple balls & powerups. this also ensures
    -- that any balls/powerups from previous levels or playstates are
    -- forgotten/erased and a fresh, empty table is created.
    self.balls = {}
    self.fallingPowerups = {}   -- all powerups falling on screen that must be updated
    self.activePowerups = {}    -- all powerups which have effects (like key) that must be tracked

    -- we can skip the ball passed through in params entirely
    -- because of the spawnBalls helper below.
    self:spawnBalls(1)

    -- add a score threshold at which the paddle should first grow
    -- initially set the threshold to 1000
    -- add a score interval at which the paddle should continue to grow
    -- paddle shrinking will happen automatically when a life is lost
    self.PaddleGrowthThreshold = 1000
    self.PaddleGrowthInterval = 2000

    -- keep track of locked brick presence with flag so that
    -- key powerups spawn or don't spawn accordingly.
    self.lockedBrickExists = params.lockedBrickExists or false

    -- ================================================================

end

-- ====================== TIM LUMNAH'S EDITS ======================
-- adds helper functions to spawn powerups & balls
-- adds helper functions to check for collisions of all types
-- this enables cleaner looping in PlayState:update(), given that
-- self.balls and self.fallingPowerups tables will need to be looped through

function PlayState:spawnPowerup(x, y, type)
    -- spawns a powerup--typically when a brick is broken
    -- or otherwise when called by update().
    
    -- Currently only spawns the powerup, but just the fact of
    -- having this helper enables future expansion for powerup
    -- sounds, animations, or further logic.
        
    table.insert(self.fallingPowerups, Powerup(x, y, type))

end

function PlayState:spawnBalls(qty)
    -- spawn balls in a given qty
    -- used in checkCollisionPowerup() when powerup
    -- collides with paddle

    for i = 1, qty do
        -- spawn new ball at the paddle's center
        local newBall = Ball(
            math.random(1, 4),      -- use a random skin
            self.paddle.x + self.paddle.width / 2 - 4,
            self.paddle.y - 8
        )

        -- random horizontal velocity
        newBall.dx = math.random(-200, 200)

        -- upward vertical velocity
        newBall.dy = math.random(-60, -50)

        -- insert the new ball into the balls table
        table.insert(self.balls, newBall)
    end
end


function PlayState:checkCollisionPowerup(powerup)
    -- helper to check powerup collision with the paddle
    -- detects if the paddle "catches" the powerup 
    -- and if so, spawns 2 more balls

    if powerup:collides(self.paddle) then
        -- remove the powerup so it doesn’t trigger repeatedly
        for k, p in pairs(self.fallingPowerups) do
            if p == powerup then
                table.remove(self.fallingPowerups, k)
                break
            end
        end

        -- trigger the effect logic
        if powerup.type == 'normal' then
            self:spawnBalls(2)
            gSounds['powerup']:play()   -- assuming you have a suitable sound
        elseif powerup.type == 'key' then
            gSounds['key']:play()       -- optional, just gives audio feedback
        end

        -- add the powerup effect/benefits to the activePowerups table
        -- using a bool flag such that it won't infinitely write to the table
        self.activePowerups[powerup.type] = true
    end
end

-- create a helper to check ball collision 
function PlayState:checkCollisionPaddle(ball)

    if ball:collides(self.paddle) then

        ball.y = self.paddle.y - 8
        ball.dy = -ball.dy

        local isPaddleMovingLeft = self.paddle.dx < 0
        local isPaddleMovingRight = self.paddle.dx > 0
        local paddleCenter = self.paddle.x + self.paddle.width / 2

        local startingBounceDX = 50
        local bounceAngleMultiplier = 8

        if ball.x < paddleCenter and isPaddleMovingLeft then
            local ballOffset = paddleCenter - ball.x
            ball.dx = -startingBounceDX - bounceAngleMultiplier * ballOffset

        elseif ball.x > paddleCenter and isPaddleMovingRight then
            local ballOffset = ball.x - paddleCenter
            ball.dx = startingBounceDX + bounceAngleMultiplier * ballOffset
        end

        gSounds['paddle-hit']:play()
    end
end

function PlayState:checkCollisionBricks(ball)
    -- moves entire brick collision logic into helper
    -- adds powerup spawning with a given likelihood
    -- when a brick is destroyed

    -- ====================== TIM LUMNAH'S EDITS ======================
    -- check if the player currently has a key powerup using helper function
    local keyPowerup = self.activePowerups['key']
    -- ================================================================

            
    -- detect collision across all bricks with the ball
    for k, brick in pairs(self.bricks) do

        -- only check collision if we're in play
        if brick.inPlay and ball:collides(brick) then

            
            -- ====================== TIM LUMNAH'S EDITS ======================

            -- pass keyPowerup var through to brick:hit() so that it can
            -- unlock locked brick(s) if possible and necessary.
            
            local hitResult = brick:hit(keyPowerup)

            -- add to score conditionally and proportionally to whether or not
            -- the brick is/was locked and if it was destroyed
            if hitResult ~= 'locked' then
                local brickScore = brick.tier * 200 + brick.color * 25
                
                -- add bonus points for breaking a locked brick
                -- assume that brick.isLocked means that the brick WAS locked
                -- but has now been broken, based on other game mechanics.
                -- In other words, because lockedBricks are currently instatiated
                -- with tier=0, it's safe to assume with no further logic that
                -- a locked brick has been destroyed if struck by a ball while
                -- keyPowerup is active.
                if brick.isLocked then
                    brickScore = brickScore * 2
                end
                self.score = self.score + brickScore
            end

            -- check paddle growth and increase paddle size if threshold is met
            if self.score >= self.PaddleGrowthThreshold then
                self.paddle:grow()

                -- set next growth threshold based on growth interval set in init()
                -- add growth interval to current score instead of the previous growth threshold
                self.PaddleGrowthThreshold = self.score + self.PaddleGrowthInterval
            end
            -- ================================================================

            -- if we have enough points, recover a point of health
            if self.score > self.recoverPoints then
                -- can't go above 3 health
                self.health = math.min(3, self.health + 1)

                -- multiply recover points by 2
                self.recoverPoints = math.min(100000, self.recoverPoints * 2)

                -- play recover sound effect
                gSounds['recover']:play()
            end

            -- go to our victory screen if there are no more bricks left
            if self:checkVictory() then
                gSounds['victory']:play()

                gStateMachine:change('victory', {
                    level = self.level,
                    paddle = self.paddle,
                    health = self.health,
                    score = self.score,
                    highScores = self.highScores,
                    ball = ball,
                    recoverPoints = self.recoverPoints
                })
            end

            
            -- ====================== TIM LUMNAH'S EDITS ======================
            -- spawn a powerup with 50% chance (for testing/debug)
            if math.random(2) == 1 then
                
                -- default to normal powerup
                local type = 'normal'
                
                -- spawn key at 25% chance, but only if locked brick exists
                if self.lockedBrickExists and math.random(4) == 1 then
                    type = 'key'
                end

                self:spawnPowerup(brick.x, brick.y, type)

            end

            -- ================================================================
            
            --
            -- collision code for bricks
            --
            -- we check to see how much we overlap on the brick between X and Y axes;
            -- the delta between the centers of the brick and ball will help us pinpoint
            -- which side, and then how far in the ball has overlapped will determine
            -- whether to prioritize a Y bounce or an X bounce

            local BALL_RADIUS = 4
            local BRICK_W, BRICK_H = brick.width, brick.height

            -- centers of X and Y of our brick and ball
            local cxB, cyB = brick.x + BRICK_W / 2, brick.y + BRICK_H / 2
            local cxb, cyb = ball.x + BALL_RADIUS, ball.y + BALL_RADIUS

            -- signed collision offsets between brick and ball
            local ox = cxB - cxb
            local oy = cyB - cyb

            -- penetration depth of the ball on X and Y;
            -- add half-extents of brick and ball, then subtract
            -- amount of overlap on that axis; the higher penetration
            -- depth is the prioritized collision and axis of bounce
            local px = BRICK_W / 2 + BALL_RADIUS - math.abs(ox)
            local py = BRICK_H / 2 + BALL_RADIUS - math.abs(oy)

            if px < py then
                ball.dx = -ball.dx
                ball.x = ball.x + (ox > 0 and -px or px)
            else
                ball.dy = -ball.dy
                ball.y = ball.y + (oy > 0 and -py or py)
            end

            -- slightly scale the y velocity to speed up the game, capping at +- 150
            if math.abs(ball.dy) < 150 then
                ball.dy = ball.dy * 1.02
            end

            -- only allow colliding with one brick, for corners
            break
        end
    end
end

function PlayState:checkBelowBounds()
    -- replaces original lower boundary code from update() method
    -- to allow for balls to despawn with no lives lost if multiple
    -- balls are in play.

    -- remove balls that fell below the screen
    for i = #self.balls, 1, -1 do
        if self.balls[i].y >= VIRTUAL_HEIGHT then
            table.remove(self.balls, i)
        end
    end

    -- only lose a life if there are NO balls left
    if #self.balls == 0 then
        self.health = self.health - 1
        gSounds['hurt']:play()

        -- shrink paddle
        self.paddle:shrink()

        if self.health == 0 then
            gStateMachine:change('game-over', {
                score = self.score,
                highScores = self.highScores
            })
        else
            gStateMachine:change('serve', {
                paddle = self.paddle,
                bricks = self.bricks,
                lockedBrickExists = self.lockedBrickExists,
                health = self.health,
                score = self.score,
                highScores = self.highScores,
                level = self.level,
                recoverPoints = self.recoverPoints
            })
        end
    end
end


-- ================================================================




function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    self.paddle:update(dt)

    -- ====================== TIM LUMNAH'S EDITS ======================
    
    for k, powerup in pairs(self.fallingPowerups) do
        powerup:update(dt)
        self:checkCollisionPowerup(powerup)
    end
    
    -- must update ball table with loop
    for k, ball in pairs(self.balls) do
        ball:update(dt)

        -- check ball collision in loop using helper
        self:checkCollisionPaddle(ball)
        self:checkCollisionBricks(ball)
        self:checkBelowBounds(ball)
    end
    
    -- ================================================================


    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    

    self.paddle:render()

    -- ====================== TIM LUMNAH'S EDITS ======================
    for k, powerup in pairs(self.fallingPowerups) do
        powerup:render()
    end
    for k, ball in pairs(self.balls) do
        ball:render()
    end
    for k, brick in pairs(self.bricks) do
        brick:render()
        brick:renderParticles()
    end
    -- ================================================================

    renderScore(self.score)
    renderHealth(self.health)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end
    end

    return true
end
