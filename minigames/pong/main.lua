--[[
    Pong minigame. Adapted from CS50 2D scaffold by Colton Ogden.
    Wired into MinigameState; no standalone push setup.

    Controls: Up/Down = player (right paddle). Left paddle is CPU.
    Enter = advance state, Escape/X = exit to game
]]

local BASE     = "minigames.pong."
local FILEBASE = "minigames/pong/"

local Class   = require(BASE .. "class")
local Paddle  = require(BASE .. "Paddle")
local Ball    = require(BASE .. "Ball")

PADDLE_SPEED = 200
local AI_SPEED = 55  -- px/sec; lower = lazier tracking

local Pong = {}

function Pong.load()
    Pong.smallFont = love.graphics.newFont(FILEBASE .. "font.ttf", 8)
    Pong.largeFont = love.graphics.newFont(FILEBASE .. "font.ttf", 16)
    Pong.scoreFont = love.graphics.newFont(FILEBASE .. "font.ttf", 32)

    local SOUNDS = FILEBASE .. "sounds/"
    Pong.sounds = {
        ['paddle_hit'] = love.audio.newSource(SOUNDS .. 'paddle_hit.wav', 'static'),
        ['score']      = love.audio.newSource(SOUNDS .. 'score.wav',      'static'),
        ['wall_hit']   = love.audio.newSource(SOUNDS .. 'wall_hit.wav',   'static'),
    }

    Pong.player1      = Paddle:new(10, 30, 5, 20)
    Pong.player2      = Paddle:new(VIRTUAL_WIDTH - 15, VIRTUAL_HEIGHT - 30, 5, 20)
    Pong.aiTargetY    = VIRTUAL_HEIGHT / 2
    Pong.ball         = Ball:new(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)
    Pong.player1Score = 0
    Pong.player2Score = 0
    Pong.servingPlayer = 1
    Pong.winningPlayer = 0
    Pong.gameState    = 'start'
    Pong.rewardPending = false
end

function Pong.update(dt)
    -- key transitions
    if love.keyboard.wasPressed('escape') then
        if Pong.rewardPending then
            return { outcome = 'player_win', reward = MINIGAME_DEFS['pong'].reward }
        end
        return "exit"
    end

    if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
        if Pong.gameState == 'start' then
            Pong.gameState = 'serve'
        elseif Pong.gameState == 'serve' then
            Pong.gameState = 'play'
        elseif Pong.gameState == 'done' then
            Pong.gameState = 'serve'
            Pong.ball:reset()
            Pong.player1Score = 0
            Pong.player2Score = 0
            Pong.rewardPending = false
            if Pong.winningPlayer == 1 then
                Pong.servingPlayer = 2
            else
                Pong.servingPlayer = 1
            end
        end
    end

    -- serve: set ball velocity
    if Pong.gameState == 'serve' then
        Pong.ball.dy = math.random(-50, 50)
        if Pong.servingPlayer == 1 then
            Pong.ball.dx = math.random(140, 200)
        else
            Pong.ball.dx = -math.random(140, 200)
        end
    elseif Pong.gameState == 'play' then
        -- paddle collisions
        if Pong.ball:collides(Pong.player1) then
            Pong.ball.dx = -Pong.ball.dx * 1.03
            Pong.ball.x  = Pong.player1.x + 5
            Pong.ball.dy = Pong.ball.dy < 0 and -math.random(10, 150) or math.random(10, 150)
            Pong.sounds['paddle_hit']:play()
        end
        if Pong.ball:collides(Pong.player2) then
            Pong.ball.dx = -Pong.ball.dx * 1.03
            Pong.ball.x  = Pong.player2.x - 4
            Pong.ball.dy = Pong.ball.dy < 0 and -math.random(10, 150) or math.random(10, 150)
            Pong.sounds['paddle_hit']:play()
        end

        -- wall bounces
        if Pong.ball.y <= 0 then
            Pong.ball.y  = 0
            Pong.ball.dy = -Pong.ball.dy
            Pong.sounds['wall_hit']:play()
        end
        if Pong.ball.y >= VIRTUAL_HEIGHT - 4 then
            Pong.ball.y  = VIRTUAL_HEIGHT - 4
            Pong.ball.dy = -Pong.ball.dy
            Pong.sounds['wall_hit']:play()
        end

        -- scoring
        local winScore = MINIGAME_DEFS['pong'].winScore
        if Pong.ball.x < 0 then
            Pong.servingPlayer = 1
            Pong.player2Score  = Pong.player2Score + 1
            Pong.sounds['score']:play()
            if Pong.player2Score == winScore then
                Pong.winningPlayer = 2
                Pong.gameState     = 'done'
                Pong.rewardPending = true  -- player (right paddle) won
            else
                Pong.gameState = 'serve'
                Pong.ball:reset()
            end
        end
        if Pong.ball.x > VIRTUAL_WIDTH then
            Pong.servingPlayer = 2
            Pong.player1Score  = Pong.player1Score + 1
            Pong.sounds['score']:play()
            if Pong.player1Score == winScore then
                Pong.winningPlayer = 1
                Pong.gameState     = 'done'
                Pong.rewardPending = false  -- CPU won, no reward
            else
                Pong.gameState = 'serve'
                Pong.ball:reset()
            end
        end
    end

    -- CPU (left paddle): lazily tracks ball y
    local ball_center = Pong.ball.y + Pong.ball.height / 2
    local paddle_center = Pong.player1.y + Pong.player1.height / 2
    local diff = ball_center - paddle_center
    local step = math.min(math.abs(diff), AI_SPEED * dt)
    if diff > 1 then
        Pong.player1.y = Pong.player1.y + step
    elseif diff < -1 then
        Pong.player1.y = Pong.player1.y - step
    end
    Pong.player1.y = math.max(0, math.min(VIRTUAL_HEIGHT - Pong.player1.height, Pong.player1.y))

    -- player (right paddle)
    if love.keyboard.isDown('up') then
        Pong.player2.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('down') then
        Pong.player2.dy = PADDLE_SPEED
    else
        Pong.player2.dy = 0
    end

    if Pong.gameState == 'play' then
        Pong.ball:update(dt)
    end
    Pong.player1:update(dt)
    Pong.player2:update(dt)
end

function Pong.draw()
    love.graphics.clear(40/255, 45/255, 52/255, 1)

    if Pong.gameState == 'start' then
        love.graphics.setFont(Pong.smallFont)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf('PONG', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('CPU  vs  You (Up/Down)', 0, 20, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to begin', 0, 30, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('[ESC] exit', 0, VIRTUAL_HEIGHT - 12, VIRTUAL_WIDTH, 'center')
    elseif Pong.gameState == 'serve' then
        love.graphics.setFont(Pong.smallFont)
        love.graphics.setColor(1, 1, 1, 1)
        local server = Pong.servingPlayer == 1 and 'CPU' or 'Your'
        love.graphics.printf(server .. " serve",
            0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to serve', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif Pong.gameState == 'done' then
        love.graphics.setFont(Pong.largeFont)
        love.graphics.setColor(1, 1, 1, 1)
        local winner = Pong.winningPlayer == 1 and 'CPU wins!' or 'You win!'
        love.graphics.printf(winner, 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(Pong.smallFont)
        love.graphics.printf('Enter to restart  ESC to exit', 0, 30, VIRTUAL_WIDTH, 'center')
    end

    -- scores
    love.graphics.setFont(Pong.scoreFont)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(tostring(Pong.player1Score), VIRTUAL_WIDTH / 2 - 50, VIRTUAL_HEIGHT / 3)
    love.graphics.print(tostring(Pong.player2Score), VIRTUAL_WIDTH / 2 + 30, VIRTUAL_HEIGHT / 3)

    Pong.player1:render()
    Pong.player2:render()
    Pong.ball:render()

    love.graphics.setColor(1, 1, 1, 1)
end

return Pong
