'''
    Lua code lib.
'''


LUA_COMPILETIME = \
'''
is_compiletime = true
__compile_data = {
    cur_module = \'war3map\',
    inside_compiletime_func = false,
    count = 0,
    result = {},
    require_list = {}
}

__original_require = _G.require
function require(module)
    if not __compile_data.inside_compiletime_func then
        table.insert(__compile_data.require_list, module)
    end

    local cur_module = __compile_data.cur_module
    __compile_data.cur_module = module
    res = __original_require(module)
    __compile_data.cur_module = cur_module
    return res
end

function compiletime(body, ...)
    if is_compiletime == false then
        print('Compiletime function is trying run in runtime')
        return nil
    end

    if __compile_data.inside_compiletime_func then
        print(\'Can not run compiletime function inside other compiletim function\')
        return nil
    end

    __compile_data.inside_compiletime_func = true

    local cur_module = __compile_data.cur_module
    if not __compile_data.result[cur_module] then
        __compile_data.result[cur_module] = {}
    end

    if type(body) == \'function\' then
        val = body(...)
    else
        val = body
    end
    table.insert(__compile_data.result[cur_module], val)
    pos = #__compile_data.result[cur_module]
    --print(\'Lua: inside \' .. cur_module, pos, __compile_data.result[cur_module][pos])

    __compile_data.inside_compiletime_func = false
    return val
end
'''


LUA_REQUIRE = \
'''
__require_data = {
    loaded = {},
    module = {},
    result = {}
}

function require(name)
    if not __require_data.loaded[name] then
        __require_data.result[name] = __require_data.module[name]()
        __require_data.loaded[name] = true
    end
    return __require_data.result[name]
end
'''

LUA_PRINT = \
'''
function print(msg)
    if type(msg) == 'number' then
        msg = R2S()
    end
    if type(msg) == 'string' then
        for i = 0, 23 do
            DisplayTextToPlayer(Player(i), 0, 0, msg)
    end
end
'''

LUA_REQUIRE_FUNC = \
    '''
    __require_data.module['name'] = function()
    end
    '''
