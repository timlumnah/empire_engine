--[[
    Empire Engine
    Based on CS50 2D Coursework
    PauseMenu

    Author: Tim Lumnah
    github.com/timlumnah/empire_engine

    Pause overlay. Views: main, sleep sub-menu, save slot picker,
    load slot picker.
    PlayState reads saveRequested / loadRequested / sleepRequested flags.
]]

PauseMenu = Class{}

-- main panel layout
local BOX_W = 160
-- ================== claude_changes_2026-05-25-1228 ==================
local BOX_H = 180  -- expanded from 148 to fit 8 main menu items (added Music/SFX volume)
-- ====================================================================
local BOX_X = math.floor((384 - BOX_W) / 2)
local BOX_Y = math.floor((216 - BOX_H) / 2)
local PAD = 10
local ITEM_H = 16

-- slot picker panel layout
-- ================== claude_changes_2026-05-25-1228 ==================
local SLOT_W = 260
local SLOT_H = 172
local SLOT_X = math.floor((384 - SLOT_W) / 2)
local SLOT_Y = math.floor((216 - SLOT_H) / 2)
local SLOT_ENTRY_H = 34   -- pixels per slot row
local SLOT_LIST_Y = SLOT_Y + 44
-- ====================================================================

-- confirm popup layout (shared)
local CONF_W = 168
local CONF_H = 66
local CONF_X = math.floor((384 - CONF_W) / 2)
local CONF_Y = math.floor((216 - CONF_H) / 2)
local YES_BTN = { x = CONF_X + 12,  y = CONF_Y + 44, w = 56, h = 14 }
local NO_BTN  = { x = CONF_X + 100, y = CONF_Y + 44, w = 56, h = 14 }

local SLEEP_ITEMS = {
    { label = '1 Week',   secs = math.floor(SECONDS_PER_MONTH / 4) },
    { label = '1 Month',  secs = SECONDS_PER_MONTH },
    { label = '3 Months', secs = SECONDS_PER_MONTH * 3 },
    { label = '1 Year',   secs = SECONDS_PER_MONTH * 12 },
    { label = 'Back' },
}

local function set(r, g, b, a) love.graphics.setColor(r, g, b, a or 1) end
local function hit(rect, x, y)
    return x >= rect.x and x <= rect.x + rect.w
       and y >= rect.y and y <= rect.y + rect.h
end

-- ================== claude_changes_2026-05-25-1228 ==================
-- source key categories for independent volume control
local MUSIC_KEYS = {'biome1', 'biome2', 'biome3', 'minigame-music'}
local SFX_KEYS   = {'sword', 'hit-enemy', 'door', 'heart-consume', 'pot-shatter',
    'boomerang', 'scream', 'walk', 'police-siren', 'door-open-1', 'door-open-2',
    'game-over', 'mad-npc', 'minigame-win', 'package-open', 'win', 'warning'}

local function applyMusicVol(vol)
    for _, k in ipairs(MUSIC_KEYS) do
        if gSounds[k] then gSounds[k]:setVolume(vol) end
    end
end
local function applySfxVol(vol)
    for _, k in ipairs(SFX_KEYS) do
        if gSounds[k] then gSounds[k]:setVolume(vol) end
    end
end
-- ====================================================================

local function render_confirm(msg)
    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle('fill', 0, 0, 384, 216)
    love.graphics.setColor(0.08, 0.08, 0.13, 0.97)
    love.graphics.rectangle('fill', CONF_X, CONF_Y, CONF_W, CONF_H, 4)
    love.graphics.setColor(0.45, 0.45, 0.6, 1)
    love.graphics.rectangle('line', CONF_X, CONF_Y, CONF_W, CONF_H, 4)
    love.graphics.setFont(gFonts['small'])
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(msg, CONF_X + 8, CONF_Y + 10, CONF_W - 16, 'center')
    love.graphics.setColor(0.15, 0.45, 0.15, 1)
    love.graphics.rectangle('fill', YES_BTN.x, YES_BTN.y, YES_BTN.w, YES_BTN.h, 3)
    love.graphics.setColor(0.4, 1, 0.4, 1)
    love.graphics.rectangle('line', YES_BTN.x, YES_BTN.y, YES_BTN.w, YES_BTN.h, 3)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('YES', YES_BTN.x, YES_BTN.y + 3, YES_BTN.w, 'center')
    love.graphics.setColor(0.45, 0.1, 0.1, 1)
    love.graphics.rectangle('fill', NO_BTN.x, NO_BTN.y, NO_BTN.w, NO_BTN.h, 3)
    love.graphics.setColor(1, 0.35, 0.35, 1)
    love.graphics.rectangle('line', NO_BTN.x, NO_BTN.y, NO_BTN.w, NO_BTN.h, 3)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('NO', NO_BTN.x, NO_BTN.y + 3, NO_BTN.w, 'center')
    love.graphics.setColor(1, 1, 1, 1)
end

-- ================== claude_changes_2026-05-25-1228 ==================
-- formats a cash value with commas and sign for the slot picker
local function fmt_slot_cash(n)
    if not n then return '$0' end
    local abs = tostring(math.floor(math.abs(n)))
    local c = abs:reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')
    return (n < 0 and '-$' or '$') .. c
end
-- ====================================================================

function PauseMenu:init()
    self.active = false
    self.mode = 'main'
    self.mainSel = 1
    self.sleepSel = 1
    self.sleepRequested = nil
    self.saveRequested = nil
    self.loadRequested = nil
    self.confirming = false
    self.confirmMsg = ''
    self.confirmAction = nil
    -- ================== claude_changes_2026-05-25-1228 ==================
    self.gameSpeed = 1          -- 1, 2, or 4; PlayState reads this each frame
    self.slotSel = 1            -- selected row in save/load slot picker
    self.slotList = nil         -- cached from SaveLoad.listSlots()
    self.musicVol = 1.0         -- music source volume (0.0 - 1.0)
    self.sfxVol   = 1.0         -- sfx source volume (0.0 - 1.0)
    -- ====================================================================
end

function PauseMenu:open()
    self.active = true
    self.mode = 'main'
    self.mainSel = 1
    self.sleepSel = 1
    self.sleepRequested = nil
    self.saveRequested = nil
    self.loadRequested = nil
    self.confirming = false
    self.confirmMsg = ''
    self.confirmAction = nil
end

function PauseMenu:close()
    self.active = false
end

function PauseMenu:showConfirm(msg, action)
    self.confirming = true
    self.confirmMsg = msg
    self.confirmAction = action
end

function PauseMenu:resolveConfirm(yes)
    if yes and self.confirmAction then self.confirmAction() end
    self.confirming = false
    self.confirmMsg = ''
    self.confirmAction = nil
end

local function next_enabled(items, cur, dir)
    local n = #items
    local i = cur
    for _ = 1, n do
        i = ((i - 1 + dir) % n) + 1
        if not items[i].disabled then return i end
    end
    return cur
end

-- ================== claude_changes_2026-05-25-1228 ==================
-- returns the 3 manual save slots (1-3); excludes autosave from manual save picker
local function manualSlots(slotList)
    local out = {}
    for _, s in ipairs(slotList) do
        if type(s.id) == 'number' then out[#out+1] = s end
    end
    return out
end

-- nav for slot pickers: skip empty slots when loading
local function nextSlot(slots, cur, dir, skipEmpty)
    local n = #slots
    local i = cur
    for _ = 1, n do
        i = ((i - 1 + dir) % n) + 1
        if not skipEmpty or not slots[i].empty then return i end
    end
    return cur
end
-- ====================================================================

function PauseMenu:update(dt)
    if not self.active then return end

    -- ================== claude_changes_2026-05-25-1228 ==================
    -- check any save exists to enable Load option (checked each frame)
    -- main menu items are rebuilt inline in render; disabled state set here
    if self.mode == 'main' then
        -- confirm popup eats all input
        if self.confirming then
            if love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter')
               or love.keyboard.wasPressed('y') then
                self:resolveConfirm(true)
            elseif love.keyboard.wasPressed('escape') or love.keyboard.wasPressed('n') then
                self:resolveConfirm(false)
            end
            return
        end

        local mainItems = self:buildMainItems()
        if love.keyboard.wasPressed('up') then
            self.mainSel = next_enabled(mainItems, self.mainSel, -1)
        elseif love.keyboard.wasPressed('down') then
            self.mainSel = next_enabled(mainItems, self.mainSel, 1)
        elseif love.keyboard.wasPressed('left') then
            self:adjustVolume(mainItems, -0.1)
        elseif love.keyboard.wasPressed('right') then
            self:adjustVolume(mainItems, 0.1)
        elseif love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter') then
            self:selectMain(mainItems)
        elseif love.keyboard.wasPressed('escape') then
            self:close()
        end

    elseif self.mode == 'sleep' then
        if self.confirming then
            if love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter')
               or love.keyboard.wasPressed('y') then
                self:resolveConfirm(true)
            elseif love.keyboard.wasPressed('escape') or love.keyboard.wasPressed('n') then
                self:resolveConfirm(false)
            end
            return
        end
        if love.keyboard.wasPressed('up') then
            self.sleepSel = self.sleepSel > 1 and self.sleepSel - 1 or #SLEEP_ITEMS
        elseif love.keyboard.wasPressed('down') then
            self.sleepSel = self.sleepSel < #SLEEP_ITEMS and self.sleepSel + 1 or 1
        elseif love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter') then
            self:selectSleep()
        elseif love.keyboard.wasPressed('escape') then
            self.mode = 'main'
            self.mainSel = 2
        end

    elseif self.mode == 'save_slots' then
        if self.confirming then
            if love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter')
               or love.keyboard.wasPressed('y') then
                self:resolveConfirm(true)
            elseif love.keyboard.wasPressed('escape') or love.keyboard.wasPressed('n') then
                self:resolveConfirm(false)
            end
            return
        end
        local slots = manualSlots(self.slotList or {})
        if love.keyboard.wasPressed('up') then
            self.slotSel = nextSlot(slots, self.slotSel, -1, false)
        elseif love.keyboard.wasPressed('down') then
            self.slotSel = nextSlot(slots, self.slotSel, 1, false)
        elseif love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter') then
            self:confirmSaveSlot(slots)
        elseif love.keyboard.wasPressed('escape') then
            self.mode = 'main'
        end

    elseif self.mode == 'load_slots' then
        if self.confirming then
            if love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter')
               or love.keyboard.wasPressed('y') then
                self:resolveConfirm(true)
            elseif love.keyboard.wasPressed('escape') or love.keyboard.wasPressed('n') then
                self:resolveConfirm(false)
            end
            return
        end
        local slots = self.slotList or {}
        if love.keyboard.wasPressed('up') then
            self.slotSel = nextSlot(slots, self.slotSel, -1, true)
        elseif love.keyboard.wasPressed('down') then
            self.slotSel = nextSlot(slots, self.slotSel, 1, true)
        elseif love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter') then
            self:confirmLoadSlot(slots)
        elseif love.keyboard.wasPressed('escape') then
            self.mode = 'main'
        end
    end
    -- ====================================================================
end

-- ================== claude_changes_2026-05-25-1228 ==================
-- builds the main menu item list each frame (dynamic labels for speed and volume)
function PauseMenu:buildMainItems()
    return {
        { label = 'Resume' },
        { label = 'Sleep... (warp)' },
        { label = string.format('Speed: %dx', self.gameSpeed) },
        { label = string.format('Music: %d%%', math.floor(self.musicVol * 100)), volType = 'music' },
        { label = string.format('SFX:   %d%%', math.floor(self.sfxVol   * 100)), volType = 'sfx'   },
        { label = 'Save Game' },
        { label = 'Load Game', disabled = not SaveLoad.hasSave(), whenDisabled = 'no saves' },
        { label = 'Quit' },
    }
end

function PauseMenu:adjustVolume(items, delta)
    local item = items[self.mainSel]
    if not item or not item.volType then return end
    if item.volType == 'music' then
        self.musicVol = math.floor(math.max(0, math.min(1, self.musicVol + delta)) * 10 + 0.5) / 10
        applyMusicVol(self.musicVol)
    elseif item.volType == 'sfx' then
        self.sfxVol = math.floor(math.max(0, math.min(1, self.sfxVol + delta)) * 10 + 0.5) / 10
        applySfxVol(self.sfxVol)
    end
end

function PauseMenu:selectMain(items)
    local item = items[self.mainSel]
    if not item or item.disabled then return end
    if item.volType then return end  -- volume items use left/right, not enter

    if item.label == 'Resume' then
        self:close()
    elseif item.label == 'Sleep... (warp)' then
        self.mode = 'sleep'
        self.sleepSel = 1
    elseif item.label:sub(1, 6) == 'Speed:' then
        -- cycle through 1x → 2x → 4x → 1x
        local speeds = {1, 2, 4}
        for i, s in ipairs(speeds) do
            if s == self.gameSpeed then
                self.gameSpeed = speeds[(i % #speeds) + 1]
                break
            end
        end
    elseif item.label == 'Save Game' then
        self.slotList = SaveLoad.listSlots()
        self.slotSel = 1
        self.mode = 'save_slots'
    elseif item.label == 'Load Game' then
        self.slotList = SaveLoad.listSlots()
        -- default selection to first non-empty slot
        self.slotSel = 1
        for i, s in ipairs(self.slotList) do
            if not s.empty then self.slotSel = i; break end
        end
        self.mode = 'load_slots'
    elseif item.label == 'Quit' then
        self:showConfirm('Quit game?', function()
            love.event.quit()
        end)
    end
end

function PauseMenu:confirmSaveSlot(slots)
    local slot = slots[self.slotSel]
    if not slot then return end
    local msg = slot.empty
        and 'Save to ' .. slot.label .. '?'
        or 'Overwrite ' .. slot.label .. '?\n(' .. (slot.playerName or '?') .. ')'
    self:showConfirm(msg, function()
        self.saveRequested = { slotId = slot.id }
        self.mode = 'main'
        self:close()
    end)
end

function PauseMenu:confirmLoadSlot(slots)
    local slot = slots[self.slotSel]
    if not slot or slot.empty then return end
    self:showConfirm('Load ' .. slot.label .. '?\nCurrent progress lost.', function()
        self.loadRequested = { slotId = slot.id, legacyLoad = slot.legacyLoad }
        self.mode = 'main'
        self:close()
    end)
end
-- ====================================================================

function PauseMenu:selectSleep()
    local item = SLEEP_ITEMS[self.sleepSel]
    if item.label == 'Back' then
        self.mode = 'main'
        self.mainSel = 2
    elseif item.secs then
        self:showConfirm('Sleep for ' .. item.label .. '?', function()
            self.sleepRequested = item.secs
        end)
    end
end

function PauseMenu:mousepressed(x, y, button)
    if not self.active or button ~= 1 then return end

    if self.confirming then
        if hit(YES_BTN, x, y) then self:resolveConfirm(true)
        elseif hit(NO_BTN, x, y) then self:resolveConfirm(false) end
        return
    end

    if self.mode == 'main' then
        if x < BOX_X or x > BOX_X + BOX_W then return end
        local items = self:buildMainItems()
        for i, item in ipairs(items) do
            local iy = BOX_Y + 36 + (i - 1) * ITEM_H
            if y >= iy and y < iy + ITEM_H and not item.disabled then
                self.mainSel = i
                self:selectMain(items)
                return
            end
        end
    elseif self.mode == 'sleep' then
        if x < BOX_X or x > BOX_X + BOX_W then return end
        for i, item in ipairs(SLEEP_ITEMS) do
            local iy = BOX_Y + 40 + (i - 1) * ITEM_H
            if y >= iy and y < iy + ITEM_H then
                self.sleepSel = i
                self:selectSleep()
                return
            end
        end
    end
end

-- render

function PauseMenu:render()
    if not self.active then return end

    if self.mode == 'main' then
        self:renderMain()
    elseif self.mode == 'sleep' then
        self:renderSleep()
    -- ================== claude_changes_2026-05-25-1228 ==================
    elseif self.mode == 'save_slots' then
        self:renderSlotPicker('SAVE GAME', manualSlots(self.slotList or {}), false)
    elseif self.mode == 'load_slots' then
        self:renderSlotPicker('LOAD GAME', self.slotList or {}, true)
    -- ====================================================================
    end

    if self.confirming then render_confirm(self.confirmMsg) end
    set(1, 1, 1, 1)
end

function PauseMenu:renderMain()
    set(0.75, 0.75, 0.75, 0.9)
    love.graphics.rectangle('fill', BOX_X, BOX_Y, BOX_W, BOX_H, 3)
    set(0.04, 0.04, 0.06, 0.96)
    love.graphics.rectangle('fill', BOX_X + 2, BOX_Y + 2, BOX_W - 4, BOX_H - 4, 3)

    local ix = BOX_X + PAD
    local iw = BOX_W - PAD * 2

    love.graphics.setFont(gFonts['gothic-medium'])
    set(1, 0.84, 0, 1)
    love.graphics.printf('PAUSED', ix, BOX_Y + 6, iw, 'center')

    set(1, 1, 1, 0.2)
    love.graphics.line(ix, BOX_Y + 30, BOX_X + BOX_W - PAD, BOX_Y + 30)

    local items = self:buildMainItems()
    love.graphics.setFont(gFonts['small'])
    for i, item in ipairs(items) do
        local iy = BOX_Y + 36 + (i - 1) * ITEM_H
        set(1, 0.84, 0, 1)
        love.graphics.print(
            (i == self.mainSel and not item.disabled) and '>' or ' ',
            ix, iy
        )
        if item.disabled then
            set(0.38, 0.38, 0.38, 1)
            local suffix = item.whenDisabled and '  (' .. item.whenDisabled .. ')' or ''
            love.graphics.print(item.label .. suffix, ix + 9, iy)
        elseif i == self.mainSel then
            set(1, 0.95, 0.55, 1)
            love.graphics.print(item.label, ix + 9, iy)
            -- ================== claude_changes_2026-05-25-1228 ==================
            -- dim right-arrow hints left/right adjusts this item
            if item.volType then
                set(0.4, 0.4, 0.4, 1)
                love.graphics.print('>', BOX_X + BOX_W - PAD - 5, iy)
            end
            -- ====================================================================
        else
            set(0.9, 0.9, 0.9, 1)
            love.graphics.print(item.label, ix + 9, iy)
        end
    end

    set(0.35, 0.35, 0.35, 1)
    -- ================== claude_changes_2026-05-25-1228 ==================
    love.graphics.printf('[< >] vol   [ESC] resume', ix, BOX_Y + BOX_H - 11, iw, 'center')
    -- ====================================================================
end

function PauseMenu:renderSleep()
    set(0.75, 0.75, 0.75, 0.9)
    love.graphics.rectangle('fill', BOX_X, BOX_Y, BOX_W, BOX_H, 3)
    set(0.04, 0.04, 0.06, 0.96)
    love.graphics.rectangle('fill', BOX_X + 2, BOX_Y + 2, BOX_W - 4, BOX_H - 4, 3)

    local ix = BOX_X + PAD
    local iw = BOX_W - PAD * 2

    love.graphics.setFont(gFonts['gothic-medium'])
    set(0.6, 0.8, 1, 1)
    love.graphics.printf('SLEEP', ix, BOX_Y + 6, iw, 'center')

    love.graphics.setFont(gFonts['small'])
    set(0.55, 0.55, 0.55, 1)
    love.graphics.printf('Wake up in...', ix, BOX_Y + 24, iw, 'center')

    set(1, 1, 1, 0.2)
    love.graphics.line(ix, BOX_Y + 34, BOX_X + BOX_W - PAD, BOX_Y + 34)

    for i, item in ipairs(SLEEP_ITEMS) do
        local iy = BOX_Y + 40 + (i - 1) * ITEM_H
        set(1, 0.84, 0, 1)
        love.graphics.print(i == self.sleepSel and '>' or ' ', ix, iy)
        if i == self.sleepSel then set(1, 0.95, 0.55, 1)
        elseif item.label == 'Back' then set(0.55, 0.55, 0.55, 1)
        else set(0.9, 0.9, 0.9, 1) end
        love.graphics.print(item.label, ix + 9, iy)
    end

    set(0.35, 0.35, 0.35, 1)
    love.graphics.printf('[ESC] back', ix, BOX_Y + BOX_H - 11, iw, 'center')
end

-- ================== claude_changes_2026-05-25-1228 ==================
-- shared renderer for save and load slot pickers
-- loadMode=true = skip empty slots in selection indicator; show LOAD hint
function PauseMenu:renderSlotPicker(title, slots, loadMode)
    set(0.75, 0.75, 0.75, 0.9)
    love.graphics.rectangle('fill', SLOT_X, SLOT_Y, SLOT_W, SLOT_H, 3)
    set(0.04, 0.04, 0.06, 0.96)
    love.graphics.rectangle('fill', SLOT_X + 2, SLOT_Y + 2, SLOT_W - 4, SLOT_H - 4, 3)

    local ix = SLOT_X + PAD
    local iw = SLOT_W - PAD * 2

    love.graphics.setFont(gFonts['gothic-medium'])
    set(1, 0.84, 0, 1)
    love.graphics.printf(title, ix, SLOT_Y + 6, iw, 'center')

    set(1, 1, 1, 0.2)
    love.graphics.line(ix, SLOT_Y + 28, SLOT_X + SLOT_W - PAD, SLOT_Y + 28)

    love.graphics.setFont(gFonts['small'])
    for i, slot in ipairs(slots) do
        local ey = SLOT_LIST_Y + (i - 1) * SLOT_ENTRY_H
        local sel = (i == self.slotSel)
        local unavail = loadMode and slot.empty

        -- row highlight
        if sel and not unavail then
            set(1, 1, 1, 0.06)
            love.graphics.rectangle('fill', SLOT_X + 3, ey, SLOT_W - 6, SLOT_ENTRY_H - 2)
        end

        -- cursor
        set(1, 0.84, 0, 1)
        love.graphics.print((sel and not unavail) and '>' or ' ', ix, ey + 4)

        -- slot label
        if unavail then set(0.38, 0.38, 0.38, 1)
        elseif sel then set(1, 0.95, 0.55, 1)
        else set(0.9, 0.9, 0.9, 1) end
        love.graphics.print(slot.label, ix + 10, ey + 4)

        -- metadata row
        if slot.empty then
            set(0.35, 0.35, 0.35, 1)
            love.graphics.print('-- EMPTY --', ix + 10, ey + 16)
        else
            set(0.55, 0.75, 0.55, 1)
            love.graphics.print(
                string.format('%s  %s', slot.playerName or '?', fmt_slot_cash(slot.cash)),
                ix + 10, ey + 16
            )
            set(0.4, 0.4, 0.4, 1)
            love.graphics.print(slot.savedAt or '', ix + 160, ey + 16)
        end

        -- divider
        set(1, 1, 1, 0.08)
        love.graphics.line(ix, ey + SLOT_ENTRY_H - 1, SLOT_X + SLOT_W - PAD, ey + SLOT_ENTRY_H - 1)
    end

    set(0.35, 0.35, 0.35, 1)
    local hint = loadMode
        and '[ENTER] load   [ESC] back'
        or  '[ENTER] save   [ESC] back'
    love.graphics.printf(hint, ix, SLOT_Y + SLOT_H - 11, iw, 'center')
end
-- ====================================================================

return PauseMenu
