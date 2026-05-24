--[[
    Empire Engine
    Based on CS50 2D Coursework

    PlayState.lua

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    Primary gameplay state. Owns the world, player, market events,
    biome music, police encounters, HUD, all in-game menus, minigame
    launch, and the sleep/wake cycle. Central hub of the game loop.
]]

PlayState = Class{__includes = BaseState}
local renderMap = false
local plotBeatsSeen = {}   -- module-level; persists across state changes within a session
local savedWorld = nil     -- world snapshot preserved across minigame round-trips
local savedPlayer = nil    -- player snapshot preserved across minigame round-trips

local BIOME_MUSIC = {
    ['start'] = 'biome1',
    ['mid'] = 'biome2',
    ['endgame'] = 'biome3',
}

local function switchBiomeMusic(biomeName)
    local newKey = BIOME_MUSIC[biomeName]
    if not newKey then return end
    for _, key in pairs(BIOME_MUSIC) do
        if key ~= newKey then gSounds[key]:stop() end
    end
    if not gSounds[newKey]:isPlaying() then
        gSounds[newKey]:play()
    end
end

-- shared helper for reward/penalty text that floats from center to a target point
local function renderFlyingTextAnim(anim, text, ex, ey, tr, tg, tb)
    local t = anim.timer / anim.duration
    local ease = t * t * (3 - 2 * t)
    local sx = VIRTUAL_WIDTH / 2
    local sy = VIRTUAL_HEIGHT / 2
    local cx = sx + (ex - sx) * ease
    local cy = sy + (ey - sy) * ease
    local alpha
    if t < 0.08 then alpha = t / 0.08
    elseif t > 0.7 then alpha = 1 - (t - 0.7) / 0.3
    else alpha = 1 end
    local scale = 2 - ease
    local font = gFonts['medium']
    love.graphics.setFont(font)
    local tw = font:getWidth(text)
    local th = font:getHeight()
    love.graphics.setColor(tr * 0.85, tg * 0.85, tb * 0.85, alpha * 0.35)
    love.graphics.rectangle('fill', cx - tw * scale / 2 - 4, cy - 2, tw * scale + 8, th * scale + 2, 3)
    love.graphics.setColor(tr, tg, tb, alpha)
    love.graphics.push()
    love.graphics.translate(cx, cy)
    love.graphics.scale(scale, scale)
    love.graphics.print(text, -tw / 2, 0)
    love.graphics.pop()
    love.graphics.setColor(1, 1, 1, 1)
end

local COMPETITOR_INSULTS = {
    "get lost, amateur.",
    "you can't afford my lunch.",
    "i'll buy your business at a discount.",
    "nice startup. shame if it fails.",
    "go back to your day job.",
    "my intern makes more than you.",
    "bankrupt by friday.",
    "i've crushed bigger fish.",
    "you're not even competition.",
    "come back with real money.",
}

function PlayState:init()
    self.businessMenu = BusinessMenu()
    self.businessOpenMenu = BusinessOpenMenu()
    self.loanMenu = LoanMenu()
    self.pauseMenu = PauseMenu()
    self.marketplaceMenu = MarketplaceMenu()
    self.inventoryMenu = InventoryMenu()
    self.npcMenu = NpcMenu()

    -- sleep / fast-forward state
    self.sleeping = false
    self.sleepDt = 0
    self.sleepMax = 0

    -- save confirmation flash (seconds remaining)
    self.saveFlash = 0

    self.livingCostTimer = 0

    -- set true when returning from win screen; disables win check
    self.freePlay = false

    -- market event banner
    self.eventBanner = nil
    self.eventBannerTimer = 0

    self.rewardAnim = nil
    self.showHelp = false
    self.shmoozeSystem = ShmoozeSystem()
    self.competitorInsult = nil
    self.healthLossAnim = nil
    self.police = nil
    self.activePlotDialogue = nil
    self.currentBiomeName = nil
    self.warnTimer = 0
    self.warnActive = false

    self.policeHandler = Event.on('competitor-killed', function()
        if not self.police then self:triggerPolice() end
        return false
    end)
    -- clickable ? button; sits after hearts
    local bx = 3 * (TILE_SIZE + 1) + 4
    self.helpBtn = { x = bx, y = 2, w = 10, h = 11 }

    self.player = Player {
        animations = ENTITY_DEFS['player'].animations,
        walkSpeed = ENTITY_DEFS['player'].walkSpeed,
        
        x = VIRTUAL_WIDTH / 2 - 8,
        y = VIRTUAL_HEIGHT / 2 - 11,
        
        width = 16,
        height = 22,

        -- one heart = 2 health
        health = 6,

        -- rendering and collision offset for spaced sprites
        offsetY = 5
    }

    self.player.loans = {}
    self.player.businesses = self.player.businesses or {}
    self.player.inventory = {}
    self.player.pendingDeliveries = {}
    self.player.hunger = HUNGER_MAX
    self.player.thirst = THIRST_MAX

    self.player.inventory['yphone'] = 1

    self.world = WorldMaker.generate(self.player)
    self.currentRoom = self.world.currentRoom
    self.player.room = self.world.currentRoom
    
    self.player.stateMachine = StateMachine {
        ['walk'] = function() return PlayerWalkState(self.player, self.world) end,
        ['idle'] = function() return PlayerIdleState(self.player) end,
        ['swing-sword'] = function() return PlayerSwingSwordState(self.player, self.world) end,
        ['lift'] = function() return PlayerLiftState(self.player, self.world) end,
        ['carrying'] = function() return PlayerCarryingState(self.player, self.world) end,
        ['carrying-idle'] = function() return PlayerCarryingIdleState(self.player) end,
        ['throw'] = function() return PlayerThrowState(self.player, self.world) end,
    }
    self.player:changeState('idle')
end

function PlayState:mousepressed(x, y, button)
    if button ~= 1 then return end

    if self.activePlotDialogue then
        self.activePlotDialogue = nil
        return
    end

    -- help popup: any click closes it
    if self.showHelp then
        self.showHelp = false
        return
    end

    -- forward to whichever menu is active
    if self.npcMenu.active then
        self.npcMenu:mousepressed(x, y, button)
        return
    end
    if self.pauseMenu.active then
        self.pauseMenu:mousepressed(x, y, button)
        return
    end
    if self.businessOpenMenu.active then
        self.businessOpenMenu:mousepressed(x, y, button)
        return
    end
    if self.loanMenu.active then
        self.loanMenu:mousepressed(x, y, button)
        return
    end
    if self.marketplaceMenu.active then
        self.marketplaceMenu:mousepressed(x, y, button)
        return
    end
    if self.inventoryMenu.active then
        self.inventoryMenu:mousepressed(x, y, button)
        return
    end

    -- ? help button
    local btn = self.helpBtn
    if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
        self.showHelp = true
    end
end

function PlayState:update(dt)
    -- active plot dialogue blocks all input
    if self.activePlotDialogue then
        if love.keyboard.wasPressed('return') or love.keyboard.wasPressed('space') then
            self.activePlotDialogue = nil
        end
        return
    end

    -- help popup blocks all other input
    if self.showHelp then
        if love.keyboard.wasPressed('escape') or love.keyboard.wasPressed('h') then
            self.showHelp = false
        end
        return
    end

    -- sleep fast-forward
    if self.sleeping then
        if love.keyboard.wasPressed('escape') then
            self.sleeping = false
            self.sleepDt = 0
            self.player.hunger = HUNGER_MAX * 0.25
            self.player.thirst = THIRST_MAX * 0.25
            self:flushDeliveries()
        else
            local fastDt = dt * SLEEP_MULTIPLIER
            local remaining = self.sleepMax - self.sleepDt
            local stepDt = math.min(fastDt, remaining)

            -- advance only the economic sim, not player/room
            self.world.time = self.world.time + stepDt
            self.world.market:update(stepDt)
            local profit = 0
            for _, bus in ipairs(self.player.businesses) do
                local ctx = self.world:buildMarketContext(bus)
                profit = profit + (bus:update(stepDt, self.world.market, ctx) or 0)
            end
            for _, loan in ipairs(self.player.loans or {}) do
                profit = profit - (loan.monthlyPayment / SECONDS_PER_MONTH) * stepDt
            end
            self.player.cash = self.player.cash + profit
            self:updateLivingCosts(stepDt)

            self.sleepDt = self.sleepDt + stepDt
            if self.sleepDt >= self.sleepMax then
                self.sleeping = false
                self.sleepDt = 0
                self.player.hunger = HUNGER_MAX * 0.25
                self.player.thirst = THIRST_MAX * 0.25
                self:flushDeliveries()
            end
        end
        return
    end

    -- pause menu
    if love.keyboard.wasPressed('p') and not self.npcMenu.active then
        if self.pauseMenu.active then
            self.pauseMenu:close()
        else
            self.pauseMenu:open()
        end
    end

    if self.pauseMenu.active then
        self.pauseMenu:update(dt)
        -- check if player picked a sleep duration
        if self.pauseMenu.sleepRequested then
            self.sleepMax = self.pauseMenu.sleepRequested
            self.sleepDt = 0
            self.sleeping = true
            self.pauseMenu.sleepRequested = nil
            self.pauseMenu:close()
        end

        if self.pauseMenu.saveRequested then
            self.pauseMenu.saveRequested = nil
            SaveLoad.save(self.player, self.world)
            self.saveFlash = 2.0
        end

        if self.pauseMenu.loadRequested then
            self.pauseMenu.loadRequested = nil
            local data = SaveLoad.load()
            if data then
                gStateMachine:change('play', { saveData = data })
                return
            end
        end

        return
    end

    -- portfolio menu
    if love.keyboard.wasPressed('tab') and not self.npcMenu.active then
        self.businessMenu:toggle()
    end

    if self.businessMenu.active then
        if love.keyboard.wasPressed('escape') then
            self.businessMenu:toggle()
        else
            self.businessMenu:update(dt, self.player)
        end
        return
    end

    -- open-business menu
    if self.businessOpenMenu.active then
        self.businessOpenMenu:update(dt)
        return
    end

    -- loan menu
    if self.loanMenu.active then
        self.loanMenu:update(dt)
        return
    end

    -- npc menu
    if self.npcMenu.active then
        self.npcMenu:update(dt)
        if self.npcMenu.wantsBusinessMenu then
            self.npcMenu.wantsBusinessMenu = false
            self.businessOpenMenu:open(self.player, self.world.currentRoom.biome)
        end
        if self.npcMenu.wantsLoanMenu then
            self.npcMenu.wantsLoanMenu = false
            self.loanMenu:open(self.player)
        end
        return
    end

    -- marketplace menu
    if love.keyboard.wasPressed('c') then
        if self.marketplaceMenu.active then
            self.marketplaceMenu:close()
        elseif self:playerHasMarketAccess() then
            self.marketplaceMenu:open(self.player)
        end
    end

    if self.marketplaceMenu.active then
        self.marketplaceMenu:update(dt)
        return
    end

    -- marketplace queued a minigame launch
    if self.marketplaceMenu.pendingMinigame then
        local game = self.marketplaceMenu.pendingMinigame
        self.marketplaceMenu.pendingMinigame = nil
        savedWorld = self.world
        savedPlayer = self.player
        gStateMachine:change('minigame', { previousState = 'play', minigameName = game })
        return
    end

-- ================== claude_changes_2026-05-23-2157 ==================
    -- marketplace queued a business menu open
    if self.marketplaceMenu.pendingBusinessMenu then
        self.marketplaceMenu.pendingBusinessMenu = false
        self.businessMenu:toggle()
    end
-- ====================================================================

    -- inventory menu
    if love.keyboard.wasPressed('i') then
        if self.inventoryMenu.active then
            self.inventoryMenu:close()
        else
            self.inventoryMenu:open(self.player)
        end
    end

    if self.inventoryMenu.active then
        self.inventoryMenu:update(dt)
        return
    end

    -- normal gameplay
    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end

    if love.keyboard.wasPressed('h') then
        self.showHelp = true
    end

    if love.keyboard.wasPressed('m') then
        renderMap = not renderMap
    end

    if love.keyboard.wasPressed('b') then
        self.player:printBusinesses()
    end

    if love.keyboard.wasPressed('r') then
        gStateMachine:change('play')
    end

    if self.saveFlash > 0 then self.saveFlash = self.saveFlash - dt end
    if self.rewardAnim then
        self.rewardAnim.timer = self.rewardAnim.timer + dt
        if self.rewardAnim.timer >= self.rewardAnim.duration then
            self.rewardAnim = nil
        end
    end
    if self.competitorInsult then
        self.competitorInsult.timer = self.competitorInsult.timer + dt
        if self.competitorInsult.timer >= self.competitorInsult.duration then
            self.competitorInsult = nil
        end
    end
    if self.healthLossAnim then
        self.healthLossAnim.timer = self.healthLossAnim.timer + dt
        if self.healthLossAnim.timer >= self.healthLossAnim.duration then
            self.healthLossAnim = nil
        end
    end

    -- low-stat warning sound: play immediately on crossing threshold, repeat every 10s
    local anyLow = self.player.health <= 2
        or self.player.hunger <= HUNGER_MAX * 0.25
        or self.player.thirst <= THIRST_MAX * 0.25
    if anyLow then
        if not self.warnActive then
            self.warnActive = true
            self.warnTimer = 10
        end
        self.warnTimer = self.warnTimer + dt
        if self.warnTimer >= 10 then
            self.warnTimer = 0
            gSounds['warning']:stop()
            gSounds['warning']:play()
        end
    else
        self.warnActive = false
        self.warnTimer = 0
    end

    -- switch biome music on room change
    local biomeName = self.world.currentRoom.biomeName
    if biomeName ~= self.currentBiomeName then
        self.currentBiomeName = biomeName
        switchBiomeMusic(biomeName)
    end

    self.world:update(dt)
    self.shmoozeSystem:update(dt, self.world.currentRoom)

    self:updateLivingCosts(dt)

    -- hunger and thirst decay over real time
    self.player.hunger = math.max(0, self.player.hunger - HUNGER_DECAY_RATE * dt)
    self.player.thirst = math.max(0, self.player.thirst - THIRST_DECAY_RATE * dt)

    -- health drains when starving or dehydrated; faster if both
    local starving = self.player.hunger < 1
    local dehydrated = self.player.thirst < 1
    if starving or dehydrated then
        local rate = (starving and dehydrated) and VITAL_HEALTH_DRAIN_FAST or VITAL_HEALTH_DRAIN_SLOW
        self.player.health = self.player.health - rate * dt
        if self.player.health <= 0 then
            gStateMachine:change('game-over', { reason = 'death' })
        end
    end

    -- tick pending deliveries; spawn box when timer expires
    self:tickDeliveries(dt)

    -- pick up market event notification and start banner
    local note = self.world.market.pendingNotification
    if note then
        self.world.market.pendingNotification = nil
        self.eventBanner = note
        self.eventBannerTimer = 8.0
    end

    -- tick banner timer
    if self.eventBannerTimer > 0 then
        self.eventBannerTimer = self.eventBannerTimer - dt
        if self.eventBannerTimer <= 0 then
            self.eventBanner = nil
        end
    end

    -- NPC set this flag; open NPC landing menu
    if self.player.wantsNpcMenu then
        local req = self.player.wantsNpcMenu
        self.player.wantsNpcMenu = nil
        self.npcMenu:open(req.npc, req.isBanker)
    end

    -- competitor hit the player with a rude remark and stole half a heart
    if self.player.wantsCompetitorInteract then
        self.player.wantsCompetitorInteract = nil
        local msg = COMPETITOR_INSULTS[math.random(#COMPETITOR_INSULTS)]
        gSounds['mad-npc']:play()
        self.player.health = math.max(0, self.player.health - 0.5)
        self.competitorInsult = { msg = msg, timer = 0, duration = 2.2 }
        self.healthLossAnim = { timer = 0, duration = 1.8 }
        if self.player.health <= 0 then
            gStateMachine:change('game-over', { reason = 'death' })
            return
        end
    end

    -- police response tick
    if self.police then
        local result = self.police:update(dt, self.player)
        if result == 'expired' then
            self.police = nil
        elseif result == 'arrested' then
            return
        end
    end

    -- plot threshold beats
    for _, beat in ipairs(PLOT_BEATS) do
        if not plotBeatsSeen[beat.id] and type(beat.trigger) == 'number' and self.player.cash >= beat.trigger then
            plotBeatsSeen[beat.id] = true
            self.activePlotDialogue = beat
            if beat.marketEvent then
                self.world.market:applyEvent(beat.marketEvent)
                -- suppress the market banner; plot dialogue covers it
                self.world.market.pendingNotification = nil
            end
            break
        end
    end

    -- win / loss checks
    if self.player.cash >= WIN_CASH_GOAL and not self.freePlay then
        local buses = {}
        for _, b in ipairs(self.player.businesses) do
            buses[#buses+1] = { type=b.type, cash=b.cash, reputation=b.reputation, age=b.age }
        end
        gStateMachine:change('win', {
            finalCash = self.player.cash,
            businessCount = #self.player.businesses,
            worldTime = self.world.time,
            saveData = {
                player = { cash=self.player.cash, health=self.player.health },
                world_time = self.world.time,
                market = { sentiment=self.world.market.sentiment, gdpGrowth=self.world.market.gdpGrowth, interestRate=self.world.market.interestRate, volatility=self.world.market.volatility },
                businesses = buses,
            }
        })
    elseif self.player.cash <= -BANKRUPTCY_THRESHOLD then
        gStateMachine:change('game-over', {reason = 'bankrupt'})
    end
end

function PlayState:enter(params)
    -- no params = fresh new game; reset plot state and show intro
    if not params then
        plotBeatsSeen = {}
        for _, beat in ipairs(PLOT_BEATS) do
            if beat.trigger == 'start' then
                plotBeatsSeen[beat.id] = true
                self.activePlotDialogue = beat
                break
            end
        end
    end

    if params and params.freePlay then
        self.freePlay = true
    end

    if params and params.minigameResult then
        -- restore world and player from before the minigame transition
        if savedWorld and savedPlayer then
            self.world:destroy()  -- discard the fresh world created in init()
            self.world = savedWorld
            self.world:reattach()
            self.currentRoom = savedWorld.currentRoom
            self.player = savedPlayer
            self.player.room = savedWorld.currentRoom
            self.player.stateMachine = StateMachine {
                ['walk'] = function() return PlayerWalkState(self.player, self.world) end,
                ['idle'] = function() return PlayerIdleState(self.player) end,
                ['swing-sword'] = function() return PlayerSwingSwordState(self.player, self.world) end,
                ['lift'] = function() return PlayerLiftState(self.player, self.world) end,
                ['carrying'] = function() return PlayerCarryingState(self.player, self.world) end,
                ['carrying-idle'] = function() return PlayerCarryingIdleState(self.player) end,
                ['throw'] = function() return PlayerThrowState(self.player, self.world) end,
            }
            self.player:changeState('idle')
            savedWorld = nil
            savedPlayer = nil
        end

        local res = params.minigameResult
        if res.outcome == 'player_win' and res.reward then
            gSounds['minigame-win']:play()
            self.player.cash = self.player.cash + res.reward
            self.player.displayCash = self.player.cash
            self.rewardAnim = {
                amount = res.reward,
                timer = 0,
                duration = 2.0,
            }
        end
    end

    if not params or not params.saveData then return end
    local d = params.saveData

    if d.player then
        self.player.cash = d.player.cash or self.player.cash
        self.player.health = d.player.health or self.player.health
        self.player.displayCash = self.player.cash
    end

    if d.world_time then
        self.world.time = d.world_time
    end

    if d.market then
        local m = self.world.market
        m.sentiment = d.market.sentiment or m.sentiment
        m.gdpGrowth = d.market.gdpGrowth or m.gdpGrowth
        m.interestRate = d.market.interestRate or m.interestRate
        m.volatility = d.market.volatility or m.volatility
    end

    if d.businesses then
        self.player.businesses = {}
        for _, bd in ipairs(d.businesses) do
            if BUSINESS_TYPES[bd.type] then
                local bus = Business(BUSINESS_TYPES[bd.type])
                bus.cash = bd.cash or bus.cash
                bus.reputation = bd.reputation or 1.0
                bus.age = bd.age or 0
                table.insert(self.player.businesses, bus)
            end
        end
    end

    -- start music for the current biome (covers fresh start, load, and minigame return)
    local startBiome = self.world.currentRoom.biomeName
    self.currentBiomeName = startBiome
    switchBiomeMusic(startBiome)
end

function PlayState:exit()
    self.world:destroy()
    if self.police and self.police.siren then
        self.police.siren:stop()
    end
    if self.policeHandler then
        self.policeHandler:remove()
        self.policeHandler = nil
    end
end

-- separate rendering of different UI elements into helpers

function PlayState:render()
    -- render world and all entities separate from hearts GUI
    love.graphics.push()
    self.world:render()
    love.graphics.pop()

    self.shmoozeSystem:render()
    if self.police then self.police:renderOverlay(self.player) end
    if self.competitorInsult then self:renderCompetitorInsult() end
    if self.healthLossAnim then self:renderHealthLossAnim() end
    self:renderHearts()
    if self.police then self.police:renderLightBar(self.helpBtn) end
    self:renderTopRightStats()
    self:renderMap()

    self:renderVitalBars()

    -- menus render on top of everything
    self.businessMenu:render(self.player, self.world.market)
    self.businessOpenMenu:render()
    self.loanMenu:render()
    self.npcMenu:render()
    self.pauseMenu:render()
    self.marketplaceMenu:render()
    self.inventoryMenu:render()

    if self.sleeping then
        self:renderSleep()
    end

    if self.showHelp then
        self:renderHelp()
    end

    if self.freePlay then
        love.graphics.setFont(gFonts['small'])
        love.graphics.setColor(1, 0.85, 0.1, 0.7)
        love.graphics.printf('FREE PLAY', 0, VIRTUAL_HEIGHT - 11, VIRTUAL_WIDTH, 'center')
        love.graphics.setColor(1, 1, 1, 1)
    end

    self:renderEventBanner()
    if self.rewardAnim then self:renderRewardAnim() end

    if self.saveFlash > 0 then
        love.graphics.setFont(gFonts['small'])
        love.graphics.setColor(0.4, 1, 0.5, math.min(1, self.saveFlash))
        love.graphics.printf('Saved!', 0, VIRTUAL_HEIGHT - 18, VIRTUAL_WIDTH, 'center')
        love.graphics.setColor(1, 1, 1, 1)
    end

    if self.activePlotDialogue then self:renderPlotDialogue() end
end

function PlayState:renderSleep()
    local progress = self.sleepMax > 0 and (self.sleepDt / self.sleepMax) or 0

    -- dim world
    love.graphics.setColor(0, 0, 0, 0.72)
    love.graphics.rectangle('fill', 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)

    -- heading
    love.graphics.setFont(gFonts['gothic-large'])
    love.graphics.setColor(0.7, 0.8, 1, 1)
    love.graphics.printf('Z Z Z', 0, VIRTUAL_HEIGHT / 2 - 28, VIRTUAL_WIDTH, 'center')

    -- progress bar
    local barW = 180
    local barH = 6
    local barX = math.floor((VIRTUAL_WIDTH - barW) / 2)
    local barY = VIRTUAL_HEIGHT / 2 + 8

    love.graphics.setColor(0.2, 0.2, 0.35, 1)
    love.graphics.rectangle('fill', barX, barY, barW, barH, 2)
    love.graphics.setColor(0.55, 0.7, 1, 1)
    love.graphics.rectangle('fill', barX, barY, math.floor(barW * progress), barH, 2)

    -- time skipped so far
    love.graphics.setFont(gFonts['small'])
    love.graphics.setColor(0.5, 0.5, 0.6, 1)
    local skippedMonths = self.sleepDt / SECONDS_PER_MONTH
    love.graphics.printf(
        string.format('%.1f months passed', skippedMonths),
        0, barY + 10, VIRTUAL_WIDTH, 'center'
    )

    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.printf('[ESC] wake early', 0, barY + 20, VIRTUAL_WIDTH, 'center')

    love.graphics.setColor(1, 1, 1, 1)
end

function PlayState:renderHearts()
    -- red pulse behind hearts when health is critically low (1 heart or less)
    if self.player.health <= 2 then
        local pulse = 0.25 + 0.25 * math.abs(math.sin(love.timer.getTime() * 3))
        love.graphics.setColor(1, 0.1, 0.1, pulse)
        love.graphics.rectangle('fill', -2, 0, 3 * (TILE_SIZE + 1) + 2, TILE_SIZE + 4, 3)
    end

    local healthLeft = self.player.health
    local heartFrame = 1

    for i = 1, 3 do
        if healthLeft > 1 then
            heartFrame = 5
        elseif healthLeft == 1 then
            heartFrame = 3
        else
            heartFrame = 1
        end
        love.graphics.draw(gTextures['hearts'], gFrames['hearts'][heartFrame],
            (i - 1) * (TILE_SIZE + 1), 2)
        healthLeft = healthLeft - 2
    end

    -- ? help button
    local btn = self.helpBtn
    love.graphics.setColor(0.15, 0.15, 0.2, 0.85)
    love.graphics.rectangle('fill', btn.x, btn.y, btn.w, btn.h, 2)
    love.graphics.setColor(1, 1, 0.5, 1)
    love.graphics.setFont(gFonts['small'])
    love.graphics.printf('?', btn.x, btn.y + 1, btn.w, 'center')

    -- biome name readout (offset right to leave space for police light bar)
    local room = self.world and self.world.currentRoom
    local biomeName = (room and room.biomeName) or '?'
    love.graphics.setColor(0.7, 0.85, 1, 1)
    love.graphics.print(string.upper(biomeName), btn.x + btn.w + 28, btn.y + 2)

    love.graphics.setColor(1, 1, 1, 1)
end

function PlayState:renderTopRightStats()
    local font = gFonts['medium']
    love.graphics.setFont(font)

    local margin = 8
    local y = 4

    -- convert game-seconds to months / day-of-month
    local totalTime = self.world and self.world.time or 0
    local secsPerDay = SECONDS_PER_MONTH / 30
    local totalDays = math.floor(totalTime / secsPerDay)
    local month = math.floor(totalDays / 30) + 1
    local dayOfMonth = (totalDays % 30) + 1

    local timeText = string.format("Mo%d D%d", month, dayOfMonth)

    -- cash text -- use displayCash for steadier rendering
    local cash = self.player.displayCash or 0
    local absInt = tostring(math.floor(math.abs(cash)))
    local commified = absInt:reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')
    local cashText = (cash < 0 and '-$' or '$') .. commified

    -- start from right edge
    local x = VIRTUAL_WIDTH - margin

    -- draw time
    local timeWidth = font:getWidth(timeText)
    x = x - timeWidth
    love.graphics.print(timeText, x, y)

    -- spacing between elements
    local spacing = 12

    -- display cash
    local cashWidth = font:getWidth(cashText)
    x = x - spacing - cashWidth
    love.graphics.print(cashText, x, y)
end

function PlayState:renderHelp()
    renderHelpPopup()
end

function PlayState:renderEventBanner()
    if not self.eventBanner then return end

    local bw = 304
    local bh = 28
    local bx = math.floor((VIRTUAL_WIDTH - bw) / 2)
    local by = VIRTUAL_HEIGHT - 46

    -- fade out over the last 1.5 seconds
    local alpha = math.min(1.0, self.eventBannerTimer / 1.5)

    -- background + border (green for positive sentiment, red for negative)
    local positive = (self.eventBanner.sentiment or 0) > 0
    if positive then
        love.graphics.setColor(0.04, 0.30, 0.08, 0.93 * alpha)
        love.graphics.rectangle('fill', bx, by, bw, bh, 3)
        love.graphics.setColor(0.22, 0.75, 0.30, alpha)
        love.graphics.rectangle('line', bx, by, bw, bh, 3)
    else
        love.graphics.setColor(0.45, 0.04, 0.04, 0.93 * alpha)
        love.graphics.rectangle('fill', bx, by, bw, bh, 3)
        love.graphics.setColor(0.85, 0.22, 0.22, alpha)
        love.graphics.rectangle('line', bx, by, bw, bh, 3)
    end

    love.graphics.setFont(gFonts['small'])

    -- event name
    love.graphics.setColor(positive and 0.5 or 1, positive and 1 or 0.65, positive and 0.4 or 0.1, alpha)
    love.graphics.printf('! ' .. string.upper(self.eventBanner.name), bx, by + 4, bw, 'center')

    -- description
    love.graphics.setColor(0.88, 0.88, 0.88, 0.9 * alpha)
    love.graphics.printf(self.eventBanner.description, bx, by + 15, bw, 'center')

    love.graphics.setColor(1, 1, 1, 1)
end

function PlayState:renderMap()
    -- render grid of world rooms (8px tiles), top right of screen, if flag enabled
    if renderMap then
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle('fill', VIRTUAL_WIDTH - 92, 16, 82, 82)
        love.graphics.setColor(1, 1, 1, 0.5)

        for y = 1, #self.world.rooms do
            for x = 1, #self.world.rooms[y] do
                local room = self.world.rooms[y][x]

                -- Check if the room exists
                if room then
                    -- Check if the room is the current room
                    if self.world.currentRoom.x == x and self.world.currentRoom.y == y then
                        love.graphics.setColor(1, 0, 0, 0.5)  -- Red for the current room
                    -- Check if the room contains the chest
                    elseif room.chest then
                        love.graphics.setColor(255, 215, 0, 0.5)  -- Gold for the room with the chest
                    else
                        love.graphics.setColor(0, 1, 0, 0.5)  -- Green for regular rooms
                    end
                end

                -- Render the room tile
                love.graphics.rectangle('fill', (x - 1) * 8 + VIRTUAL_WIDTH - 90,
                        (y - 1) * 8 + 18, 8 - 2, 8 - 2)
                love.graphics.setColor(1, 1, 1, 0.5)  -- Reset the color back to default
            end
        end

        love.graphics.setColor(1, 1, 1, 1)  -- Final color reset to white
    end
end

function PlayState:playerHasMarketAccess()
    -- returns true if player owns a computer or phone
    local inv = self.player.inventory
    if not inv then return false end
    for productKey, qty in pairs(inv) do
        if qty > 0 then
            local product = PRODUCTS[productKey]
            if product and (product.type == 'computer' or product.type == 'phone') then
                return true
            end
        end
    end
    return false
end

function PlayState:updateLivingCosts(dt)
    self.livingCostTimer = self.livingCostTimer + dt
    while self.livingCostTimer >= SECONDS_PER_MONTH do
        self.livingCostTimer = self.livingCostTimer - SECONDS_PER_MONTH
        self.player.cash = self.player.cash - (RENT + UTILS)
        self.player.displayCash = self.player.cash
    end
end

function PlayState:tickDeliveries(dt)
    -- decrement delivery timers; spawn box when any reach 0
    local deliveries = self.player.pendingDeliveries
    if not deliveries then return end

    for i = #deliveries, 1, -1 do
        local d = deliveries[i]
        d.timer = d.timer - dt
        if d.timer <= 0 then
            self:spawnDeliveryBox(d.items)
            table.remove(deliveries, i)
        end
    end
end

function PlayState:flushDeliveries()
    -- spawn all pending deliveries immediately (called on wake from sleep)
    local deliveries = self.player.pendingDeliveries
    if not deliveries then return end
    for i = #deliveries, 1, -1 do
        self:spawnDeliveryBox(deliveries[i].items)
        table.remove(deliveries, i)
    end
end

function PlayState:spawnDeliveryBox(items)
    local room = self.world.currentRoom
    local x, y
    local attempts = 0
    repeat
        x = math.random(MAP_RENDER_OFFSET_X + TILE_SIZE * 2, VIRTUAL_WIDTH - TILE_SIZE * 3 - 16)
        y = math.random(MAP_RENDER_OFFSET_Y + TILE_SIZE * 2, VIRTUAL_HEIGHT - TILE_SIZE * 3 - 16)
        attempts = attempts + 1
    until room:valid_spawn(x, y, 16, 16) or attempts > 30

    if attempts > 30 then
        x = VIRTUAL_WIDTH / 2 - 8
        y = VIRTUAL_HEIGHT / 2 - 28
    end

    local box = GameObject({
        type = 'chest',
        texture = 'chest',
        x = x, y = y,
        width = 16, height = 16,
        solid = true,
        collidable = false,
        consumable = false,
        defaultState = 'closed',
        state = 'closed',
        states = {
            ['closed'] = { frame = 1 },
            ['open'] = { frame = 2 },
        },
        room = room,
        deliveryItems = items,
    })

    box.onInteract = function(player_ent, obj, _room)
        if obj.state == 'closed' then
            obj.state = 'open'
            gSounds['package-open']:play()
            for productKey, qty in pairs(obj.deliveryItems) do
                player_ent.inventory[productKey] = (player_ent.inventory[productKey] or 0) + qty
            end
            obj.openTimer = 1.5
        end
    end

    box.onUpdate = function(o, dt)
        if o.openTimer then
            o.openTimer = o.openTimer - dt
            if o.openTimer <= 0 then
                o:destroy()
            end
        end
    end

    table.insert(room.objects, box)
end

function PlayState:renderVitalBars()
    -- hunger and thirst bars, bottom-left
    local x = 4
    local bar_w = 44
    local bar_h = 3
    love.graphics.setFont(gFonts['small'])
    local pulse = 0.25 + 0.25 * math.abs(math.sin(love.timer.getTime() * 3))

    local hungerLow = self.player.hunger <= HUNGER_MAX * 0.25
    local thirstLow = self.player.thirst <= THIRST_MAX * 0.25
    local hy = VIRTUAL_HEIGHT - 20
    local ty = VIRTUAL_HEIGHT - 12

    -- red overlay behind each low stat row (matches hearts treatment)
    if hungerLow then
        love.graphics.setColor(1, 0.1, 0.1, pulse)
        love.graphics.rectangle('fill', x - 2, hy - 1, bar_w + 14, bar_h + 4, 2)
    end
    if thirstLow then
        love.graphics.setColor(1, 0.1, 0.1, pulse)
        love.graphics.rectangle('fill', x - 2, ty - 1, bar_w + 14, bar_h + 4, 2)
    end

    -- hunger bar (orange)
    love.graphics.setColor(0.25, 0.25, 0.25, 0.65)
    love.graphics.rectangle('fill', x + 8, hy + 1, bar_w, bar_h)
    love.graphics.setColor(1, 0.55, 0.1, 1)
    love.graphics.rectangle('fill', x + 8, hy + 1, math.max(0, (self.player.hunger / HUNGER_MAX)) * bar_w, bar_h)
    love.graphics.setColor(hungerLow and 1 or 0.85, hungerLow and 0.15 or 0.5, 0.1, 1)
    love.graphics.print('H', x, hy)

    -- thirst bar (blue)
    love.graphics.setColor(0.25, 0.25, 0.25, 0.65)
    love.graphics.rectangle('fill', x + 8, ty + 1, bar_w, bar_h)
    love.graphics.setColor(0.2, 0.6, 1, 1)
    love.graphics.rectangle('fill', x + 8, ty + 1, math.max(0, (self.player.thirst / THIRST_MAX)) * bar_w, bar_h)
    love.graphics.setColor(thirstLow and 1 or 0.2, thirstLow and 0.15 or 0.5, thirstLow and 0.1 or 0.9, 1)
    love.graphics.print('T', x, ty)

    love.graphics.setColor(1, 1, 1, 1)
end

function PlayState:triggerPolice()
    for _, key in pairs(BIOME_MUSIC) do gSounds[key]:stop() end
    self.police = PoliceSystem(function()
        switchBiomeMusic(self.currentBiomeName)
    end)
end

function PlayState:renderCompetitorInsult()
    local c = self.competitorInsult
    local t = c.timer / c.duration
    local alpha
    if t < 0.08 then
        alpha = t / 0.08
    elseif t > 0.55 then
        alpha = 1 - (t - 0.55) / 0.45
    else
        alpha = 1
    end

    local bw = 190
    local bh = 30
    local bx = math.floor((VIRTUAL_WIDTH - bw) / 2)
    local by = math.floor(VIRTUAL_HEIGHT * 0.44)

    love.graphics.setColor(0.18, 0.02, 0.02, 0.92 * alpha)
    love.graphics.rectangle('fill', bx, by, bw, bh, 3)
    love.graphics.setColor(0.75, 0.1, 0.1, alpha)
    love.graphics.rectangle('line', bx, by, bw, bh, 3)

    love.graphics.setFont(gFonts['small'])
    love.graphics.setColor(1, 0.72, 0.72, alpha)
    love.graphics.printf(c.msg, bx, by + 5, bw, 'center')
    love.graphics.setColor(1, 0.28, 0.28, alpha)
    love.graphics.printf('-1/2 heart', bx, by + 18, bw, 'center')

    love.graphics.setColor(1, 1, 1, 1)
end

function PlayState:renderHealthLossAnim()
    renderFlyingTextAnim(self.healthLossAnim, '-1/2 HP', 8, 8, 1, 0.15, 0.15)
end

function PlayState:renderRewardAnim()
    renderFlyingTextAnim(self.rewardAnim,
        string.format('+$%d', self.rewardAnim.amount),
        VIRTUAL_WIDTH - 48, 4, 0.3, 1, 0.45)
end

function PlayState:renderPlotDialogue()
    local beat = self.activePlotDialogue
    local w = 280
    local h = 155
    local pad = 10
    local bx = math.floor((VIRTUAL_WIDTH - w) / 2)
    local by = math.floor((VIRTUAL_HEIGHT - h) / 2)

    -- dim background
    love.graphics.setColor(0, 0, 0, 0.78)
    love.graphics.rectangle('fill', 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)

    -- box
    love.graphics.setColor(0.07, 0.07, 0.12, 0.97)
    love.graphics.rectangle('fill', bx, by, w, h, 4)
    love.graphics.setColor(0.45, 0.45, 0.65, 1)
    love.graphics.rectangle('line', bx, by, w, h, 4)

    -- title
    love.graphics.setFont(gFonts['zelda-small'])
    love.graphics.setColor(1, 0.85, 0.25, 1)
    love.graphics.printf(beat.title, bx, by + pad, w, 'center')

    -- body
    love.graphics.setFont(gFonts['small'])
    love.graphics.setColor(0.88, 0.88, 0.88, 1)
    love.graphics.printf(beat.text, bx + pad, by + 32, w - pad * 2, 'left')

    -- prompt
    love.graphics.setColor(0.4, 0.4, 0.5, 1)
    love.graphics.printf('Press ENTER or click to continue', bx, by + h - 12, w, 'center')

    love.graphics.setColor(1, 1, 1, 1)
end

