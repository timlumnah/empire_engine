-- ================== claude_changes_2026-05-23-2136 ==================
--[[
   Empire Engine
   Based on CS50 2D Coursework

   -- Util.lua --

   Author: Tim Lumnah
   github.com/timlumnah/empire_engine

   Shared utility functions: generateQuads() for sprite-sheet
   slicing, renderHelpPopup() for the in-game objectives overlay,
   and commify() for comma-formatted money strings.
]]
-- ====================================================================

--[[
    Given an "atlas" (a texture with multiple sprites), as well as a
    width and a height for the tiles therein, split the texture into
    all of the quads by simply dividing it evenly.
]]
-- ================== claude_changes_2026-05-23-1243 ==================
-- commify was listed in the header docstring but never implemented.
-- formats a number as a comma-separated integer string, e.g. 50000000 -> "50,000,000"
function commify(n)
    local s = tostring(math.floor(math.abs(n)))
    local result = s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return (n < 0 and "-" or "") .. result
end
-- ====================================================================

function GenerateQuads(atlas, tilewidth, tileheight)
    local sheetWidth = atlas:getWidth() / tilewidth
    local sheetHeight = atlas:getHeight() / tileheight

    local sheetCounter = 1
    local spritesheet = {}

    for y = 0, sheetHeight - 1 do
        for x = 0, sheetWidth - 1 do
            spritesheet[sheetCounter] =
                love.graphics.newQuad(x * tilewidth, y * tileheight, tilewidth,
                tileheight, atlas:getDimensions())
            sheetCounter = sheetCounter + 1
        end
    end

    return spritesheet
end

--[[
    Recursive table printing function.
    https://coronalabs.com/blog/2014/09/02/tutorial-printing-table-contents/
]]
function renderHelpPopup()
    -- objectives + controls overlay; shared by StartState and PlayState
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle('fill', 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)

    local bw, bh = 200, 210
    local bx = math.floor((VIRTUAL_WIDTH - bw) / 2)
    local by = math.floor((VIRTUAL_HEIGHT - bh) / 2)

    love.graphics.setColor(0.08, 0.08, 0.13, 0.97)
    love.graphics.rectangle('fill', bx, by, bw, bh, 4)
    love.graphics.setColor(0.45, 0.45, 0.6, 1)
    love.graphics.rectangle('line', bx, by, bw, bh, 4)

    love.graphics.setFont(gFonts['small'])

    -- objectives section
    love.graphics.setColor(1, 1, 0.55, 1)
    love.graphics.printf('HOW TO PLAY', bx, by + 7, bw, 'center')

    local objectives = {
        'Three rooms: Start, Mid, Endgame.',
        'Doors locked. Talk to an NPC,',
        'pick SHMOOZE, type a compliment.',
        '3 affinity = door unlocked.',
        'Press Enter near an NPC to open',
        'a business or take out a loan.',
        -- ================== claude_changes_2026-05-23-1243 ==================
        'Earn monthly profit. Reach $' .. commify(WIN_CASH_GOAL) .. '.',
        -- ====================================================================
        'Avoid bankruptcy or death.',
    }

    local oy = by + 20
    love.graphics.setColor(0.85, 0.85, 0.85, 1)
    for _, line in ipairs(objectives) do
        love.graphics.printf(line, bx + 8, oy, bw - 16, 'left')
        oy = oy + 10
    end

    -- divider
    love.graphics.setColor(0.35, 0.35, 0.5, 1)
    love.graphics.line(bx + 8, oy + 2, bx + bw - 8, oy + 2)
    oy = oy + 10

    -- controls section
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf('CONTROLS', bx, oy, bw, 'center')
    oy = oy + 12

    local controls = {
        { 'Arrows', 'Move' },
        { 'Enter', 'Interact with NPC' },
        { 'Space', 'Sword / throw' },
        { 'C', 'Marketplace' },
        { 'I', 'Inventory' },
        { 'TAB', 'Business portfolio' },
        { 'P', 'Pause / sleep' },
        { 'R', 'Restart game' },
        { 'ESC', 'Quit / close menu' },
    }

    local col1 = bx + 8
    local col2 = bx + 82

    for _, row in ipairs(controls) do
        love.graphics.setColor(0.65, 0.88, 1, 1)
        love.graphics.print(row[1], col1, oy)
        love.graphics.setColor(0.85, 0.85, 0.85, 1)
        love.graphics.print(row[2], col2, oy)
        oy = oy + 11
    end

    love.graphics.setColor(0.38, 0.38, 0.45, 1)
    love.graphics.printf('[ESC] to close', bx, by + bh - 13, bw, 'center')
    love.graphics.setColor(1, 1, 1, 1)
end

function print_r ( t )
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end