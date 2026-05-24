--[[
    Breakout minigame wrapper.
    Adapts standalone Breakout into the MinigameState module pattern.
    Uses global save/restore to keep breakout globals isolated from the main game.

    Controls: Left/Right = paddle. Enter = confirm. Escape/X = exit to game.
    Win: clear level 1 -> reward. Game over -> no reward, return to game.
]]

local FILEBASE = "minigames/breakout/"

-- Capture main game virtual dims before any swap
local MAIN_VW = VIRTUAL_WIDTH
local MAIN_VH = VIRTUAL_HEIGHT

local Breakout = {}

-- Globals breakout clobbers; saved and restored around every call
local SWAP_KEYS = {
    'gStateMachine', 'gTextures', 'gFonts', 'gSounds', 'gFrames',
    'VIRTUAL_WIDTH', 'VIRTUAL_HEIGHT', 'PADDLE_SPEED',
    'PlayState', 'GameOverState', 'VictoryState',
    'ServeState', 'StartState', 'HighScoreState',
    'EnterHighScoreState', 'PaddleSelectState',
    'Ball', 'Brick', 'Paddle', 'Powerup', 'LevelMaker',
    'GenerateQuads', 'GenerateQuadsPaddles', 'GenerateQuadsBalls',
    'GenerateQuadsBricks', 'GenerateQuadsPowerupsRow',
    'renderScore', 'renderHealth', 'displayFPS', 'loadHighScores',
    'NONE', 'SOLID', 'ALTERNATE', 'SKIP', 'MULTI_PYRAMID', 'SINGLE_PYRAMID',
    'paletteColors', 'POWERUP_FRAMES',
    'b',
}

local bGlobals = {}
local mainGlobals = {}

local function swapIn()
    for _, k in ipairs(SWAP_KEYS) do
        mainGlobals[k] = _G[k]
        _G[k] = bGlobals[k]
    end
end

local function swapOut()
    for _, k in ipairs(SWAP_KEYS) do
        bGlobals[k] = _G[k]
        _G[k] = mainGlobals[k]
    end
end

local bExitPending = false
local bWinPending = false
local bLoaded = false

-- Intercepts game-over and level-complete transitions to signal back to MinigameState
local function wrapStateMachine(sm)
    local proxy = {}

    function proxy:change(stateName, params)
        if stateName == 'game-over' or stateName == 'enter-high-score' then
            bExitPending = true
        elseif stateName == 'serve' and params and (params.level or 1) > 1 then
            -- level 1 cleared; player wins
            bWinPending = true
        else
            sm:change(stateName, params)
        end
    end

    function proxy:update(dt) sm:update(dt) end
    function proxy:render()   sm:render()   end

    return proxy
end

function Breakout.load()
    bExitPending = false
    bWinPending = false

    swapIn()

    local origQuit = love.event.quit
    love.event.quit = function() bExitPending = true end

    if not bLoaded then
        -- util first: defines GenerateQuads*
        require('minigames.breakout.src.Util')
        -- constants: sets VIRTUAL_WIDTH=432, VIRTUAL_HEIGHT=243, PADDLE_SPEED=200
        require('minigames.breakout.src.constants')

        require('minigames.breakout.src.Ball')
        require('minigames.breakout.src.Brick')
        require('minigames.breakout.src.Paddle')
        require('minigames.breakout.src.Powerup')
        require('minigames.breakout.src.LevelMaker')

        -- state classes (use main game's identical BaseState)
        require('minigames.breakout.src.states.PlayState')
        require('minigames.breakout.src.states.ServeState')
        require('minigames.breakout.src.states.GameOverState')
        require('minigames.breakout.src.states.VictoryState')
        require('minigames.breakout.src.states.StartState')
        require('minigames.breakout.src.states.HighScoreState')
        require('minigames.breakout.src.states.EnterHighScoreState')
        require('minigames.breakout.src.states.PaddleSelectState')

        gFonts = {
            ['small'] = love.graphics.newFont(FILEBASE .. 'fonts/font.ttf', 8),
            ['medium'] = love.graphics.newFont(FILEBASE .. 'fonts/font.ttf', 16),
            ['large'] = love.graphics.newFont(FILEBASE .. 'fonts/font.ttf', 32),
        }

        gTextures = {
            ['background'] = love.graphics.newImage(FILEBASE .. 'graphics/background.png'),
            ['main'] = love.graphics.newImage(FILEBASE .. 'graphics/breakout.png'),
            ['arrows'] = love.graphics.newImage(FILEBASE .. 'graphics/arrows.png'),
            ['hearts'] = love.graphics.newImage(FILEBASE .. 'graphics/hearts.png'),
            ['particle'] = love.graphics.newImage(FILEBASE .. 'graphics/particle.png'),
        }

        gFrames = {
            ['arrows'] = GenerateQuads(gTextures['arrows'], 24, 24),
            ['paddles'] = GenerateQuadsPaddles(gTextures['main']),
            ['balls'] = GenerateQuadsBalls(gTextures['main']),
            ['bricks'] = GenerateQuadsBricks(gTextures['main']),
            ['hearts'] = GenerateQuads(gTextures['hearts'], 10, 9),
            ['powerups'] = GenerateQuadsPowerupsRow(gTextures['main']),
            ['locked'] = GenerateQuads(gTextures['main'], 32, 16)[24],
        }

        local SND = FILEBASE .. 'sounds/'
        gSounds = {
            ['paddle-hit'] = love.audio.newSource(SND .. 'paddle_hit.wav', 'static'),
            ['score'] = love.audio.newSource(SND .. 'score.wav', 'static'),
            ['wall-hit'] = love.audio.newSource(SND .. 'wall_hit.wav', 'static'),
            ['confirm'] = love.audio.newSource(SND .. 'confirm.wav', 'static'),
            ['select'] = love.audio.newSource(SND .. 'select.wav', 'static'),
            ['no-select'] = love.audio.newSource(SND .. 'no-select.wav', 'static'),
            ['brick-hit-1'] = love.audio.newSource(SND .. 'brick-hit-1.wav', 'static'),
            ['brick-hit-2'] = love.audio.newSource(SND .. 'brick-hit-2.wav', 'static'),
            ['hurt'] = love.audio.newSource(SND .. 'hurt.wav', 'static'),
            ['victory'] = love.audio.newSource(SND .. 'victory.wav', 'static'),
            ['recover'] = love.audio.newSource(SND .. 'recover.wav', 'static'),
            ['high-score'] = love.audio.newSource(SND .. 'high_score.wav', 'static'),
            ['pause'] = love.audio.newSource(SND .. 'pause.wav', 'static'),
            ['powerup'] = love.audio.newSource(SND .. 'powerup.wav', 'static'),
            ['key'] = love.audio.newSource(SND .. 'key.wav', 'static'),
        }

        -- global helpers that state render methods call by name
        renderScore = function(score)
            love.graphics.setFont(gFonts['small'])
            love.graphics.print('Score:', VIRTUAL_WIDTH - 60, 5)
            love.graphics.printf(tostring(score), VIRTUAL_WIDTH - 50, 5, 40, 'right')
        end

        renderHealth = function(health)
            local hx = VIRTUAL_WIDTH - 100
            for i = 1, health do
                love.graphics.draw(gTextures['hearts'], gFrames['hearts'][1], hx, 4)
                hx = hx + 11
            end
            for i = 1, 3 - health do
                love.graphics.draw(gTextures['hearts'], gFrames['hearts'][2], hx, 4)
                hx = hx + 11
            end
        end

        displayFPS = function() end

        loadHighScores = function()
            local scores = {}
            for i = 1, 10 do
                scores[i] = { name = 'CTO', score = (11 - i) * 100 }
            end
            return scores
        end

        bLoaded = true
    else
    end

    local sm = StateMachine {
        ['start'] = function() return StartState() end,
        ['play'] = function() return PlayState() end,
        ['serve'] = function() return ServeState() end,
        ['game-over'] = function() return GameOverState() end,
        ['victory'] = function() return VictoryState() end,
        ['high-scores'] = function() return HighScoreState() end,
        ['enter-high-score'] = function() return EnterHighScoreState() end,
        ['paddle-select'] = function() return PaddleSelectState() end,
    }
    sm:change('start', { highScores = loadHighScores() })

    gStateMachine = wrapStateMachine(sm)

    swapOut()
    love.event.quit = origQuit
end

function Breakout.update(dt)
    -- signals set on previous frame
    if bExitPending then
        bExitPending = false
        return "exit"
    end
    if bWinPending then
        bWinPending = false
        return { outcome = 'player_win', reward = MINIGAME_DEFS['breakout'].reward }
    end

    swapIn()

    local origQuit = love.event.quit
    love.event.quit = function() bExitPending = true end

    gStateMachine:update(dt)

    swapOut()
    love.event.quit = origQuit

    -- signals set during this frame's update
    if bExitPending then
        bExitPending = false
        return "exit"
    end
    if bWinPending then
        bWinPending = false
        return { outcome = 'player_win', reward = MINIGAME_DEFS['breakout'].reward }
    end
end

function Breakout.draw()
    swapIn()

    -- scale breakout's 432x243 virtual space into main game's 384x216 canvas
    local scaleX = MAIN_VW / VIRTUAL_WIDTH
    local scaleY = MAIN_VH / VIRTUAL_HEIGHT

    love.graphics.push()
    love.graphics.scale(scaleX, scaleY)

    local bg = gTextures['background']
    love.graphics.draw(bg, 0, 0, 0,
        VIRTUAL_WIDTH / (bg:getWidth() - 1),
        VIRTUAL_HEIGHT / (bg:getHeight() - 1))

    gStateMachine:render()

    love.graphics.pop()

    swapOut()
end

function Breakout.cleanup()
    swapIn()
    swapOut()
end

return Breakout
