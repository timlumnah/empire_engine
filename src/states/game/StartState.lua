--[[
    Empire Engine
    Based on CS50 2D Coursework

    -- StartState --

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    Title screen and opening narrative. Displays the main menu,
    runs the intro plot dialogue, and transitions into PlayState
    when the player confirms they are ready to begin.
]]

StartState = Class{__includes = BaseState}

-- ================== claude_changes_2026-05-25-1228 ==================
-- key pools for name entry text input
local NAME_MAX = 14
local NAME_ALPHA_KEYS = {}
for i = 1, 26 do NAME_ALPHA_KEYS[i] = string.char(96 + i) end
local NAME_NUM_KEYS = {'0','1','2','3','4','5','6','7','8','9'}

-- slot picker layout for the Continue flow
local SSLOT_W = 260
local SSLOT_H = 172
local SSLOT_X = math.floor((VIRTUAL_WIDTH  - SSLOT_W) / 2)
local SSLOT_Y = math.floor((VIRTUAL_HEIGHT - SSLOT_H) / 2)
local SSLOT_ENTRY_H = 34
local SSLOT_LIST_Y  = SSLOT_Y + 44
local SSLOT_PAD     = 10

local function fmt_slot_cash(n)
    if not n then return '$0' end
    local abs = tostring(math.floor(math.abs(n)))
    local c = abs:reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')
    return (n < 0 and '-$' or '$') .. c
end

-- nav helper: skip empty slots when loading
local function nextStartSlot(slots, cur, dir)
    local n = #slots
    local i = cur
    for _ = 1, n do
        i = ((i - 1 + dir) % n) + 1
        if not slots[i].empty then return i end
    end
    return cur
end
-- ====================================================================

local MENU_ITEMS = {
    { label = 'New Game'    },
    { label = 'Continue',   disabled = true },
    { label = 'How to Play' },
    { label = 'Quit'        },
}

local function next_enabled(cur, dir)
    local n = #MENU_ITEMS
    local i = cur
    for _ = 1, n do
        i = ((i - 1 + dir) % n) + 1
        if not MENU_ITEMS[i].disabled then return i end
    end
    return cur
end

function StartState:init()
    self.showHelp = false
    self.sel = 1
    -- ================== claude_changes_2026-05-25-1228 ==================
    self.mode = 'menu'      -- 'menu', 'name_entry', or 'load_slots'
    self.nameInput = ''
    self.slotList = nil
    self.slotSel  = 1
    -- ====================================================================
    MENU_ITEMS[2].disabled = not SaveLoad.hasSave()
    for _, key in ipairs({'biome2', 'biome3'}) do
        if gSounds[key] then gSounds[key]:stop() end
    end
    if gSounds['biome1'] and not gSounds['biome1']:isPlaying() then
        gSounds['biome1']:play()
    end
end

function StartState:update(dt)
    if self.showHelp then
        if love.keyboard.wasPressed('escape') or love.keyboard.wasPressed('h') then
            self.showHelp = false
        end
        return
    end

    -- ================== claude_changes_2026-05-25-1228 ==================
    if self.mode == 'load_slots' then
        local slots = self.slotList or {}
        if love.keyboard.wasPressed('up') then
            self.slotSel = nextStartSlot(slots, self.slotSel, -1)
        elseif love.keyboard.wasPressed('down') then
            self.slotSel = nextStartSlot(slots, self.slotSel, 1)
        elseif love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter') then
            local slot = slots[self.slotSel]
            if slot and not slot.empty then
                local data = slot.legacyLoad and SaveLoad.loadLegacy() or SaveLoad.load(slot.id)
                if data then
                    gStateMachine:change('play', { saveData = data })
                end
            end
        elseif love.keyboard.wasPressed('escape') then
            self.mode = 'menu'
        end
        return
    end

    if self.mode == 'name_entry' then
        for _, k in ipairs(NAME_ALPHA_KEYS) do
            if love.keyboard.wasPressed(k) and #self.nameInput < NAME_MAX then
                self.nameInput = self.nameInput .. string.upper(k)
            end
        end
        for _, k in ipairs(NAME_NUM_KEYS) do
            if love.keyboard.wasPressed(k) and #self.nameInput < NAME_MAX then
                self.nameInput = self.nameInput .. k
            end
        end
        if love.keyboard.wasPressed('space') and #self.nameInput < NAME_MAX then
            self.nameInput = self.nameInput .. ' '
        end
        if love.keyboard.wasPressed('backspace') and #self.nameInput > 0 then
            self.nameInput = self.nameInput:sub(1, -2)
        end
        if (love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter'))
            and #self.nameInput > 0 then
            gStateMachine:change('play', { playerName = self.nameInput, isNewGame = true })
        end
        if love.keyboard.wasPressed('escape') then
            self.mode = 'menu'
            self.nameInput = ''
        end
        return
    end
    -- ====================================================================

    if love.keyboard.wasPressed('up') then
        self.sel = next_enabled(self.sel, -1)
    elseif love.keyboard.wasPressed('down') then
        self.sel = next_enabled(self.sel, 1)
    elseif love.keyboard.wasPressed('escape') then
        love.event.quit()
    elseif love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
        self:selectItem()
    end
end

function StartState:selectItem()
    local item = MENU_ITEMS[self.sel]
    if item.disabled then return end

    if item.label == 'New Game' then
        -- ================== claude_changes_2026-05-25-1228 ==================
        self.mode = 'name_entry'
        self.nameInput = ''
        -- ====================================================================
    elseif item.label == 'Continue' then
        -- ================== claude_changes_2026-05-25-1228 ==================
        self.slotList = SaveLoad.listSlots()
        self.slotSel  = 1
        for i, s in ipairs(self.slotList) do
            if not s.empty then self.slotSel = i; break end
        end
        self.mode = 'load_slots'
        -- ====================================================================
    elseif item.label == 'How to Play' then
        self.showHelp = true
    elseif item.label == 'Quit' then
        love.event.quit()
    end
end

function StartState:render()
    love.graphics.draw(gTextures['background'], 0, 0, 0,
        VIRTUAL_WIDTH / gTextures['background']:getWidth(),
        VIRTUAL_HEIGHT / gTextures['background']:getHeight())

    love.graphics.setFont(gFonts['zelda'])
    love.graphics.setColor(34/255, 34/255, 34/255, 1)
-- ================== claude_changes_2026-05-23-2140 ==================
    love.graphics.printf('Empire Engine', 2, VIRTUAL_HEIGHT / 2 - 70, VIRTUAL_WIDTH, 'center')

    love.graphics.setColor(175/255, 53/255, 42/255, 1)
    love.graphics.printf('Empire Engine', 0, VIRTUAL_HEIGHT / 2 - 72, VIRTUAL_WIDTH, 'center')
-- ====================================================================

    -- ================== claude_changes_2026-05-25-1228 ==================
    if self.mode == 'name_entry' then
        -- name entry panel overlays the menu area
        local bw, bh = 220, 84
        local bx = math.floor((VIRTUAL_WIDTH - bw) / 2)
        local by = VIRTUAL_HEIGHT / 2 - 16
        love.graphics.setColor(0.07, 0.07, 0.12, 0.97)
        love.graphics.rectangle('fill', bx, by, bw, bh, 4)
        love.graphics.setColor(0.45, 0.45, 0.65, 1)
        love.graphics.rectangle('line', bx, by, bw, bh, 4)

        love.graphics.setFont(gFonts['zelda-small'])
        love.graphics.setColor(1, 0.84, 0, 1)
        love.graphics.printf('ENTER YOUR NAME', bx, by + 7, bw, 'center')

        love.graphics.setFont(gFonts['small'])
        local cursor = math.floor(love.timer.getTime() * 2) % 2 == 0 and '_' or ''
        if self.nameInput == '' then
            love.graphics.setColor(0.35, 0.35, 0.35, 1)
            love.graphics.printf('type name, press enter', bx, by + 38, bw, 'center')
        else
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf(self.nameInput .. cursor, bx, by + 38, bw, 'center')
        end

        love.graphics.setColor(0.35, 0.35, 0.35, 1)
        love.graphics.printf('[ENTER] start   [ESC] back', bx, by + 66, bw, 'center')
        love.graphics.setColor(1, 1, 1, 1)
    elseif self.mode == 'load_slots' then
        self:renderLoadSlots()
    -- ====================================================================
    else
    -- ================== claude_changes_2026-05-25-1228 ==================

    -- menu
    love.graphics.setFont(gFonts['zelda-small'])
    local menu_top = VIRTUAL_HEIGHT / 2 - 10
    local item_h = 22
    for i, item in ipairs(MENU_ITEMS) do
        local y = menu_top + (i - 1) * item_h
        if item.disabled then
            love.graphics.setColor(0.38, 0.38, 0.38, 1)
        elseif i == self.sel then
            love.graphics.setColor(1, 0.95, 0.55, 1)
        else
            love.graphics.setColor(0.9, 0.9, 0.9, 1)
        end
        local prefix = (i == self.sel and not item.disabled) and '> ' or '  '
        love.graphics.printf(prefix .. item.label, 0, y, VIRTUAL_WIDTH, 'center')
    end

    -- ================== claude_changes_2026-05-25-1228 ==================
    end
    -- ====================================================================

    love.graphics.setColor(1, 1, 1, 1)

    if self.showHelp then
        renderHelpPopup()
    end
end

-- ================== claude_changes_2026-05-25-1228 ==================
function StartState:renderLoadSlots()
    local slots = self.slotList or {}
    local ix = SSLOT_X + SSLOT_PAD
    local iw = SSLOT_W - SSLOT_PAD * 2

    -- dim background
    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle('fill', 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)

    -- panel
    love.graphics.setColor(0.75, 0.75, 0.75, 0.9)
    love.graphics.rectangle('fill', SSLOT_X, SSLOT_Y, SSLOT_W, SSLOT_H, 3)
    love.graphics.setColor(0.04, 0.04, 0.06, 0.96)
    love.graphics.rectangle('fill', SSLOT_X + 2, SSLOT_Y + 2, SSLOT_W - 4, SSLOT_H - 4, 3)

    -- title
    love.graphics.setFont(gFonts['gothic-medium'])
    love.graphics.setColor(1, 0.84, 0, 1)
    love.graphics.printf('LOAD GAME', ix, SSLOT_Y + 6, iw, 'center')

    love.graphics.setColor(1, 1, 1, 0.2)
    love.graphics.line(ix, SSLOT_Y + 28, SSLOT_X + SSLOT_W - SSLOT_PAD, SSLOT_Y + 28)

    -- slot rows
    love.graphics.setFont(gFonts['small'])
    for i, slot in ipairs(slots) do
        local ey  = SSLOT_LIST_Y + (i - 1) * SSLOT_ENTRY_H
        local sel = (i == self.slotSel)

        if sel and not slot.empty then
            love.graphics.setColor(1, 1, 1, 0.06)
            love.graphics.rectangle('fill', SSLOT_X + 3, ey, SSLOT_W - 6, SSLOT_ENTRY_H - 2)
        end

        love.graphics.setColor(1, 0.84, 0, 1)
        love.graphics.print((sel and not slot.empty) and '>' or ' ', ix, ey + 4)

        if slot.empty then
            love.graphics.setColor(0.38, 0.38, 0.38, 1)
            love.graphics.print(slot.label, ix + 10, ey + 4)
            love.graphics.setColor(0.28, 0.28, 0.28, 1)
            love.graphics.print('-- EMPTY --', ix + 10, ey + 16)
        else
            if sel then love.graphics.setColor(1, 0.95, 0.55, 1)
            else love.graphics.setColor(0.9, 0.9, 0.9, 1) end
            love.graphics.print(slot.label, ix + 10, ey + 4)
            love.graphics.setColor(0.55, 0.75, 0.55, 1)
            love.graphics.print(
                string.format('%s  %s', slot.playerName or '?', fmt_slot_cash(slot.cash)),
                ix + 10, ey + 16
            )
            love.graphics.setColor(0.4, 0.4, 0.4, 1)
            love.graphics.print(slot.savedAt or '', ix + 160, ey + 16)
        end

        love.graphics.setColor(1, 1, 1, 0.08)
        love.graphics.line(ix, ey + SSLOT_ENTRY_H - 1, SSLOT_X + SSLOT_W - SSLOT_PAD, ey + SSLOT_ENTRY_H - 1)
    end

    love.graphics.setColor(0.35, 0.35, 0.35, 1)
    love.graphics.printf('[ENTER] load   [ESC] back', ix, SSLOT_Y + SSLOT_H - 11, iw, 'center')
    love.graphics.setColor(1, 1, 1, 1)
end
-- ====================================================================
