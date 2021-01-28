local Utils = require('src.Utils')

if (IsGame()) then
    return {}
end

---@type BuilderFile
local File = require('src.File')

---@type BuilderBuildFinal
local BuilderFinal = require('src.buildtime.BuildFinal')
---@type BuilderMacro
local BuiderMacro = require('src.buildtime.Macro')
---@type BuilderRequire
local BuilderRequire = require('src.buildtime.Require')

local sep = package.config:sub(1,1)

---@class BuilderBuild
local Build = {}

Build.__path__ = debug.getinfo(1, "S").source:sub(2)
Build.__dir__ = File.getFileDir(Build.__path__)
Build.__MAP_SUBDIR__ = 'map'

Build.package_template = [[
__required_packages['%s'] = function()
    %s
end
]]

---@param conf BuilderConfig
function Build.start(conf)
    local src = conf.Src
    local dst = conf.Dst
    local lang = conf.Lang
    local tstl = conf.Tstl

    print('Building started:\n    Src: '..src..'\n    Dst: '..dst..'\n    Lang: '..lang)

    Build.initUtils(src, dst)

    if (not File.isDir(dst)) then
        File.makeDir(dst)
    end

    local map_dir = dst..sep..Build.__MAP_SUBDIR__
    if (File.isDir(map_dir)) then
        File.removeDir(map_dir)
    end
    File.makeDir(map_dir)

    local lua_src = src
    if (conf.Lang == 'ts') then
        lua_src = dst..sep..'tstl_tmp'
        Build.ts2lua(src, lua_src, tstl)
    end

    Build.runBuildtime(lua_src)

    -- Get list of used files
    local used = BuilderRequire.getPackages()
    -- Replace macros in used packages
    BuiderMacro.replace(used)

    -- Generate output file.
    local out = Build.getRuntimeTemplate()
    for path, context in Utils.pairsByKeys(used) do
        -- Convert path to lua package format
        local name = path:sub(1, #path - 4):gsub(sep, '.')
        local ctx = context:gsub('\n', '\n\t')

        -- print(name)
        out = out..'\n\n'..Build.package_template:format(name, ctx)
    end
    Build.optimize(out)

    -- Save to map_dir
    local out_path = map_dir..sep..'war3map.lua'
    File.write(out, out_path)

    print('Building finished.')
end

---@param src string
---@param dst string
function Build.initUtils(src, dst)
    dst = dst..sep..Build.__MAP_SUBDIR__

    if (src:sub(#src) == sep) then src = src:sub(1, #src - 1) end
    if (dst:sub(#dst) == sep) then dst = dst:sub(1, #dst - 1) end

    Utils.SetSrc(src)
    Utils.SetDst(dst)
end

---@param src string
---@param dst string
---@param tstl string
function Build.ts2lua(src, dst, tstl)
    print('Building Lua from TypeScript ...')

    if (File.isDir(dst)) then
        File.removeDir(dst)
    end
    File.makeDir(dst)

    os.execute ('node '..tstl..
                    ' --experimentalDecorators'..
                    ' --rootDir '..src..
                    ' --outDir '..dst)

    print('Building Lua from TypeScript done.\n')
end

---@param lua_src string
function Build.runBuildtime(lua_src)
    print('Executing buildtime scripts ...')

    Build.enableAPI(true, lua_src)
    -- Start user's script
    local package_path = package.path
    package.path = lua_src..sep.."?.lua"
    require('config')
    require('main')
    package.path = package_path
    -- Finished
    Build.enableAPI(false)

    print('Executing buildtime scripts done.')
end

---@param flag boolean
---@param lua_src string
function Build.enableAPI(flag, lua_src)
    BuilderFinal.enable(flag)
    BuilderRequire.enable(flag, lua_src)
    BuiderMacro.enable(flag, lua_src)
end

---@return string
function Build.getRuntimeTemplate()
    local dir = Build.__dir__

    local _utils = File.read(dir..sep..'runtime'..sep..'Utils.lua')
    local _main = File.read(dir..sep..'runtime'..sep..'Main.lua')
    local _buildFinal = File.read(dir..sep..'runtime'..sep..'BuildFinal.lua')
    local _macro = File.read(dir..sep..'runtime'..sep..'Macro.lua')
    local _require = File.read(dir..sep..'runtime'..sep..'Require.lua')

    return _utils..'\n\n'..
           _main..'\n\n'..
           _buildFinal..'\n\n'..
           _macro..'\n\n'..
           _require..'\n\n'
end

---@param out  string
function Build.optimize(out)
    out = out:gsub('--%[%b[]%]', '')
    out = out:gsub('%-%-[^\n]*', '')
    out = out:gsub('\n[%s\n\t]*\n', '\n')

    return out
end

return Build