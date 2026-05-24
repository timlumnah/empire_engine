# Empire Engine

CS50 2D -- Final Project
LOVE 11.5 / Lua

A top-down business simulation RPG. Explore a procedurally genearted world, buy and manage businesses, grow your cash empire, and reach the financial goal before going bankrupt or dying. Help your grandmother afford treatment for Varendorf's Syndrome.

---

Run like any other normal lua project.  Enter project directory and run "love ."

---

## Controls
Move with arrow keys
P for pause
Enter to interact
C to use computer
Tab to view businesses.
I to view inventory
H toggles help popup

---

**Win condition:** Reach WIN_CASH_GOAL, defined in constants ($50,000,000).

**Lose conditions:**
- Die -- health reaches 0
- Bankruptcy -- cash drops below BANKRUPTCY_THRESHOLD, defined in constants (-$50,000)
- Go to jail

---

==============================================================================
## File Structure


empire_engine/
  main.lua                   -- entry point, LOVE callbacks
  conf.lua                   -- LOVE config
  src/
    Dependencies.lua         -- requires all modules
    constants.lua            -- global constants
    StateMachine.lua         -- generic state machine
    Entity.lua               -- base entity class
    Player.lua               -- player class (inherits Entity)
    Business.lua             -- business simulation class
    BusinessMenu.lua         -- portfolio viewer UI
    BusinessOpenMenu.lua     -- business purchase UI
    LoanMenu.lua             -- banker NPC loan UI
    MarketplaceMenu.lua      -- computer/phone marketplace and games launcher
    InventoryMenu.lua        -- inventory viewer; consume food/beverages
    Market.lua               -- global market simulation
    PauseMenu.lua            -- pause / sleep / save menu
    SaveLoad.lua             -- JSON save and load
    WorldMaker.lua           -- procedural world generation
    Util.lua                 -- shared helpers
    Animation.lua            -- sprite animation
    defs/
      entity_defs.lua        -- entity type definitions
      object_defs.lua        -- world object definitions
      business_defs.lua      -- business type stats
      biomes.lua             -- biome definitions
      products.lua           -- purchasable products (food, items)
      vendors.lua            -- vendor definitions (who sells what)
      minigame_defs.lua      -- per-minigame config (reward, win score)
      market_events.lua      -- negative market event definitions
      positive_market_events.lua -- positive market event definitions
      plot.lua               -- story beat definitions and narrative text
    world/
      World.lua              -- world container, room transitions
      Room.lua               -- single room: tiles, entities, objects, collision
      Doorway.lua            -- doorway transitions between rooms
    states/
      game/
        StartState.lua       -- title screen
        PlayState.lua        -- main gameplay loop
        GameOverState.lua    -- loss screen
        WinState.lua         -- win screen
        MinigameState.lua    -- module wrapper state for embedded minigames
      entity/                -- player sub-states (walk, idle, sword, lift, carry, etc.)
  minigames/
    pong/                    -- Pong minigame (1P vs CPU, wired into MinigameState)
    breakout/                -- Breakout minigame (wired into MinigameState)
  lib/
    class.lua                -- OOP class system
    push.lua                 -- virtual resolution scaling
    json.lua                 -- JSON encode/decode (for save system)
    knife/                   -- event/timer library
  graphics/                  -- sprite sheets, tiles, UI images
  sounds/                    -- sound effect .wav files
  fonts/                     -- bitmap and TTF fonts

==============================================================================

---

## Gameplay Systems

### World
Three fixed rooms in a vertical chain: Start, Mid, and Endgame. Each room has a locked top door leading to the next room and (in rooms 2 and 3) an open bottom door back. Biome determines which entities appear, which businesses are avaliable, and which floor/wall tile set renders.

### Player
Inherits from Entity. Has health (3 hearts = 6 HP), cash balance, owned businesses, hunger, and thirst. Can swing a sword and lift and throw objects. Death triggers game over.

### Hunger and Thirst
Hunger and thirst decrease in real time. If either drops below 1, health drains. Food and beverages can be purchased from the marketplace with delivery speeds of ~seconds depending on vendors.  Consume healthy food and water for improved health.  Bandages can be used to restore health faster.

### Business System
Businesses are bound to biomes in defs.  Each business tracks revenue, expenses, profit/loss, cash balance, reputation, and age. Businesses update continously (1 game-month = 30 real seconds at 1x speed). Profit is added to player cash each update cycle.

### Market Simulation
Global market runs continuously. Tracks sentiment, GDP growth, interest rate, and volatility. Market state applies multipliers to all business profitability. Random fluctuations applied each frame.

Random market events fire periodically — both negative (recession, supply crisis, rate hike) and positive (tech boom, trade deal, bull market). Active events shown as a banner on screen: red for negative, green for positive. Only one event is active at a time.

### NPC Interaction
Each room spawns two random NPCs (dude / dudette) and one banker. Walk up to any NPC and press Enter. A landing menu appears with two options:

- **Option 1 (BUSINESS / LOAN)** -- opens the business purchase menu (dude/dudette) or the loan menu (banker).
- **Option 2 (SHMOOZE)** -- opens the shmooze screen. Type a compliment and press Enter. If it contains a recognized keyword ("nice hair", "awesome", "you rock", etc.), the NPC's affinity goes up by 1. A green bar above the NPC's head shows current affinity. At 3/3, the top door of the room unlocks.

Any NPC in the room can be shmooozed. One NPC reaching 3/3 affinity is enough to unlock the door.

Competitor NPCs also spawn in rooms. Cannot interact or shmooze. Contact causes damage.

### Marketplace (Computer / Phone)
Press C when the player owns a computer or phone. Opens a three-page UI:

- **Landing** -- choose Store or Games
- **Store** -- browse products by vendor. Press Enter to open a buy-confirm dialog. Use Left/Right to set quantity (1-99). Total price shown in green if affordble, red if not. Products are delivered to the current room as a chest object. Walk up and press Enter to collect items; the chest disappears after opening.
- **Games** -- select a minigame to play. Winning earns a cash reward.

### Inventory
Press I to open the inventory. Food and beverages can be consumed for hunger/thirst and a small health boost. Items show vendor, delivery time, quantity owned, and whether they are consumable or owned equipment.

### Loan System
Talk to the banker NPC to take out a loan, if necessary. Loan cash is added immediately. Monthly interest deducted automatically. Loans are interest-only. Active loans shown in loan menu.

### Minigames
Pong & breakout are available as minigames, which the player can play from their computer for a small reward upon winning.

### Living Costs
Rent ($1,500) and utilities ($350) are deducted from player cash automatically every game-month. Costs apply during sleep fast-forward as well. Both figures are visible in the business portfolio (TAB) under "MONTHLY OVERHEAD." The total shows red if current cash is below the combined cost.

### Sleep / Time-Skip
From the pause menu, choose Sleep... (warp) and a duration (1 week, 1 month, 3 months, 1 year). Economic simulation fast-forwards at 10x speed. Progress bar shown. Press Escape to wake early. On wake, hunger and thirst are restored to 25% of max, and any pending deliveries are spawned immediatley.

### Save / Load
Saves to JSON via LOVE's save directory. Saves: player cash, health, owned businesses, market state, world time. World layout regenerates on load. Load option appears in pause menu when a save file exists.

### Plot / Narrative
Three story beat popups fire automatically at key financial milestones: intro on game start, midgame at 50% progress toward WIN_CASH_GOAL, and endgame triggers at 90% completion.  While financial milestones share the same names as the biomes, they're not linked logically by any gameplay mechanic. The win screen shows a narrative resolution around the player's grandmother and Varendorf's Syndrome.

---

## Design Decisions

**Time scale compression.** Real-world business months compressed to 30 seconds per game-month. Business capacity values tuned to produce profitable returns at this scale.

**Biome-gated progression.** Business availability filtered by room biome. Cheap businesses appear early; endgame options (casino, aerospace) only in endgame rooms. Natural economic progression without explicit level gating.

**Confirm dialogs everywhere.** Business purchases, save, load, and sleep all require a yes/no step. Prevents fat-finger loss of cash or save data.

**Repurposed Zelda dungeon project.** Movement, rooms, collision, entity states, and animation reuse or extend the CS50 2D Zelda assignment. All economic, UI, marketplace, inventory, and minigame systems are original.

---

## Reused vs Original Code

**Reused from CS50 2D Zelda:**
- `Entity.lua` -- base entity class and state machine wiring
- `Animation.lua` -- sprite animation system
- `StateMachine.lua` -- generic state machine
- `src/states/entity/` -- player walk, idle, sword, lift, carry states
- `Room.lua` -- tile rendering, collision detection structure, doorway transitions
- `World.lua` -- room grid and transition logic
- `WorldMaker.lua` -- room layout generation (rewritten for fixed 3-room chain)
- `push.lua`, `class.lua` -- third-party libraries (unchanged)

**Reused from CS50 2D Breakout:**
- `minigames/breakout/src/` -- Ball, Brick, Paddle, Powerup, LevelMaker, all state classes
- Adapted: original standalone game wrapped in global save/restore module pattern. Escape/game-over/victory transitions intercepted to integrate reward system.

**Reused from CS50 2D Pong:**
- `minigames/pong/` -- Ball, Paddle classes and rendering
- Adapted: left paddle converted to CPU AI, win/loss conditions wired to reward system, integrated into MinigameState module pattern.

**New to This Project:**
- `Business.lua` -- full business simulation
- `Market.lua` -- global market simulation
- `MarketplaceMenu.lua` -- three-page computer/phone UI with store and games launcher
- `InventoryMenu.lua` -- inventory and item consumption UI
- `BusinessMenu.lua`, `BusinessOpenMenu.lua`, `LoanMenu.lua`, `PauseMenu.lua` -- all other UI
- `SaveLoad.lua` -- JSON save/load system
- `NpcMenu.lua` -- NPC landing menu (business/loan + shmooze) and shmooze text-input screen
- `defs/business_defs.lua`, `defs/biomes.lua`, `defs/products.lua`, `defs/vendors.lua`, `defs/minigame_defs.lua`, `defs/shmooze_defs.lua`, `defs/market_events.lua`, `defs/positive_market_events.lua`, `defs/plot.lua`
- `src/states/game/WinState.lua`, `GameOverState.lua`, `MinigameState.lua`
- `world/biomes.lua` -- biome assignment and floor tile logic
- Win/lose logic, hunger/thirst/living-cost systems, delivery box system, reward animation, sleep system, loan system, HUD

---

## Assets and Libraries

**Libraries:**
- [LOVE 11.5, push.lua, class.lua, knife, json.lua

**Graphics:**
- Tilesheet and character sprites: CS50 2D course assets
- Business menu and HUD elements: original
- Breakout sprite sheet and backgrounds: CS50 2D Breakout course assets
- Minor changes to course spritesheets using graphics software to alter pixels 

**Audio:**
- Sound effects: CS50 2D course assets (sword, hurt, door, etc.)
- Breakout sounds: CS50 2D Breakout course assets
- Additional sound effects (game-over, win, mad NPC, minigame win, package open, door open sequence) used from : https://mixkit.co/free-sound-effects 
- Background music 3 biome tracks, cited in Dependencies.lua, are taken from https://pixabay.com


