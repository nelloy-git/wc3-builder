local sep = package.config:sub(1,1)

---@type BuilderFile
local File = require('src.File')
---@type BuilderJson
local Json = require('src.Json')

---@class BuilderConfig
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
    local json = Json.decode(str)

    json["compilerOptions"] = json["compilerOptions"] or {}
    json["compilerOptions"]['rootDir'] = json["compilerOptions"]['rootDir'] or 'src'
    json["compilerOptions"]['outDir'] = json["compilerOptions"]['outDir'] or 'dst'

    json["wc3-builder"] = json["wc3-builder"] or {}
    json["wc3-builder"]['lang'] = json["wc3-builder"].lang or 'lua'
    json["wc3-builder"]['tstl'] = json["wc3-builder"].tstl or "./node_modules/typescript-to-lua/dist/tstl.js"

    return json
end

return Config