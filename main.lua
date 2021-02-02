local sep = package.config:sub(1,1)
local __path__ = debug.getinfo(1, "S").source:sub(2)
local __dir__ = __path__:sub(1, __path__:match('^.*()'..sep))

-- Add builder dir to packages list
local package_path = package.path
package.path = package.path..';'..__dir__..sep.."?.lua"

---@type BuilderBuild
local Build = require('src.Build')
---@type BuilderConfig
local Config = require('src.Config')
---@type BuilderFile
local File = require('src.File')

local conf_path = arg[1] or './tsconfig.json'

local conf = Config.parse(conf_path)
if (not conf) then return end

conf['compilerOptions']['rootDir'] = conf['compilerOptions']['rootDir'] or 'src'
conf['compilerOptions']['outDir'] = conf['compilerOptions']['outDir'] or 'dst'

if not (conf["wc3-builder"].Lang == 'lua' or conf["wc3-builder"].Lang =='ts') then
    print('Got unknown language. \'lua\' and \'ts\' are available only. Lang: \"'..conf['wc3-builder'].Lang..'\"')
    return
end

Build.start(conf)

package.path = package_path