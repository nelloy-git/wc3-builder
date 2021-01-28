local Utils = require('src.Utils')

if (IsGame()) then
    return {}
end

---@type BuilderFile
local File = require('src.File')
local sep = package.config:sub(1,1)

---@class BuilderBuild
local Build = {}

Build.__path__ = debug.getinfo(0, "S").source:sub(2)
Build.__MAP_SUBDIR__ = 'map'

---@param conf BuilderConfig
function Build.start(conf)
    local src = conf.Src
    local dst = conf.Dst
    local lang = conf.Lang
    local tstl = conf.Tstl

    print('Building started:\n    Src: '..src..'\n    Dst: '..dst..'\n    Lang: '..lang)

    if (src:sub(#src) == sep) then src = src:sub(1, #src - 1) end
    if (dst:sub(#dst) == sep) then dst = dst:sub(1, #dst - 1) end

    Utils.SetSrc(src)
    Utils.SetDst(dst)

    if (File.isDir(dst)) then
        File.removeDir(dst)
    end
    File.makeDir(dst)

    local lua_src = src
    if (conf.Lang == 'ts') then
        lua_src = dst..sep..'tstl_tmp'
        Build.ts2lua(src, lua_src, tstl)
    end


end

---@param src string
---@param dst string
---@param tstl string
function Build.ts2lua(src, dst, tstl)
    print('Building Lua from TypeScript')
    File.makeDir(dst)
    os.execute ('node '..tstl..
                    ' --experimentalDecorators'..
                    ' --rootDir '..src..
                    ' --outDir '..dst)
end

return Build