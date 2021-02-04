require('src.Utils')

---@class BuilderFile
local File = {}
local sep = package.config:sub(1,1)

function File.isExist(path)
    local ok, err, code = os.rename(path, path)
    if not ok then
       if code == 13 then
          -- Permission denied, but it exists
          return true
       end
    end
    return ok, err
end

---@param path string
---@return string
function File.read(path)
    local f = io.open(path)
    local str = f:read("*a")
    f:close()
    return str
end

---@param data string
---@param path string
function File.write(data, path)
    local f = io.open(path, "w")
    f:write(data)
    f:close()
end

---@param data string
---@param path string
function File.append(data, path)
    local f = io.open(path, "a+")
    f:write(data)
    f:close()
end

---@param path string
---@return string
function File.getFileDir(path)
    return path:sub(1, path:match('^.*()'..sep))
end

---@param path string
function File.runLua(path)
    -- Adds sources to package searching list.
    local package_path = package.path
    package.path = package.path..';'..
                   File.getFileDir(path)..sep.."?.lua"

    local success, result = pcall(dofile, path)
    if not success then
        print(result)
    end

    -- Restore package.path
    package.path = package_path
end

---@param path string
---@return boolean
function File.isDir(path)
    return File.isExist(path..sep)
end

---@param path string
---@return boolean
function File.removeDir(path)
    if (not File.isDir(path)) then
        return false
    end

    -- Clear dst dir.
    if sep == '/' then
        -- Linux
        os.execute('rm -r '..path)
    elseif sep == '\\' then
        -- Windows
        os.execute('rmdir /Q /S '..path)
    end
    return true
end

function File.makeDir(path)
    -- Clear dst dir.
    if sep == '/' then
        -- Linux
        os.execute('mkdir -p '..path)
    elseif sep == '\\' then
        -- Windows
        os.execute('mkdir '..path)
    end
end

return File