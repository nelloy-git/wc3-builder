---@type BuilderFile
local File = require('src.File')

---@class BuildtimeRequire
local BuilderRequire = {}
local packages
local current = {}
local src_dir
local dst_dir

---@param package_name string
local function registerFile(package_name)
    local sep = package.config:sub(1,1)
    local path = package_name:gsub('%.', sep)..'.lua'

    if not packages[path] then
        if not File.isExist(src_dir..sep..path) then
            error('Can not find file: '..src_dir..sep..path, 3)
        end
        packages[path] = File.read(src_dir..sep..path)
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
        print('=====================')
        for i = 1, #current do
            print(current[i])
        end
        print('=====================')
        error('recursive require detected.', 2)
    end

    local sep = package.config:sub(1,1)
    local file_path = src_dir..sep..package_name:gsub('%.', sep)..'.lua'
    local dir_path = src_dir..sep..package_name:gsub('%.', sep)
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

function BuilderRequire.getLoadingPackage(depth)
    return current[#current - (depth or 0)]
end

---@param src string
---@param dst string
function BuilderRequire.enable(src, dst)
    packages = {}
    src_dir = src
    dst_dir = dst

    _G.require = changed_require
    _G.getLoadingPackage = BuilderRequire.getLoadingPackage
end

function BuilderRequire.disable()
    src_dir = nil
    dst_dir = nil

    _G.require = origin_require
end

return BuilderRequire