---@class BuildtimeUtils
local Utils = {}

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

---@param src string
---@param dst string
function Utils.enable(src, dst)
    src_dir = src
    dst_dir = dst

    _G.IsGame = _IsGame
    _G.GetSrc = _GetSrc
    _G.GetDst = _GetDst
end

function Utils.disable()
    src_dir = nil
    dst_dir = nil

    _G.IsGame = nil
    _G.GetSrc = nil
    _G.GetDst = nil
end

return Utils