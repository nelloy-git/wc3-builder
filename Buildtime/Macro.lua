---@type BuildtimeFileUtils
local BuildtimeFileUtils = require('Buildtime.FileUtils')

---@class BuildtimeMacro
local BuildtimeMacro = {}

local inside_macro = false
local macro_list
local src

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
    if not BuildtimeFileUtils.isExist(file_path) then
        error('Can not find file: '..file_path, 3)
    end

    local context = BuildtimeFileUtils.readFile(file_path)
    local pos = findLine(context, line)
    local postfix = context:sub(pos + 1)
    return postfix:match('Macro%b()')
end

---@param path string
---@param line number
---@param result nil | boolean | number | string | table
local function registerMacro(path, line, result)
    ---@class BuildtimeMacroData
    local macro_data = {
        path = path:sub(src:len() + 2),
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
        error('BuildtimeMacro: got wrong type.', 2)
    end

    local info = debug.getinfo(2, 'lSn')
    local path = info.source:sub(2, #info.source)
    local line = info.currentline
    registerMacro(path, line, res)

    inside_macro = false
end

local build_final_list = {}
local function buildFinal(func, ...)
    table.insert(build_final_list, {f = func, a = {...}})
end

---@return table<integer, BuildtimeMacroData>
function BuildtimeMacro.getMacroList()
    local copy = {}
    for k,v in pairs(macro_list) do
        copy[k] = v
    end
    return copy
end

---@param flag boolean
---@param src_dir string
function BuildtimeMacro.enable(flag, src_dir)
    src = src_dir

    if flag then
        macro_list = {}
        _G.Macro = macroFunc
        _G.BuildFinal = buildFinal
    else
        for i = 1, #build_final_list do
            build_final_list[i].f(table.unpack(build_final_list[i].a))
        end
        
        _G.Macro = nil
        _G.BuildFinal = nil
    end
end

return BuildtimeMacro