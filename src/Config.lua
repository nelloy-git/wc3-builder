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
        local conf = File.read(Config.__dir__..sep..'conf.json')
        File.write(conf, conf_path)
    end

    print('Reading '..conf_path)
    local str = File.read(conf_path)

    ---@class BuilderConfig
    ---@field Src string
    ---@field Dst string
    ---@field Lang string|"'lua'"|"'ts'"
    ---@field Tstl string|nil
    local json = Json.decode(str)

    if (not File.isDir(json.Src)) then
        print('Can not find sources directory. Path: '..json.Src)
        return
    end

    if not (json.Lang == 'lua' or json.Lang =='ts') then
        print('Got unknown language. \'lua\' and \'ts\' are available only. Lang: \"'..json.Lang..'\"')
        return
    end

    return json
end

return Config