---@type BuilderFile
local File = require('src.File')

---@class BuilderRequire
local BuilderRequire = {}
local packages
local current = {}
local src

---@param package_name string
local function registerFile(package_name)
    local sep = package.config:sub(1,1)
    local path = package_name:gsub('%.', sep)..'.lua'

    if not packages[path] then
        if not File.isExist(src..sep..path) then
            error('Can not find file: '..src..sep..path, 3)
        end
        packages[path] = File.read(src..sep..path)
    end
end

local origin_require = _G.require
local loading_packages = {}
---@param package_name string
local function changed_require(package_name)
    if type(package_name) ~= 'string' then
        error('require function got non string value.', 2)
    end

    if loading_packages[package_name] then
        error('recursive require detected.', 2)
    end

    local sep = package.config:sub(1,1)
    local file_path = src..sep..package_name:gsub('%.', sep)..'.lua'
    local dir_path = src..sep..package_name:gsub('%.', sep)
    if not File.isExist(file_path) and
           File.isDir(dir_path) then
        package_name = package_name..'.index'
    end

    registerFile(package_name)

    loading_packages[package_name] = true
    table.insert(current, package_name)
    local res = origin_require(package_name)
    table.remove(current, #current)
    loading_packages[package_name] = nil
    return res
end

---@return table<string, string>
function BuilderRequire.getPackages()
    local copy = {}
    for k,v in pairs(packages) do
        copy[k] = v
    end
    return copy
end

---@param flag boolean
function BuilderRequire.enable(flag, lua_src)
    if flag then
        packages = {}
        src = lua_src
        _G.require = changed_require
        _G.currentPackage = function(depth) return current[#current - (depth or 0)] end
    else
        _G.require = origin_require
    end
end

return BuilderRequire