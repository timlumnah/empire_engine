--[[
    Empire Engine
    Based on CS50 2D Coursework

    Dependencies.lua

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    Loads and registers all global game resources: textures, sprite
    quad atlases, fonts, and sound effects / music streams. Must be
    required before any state accesses gTextures, gFonts, gSounds,
    or gFrames.
]]

--
-- libraries
--

Class = require 'lib.class'
Event = require 'lib.knife.event'
push = require 'lib.push'
Timer = require 'lib.knife.timer'
CALLBACKS = require 'src.CallBacks'

require 'src.Animation'
require 'src.constants'
require 'src.Entity'

require 'src.GameObject'
require 'src.Projectile'
require 'src.Business'
require 'src.SaveLoad'
require 'src.BusinessMenu'
require 'src.BusinessOpenMenu'
require 'src.LoanMenu'
require 'src.PauseMenu'
require 'src.Market'

require 'src.defs.object_defs'
require 'src.defs.entity_defs'
require 'src.defs.business_defs'
require 'src.defs.biomes'
require 'src.defs.market_events'
require 'src.Util'
require 'src.defs.plot'
require 'src.defs.products'
require 'src.defs.vendors'
require 'src.defs.minigame_defs'
require 'src.defs.shmooze_defs'

require 'src.MarketplaceMenu'
require 'src.NpcMenu'
require 'src.InventoryMenu'

require 'src.Hitbox'
require 'src.Player'
require 'src.StateMachine'


require 'src.world.Doorway'
require 'src.world.World'
require 'src.WorldMaker'
require 'src.world.Room'

require 'src.states.BaseState'

require 'src.states.entity.EntityIdleState'
require 'src.states.entity.EntityWalkState'

require 'src.states.entity.player.PlayerIdleState'
require 'src.states.entity.player.PlayerSwingSwordState'
require 'src.states.entity.player.PlayerWalkState'
require 'src.states.entity.player.PlayerLiftState'
require 'src.states.entity.player.PlayerCarryingState'
require 'src.states.entity.player.PlayerCarryingIdleState'
require 'src.states.entity.player.PlayerThrowState'
require 'src.states.entity.player.PlayerBoomerangState'

require 'src.PoliceSystem'
require 'src.ShmoozeSystem'

require 'src.states.game.GameOverState'
require 'src.states.game.WinState'
require 'src.states.game.PlayState'
require 'src.states.game.StartState'
require 'src.states.MinigameState'

gTextures = {
    ['tiles'] = love.graphics.newImage('graphics/tilesheet.png'),
    ['background'] = love.graphics.newImage('graphics/background.png'),
    ['character-walk'] = love.graphics.newImage('graphics/character_walk.png'),
    ['character-swing-sword'] = love.graphics.newImage('graphics/character_swing_sword.png'),
    ['hearts'] = love.graphics.newImage('graphics/hearts.png'),
    ['switches'] = love.graphics.newImage('graphics/switches.png'),
    ['entities'] = love.graphics.newImage('graphics/entities.png'),

    -- ['floor-tiles'] = love.graphics.newImage('graphics/floor_tiles_16px.png'),

    ['pot'] = love.graphics.newImage('graphics/pot_16px.png'),
    ['boomerang'] = love.graphics.newImage('graphics/boomerang_16px.png'),
    ['chest'] = love.graphics.newImage('graphics/chest_16px.png'),
    ['character-pot-lift'] = love.graphics.newImage('graphics/character_pot_lift.png'),
    ['character-pot-walk'] = love.graphics.newImage('graphics/character_pot_walk.png'),
    ['particle'] = love.graphics.newImage('graphics/particle.png'),
}

gFrames = {
    ['tiles'] = GenerateQuads(gTextures['tiles'], 16, 16),
    ['character-walk'] = GenerateQuads(gTextures['character-walk'], 16, 32),
    ['character-swing-sword'] = GenerateQuads(gTextures['character-swing-sword'], 32, 32),
    ['entities'] = GenerateQuads(gTextures['entities'], 16, 16),
    ['hearts'] = GenerateQuads(gTextures['hearts'], 16, 16),
    ['switches'] = GenerateQuads(gTextures['switches'], 16, 18),
    -- ['floor-tiles'] = GenerateQuads(gTextures['floor-tiles'], 16, 16),
    ['pot'] = GenerateQuads(gTextures['pot'], 16, 16),
    ['boomerang'] = GenerateQuads(gTextures['boomerang'], 16, 16),
    ['chest'] = GenerateQuads(gTextures['chest'], 16, 16),
    ['character-pot-lift'] = GenerateQuads(gTextures['character-pot-lift'], 16, 32),
    ['character-pot-walk'] = GenerateQuads(gTextures['character-pot-walk'], 16, 32),

}

gFonts = {
    ['small'] = love.graphics.newFont('fonts/font.ttf',         8),
    ['medium'] = love.graphics.newFont('fonts/font.ttf',        16),
    ['large'] = love.graphics.newFont('fonts/font.ttf',        32),
    ['gothic-medium'] = love.graphics.newFont('fonts/font.ttf',         16),
    ['gothic-large'] = love.graphics.newFont('fonts/font.ttf',         32),
    ['zelda'] = love.graphics.newFont('fonts/ariblk.ttf',       32),
    ['zelda-small'] = love.graphics.newFont('fonts/ariblk.ttf',       16),
}

gSounds = {
    ['sword'] = love.audio.newSource('sounds/sword.wav', 'static'),
    ['hit-enemy'] = love.audio.newSource('sounds/hit_enemy.wav', 'static'),
    ['door'] = love.audio.newSource('sounds/door.wav', 'static'),

    -- https://pixabay.com/sound-effects/film-special-effects-health-pickup-6860/
    ['heart-consume'] = love.audio.newSource('sounds/heart.mp3', 'static'),

    -- https://pixabay.com/sound-effects/film-special-effects-glass-shatter-7-95202/
    ['pot-shatter'] = love.audio.newSource('sounds/pot_shatter.wav', 'static'),
    ['boomerang'] = love.audio.newSource('sounds/boomerang.wav', 'static'),
    ['scream'] = love.audio.newSource('sounds/wilhelm.wav', 'static'),
    ['walk'] = love.audio.newSource('sounds/walk.mp3', 'static'),
    ['police-siren'] = love.audio.newSource('sounds/police_siren.mp3', 'stream'),

    -- https://mixkit.co/free-sound-effects
    ['door-open-1'] = love.audio.newSource('sounds/door_open_1.wav', 'static'),
    ['door-open-2'] = love.audio.newSource('sounds/door_open_2.wav', 'static'),
    ['game-over'] = love.audio.newSource('sounds/gameOverState.wav', 'static'),
    ['mad-npc'] = love.audio.newSource('sounds/mad_npc.wav', 'static'),
    ['minigame-win'] = love.audio.newSource('sounds/minigame_win.wav', 'static'),
    ['package-open'] = love.audio.newSource('sounds/package_open.wav', 'static'),
    ['win'] = love.audio.newSource('sounds/winState.wav', 'static'),

    -- -- Music by <a href="https://pixabay.com/users/litesaturation-17654080/?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=321405">LiteSaturation</a> from <a href="https://pixabay.com//?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=321405">Pixabay</a>
    -- ['music1'] = love.audio.newSource('sounds/litesaturation-piano-jazz-321405.mp3', 'static'),

    -- -- Music by <a href="https://pixabay.com/users/atlasaudio-54514918/?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=490623">AtlasAudio</a> from <a href="https://pixabay.com//?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=490623"
    -- ['music2'] = love.audio.newSource('sounds/atlasaudio-jazz-490623.mp3', 'static'),

    -- ['music3'] = love.audio.newSource('sounds/pno_jazz.mp3', 'static'),

    ['minigame-music'] = love.audio.newSource('minigames/breakout/sounds/music.wav', 'static'),
    ['warning'] = love.audio.newSource('sounds/warning.wav', 'static'),

    -- Music by Ievgen Poltavskyi from Pixabay
    ['biome1'] = love.audio.newSource('sounds/biome1.mp3', 'stream'),
    -- Music by Mykola Sosin from Pixabay
    ['biome2'] = love.audio.newSource('sounds/biome2.mp3', 'stream'),
    -- Music by Andrii Poradovskyi from Pixabay
    ['biome3'] = love.audio.newSource('sounds/biome3.mp3', 'stream'),
}

gSounds['minigame-music']:setLooping(true)
gSounds['biome1']:setLooping(true)
gSounds['biome2']:setLooping(true)
gSounds['biome3']:setLooping(true)