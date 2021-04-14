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
    if (not f) then
        error('Can not open file '..path)
    end
    local str = f:read("*a")
    f:close()
    return str
end

---@param data string
---@param path string
function File.write(data, path)
    local f = io.open(path, "w")
    if (not f) then
        error('Can not open file '..path)
    end
    f:write(data)
    f:close()
end

---@param data string
---@param path string
function File.append(data, path)
    local f = io.open(path, "a+")
    if (not f) then
        error('Can not open file '..path)
    end
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

function File.scanDir(dir)
    local p = io.popen('dir /s /b /o "'..dir..'"')  --Open directory look for files, save data in p. By giving '-type f' as parameter, it returns all files.     
    return p:lines()
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
        if (File.isDir(path)) then
            local files = File.scanDir(path)
            for file in files do
                os.remove(file)
            end
        end

        os.remove(path)
    end
    return true
end

function File.makeDir(path)
    if (File.isDir(path)) then
        return
    end

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