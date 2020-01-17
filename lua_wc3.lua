local is_compiletime = true
local src_dir = ''
local dst_dir = ''
local sep = package.config:sub(1,1)

---@return boolean
function IsCompiletime()
    return is_compiletime
end

function GetSrcDir()
    return src_dir
end

function GetDstDir()
    return dst_dir
end

local compiletime_packages = {}
local runtime_packages = {}
local loading_packages = {}

local original_require = _G.require
local inside_compiletime_function = false
local package_func_code = [[
package_files['%s'] = function()
    %s
end
]]
local runtime_code = [[
package_files = {}
do
    local is_compiletime = false

    function IsCompiletime()
        return is_compiletime
    end

    local loaded_packages = {}
    local loading_packages = {}
    function require(package_name)
        if loading_packages[package_name] then
            return nil
        end

        if not loaded_packages[package_name] then
            loading_packages[package_name] = true
            loaded_packages[package_name] = package_files[package_name]() or true
            loading_packages[package_name] = nil
        end
        return loaded_packages[package_name]
    end
end

]]

---@param package_name string
local function name2path(package_name)
    return src_dir..package_name:gsub('%.', sep)..'.lua'
end

---@param path string
local function path2name(path)
    path = path:sub(#src_dir + 1)
    --path = path:gsub(src_dir, '')
    path = string.gsub(path, sep, '.')
    return path:sub(1, #path - 4)
end

local function file_exists(file)
    local f = io.open(file, "rb")
    if f then
        f:close()
    end
    return f ~= nil
end

local function readFile(path)
    if not file_exists(path) then
        local info = debug.getinfo(2, 'lS')
        error(string.format('can not find file. %s:%s', info.source, info.currentline))
    end

    local lines = {}
    for line in io.lines(path) do 
      lines[#lines + 1] = line
    end

    local str = table.concat(lines, '\n')

    local s = string.find(str, '--[[', nil, true)
    while s do
        local e = string.find(str, '%]%]', s) or s
        str = str:sub(1, s - 1)..str:sub(e + 2, #str)
        s = string.find(str, '--[[', nil, true)
    end

    s = string.find(str, '%-%-')
    while s do
        local e = string.find(str, '\n', s) or s
        str = str:sub(1, s - 1)..str:sub(e + 1, #str)
        s = string.find(str, '%-%-')
    end

    s = string.find(str, '\n\n')
    while s do
        str = string.gsub(str, '\n\n', '\n')
        s = string.find(str, '\n\n')
    end

    return str
end

local function writeFile(str, path)
    local f = io.open(path, "w")
    f:write(str)
    f:close()
end

local finalize_functions = {}
function AddCompileFinal(func)
    table.insert(finalize_functions, func)
end

local function runFinalize()
    for i = 1, #finalize_functions do
        finalize_functions[#finalize_functions + 1 - i]()
    end
end

---@param src string
---@param dst string
local function Compile(src, dst)
    src_dir = src..sep
    dst_dir = dst..sep
    require('war3map')

    local res = runtime_packages[name2path('war3map')]
    runtime_packages[name2path('war3map')] = nil
    for k, v in pairs(runtime_packages) do
        res = string.format(package_func_code,
                            path2name(k), v:gsub('\n', '\n\t'))..'\n'..res
    end
    res = runtime_code..res
    writeFile(res, dst_dir..sep..'war3map.lua')
    runFinalize()
end

function require(package_name)
    local info = debug.getinfo(2, 'lS')

    if not type(package_name) == 'string' then
        error(string.format('require function got non string value. %s:%s', info.source, info.currentline))
    end

    if info.name then
        error(string.format('require function can be used in main file chunk only. %s:%d', info.source, info.currentline))
    end

    if loading_packages[package_name] then
        return
    end

    --print(package_name, inside_compiletime_function)
    local path = name2path(package_name)
    if inside_compiletime_function then
        if not compiletime_packages[path] then
            print('Compiletime require:', path)
            compiletime_packages[path] = readFile(path)
        end
    else
        if not runtime_packages[path] then
            print('Runtime require:', path)
            runtime_packages[path] = readFile(path)
        end
    end

    loading_packages[package_name] = true
    local res = original_require(package_name)
    loading_packages[package_name] = nil
    return res
end


local function checkCompiletimeResult(result)
    local res_type = type(result)
    if res_type == 'string' or res_type == 'number' or res_type == 'nil' then
        return true
    elseif res_type == 'table' then
        for k,v in pairs(result) do
            if not checkCompiletimeResult(k) or not checkCompiletimeResult(v) then
                return false
            end
        end
        return true
    end
    return false
end

local function compiletimeToString(val)
    local t = type(val)
    if t == 'string' then
        val = val:gsub('\'', '\\\'')
        local c = string.char(37)
        val = val:gsub('%%', '%%%%')
        return '\''..val..'\''
    elseif t == 'number' then
        return tostring(val)
    elseif t == 'nil' then
        return 'nil'
    elseif t == 'table' then
        local res = '{'
        for k, v in pairs(val) do
            res = res..string.format('[%s] = %s,', compiletimeToString(k), compiletimeToString(v))
        end
        return res..'}'
    end
end

function Compiletime(body, ...)
    local info = debug.getinfo(2, 'lSn')

    if inside_compiletime_function then
        error(string.format('compiletime function can not run inside other compiletime function. %s:%d', info.source, info.currentline))
    end

    inside_compiletime_function = true

    if not is_compiletime then
        error(string.format('compiletime function can not run in runtime. %s:%d', info.source, info.currentline))
    end

    if info.name then
        error(string.format('compiletime function can be used in main file chunk only. %s:%d', info.source, info.currentline))
    end

    local res
    if type(body) == 'function' then
        res = body(...)
    else
        res = body
    end

    if not checkCompiletimeResult(res) then
        error(string.format('compiletime function can return only string, number or table with strings, numbers and tables. %s:%s', info.source, info.currentline))
    end

    local path = src_dir..info.source:sub(4, #info.source)
    if runtime_packages[path] then
        runtime_packages[path] = string.gsub(runtime_packages[path], ' Compiletime%b()', ' '..compiletimeToString(res), 1)
        --print(runtime_packages[path])
    end
    if compiletime_packages[path] then
        compiletime_packages[path] = string.gsub(compiletime_packages[path], ' Compiletime%b()', ' '..compiletimeToString(res), 1)
        --print(compiletime_packages[path])
    end

    inside_compiletime_function = false

    return res
end

return Compile