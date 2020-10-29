---@class BuilderUtils
local Utils = {}

local sep = package.config:sub(1,1)

---@param inputstr string
---@param sep string
---@return table
local function split (inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

---@param full_path string
---@return string
local function removeFilename(full_path)
    local pos = full_path:find(sep)
    local last = pos
    while (pos) do
        last = pos
        pos = full_path:find(sep, pos + 1)
    end

    return full_path:sub(1, last - 1)
end

---@return string
function Utils.getCurDir()
    if sep == '/' then
        return '.'
    end
    local full_path = debug.getinfo(2, "S").source:sub(2)
    return removeFilename(full_path)
end

---@param file string
---@return boolean
function Utils.fileExists(file)
    local ok, err, code = os.rename(file, file)
    if not ok then
       if code == 13 then
          -- Permission denied, but it exists
          return true
       end
    end
    return ok, err
end

---@return boolean
function Utils.isDir(path)
    -- "/" works on both Unix and Windows
    return Utils.fileExists(path.."/")
end

---@param src string
---@param dst string
function Utils.copyFile(src, dst)
    if not Utils.fileExists(src) then
        error("File "..src.." is not exist.")
    end

    local infile = io.open(src, "rb")
    local instr = infile:read("*a")
    infile:close()

    local outfile = io.open(dst, "wb")
    outfile:write(instr)
    outfile:close()
end

-- Lua implementation of PHP scandir function
function Utils.scanDir(directory)
    local i, t, popen = 0, {}, io.popen
    local pfile
    if sep == '/' then
        pfile = popen('ls -a "'..directory..'"')
    else
        pfile = popen('dir '..directory..' /b/a')
    end
    for filename in pfile:lines() do
        i = i + 1
        t[i] = filename
    end
    pfile:close()
    return t
end

---@param src string
---@param dst string
function Utils.copyDir(src, dst)
    if not Utils.isDir(dst) then
        os.execute('mkdir '..dst)
    end

    local list = Utils.scanDir(src)
    for i = 1, #list do
        ---@type string
        local name = list[i]
        if Utils.isDir(src..sep..name) then
            Utils.copyDir(src..sep..name, dst..sep..name)
        else
            if Utils.fileExists(src..sep..name) then
                Utils.copyFile(src..sep..name, dst..sep..name)
            end
        end
    end
end

---@param path string
---@return string
function Utils.readFile(path)
    if not Utils.fileExists(path) then
        error("Cannot find file "..path, 2)
    end

    local f = io.open(path)
    local str = f:read("*a")
    f:close()
    return str
end

---@param data string
---@param path string
function Utils.writeFile(data, path)
    local f = io.open(path, "w")
    f:write(data)
    f:close()
end

---@param data string
---@param path string
function Utils.appendFile(data, path)
    if not Utils.fileExists(path) then
        error("Cannot find file "..path, 2)
    end

    local f = io.open(path, "a+")
    f:write(data)
    f:close()
end

---@param val string|number|nil|boolean|table
---@param level number | nil
function Utils.toString(val, level)
    local t = type(val)
    if t == 'string' then
        val = val:gsub('\'', '\\\'')
        val = val:gsub('\\', '\\\\')
        val = val:gsub('%%', '%%%%')
        return '\''..val..'\''
    elseif t == 'number' then
        return tostring(val)
    elseif t == 'nil' then
        return 'NULL'
    elseif t == 'boolean' then
        if val then
            return 'true'
        else
            return 'false'
        end
    elseif t == 'table' then
        local res = '{\n'
        for k, v in pairs(val) do
            res = res..string.format('[%s] = %s,\n',
                                     Utils.toString(k, level and level + 1 or 4),
                                     Utils.toString(v, level and level + 1 or 4))
        end
        return res..'}'
    else
        error('Can not use \''..t..'\' type', level or 4)
    end
end

---@param str string
---@param line number
---@return number
function Utils.findLinePos(str, line)
    local ln = 1
    local pos = 0
    for i = 1, line - 1 do
        pos = string.find(str, '\n', pos + 1)
        ln = ln + 1
    end
    return pos
end

---@param path string
function Utils.clearFile(path)
    local f = io.open(path, 'w')
    f:write('')
    f:close();
end

return Utils