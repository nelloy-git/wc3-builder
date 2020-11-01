---@type BuildtimeFileUtils
local BuildtimeFileUtils = require('Buildtime.FileUtils')

---@class BuildtimeRequire
local BuildtimeRequire = {}
local packages
local src

---@param package_name string
local function registerFile(package_name)
    local sep = package.config:sub(1,1)
    local path = package_name:gsub('%.', sep)..'.lua'

    if not packages[path] then
        if not BuildtimeFileUtils.isExist(src..sep..path) then
            error('Can not find file: '..src..sep..path, 3)
        end
        packages[path] = BuildtimeFileUtils.readFile(src..sep..path)
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

    registerFile(package_name)

    loading_packages[package_name] = true
    local res = origin_require(package_name)
    loading_packages[package_name] = nil
    return res
end

---@return table<string, string>
function BuildtimeRequire.getPackages()
    local copy = {}
    for k,v in pairs(packages) do
        copy[k] = v
    end
    return copy
end

---@param flag boolean
---@param src_dir string | nil
function BuildtimeRequire.enable(flag, src_dir)
    src = src_dir

    if flag then
        packages = {}
        _G.require = changed_require
        _G.fake_require = origin_require
    else
        _G.require = origin_require
        _G.fake_require = nil
    end
end

return BuildtimeRequire