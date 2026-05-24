--[[
    minimal JSON encoder + decoder
    handles: null, bool, number, string, array, object
    encode: json.encode(val) -> string
    decode: json.decode(str) -> value
]]

local M = {}

-- ── encode ──────────────────────────────────────────────────

local function enc(v)
    local t = type(v)
    if     t == 'nil'     then return 'null'
    elseif t == 'boolean' then return tostring(v)
    elseif t == 'number'  then
        if v ~= v then return 'null' end  -- NaN guard
        return string.format('%.14g', v)
    elseif t == 'string'  then
        return '"' .. v:gsub('[\\"]', function(c) return '\\' .. c end)
                       :gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t') .. '"'
    elseif t == 'table'   then
        -- array if all keys are consecutive ints from 1
        local n = #v
        local cnt = 0; for _ in pairs(v) do cnt = cnt + 1 end
        if n == cnt then
            local a = {}; for i = 1, n do a[i] = enc(v[i]) end
            return '[' .. table.concat(a, ',') .. ']'
        else
            local a = {}
            for k, val in pairs(v) do
                if type(k) == 'string' then
                    a[#a+1] = enc(k) .. ':' .. enc(val)
                end
            end
            table.sort(a)
            return '{' .. table.concat(a, ',') .. '}'
        end
    end
    return 'null'
end

function M.encode(val) return enc(val) end

-- ── decode ──────────────────────────────────────────────────

function M.decode(s)
    local p = 1

    local function ws()
        while p <= #s and s:byte(p) <= 32 do p = p + 1 end
    end

    local pv  -- forward-declared

    local ESC = { ['"']='"', ['\\']='\\', ['/']='./', n='\n', r='\r', t='\t', b='\b', f='\f' }

    local function pstr()
        p = p + 1; local buf = {}
        while p <= #s do
            local c = s:sub(p,p)
            if c == '"' then p = p + 1; return table.concat(buf) end
            if c == '\\' then p = p + 1; buf[#buf+1] = ESC[s:sub(p,p)] or s:sub(p,p)
            else buf[#buf+1] = c end
            p = p + 1
        end
        error('json: unterminated string')
    end

    local function parr()
        p = p + 1; local a = {}; ws()
        if s:sub(p,p) == ']' then p = p + 1; return a end
        repeat
            a[#a+1] = pv(); ws()
            if s:sub(p,p) == ',' then p = p + 1 end
        until s:sub(p,p) == ']'
        p = p + 1; return a
    end

    local function pobj()
        p = p + 1; local o = {}; ws()
        if s:sub(p,p) == '}' then p = p + 1; return o end
        repeat
            ws(); local k = pstr(); ws(); p = p + 1; ws()  -- skip ':'
            o[k] = pv(); ws()
            if s:sub(p,p) == ',' then p = p + 1 end
        until s:sub(p,p) == '}'
        p = p + 1; return o
    end

    pv = function()
        ws(); local c = s:sub(p,p)
        if     c == '"' then return pstr()
        elseif c == '[' then return parr()
        elseif c == '{' then return pobj()
        elseif c == 't' then p=p+4; return true
        elseif c == 'f' then p=p+5; return false
        elseif c == 'n' then p=p+4; return nil
        else
            local n = s:match('^-?%d+%.?%d*[eE]?[+-]?%d*', p)
            if n then p=p+#n; return tonumber(n) end
            error('json: unexpected "' .. c .. '" at pos ' .. p)
        end
    end

    return pv()
end

return M
