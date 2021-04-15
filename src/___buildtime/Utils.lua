---@class BuildtimeUtils
local Utils = {}

local sep = package.config:sub(1, 1)

local src_dir
local dst_dir

---@return boolean
local function _IsGame()
    return false
end

---@return string|nil
local function _GetSrc()
    return src_dir
end

---@return string|nil
local function _GetDst()
    return dst_dir
end

---@return string
local function _getFilePath()
    local cur = getLoadingPackage() ---@type string

    if (not cur) then
        return error('Can not get loading package.')
    end

    return _GetSrc()..'/'..cur:gsub('%.', '/')..'.lua'
end

---@return string
local function _getFileDir()
    local file_path = _getFilePath()
    local last = file_path:find("/[^/]*$")
    return file_path:sub(1, last)
end

---@param src string
---@param dst string
function Utils.enable(src, dst)
    src_dir = src:gsub('/', sep):gsub('\\', sep)
    dst_dir = dst:gsub('/', sep):gsub('\\', sep)

    _G.IsGame = _IsGame
    _G.GetSrc = _GetSrc
    _G.GetDst = _GetDst
    _G.getFilePath = _getFilePath
    _G.getFileDir = _getFileDir
end

function Utils.disable()
    src_dir = nil
    dst_dir = nil

    _G.IsGame = nil
    _G.GetSrc = nil
    _G.GetDst = nil
    _G.getFilePath = nil
    _G.getFileDir = nil
end

return Utils