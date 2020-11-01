---@class BuildtimeFileUtils
local BuildtimeFileUtils = {}

local sep = package.config:sub(1,1)

---@param path string
---@return boolean
function BuildtimeFileUtils.isExist(path)
    local ok, err, code = os.rename(path, path)
    if not ok then
       if code == 13 then
          -- Permission denied, but it exists
          return true
       end
    end
    return ok, err
end

function BuildtimeFileUtils.getFileDir(path)
    return path:sub(1, path:match('^.*()'..sep))
end

function BuildtimeFileUtils.runLua(path)
    -- Adds sources to package searching list.
    local package_path = package.path
    package.path = package.path..';'..
                   BuildtimeFileUtils.getFileDir(path)..sep.."?.lua"

    local success, result = pcall(dofile, path)
    if not success then
        print(result)
    end

    -- Restore package.path
    package.path = package_path
end

---@param path string
---@return string
function BuildtimeFileUtils.readFile(path)
    local f = io.open(path)
    local str = f:read("*a")
    f:close()
    return str
end

---@param data string
---@param path string
function BuildtimeFileUtils.writeFile(data, path)
    local f = io.open(path, "w")
    f:write(data)
    f:close()
end

---@param data string
---@param path string
function BuildtimeFileUtils.appendFile(data, path)
    local f = io.open(path, "a+")
    f:write(data)
    f:close()
end

return BuildtimeFileUtils