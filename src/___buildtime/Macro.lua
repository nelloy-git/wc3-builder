---@type BuilderFile
local File = require('src.File')

---@class BuildtimeMacro
local BuildtimeMacro = {}

local inside_macro = false
local macro_list
local src_dir
local dst_dir

---@param str string
---@param line number
---@return number
local function findLine(str, line)
    local pos = 0
    for i = 1, line - 1 do
        pos = string.find(str, '\n', pos + 1)
    end
    return pos
end

---@param file_path string
---@param line number
---@return string
local function findMarco(file_path, line)
    if not File.isExist(file_path) then
        error('Can not find file: '..file_path, 3)
    end

    local context = File.read(file_path)
    local pos = findLine(context, line)
    local postfix = context:sub(pos + 1)
    return postfix:match('Macro%b()')
end

---@param path string
---@param line number
---@param result nil | boolean | number | string | table
local function registerMacro(path, line, result)
    if (not src_dir) then
        error('Macro function can not be called after building ends.', 3)
    end

    ---@class BuilderMacroData
    local macro_data = {
        path = path:sub(src_dir:len() + 2),
        origin = findMarco(path, line),
        result = result
    }
    table.insert(macro_list, macro_data)
end

---@param result any
---@return boolean
local function isResultValid(result)
    local t = type(result)
    if t == 'string' or
       t == 'number' or
       t == 'boolean' or
       t == 'nil' then
        return true
    elseif t == 'table' then
        for k, v in pairs(result) do
            local valid = isResultValid(k) and
                          isResultValid(v)

            if not valid then
                return false
            end
        end
        return true
    end

    return false
end

local function macroFunc(body, ...)
    if inside_macro then
        error('Macro function can not run inside another Macro function.', 2)
    end

    inside_macro = true

    -- Get result
    local res = (type(body) == 'function') and body(...) or body
    if not isResultValid(res) then
        error('Macro: got unavailable result type.', 2)
    end

    local info = debug.getinfo(2, 'lSn')
    local path = info.source:sub(2, #info.source)
    local line = info.currentline
    registerMacro(path, line, res)

    inside_macro = false

    return res
end

local escape_char_map = {
  [ "\\" ] = "\\",
  [ "\"" ] = "\"",
  [ "\b" ] = "b",
  [ "\f" ] = "f",
  [ "\n" ] = "n",
  [ "\r" ] = "r",
  [ "\t" ] = "t",
}

local function escape_char(c)
    return "\\" .. (escape_char_map[c] or string.format("u%04x", c:byte()))
end

local function encode_string(val)
    return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
end

---@param data nil | boolean | number | string | table
---@param log integer
local function toString(data, log)
    local t = type(data)
    if t == 'string' then
        if data == 'nil' then
            error('BuilderMacro: can not return string \'nil\'', log or 4)
        end
        return encode_string(data)
    elseif t == 'number' then
        return tostring(data)
    elseif t == 'nil' then
        return 'nil'
    elseif t == 'boolean' then
        if data then
            return 'true'
        else
            return 'false'
        end
    elseif t == 'table' then
        local res = '{\n'
        for k, v in pairs(data) do
            res = res..string.format('[%s] = %s,\n',
                                     toString(k, log and log + 1 or 4),
                                     toString(v, log and log + 1 or 4))
        end
        return res..'}'
    else
        error('Can not use \''..t..'\' type', log or 4)
    end
end

--- Search found Macros in list of files and replaces them.
---@param files table<string, string> @format: <path, context>
function BuildtimeMacro.replace(files)
    for i = 1, #macro_list do
        local macro_data = macro_list[i]
        local path = macro_data.path

        if files[path] then
            local origin = macro_data.origin:gsub("[%(%)%.%%%+%-%*%?%[%^%$%]]", "%%%1")
            local result = macro_data.result

            local success, s_data = pcall(toString, result)
            if not success then
                error('BuilderMacro: error in Macro:\n'..s_data, 1)
            end

            s_data = (s_data == 'nil') and '' or s_data
            files[path] = string.gsub(files[path], origin, s_data, 1)
        end
    end
end

---@param src string
---@param dst string
function BuildtimeMacro.enable(src, dst)
    inside_macro = false
    macro_list = {}
    src_dir = src
    dst_dir = dst

    _G.Macro = macroFunc
end

function BuildtimeMacro.disable()
    src_dir = nil
    dst_dir = nil

    _G.Macro = nil
end

return BuildtimeMacro