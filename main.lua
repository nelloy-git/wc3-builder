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

local conf_path = arg[1] or './tsconfig.json'
Build.start(Config.parse(conf_path))

package.path = package_path