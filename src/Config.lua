local sep = package.config:sub(1,1)

---@type BuilderFile
local File = require('src.File')
---@type BuilderJson
local Json = require('src.Json')

local Config = {}
Config.__path__ = debug.getinfo(1, "S").source:sub(2)
Config.__dir__ = File.getFileDir(Config.__path__)

---@param conf_path string
---@return BuilderConfig
function Config.parse(conf_path)
    if not File.isExist(conf_path) then
        error('Can not find config file: '..conf_path)
    end

    print('Reading '..conf_path)
    local str = File.read(conf_path)

    ---@class BuilderConfig
    local json = Json.decode(str)

    if (not File.isDir(json["wc3-builder"].Src)) then
        print('Can not find sources directory. Path: '..json.Src)
        return
    end

    if not (json["wc3-builder"].Lang == 'lua' or json["wc3-builder"].Lang =='ts') then
        print('Got unknown language. \'lua\' and \'ts\' are available only. Lang: \"'..json.Lang..'\"')
        return
    end

    return json
end

return Config