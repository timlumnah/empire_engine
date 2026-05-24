--[[
    Empire Engine
    Based on CS50 2D Coursework

    PoliceSystem.lua

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    Self-contained police response triggered when a competitor is killed.
    Manages siren audio, light-bar flash, red arrest spots, and bust countdown.
    Returns 'expired' or 'arrested' from update() so PlayState can react.
]]

PoliceSystem = Class{}

function PoliceSystem:init(onExpire)
    self.elapsed = 0
    self.lightTimer = 0
    self.lightRed = true
    self.spotX = nil
    self.spotY = nil
    self.spotTimer = 0
    self.bustPending = false
    self.bustTimer = 0
    self.onExpire = onExpire

    self.siren = gSounds['police-siren']:clone()
    self.siren:setLooping(true)
    self.siren:play()
end

function PoliceSystem:update(dt, player)
    self.elapsed = self.elapsed + dt

    -- flash light bar
    self.lightTimer = self.lightTimer + dt
    if self.lightTimer >= 0.15 then
        self.lightTimer = 0
        self.lightRed = not self.lightRed
    end

    -- red spot lifecycle
    if self.spotX then
        self.spotTimer = self.spotTimer + dt

        if self.bustPending then
            -- hold briefly so player sees the spot before game over
            self.bustTimer = self.bustTimer - dt
            if self.bustTimer <= 0 then
                self.siren:stop()
                gStateMachine:change('game-over', { reason = 'arrested' })
                return 'arrested'
            end
        else
            local px = player.x + player.width / 2
            local py = player.y + player.height / 2
            local dist = math.sqrt((px - self.spotX)^2 + (py - self.spotY)^2)
            if dist < RED_SPOT_RADIUS then
                self.bustPending = true
                self.bustTimer = 0.75
            elseif self.spotTimer >= RED_SPOT_LIFETIME then
                self.spotX = nil
                self.spotTimer = 0
            end
        end
    else
        self.spotTimer = self.spotTimer + dt
        if self.spotTimer >= RED_SPOT_GAP then
            self.spotTimer = 0
            self.spotX = math.random(
                math.floor(MAP_RENDER_OFFSET_X + TILE_SIZE * 1.5),
                math.floor(VIRTUAL_WIDTH - TILE_SIZE * 2.5)
            )
            self.spotY = math.random(
                math.floor(MAP_RENDER_OFFSET_Y + TILE_SIZE * 1.5),
                math.floor(VIRTUAL_HEIGHT - TILE_SIZE * 2.5)
            )
        end
    end

    if self.elapsed >= POLICE_DURATION then
        self.siren:stop()
        if self.onExpire then self.onExpire() end
        return 'expired'
    end
end

function PoliceSystem:renderOverlay(player)
    -- dark fog with lit circle around player
    local px = math.floor(player.x + player.width / 2)
    local py = math.floor(player.y + player.height / 2)

    love.graphics.stencil(function()
        love.graphics.circle('fill', px, py, POLICE_VISION_RADIUS)
    end, 'replace', 1)
    love.graphics.setStencilTest('notequal', 1)
    love.graphics.setColor(0, 0, 0, 0.97)
    love.graphics.rectangle('fill', 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
    love.graphics.setStencilTest()

    if self.spotX then
        local fade
        if self.bustPending then
            fade = 1
        elseif self.spotTimer < 0.12 then
            fade = self.spotTimer / 0.12
        elseif self.spotTimer > 0.85 then
            fade = (RED_SPOT_LIFETIME - self.spotTimer) / (RED_SPOT_LIFETIME - 0.85)
        else
            fade = 1
        end
        love.graphics.setColor(1, 0.05, 0.05, 0.78 * fade)
        love.graphics.circle('fill', self.spotX, self.spotY, RED_SPOT_RADIUS)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function PoliceSystem:renderLightBar(helpBtn)
    -- flashing red/blue rectangles right of the ? button
    local bx = helpBtn.x + helpBtn.w + 4
    local by = helpBtn.y + 3
    local w, h = 9, 5
    love.graphics.setColor(1, 0.1, 0.1, self.lightRed and 1 or 0.18)
    love.graphics.rectangle('fill', bx, by, w, h, 1)
    love.graphics.setColor(0.15, 0.35, 1, self.lightRed and 0.18 or 1)
    love.graphics.rectangle('fill', bx + w + 2, by, w, h, 1)
    love.graphics.setColor(1, 1, 1, 1)
end
