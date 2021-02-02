local sep = package.config:sub(1,1)

---@type BuilderFile
local File = require('src.File')
---@type BuilderJson
local Json = require('src.Json')

local Config = {}
Config.__path__ = debug.getinfo(1, "S").source:sub(2)
Config.__dir__ = File.getFileDir(Config.__path__)

---@param conf_path string
---@return table
function Config.parse(conf_path)
    if not File.isExist(conf_path) then
        error('Can not find config file: '..conf_path)
    end

    print('Reading '..conf_path)
    local str = File.read(conf_path)

    return Json.decode(str)
end

return Config