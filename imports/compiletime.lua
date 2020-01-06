local lua_wc3 = {}

lua_wc3.is_compiletime = true
lua_wc3.compiletime_packages = {}
lua_wc3.runtime_packages = {}

local inside_compiletime_function = false

function lua_wc3.init(src, dst)
    lua_wc3.src = src
    lua_wc3.dst = dst
end

local loading_modules = {}
local original_require = _G.require
function lua_wc3.require(package_name)
    if type(package_name) == 'string' then
        if inside_compiletime_function then
            lua_wc3.compiletime_packages[package_name] = 0
        end
    else
        local info = debug.getinfo(2, 'lS')
        string.format('Error: require function got non string value. %s:%s', info.source, info.currentline)
        return
    end

    if loading_modules[package_name] then
        return
    end

    if inside_compiletime_function then
        lua_wc3.compiletime_packages[package_name] = 0
    end

    return original_require(package_name)
end


local function checkCompiletimeResult(result)
    local res_type = type(result)
    if res_type == 'string' or res_type == 'number' then
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

function _G.compiletime(body, ...)
    local info = debug.getinfo(2, 'lS')

    if inside_compiletime_function then
        string.format('Error: compiletime function can not run inside other compiletim function. %s:%s', info.source, info.currentline)
        return
    end

    if not lua_wc3.is_compiletime then
        string.format('Error: compiletime function can not run in runtime. %s:%s', info.source, info.currentline)
        return
    end

    local path = info.source

    local res
    if type(body) == 'function' then
        res = body(...)
    else
        res = body
    end

    local success = checkCompiletimeResult(res)
    local res_type = type(res)
    if not success then
        string.format('Error: compiletime function can return only string, number or table with strings, numbers and tables. %s:%s', info.source, info.currentline)
        return
    end

    return res
end

local sep = package.config:sub(1,1)
---@param package_name string
function lua_wc3.name2path(package_name)
    return lua_wc3.src..package_name:gsub('.', sep)..'.lua'
end

local function file_exists(file)
    local f = io.open(file, "rb")
    if f then
        f:close()
    end
    return f ~= nil
end

function lua_wc3.readFile(path)
    if not file_exists then
        local info = debug.getinfo(2, 'lS')
        string.format('Error: can not find file. %s:%s', info.source, info.currentline)
        return
    end

    local lines = {}
    for line in io.lines(path) do 
      lines[#lines + 1] = line
    end
    return lines
end

local __finalize_list = {}
function __finalize()
    for _, fun in pairs(__finalize_list) do
        if type(fun) == 'function' then
            fun()
        end
    end
end

function addCompiletimeFinalize(fun)
    table.insert(__finalize_list, 1, fun)
end