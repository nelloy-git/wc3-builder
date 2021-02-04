---@type BuildtimeEnv
local BuildtimeEnv = require('src.___buildtime.Enviroment')
---@type BuilderFile
local File = require('src.File')
---@type BuilderUtils
local Utils = require('src.Utils')

local sep = package.config:sub(1,1)

---@class BuilderBuild
local Build = {}

local __path__ = debug.getinfo(1, "S").source:sub(2)
local __dir__ = File.getFileDir(__path__)
local __map_subdir__ = 'map'

Build.package_template = [[
__required_packages['%s'] = function()
    %s
end
]]

---@param conf BuilderConfig
function Build.start(conf)
    local src = conf["compilerOptions"]['rootDir']
    local dst = conf["compilerOptions"]['outDir']
    local lang = conf["wc3-builder"]['lang']
    local tstl = conf["wc3-builder"]['tstl']

    print('Building started:\n    Src: '..src..'\n    Dst: '..dst..'\n    Lang: '..lang)

    local dst_map = dst..sep..__map_subdir__
    Build.createDirs(dst, dst_map)

    -- Transpile TypeScrypt to lua if nessesary
    local lua_src = src
    if (lang == 'ts') then
        lua_src = dst..sep..'tstl_tmp'
        Build.ts2lua(src, lua_src, tstl)
        Build.copyLua(src, lua_src)
    end

    local used = Build.runBuildtime(src, lua_src, dst, dst_map)

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
    local out_path = dst_map..sep..'war3map.lua'
    File.write(out, out_path)

    print('Building finished.')
end

---@param dst string
---@param dst_map string
function Build.createDirs(dst, dst_map)
    if (not File.isDir(dst)) then
        File.makeDir(dst)
    end

    if (File.isDir(dst_map)) then
        File.removeDir(dst_map)
    end
    File.makeDir(dst_map)
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

---@param src string
---@param lua_src string
function Build.copyLua(src, lua_src)
    if (sep == '/') then
        os.execute('cd '..src..' && find . -name \'*.lua\' -exec cp --parents ./{} ../'..lua_src..' \';\'')
    else
        os.execute('xcopy '..src..'\\*.lua '..lua_src..' /sy > nul')
    end
end

---@param src string
---@param lua_src string
---@param dst string
---@param map_dst string
---@return table<string, string>
function Build.runBuildtime(src, lua_src, dst, map_dst)
    print('Executing buildtime scripts ...')

    BuildtimeEnv.enable(src, lua_src, dst, map_dst)

    -- Start user's script
    require('config')
    require('main')

    local used = BuildtimeEnv.getUsedFiles()

    BuildtimeEnv.disable()

    print('Executing buildtime scripts done.')

    return used
end

---@return string
function Build.getRuntimeTemplate()
    local _utils = File.read(__dir__..sep..'___runtime'..sep..'Utils.lua')
    local _main = File.read(__dir__..sep..'___runtime'..sep..'Main.lua')
    local _buildFinal = File.read(__dir__..sep..'___runtime'..sep..'BuildFinal.lua')
    local _macro = File.read(__dir__..sep..'___runtime'..sep..'Macro.lua')
    local _require = File.read(__dir__..sep..'___runtime'..sep..'Require.lua')

    return _utils..'\n\n'..
           _main..'\n\n'..
           _buildFinal..'\n\n'..
           _macro..'\n\n'..
           _require..'\n\n'
end

---@param out string
function Build.optimize(out)
    out = out:gsub('--%[%b[]%]', '')
    out = out:gsub('%-%-[^\n]*', '')
    out = out:gsub('\n[%s\n\t]*\n', '\n')

    return out
end

return Build