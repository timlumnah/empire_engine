# Third-Party Assets

Empire Engine includes assets from the following sources. These assets are NOT covered by the project's code license. Each retains its original terms.

---

## CS50 2D Course Assets

Source: Harvard CS50 2D Game Development course (https://cs50.harvard.edu/games)

**Graphics**
- `graphics/tilesheet.png` -- tile sheet (walls, floors, doors); from Zelda assignment
- `graphics/character_walk.png`, `character_swing_sword.png`, `character_pot_lift.png`, `character_pot_walk.png` -- player sprites; from Zelda assignment
- `graphics/entities.png` -- NPC and enemy sprites; from Zelda assignment
- `graphics/hearts.png`, `graphics/switches.png`, `graphics/background.png` -- HUD and world elements; from Zelda assignment
- `graphics/breakout.png`, `graphics/blocks.png`, `graphics/arrows.png`, `graphics/ui.png`, `graphics/particle.png` -- from Breakout assignment

**Audio**
- `sounds/sword.wav`, `sounds/hit_enemy.wav`, `sounds/door.wav`, `sounds/boomerang.wav`, `sounds/walk.mp3`, `sounds/wilhelm.wav`, `sounds/warning.wav` -- from Zelda assignment
- `sounds/hurt.wav`, `sounds/confirm.wav`, `sounds/high_score.wav`, `sounds/key.wav`, `sounds/no-select.wav`, `sounds/paddle_hit.wav`, `sounds/pause.wav`, `sounds/powerup.wav`, `sounds/recover.wav`, `sounds/score.wav`, `sounds/select.wav`, `sounds/victory.wav`, `sounds/wall_hit.wav` -- from Breakout/Pong assignments
- `minigames/breakout/sounds/music.wav` -- from Breakout assignment

**Code**
See README.md "Reused vs Original Code" section for the full list of Lua files adapted from CS50 2D Zelda, Breakout, and Pong assignments.

CS50 course content is shared under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc/4.0/). These assets may not be used for commercial purposes.

---

## Mixkit

Source: https://mixkit.co/free-sound-effects

**Audio**
- `sounds/door_open_1.wav`
- `sounds/door_open_2.wav`
- `sounds/gameOverState.wav`
- `sounds/mad_npc.wav`
- `sounds/minigame_win.wav`
- `sounds/package_open.wav`
- `sounds/winState.wav`

License: [Mixkit Free License](https://mixkit.co/license/). Free to use in personal and commercial projects. Assets may not be redistributed or resold as standalone files.

---

## Pixabay

Source: https://pixabay.com

**Audio -- Sound Effects**
- `sounds/heart.mp3` -- "Film Special Effects Health Pickup" (https://pixabay.com/sound-effects/film-special-effects-health-pickup-6860/)
- `sounds/pot_shatter.wav` -- "Film Special Effects Glass Shatter 7" (https://pixabay.com/sound-effects/film-special-effects-glass-shatter-7-95202/)

**Audio -- Music**
- `sounds/biome1.mp3` -- Music by Ievgen Poltavskyi from Pixabay
- `sounds/biome2.mp3` -- Music by Mykola Sosin from Pixabay
- `sounds/biome3.mp3` -- Music by Andrii Poradovskyi from Pixabay

License: [Pixabay Content License](https://pixabay.com/service/license-summary/). Free for commercial and non-commercial use. Attribution appreciated but not required.

---

## Libraries

All libraries are MIT licensed unless noted.

| Library | Author | License |
|---------|--------|---------|
| `lib/class.lua` | Matthias Richter (hump) | MIT |
| `lib/push.lua` | Ulysse Ramage | MIT |
| `lib/json.lua` | rxi | MIT |
| `lib/knife/` | airstruck | MIT |

LÖVE 11.5 game framework: https://love2d.org -- [zlib license](https://www.zlib.net/zlib_license.html)

---

## Original Assets

The following are original to this project and covered by the project license:

- All Lua source files listed under "New to This Project" in README.md
- `graphics/` -- business menu UI elements and HUD overlays created for this project
- `src/defs/` -- all definition tables (business, market, vendors, products, etc.)
