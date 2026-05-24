--[[
   Empire Engine
   Based on CS50 2D Coursework

   -- Player Carrying Idle State --

   Author: Tim Lumnah
   github.com/timlumnah/empire_engine

   Idle carrying state to mirror PlayerIdleState.
   Enables player to stand idle while carrying objects
   while incidentally disabling walking animations.
]]

PlayerCarryingIdleState = Class{__includes = EntityIdleState}

function PlayerCarryingIdleState:enter(params)
    
   -- render offset for spaced character sprite
   self.entity.offsetY = 5
   self.entity.offsetX = 0
end

function PlayerCarryingIdleState:update(dt)
   if love.keyboard.isDown('left') or love.keyboard.isDown('right') or
      love.keyboard.isDown('up') or love.keyboard.isDown('down') then
      self.entity:changeState('carrying')
   end

   -- throw the pot
   if love.keyboard.wasPressed('space') then
      self.entity:changeState('throw')
   end
end

