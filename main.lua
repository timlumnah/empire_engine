--[[
   Empire Engine
   Based on CS50 2D Coursework

   -- main.lua --

   Author: Tim Lumnah
   github.com/timlumnah/empire_engine

   Entry point. LOVE callbacks: load, update, draw, resize, keypressed, mousepressed.
   Initializes window, push virtual resolution, state machine, and input table.
]]


love.graphics.setDefaultFilter('nearest', 'nearest')
require 'src.Dependencies'

function love.load()
    love.setDeprecationOutput(false)
    math.randomseed(os.time())
    love.window.setTitle('Empire Engine')

    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        vsync = true,
        resizable = true
    })

    push.setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, { upscale = 'normal' })

    love.graphics.setFont(gFonts['small'])

    gStateMachine = StateMachine {
        ['start']     = function() return StartState() end,
        ['play']      = function() return PlayState() end,
        ['game-over'] = function() return GameOverState() end,
        ['win']       = function() return WinState() end,
        ['minigame']  = function() return MinigameState() end
    }
    gStateMachine:change('start')

    -- gSounds['music1']:setLooping(true)
    -- gSounds['music1']:play()

    love.keyboard.keysPressed = {}
end

function love.resize(w, h)
    push.resize(w, h)
end

function love.keypressed(key)
    love.keyboard.keysPressed[key] = true
end

function love.keyboard.wasPressed(key)
    return love.keyboard.keysPressed[key]
end

function love.update(dt)
    Timer.update(dt)
    gStateMachine:update(dt)
    love.keyboard.keysPressed = {}
end

function love.mousepressed(x, y, button)
    local gx, gy = push.toGame(x, y)
    if gx and gStateMachine.current.mousepressed then
        gStateMachine.current:mousepressed(gx, gy, button)
    end
end

function love.draw()
    push.start()
    gStateMachine:render()
    push.finish()
end