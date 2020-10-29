
local sep = package.config:sub(1,1)

local function getCurDir()
    local full_path = debug.getinfo(2, "S").source:sub(2)
    local pos = full_path:find(sep)
    local last = pos
    while (pos) do
        last = pos
        pos = full_path:find(sep, pos + 1)
    end

    return full_path:sub(1, last - 1)
end

package.path = package.path..';'..getCurDir()..sep.."?.lua"
local Utils = require('utils')

local is_compiletime = true
local src_dir = ''
local dst_dir = ''
local runtime_modules_path = 'runtime_modules.txt'
local compiletime_modules_path = 'compiletime_modules.txt'
local finalize = {
    functions = {},
    args = {}
}

local compiletime_packages = {}
local runtime_packages = {}
local loading_packages = {}

local inside_compiletime_function = false
local 
package_func_code = [[
package_files['%s'] = function()
    %s
end
]]

---@return boolean
function IsCompiletime()
    return is_compiletime
end

---@return string
function GetSrcDir()
    return src_dir
end

---@return string
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

local function runFinalize()
    local count = #finalize.functions
    for i = 1, count do
        finalize.functions[count + 1 - i](table.unpack(finalize.args[count + 1 - i]))
    end
    print('Compilation done.')
end

---@param package_name string
local function name2path(package_name)
    if type(package_name) ~= 'string'  then
        error('wront package name type.', 3)
    end
    return src_dir..package_name:gsub('%.', sep)..'.lua'
end

---@param path string
local function path2name(path)
    path = path:sub(#src_dir + 1)
    path = string.gsub(path, sep, '.')
    return path:sub(1, #path - 4)
end

local replace_compiletime = {
    path = {},
    original = {},
    result = {}
}

local function replaceCompiletime()
    for i = 1, #replace_compiletime.path do
        local path = replace_compiletime.path[i]
        local original = replace_compiletime.original[i]:gsub("[%(%)%.%%%+%-%*%?%[%^%$%]]", "%%%1")

        local success, result = pcall( Utils.toString, replace_compiletime.result[i])
        if success then
            runtime_packages[path] = string.gsub(runtime_packages[path], original, result, 1)
        else
            print(result)
            print(path)
            print(original)
        end
    end
end

---@param file_path string
---@param line number
---@return string
local function searchCompiletimeInFile(file_path, line)
    local pos = Utils.findLinePos(runtime_packages[file_path], line)
    local postfix = runtime_packages[file_path]:sub(pos + 1)
    --print('==========================')
    --print(file_path)
    --print('--------------------------')
    --print(postfix)
    --print('--------------------------')
    --print(postfix:match('Compiletime%b()'))
    return postfix:match('Compiletime%b()')--:sub(2)
end

---@param result any
---@return boolean
local function checkCompiletimeResult(result)
    local res_type = type(result)
    if res_type == 'string' or res_type == 'number' or res_type == 'boolean' or res_type == 'nil' then
        return true
    end

    if res_type == 'table' then
        for k,v in pairs(result) do
            if not checkCompiletimeResult(k) or not checkCompiletimeResult(v) then
                return false
            end
        end
        return true
    end

    return false
end

local function optimize(str)
    str = str:gsub('--%[%b[]%]', '')
    str = str:gsub('%-%-[^\n]*', '')
    str = str:gsub('\n[%s\n\t]*\n', '\n')
    return str
end

local original_require = _G.require
local compiletime_log = Utils.getCurDir()..sep..compiletime_modules_path
Utils.clearFile(compiletime_log)
local runtime_log = Utils.getCurDir()..sep..runtime_modules_path
Utils.clearFile(runtime_log)

---@return any
function require(package_name)
    if not type(package_name) == 'string' then
        error('require function got non string value.', 2)
    end

    if loading_packages[package_name] then
        error('recursive require detected.', 2)
    end

    if not package_name then
        error('Can not find file.', 2)
    end
    package_name = package_name:gsub('[.]+', '.')
    local path = name2path(package_name)
    local log_path
    local packages_list
    if inside_compiletime_function then
        log_path = compiletime_log
        packages_list = compiletime_packages
    else
        log_path = runtime_log
        packages_list = runtime_packages
    end

    if not packages_list[path] then
        if not Utils.fileExists(path) then
            error('Can not find file.', 2)
        end
        Utils.appendFile(path..'\n', log_path)
        packages_list[path] = Utils.readFile(path)
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
        error('Compiletime function can return only string, number or table with strings, numbers and tables. %s:%s', 2)
    end

    local info = debug.getinfo(2, 'lSn')
    local path = info.source:sub(2, #info.source)
    local line = info.currentline

    if runtime_packages[path] then
        table.insert(replace_compiletime.path, path)
        table.insert(replace_compiletime.original, searchCompiletimeInFile(path, line))
        table.insert(replace_compiletime.result, res or 'nil')
    end

    inside_compiletime_function = false

    return res
end

---@param code_src string
---@param map_dst string
---@param map_data string
local function Build(code_src, map_dst, map_data)
    -- Adds code_src to package searching list.
    package.path = package.path..';'..code_src..sep.."?.lua"

    src_dir = code_src..sep
    dst_dir = map_dst..sep

    -- Copy map data to dst
    Utils.copyDir(map_data, map_dst)

    -- Run lua code.
    local success, result = pcall(require, 'init')
    if not success then
        print(result)
        return
    end

    -- Run lua code.
    success, result = pcall(require, 'main')
    if not success then
        print(result)
        return
    end
    -- Run final functions list.
    runFinalize()
    -- Replace Compiletime functions with their values.
    replaceCompiletime()

    -- Adds runtime code.
    local res = Utils.readFile(getCurDir()..sep..'runtime_code.lua')..'\n'
    -- Concat parts.
    for k, v in pairs(runtime_packages) do
        local package = string.format(package_func_code,
                                      path2name(k), v:gsub('\n', '\n\t'))
        res = res..package
    end

    -- Optimaze file size.
    res = optimize(res)
    -- Save
    Utils.writeFile(res, dst_dir..sep..'war3map.lua')
end

Build(arg[1], arg[2], arg[3])