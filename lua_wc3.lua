local is_compiletime = true
local src_dir = ''
local dst_dir = ''
local sep = package.config:sub(1,1)
local finalize = {
    functions = {},
    args = {}
}


local replace_compiletime = {
    path = {},
    original = {},
    result = {}
}

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

--- Function executes at the end of running all required packages.
--- This function does not exist in runtime
function CompileFinal(func, ...)
    table.insert(finalize.functions, func)
    table.insert(finalize.args,{...})
end

--- Function executes at the end of running all required packages.
--- This function will execute func(...) in runtime
function CompiletimeFinalToRuntime(func, ...)
    table.insert(finalize.functions, func)
    table.insert(finalize.args, {...})
end

local compiletime_packages = {}
local runtime_packages = {}
local loading_packages = {}

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
            print('Recursive require detected.')
            return nil
        end

        if not loaded_packages[package_name] then
            loading_packages[package_name] = true
            loaded_packages[package_name] = package_files[package_name]() or true
            loading_packages[package_name] = nil
        end
        return loaded_packages[package_name]
    end

    function CompiletimeFinalInit(func)
        return func()
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
    return str
end

local function writeFile(str, path)
    local f = io.open(path, "w")
    f:write(str)
    f:close()
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
        val = val:gsub('%%', '%%%%')
        return '\''..val..'\''
    elseif t == 'number' then
        return tostring(val)
    elseif t == 'nil' then
        return 'nil'
    elseif t == 'boolean' then
        if val then
            return 'true'
        else
            return 'false'
        end
    elseif t == 'table' then
        local res = '{'
        for k, v in pairs(val) do
            res = res..string.format('[%s] = %s,', compiletimeToString(k), compiletimeToString(v))
        end
        return res..'}'
    end
end

local function replaceCompiletime()
    for i = 1, #replace_compiletime.path do
        local path = replace_compiletime.path[i]
        local original = replace_compiletime.original[i]:gsub("[%(%)%.%%%+%-%*%?%[%^%$%]]", "%%%1")
        local result = compiletimeToString(replace_compiletime.result[i])

        runtime_packages[path] = string.gsub(runtime_packages[path], original, result, 1)
    end
end

local function runFinalize()
    local count = #finalize.functions
    for i = 1, count do
        finalize.functions[count + 1 - i](table.unpack(finalize.args[count + 1 - i]))
    end
end

local function optimize(str)
    str = str:gsub('--%[%b[]%]', '')
    str = str:gsub('%-%-[^\n]*\n', '')
    str = str:gsub('\n[%s\n\t]*\n', '\n')
    return str
end

---@param src string
---@param dst string
local function Compile(src, dst)
    src_dir = src..sep
    dst_dir = dst..sep

    -- Run lua code.
    require('war3map')
    -- Run final functions list.
    runFinalize()
    -- Replace Compiletime functions with their values. 
    replaceCompiletime()

    -- Concat files
    local res = runtime_packages[name2path('war3map')]
    runtime_packages[name2path('war3map')] = nil
    for k, v in pairs(runtime_packages) do
        res = string.format(package_func_code,
                            path2name(k), v:gsub('\n', '\n\t'))..'\n'..res
    end
    res = runtime_code..res

    -- Save file
    res = optimize(res)
    writeFile(res, dst_dir..sep..'war3map.lua')
end

local original_require = _G.require
function require(package_name)
    if not type(package_name) == 'string' then
        error('require function got non string value.', 2)
    end

    if loading_packages[package_name] then
        error('recursive require detected.', 2)
    end

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

--- Compiletime functions are replaced with their results after all lua code is done.
function Compiletime(body, ...)
    -- Check Compiletime(... Compiletime(...) ...)
    if inside_compiletime_function then
        error('compiletime function can not run inside another compiletime function.', 2)
    end
    inside_compiletime_function = true

    -- Get result
    local res
    if type(body) == 'function' then
        res = body(...)
    else
        res = body
    end

    if not checkCompiletimeResult(res) then
        error('compiletime function can return only string, number or table with strings, numbers and tables. %s:%s', 2)
    end

    local info = debug.getinfo(2, 'lSn')
    local path = src_dir..info.source:sub(4, #info.source)
    local line = info.currentline
    if runtime_packages[path] then
        local ln = 1
        local pos = 0
        for i = 1, line - 1 do
            pos = string.find(runtime_packages[path], '\n', pos + 1)
            ln = ln + 1
        end
        local postfix = runtime_packages[path]:sub(pos + 1)
        local original = postfix:match('[^%a]Compiletime%b()'):sub(2)

        table.insert(replace_compiletime.path, path)
        table.insert(replace_compiletime.original, original)
        table.insert(replace_compiletime.result, res)
    end

    inside_compiletime_function = false
    return res
end

return Compile