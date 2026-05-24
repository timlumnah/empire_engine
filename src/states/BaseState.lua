--[[
    Empire Engine
    Based on CS50 2D Coursework

    BaseState.lua

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    Empty default implementations of init, enter, exit, update,
    render, and processAI. All game and entity states inherit from
    this so unimplemented methods are silent no-ops rather than errors.
]]

BaseState = Class{}

function BaseState:init() end
function BaseState:enter() end
function BaseState:exit() end
function BaseState:update(dt) end
function BaseState:render() end