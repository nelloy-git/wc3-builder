---@type BuildtimeFinal
local BFinal = require('src.___buildtime.BuildFinal')
---@type BuildtimeMacro
local BMacro = require('src.___buildtime.Macro')
---@type BuildtimeRequire
local BRequire = require('src.___buildtime.Require')
---@type BuildtimeUtils
local BUtils = require('src.___buildtime.Utils')

---@class BuildtimeEnv
local Env = {}

local sep = package.config:sub(1,1)
local package_path

---@param src string
---@param lua_src string
---@param dst string
---@param map_dst string
function Env.enable(src, lua_src, dst, map_dst)
    BUtils.enable(src, map_dst)
    BFinal.enable(lua_src, dst)
    BMacro.enable(lua_src, dst)
    BRequire.enable(lua_src, dst)

    package_path = package.path
    package.path = lua_src..sep.."?.lua"
end

function Env.disable()
    package.path = package_path

    BRequire.disable()
    BFinal.disable()
    BMacro.disable()
    BUtils.disable()
end

---@return table<string, string>
function Env.getUsedFiles()
    local used = BRequire.getPackages()
    BMacro.replace(used)
    return used
end

return Env