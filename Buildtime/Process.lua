
---@type BuildtimeBuildFinal
local BuildtimeBuildFinal = require('Buildtime.BuildFinal')
---@type BuildtimeFileUtils
local BuildtimeFileUtils = require('Buildtime.FileUtils')
---@type BuildtimeMacro
local BuildtimeMacro = require('Buildtime.Macro')
---@type BuildtimeRequire
local BuildtimeRequire = require('Buildtime.Require')

local BuildtimeProcess = {}

local dst_dir = 'map_dir'
local dst_mpq = 'map_mpq'
local log_name = 'used_files.txt'
local map_src
local map_dst
local package_template = [[
__required_packages['%s'] = function()
    %s
end
]]

---@param data nil | boolean | number | string | table
---@param log integer
local function toString(data, log)
    local t = type(data)
    if t == 'string' then
        if data == 'nil' then
            error('BuilderMacro: can not return string \'nil\'', log or 4)
        end

        data = data:gsub('\'', '\\\'')
        data = data:gsub('\\', '\\\\')
        data = data:gsub('%%', '%%%%')
        return '\''..data..'\''
    elseif t == 'number' then
        return tostring(data)
    elseif t == 'nil' then
        return 'nil'
    elseif t == 'boolean' then
        if data then
            return 'true'
        else
            return 'false'
        end
    elseif t == 'table' then
        local res = '{\n'
        for k, v in pairs(data) do
            res = res..string.format('[%s] = %s,\n',
                                     toString(k, log and log + 1 or 4),
                                     toString(v, log and log + 1 or 4))
        end
        return res..'}'
    else
        error('Can not use \''..t..'\' type', log or 4)
    end
end

local function replaceMacro(file_list, macro_list)
    for i = 1, #macro_list do
        local macro_data = macro_list[i]
        local path = macro_data.path

        if file_list[path] then
            local origin = macro_data.origin:gsub("[%(%)%.%%%+%-%*%?%[%^%$%]]", "%%%1")
            local result = macro_data.result

            local success, s_data = pcall(toString, result)
            if not success then
                error('BuilderMacro: error in Macro:\n'..s_data, 1)
            end

            s_data = (s_data == 'nil') and '' or s_data
            file_list[path] = string.gsub(file_list[path], origin, s_data, 1)
        end
    end
end

local function enableAPI(flag, lua_src)
    BuildtimeRequire.enable(flag, lua_src)
    BuildtimeBuildFinal.enable(flag)
    BuildtimeMacro.enable(flag, lua_src)

    if flag then
        IsGame = function() return false end
        GetSrc = function() return map_src end
        GetDst = function() return map_dst..package.config:sub(1,1)..dst_dir end
    else
        IsGame = nil
        GetSrc = nil
        GetDst = nil
    end
end

local function pairsByKeys (t, f)
    local a = {}
    for n in pairs(t) do
        table.insert(a, n)
    end
    table.sort(a, f)
    local i = 0      -- iterator variable
    local iter = function ()   -- iterator function
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i], t[a[i]]
        end
    end
    return iter
end

---@param src string
---@param dst string
---@param lang string "'lua'" | "'ts'"
function BuildtimeProcess.build(src, dst, lang)
    map_src = src
    map_dst = dst

    local sep = package.config:sub(1,1)
    local this_file_path = debug.getinfo(2, "S").source:sub(2)
    local this_dir_path = this_file_path:sub(1, this_file_path:match('^.*()'..sep))

    print('Building started.')

    -- Clear dst dir.
    if sep == '/' then
        -- Linux
        os.execute('rm -r '..dst..sep..dst_dir)
    elseif sep == '\\' then
        -- Windows
        os.execute('rmdir /Q /S '..dst..sep..dst_dir)
    end
    -- os.execute('mkdir '..dst)
    os.execute('mkdir '..dst..sep..dst_dir)

    local lua_src
    if lang == 'ts' then
        print('Compiling TypeScript')
        lua_src = dst..sep..'tmp_lua'
        if (not BuildtimeFileUtils.isExist(lua_src)) then
            os.execute('mkdir '..lua_src)
        end
        os.execute ('node ./node_modules/typescript-to-lua/dist/tstl.js '..
                        '--experimentalDecorators '..
                        '--rootDir '..src..' '..
                        '--outDir '..map_dst..sep..'tmp_lua')
        print('Done')
    else
        lua_src = src
    end

    enableAPI(true, lua_src)
    -- Start user's script
    local package_path = package.path
    package.path = lua_src..sep.."?.lua"
    require('config')
    require('main')
    package.path = package_path
    -- Finished
    enableAPI(false, false)

    -- Replace macros in used packages
    local packages = BuildtimeRequire.getPackages()
    local macros = BuildtimeMacro.getMacroList()
    replaceMacro(packages, macros)

    -- Prepare runtime scripts.
    local builder_dir = this_dir_path:sub(1, this_file_path:match('^.*()'..sep))
    local buildFinal_runtime = BuildtimeFileUtils.readFile(builder_dir..sep..'Runtime'..sep..'BuildFinal.lua')
    local default_runtime = BuildtimeFileUtils.readFile(builder_dir..sep..'Runtime'..sep..'Default.lua')
    local macro_runtime = BuildtimeFileUtils.readFile(builder_dir..sep..'Runtime'..sep..'Macro.lua')
    local require_runtime = BuildtimeFileUtils.readFile(builder_dir..sep..'Runtime'..sep..'Require.lua')

    -- Generate output file
    local output = default_runtime..'\n\n'..
                   require_runtime..'\n\n'..
                   macro_runtime..'\n\n'..
                   buildFinal_runtime
    BuildtimeFileUtils.writeFile('List of used packages:', dst..sep..log_name)
    for path, context in pairsByKeys(packages) do
        local package_name = path:sub(1, #path - 4):gsub(sep, '.')
        local package_context = context:gsub('\n', '\n\t')

        output = output..'\n\n'..package_template:format(package_name, package_context)
        BuildtimeFileUtils.appendFile('\n\t'..package_name, dst..sep..log_name)
    end

    -- Some optimizations
    output = output:gsub('--%[%b[]%]', '')
    output = output:gsub('%-%-[^\n]*', '')
    output = output:gsub('\n[%s\n\t]*\n', '\n')

    -- Save to map_dir
    local out_path = dst..sep..dst_dir..sep..'war3map.lua'
    BuildtimeFileUtils.writeFile(output, out_path)

    if lang == 'ts' then
        --os.execute ((sep == '/' and 'rm -r ' or 'rmdir /Q /S ')..dst..sep..'tmp_lua')
    end

    print('Building finished.')
end

return BuildtimeProcess