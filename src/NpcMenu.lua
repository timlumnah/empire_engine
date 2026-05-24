--[[
    Empire Engine
    Based on CS50 2D Coursework

    NpcMenu.lua

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    NPC interaction overlay shown when the player presses Enter near
    a friendly NPC. Offers options to shmooze, buy a business, or
    open the loan menu depedning on the NPC type.
]]


-- NPC interaction overlay, shown when player presses enter near a friendly NPC
-- two pages: landing with two options, and the shmooze text input screen
-- banker NPCs show LOAN on option 1 instead of BUSINESS
NpcMenu = Class{}

-- panel dimensions, centered on the virtual screen
local BOX_W = 220
local BOX_H = 150
local BOX_X = math.floor((VIRTUAL_WIDTH - BOX_W) / 2)
local BOX_Y = math.floor((VIRTUAL_HEIGHT - BOX_H) / 2)
local PAD = 10

local MAX_AFFINITY = 3  -- how many affinity points an NPC needs to unlock the door
local MAX_INPUT = 40    -- max characters the player can type in the shmooze field

-- button layout for the two landing page options
local BTN_H = 36
local BTN_W = BOX_W - PAD * 2 - 4
local BTN_X = BOX_X + PAD + 2
local BTN1_Y = BOX_Y + 28
local BTN2_Y = BTN1_Y + BTN_H + 8

-- all lowercase letter keys polled each frame during shmooze text input
local ALPHA_KEYS = {
    'a','b','c','d','e','f','g','h','i','j','k','l','m',
    'n','o','p','q','r','s','t','u','v','w','x','y','z',
}

-- two button color themes: green for buisness option, purple for shmooze option
local BTN_COLORS = {
    { bg = {0.1, 0.28, 0.12}, border = {0.3, 0.75, 0.35}, label = {0.4, 1, 0.5}  },
    { bg = {0.22, 0.08, 0.28}, border = {0.65, 0.3, 0.75}, label = {0.9, 0.55, 1} },
}

local function set(r, g, b, a) love.graphics.setColor(r, g, b, a or 1) end

local function render_panel()
    set(0.7, 0.75, 0.7, 0.9)
    love.graphics.rectangle('fill', BOX_X, BOX_Y, BOX_W, BOX_H, 3)
    set(0.04, 0.06, 0.04, 0.96)
    love.graphics.rectangle('fill', BOX_X + 2, BOX_Y + 2, BOX_W - 4, BOX_H - 4, 3)
end


-- sets all state fields to safe defaults, called once at startup
function NpcMenu:init()
    self.active = false
    self.npc = nil                  -- reference to the NPC this menu is open for
    self.isBanker = false           -- true if the NPC is a banker, changes button labels
    self.page = 'landing'           -- current page, either "landing" or "shmooze"
    self.landingSelected = 1        -- which of the two landing buttons is highlighted
    self.textInput = ''             -- what the player has typed in the shmooze field
    self.feedbackMsg = ''           -- message shown after shmooze submit attempt
    self.feedbackTimer = 0          -- how many seconds to show the feedback message
    self.successPending = false     -- true when max affinity reached, waits for message to expire
    self.wantsBusinessMenu = false  -- set true when player picks option 1 on a regular NPC
    self.wantsLoanMenu = false      -- set true when player picks option 1 on a banker NPC
end

-- opens the menu for a specific NPC, isBanker changes what option 1 does
-- PlayState reads wantsBusinessMenu and wantsLoanMenu after close to open the right menu
function NpcMenu:open(npc, isBanker)
    self.active = true
    self.npc = npc
    self.isBanker = isBanker or false
    self.page = 'landing'
    self.landingSelected = 1
    self.textInput = ''
    self.feedbackMsg = ''
    self.feedbackTimer = 0
    self.successPending = false
    self.wantsBusinessMenu = false
    self.wantsLoanMenu = false
end

-- deactivates the menu and clears the NPC reference
function NpcMenu:close()
    self.active = false
    self.npc = nil
end


-- routes update to the current page handler, ticks the feedback timer
function NpcMenu:update(dt)
    if not self.active then return end
    if self.feedbackTimer > 0 then self.feedbackTimer = self.feedbackTimer - dt end

    -- after a max affinity shmooze, wait for the feedback message to finish before closing
    if self.successPending and self.feedbackTimer <= 0 then
        self:close()
        return
    end

    if self.page == 'landing' then
        self:updateLanding()
    elseif self.page == 'shmooze' then
        self:updateShmooze()
    end
end

-- handles navigation and selection on the landing page
-- option 1 either opens buisness menu or loan menu depending on NPC type
-- option 2 always goes to the shmooze page
function NpcMenu:updateLanding()
    if love.keyboard.wasPressed('up') then
        self.landingSelected = self.landingSelected > 1 and self.landingSelected - 1 or 2
    elseif love.keyboard.wasPressed('down') then
        self.landingSelected = self.landingSelected < 2 and self.landingSelected + 1 or 1
    elseif love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter') then
        if self.landingSelected == 1 then
            -- option 1 differs based on NPC type, banker opens loans, others open buisness list
            if self.isBanker then
                self.wantsLoanMenu = true   -- PlayState checks this after we close
            else
                self.wantsBusinessMenu = true
            end
            self:close()
        else
            -- option 2 always takes the player to the shmooze text input screen
            self.page = 'shmooze'
            self.textInput = ''
            self.feedbackMsg = ''
            self.feedbackTimer = 0
        end
    elseif love.keyboard.wasPressed('escape') then
        self:close()
    end
end

-- handles text input on the shmooze page
-- polls each letter key every frame and appends to the input string
-- locked out while successPending is true so the player cant type after a win
function NpcMenu:updateShmooze()
    if self.successPending then return end -- dont accept input while waiting for feedback to expire

    -- poll each letter key and append to the input string if under the length limit
    for _, key in ipairs(ALPHA_KEYS) do
        if love.keyboard.wasPressed(key) and #self.textInput < MAX_INPUT then
            self.textInput = self.textInput .. key
        end
    end

    -- space key adds a space character, needed for multi word compliments
    if love.keyboard.wasPressed('space') and #self.textInput < MAX_INPUT then
        self.textInput = self.textInput .. ' '
    end

    -- backspace removes the last character from the input string
    if love.keyboard.wasPressed('backspace') then
        self.textInput = self.textInput:sub(1, -2)
    end

    if love.keyboard.wasPressed('return') then
        self:submitShmooze() -- check the input against the keyword list
    end

    if love.keyboard.wasPressed('escape') then
        -- go back to landing without submitting, clear the input field
        self.page = 'landing'
        self.textInput = ''
        self.feedbackMsg = ''
    end
end

-- checks the typed text against SHMOOZE_DEFS.keywords and updates NPC affinity
-- any keyword appearing as a substring in the input counts as a match
function NpcMenu:submitShmooze()
    -- strip leading and trailing whitespace before checking
    local trimmed = self.textInput:match('^%s*(.-)%s*$')
    if #trimmed == 0 then return end -- nothing to check

    -- lowercase the input so matching is case insensitive
    local input = trimmed:lower()
    local matched = false

    -- scan all keywords and stop as soon as one matches
    for _, keyword in ipairs(SHMOOZE_DEFS.keywords) do
        if input:find(keyword, 1, true) then -- plain text search, no pattern matching
            matched = true
            break
        end
    end

    self.textInput = '' -- clear input after every submit attempt

    if matched then
        -- keyword found, increment affinity up to MAX_AFFINITY
        self.npc.affinity = math.min((self.npc.affinity or 0) + 1, MAX_AFFINITY)
        if self.npc.affinity >= MAX_AFFINITY then
            -- max affinity reached, signal PlayState to run the door walk animation
            self.npc.walkToDoor = true
            self.feedbackMsg = 'heading to the door...'
            self.feedbackTimer = 1.5
            self.successPending = true -- locks input until message expires then closes
        else
            -- not max yet, show progress and let player try again
            self.feedbackMsg = 'they like that! (' .. self.npc.affinity .. '/' .. MAX_AFFINITY .. ')'
            self.feedbackTimer = 1.5
        end
    else
        -- no keyword found, NPC is unimpressed, no affinity change
        self.feedbackMsg = 'they look unimpressed...'
        self.feedbackTimer = 1.5
    end
end


function NpcMenu:mousepressed(x, y, button)
    if not self.active or button ~= 1 then return end
    if self.page ~= 'landing' then return end

    local btn_ys = { BTN1_Y, BTN2_Y }
    for i, by in ipairs(btn_ys) do
        if x >= BTN_X and x <= BTN_X + BTN_W and y >= by and y <= by + BTN_H then
            self.landingSelected = i
            if i == 1 then
                if self.isBanker then
                    self.wantsLoanMenu = true
                else
                    self.wantsBusinessMenu = true
                end
                self:close()
            else
                self.page = 'shmooze'
                self.textInput = ''
                self.feedbackMsg = ''
                self.feedbackTimer = 0
            end
            return
        end
    end
end


function NpcMenu:render()
    if not self.active then return end
    if self.page == 'landing' then
        self:renderLanding()
    elseif self.page == 'shmooze' then
        self:renderShmooze()
    end
end

function NpcMenu:renderLanding()
    render_panel()

    local ix = BOX_X + PAD
    local iw = BOX_W - PAD * 2

    love.graphics.setFont(gFonts['gothic-medium'])
    set(0.4, 1, 0.55, 1)
    local title = self.isBanker and 'BANKER' or string.upper(self.npc.displayName or 'NPC')
    love.graphics.printf(title, ix, BOX_Y + 8, iw, 'center')

    set(1, 1, 1, 0.15)
    love.graphics.line(ix, BOX_Y + 22, BOX_X + BOX_W - PAD, BOX_Y + 22)

    local opt1Label = self.isBanker and 'LOAN' or 'BUSINESS'
    local opt1Desc = self.isBanker and 'discuss financing' or 'browse businesses'
    local opts = { opt1Label, 'SHMOOZE' }
    local descs = { opt1Desc, 'say something nice' }
    local btn_ys = { BTN1_Y, BTN2_Y }

    for i = 1, 2 do
        local by = btn_ys[i]
        local sel = i == self.landingSelected
        local col = BTN_COLORS[i]
        local r, g, b = col.bg[1], col.bg[2], col.bg[3]
        set(sel and r * 1.6 or r, sel and g * 1.6 or g, sel and b * 1.6 or b, 1)
        love.graphics.rectangle('fill', BTN_X, by, BTN_W, BTN_H, 4)
        set(col.border[1], col.border[2], col.border[3], sel and 1 or 0.5)
        love.graphics.rectangle('line', BTN_X, by, BTN_W, BTN_H, 4)
        love.graphics.setFont(gFonts['gothic-medium'])
        set(col.label[1], col.label[2], col.label[3], 1)
        love.graphics.printf(opts[i], BTN_X, by + 6, BTN_W, 'center')
        love.graphics.setFont(gFonts['small'])
        set(0.55, 0.55, 0.55, 1)
        love.graphics.printf(descs[i], BTN_X, by + 22, BTN_W, 'center')
    end

    set(0.3, 0.3, 0.3, 1)
    love.graphics.setFont(gFonts['small'])
    love.graphics.printf('[UP/DN] select  [ENTER] open  [ESC] close', ix, BOX_Y + BOX_H - 12, iw, 'center')

    set(1, 1, 1, 1)
end

function NpcMenu:renderShmooze()
    render_panel()

    local ix = BOX_X + PAD
    local iw = BOX_W - PAD * 2
    local aff = self.npc.affinity or 0

    love.graphics.setFont(gFonts['gothic-medium'])
    set(0.9, 0.55, 1, 1)
    local title = self.isBanker and 'BANKER' or string.upper(self.npc.displayName or 'NPC')
    love.graphics.printf('SHMOOZE: ' .. title, ix, BOX_Y + 8, iw, 'center')

    set(1, 1, 1, 0.15)
    love.graphics.line(ix, BOX_Y + 22, BOX_X + BOX_W - PAD, BOX_Y + 22)

    -- affinity bar
    local barW = iw
    local barH = 5
    local barX = ix
    local barY = BOX_Y + 28
    set(0.15, 0.15, 0.15, 0.9)
    love.graphics.rectangle('fill', barX, barY, barW, barH, 2)
    if aff > 0 then
        set(0.25, 0.9, 0.45, 1)
        love.graphics.rectangle('fill', barX, barY, math.floor(barW * aff / MAX_AFFINITY), barH, 2)
    end

    love.graphics.setFont(gFonts['small'])
    set(0.5, 0.5, 0.5, 1)
    love.graphics.printf(aff .. '/' .. MAX_AFFINITY .. ' affinity', ix, BOX_Y + 36, iw, 'center')

    -- input hint
    set(0.4, 0.4, 0.4, 1)
    love.graphics.print('say something nice...', ix, BOX_Y + 50)

    -- input field
    local fieldY = BOX_Y + 60
    local fieldH = 16
    set(0.06, 0.08, 0.06, 1)
    love.graphics.rectangle('fill', ix, fieldY, iw, fieldH, 3)
    set(0.35, 0.65, 0.35, 1)
    love.graphics.rectangle('line', ix, fieldY, iw, fieldH, 3)

    local cursor = math.floor(love.timer.getTime() * 2) % 2 == 0 and '_' or ''
    set(1, 1, 1, 1)
    love.graphics.printf(self.textInput .. cursor, ix + 4, fieldY + 4, iw - 8, 'left')

    -- feedback
    if self.feedbackTimer > 0 then
        if self.successPending then
            set(0.3, 1, 0.4, 1)
        elseif self.feedbackMsg:find('unimpressed') then
            set(1, 0.4, 0.4, 1)
        else
            set(0.7, 1, 0.7, 1)
        end
        love.graphics.printf(self.feedbackMsg, ix, BOX_Y + 80, iw, 'center')
    end

    set(0.3, 0.3, 0.3, 1)
    love.graphics.printf('[ENTER] submit  [ESC] back', ix, BOX_Y + BOX_H - 12, iw, 'center')

    set(1, 1, 1, 1)
end

return NpcMenu
