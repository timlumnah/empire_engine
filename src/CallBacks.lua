--[[
   Empire Engine
   Based on CS50 2D Coursework

   -- Object Callbacks --

   Author: Tim Lumnah
   github.com/timlumnah/empire_engine

   This file contains the logic for object callbacks such as collision & consumption
   effects & behaviors of GameObjects.  
]]

local CALLBACKS = {}

function CALLBACKS.switch_onCollide(player, object, room)
   -- a function for the switch that will open all doors in the room

   if object.state == 'unpressed' then
      object.state = 'pressed'
      
      -- open every door in the room if we press the switch
      for k, doorway in pairs(room.doorways) do
         doorway.open = true
      end

      gSounds['door']:play()
   end
end

function CALLBACKS.heart_onConsume(player, object, room)

   -- player health +2 or 6, whichever is lower
   player.health = math.min(player.health + 2, 6)

   -- initiate despawn (will flag for removal in Room:update())
   object:destroy()

   gSounds['heart-consume']:play()
end

function CALLBACKS.pot_onInteract(player, object, room)
   -- switch to lift state, which handles detection!
   player:changeState('lift')
end


function CALLBACKS.pot_onUpdate(pot, dt)
   -- this is only really needed for the shattering animation
   if pot.breaking then
      if pot.currentAnimation and pot.currentAnimation.timesPlayed > 0 then
         pot:despawn()
      end
      return
   end
end

function CALLBACKS.pot_break(pot)
   -- centralized logic for breaking & despawning pots
   if pot.breaking then
      return
   end

   pot.breaking = true
   pot.dx, pot.dy = 0, 0
   pot:changeAnimation('break')
   gSounds['pot-shatter']:play()
end

function CALLBACKS.pot_onHitEntity(pot, entity)
   -- damage entity & break pot
   -- coincidentally, this kills enemies because enemy health == 1
   entity:damage(1)
   CALLBACKS.pot_break(pot)
end

function CALLBACKS.pot_onHitWall(pot)
   -- breaks on wall contact
   CALLBACKS.pot_break(pot)
end

function CALLBACKS.pot_onMaxDistance(pot)
   -- breaks at max distance == 4 tiles
   CALLBACKS.pot_break(pot)
end

function CALLBACKS.spawn_object(params)
   -- adapted from my original spawn_object() used in Mario
   -- updated to use Room in place of context table
   
   local def = GAME_OBJECT_DEFS[params.name]

   local obj = {
      type = def.type,
      texture = def.texture,
      x = params.x,
      y = params.y,
      width = def.width,
      height = def.height,
      solid = def.solid,
      collidable = def.collidable,
      consumable = def.consumable,
      callbacks = def.callbacks,
      defaultState = def.defaultState,
      state = def.defaultState,
      states = def.states,
      room = params.room,
      animations = def.animations,

      -- support frame as predetermined or a function
      frame = type(def.frame) == "function" and def.frame() or def.frame,
   }

   -- apply any overrides or extra params not in defaults
   -- loop through a nested overrides table within params
   -- and iteratively apply those to the object.
   if params.overrides then
     for k, v in pairs(params.overrides) do
         obj[k] = v
     end
   end


   local gameObject = GameObject(obj)

   -- accept context object table if none is specified in params
   local target = params.obj_table or params.room.objects
   table.insert(target, gameObject)

   return gameObject
end


function CALLBACKS.spawn_projectile(params)
   -- similar to spawn_object(), but adds velocity

   -- use params.type instead of params.name here
   -- because Room:generateObjects() creates a temporary
   -- "name" var which mirrors def.type as part of loop
   local def = GAME_OBJECT_DEFS[params.type]

   local projectile = Projectile({
      type = def.type,
      texture = def.texture,
      x = params.x,
      y = params.y,
      width = def.width,
      height = def.height,
      dx = params.dx,
      dy = params.dy,
      room = params.room,
      owner = params.owner,
      callbacks = def.callbacks,
      animations = def.animations,

      -- support frame as predetermined or a function
      frame = type(def.frame) == "function" and def.frame() or def.frame,
   })

   table.insert(params.room.projectiles, projectile)

   return projectile
end


return CALLBACKS