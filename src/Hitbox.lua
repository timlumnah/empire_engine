--[[
    Empire Engine
    Based on CS50 2D Coursework

    Hitbox.lua

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    Lightweight AABB rectangle for precise collision detection.
    Entities and objects attach a Hitbox offset from their sprite
    origin to define the solid region used in overlap checks.
]]

Hitbox = Class{}

function Hitbox:init(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
end

function Hitbox:update(x, y)
    self.x = x
    self.y = y
end