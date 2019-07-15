'''
    Lua code lib.
'''


LUA_COMPILETIME = \
'''
is_compiletime = true
__compile_data = {
    inside_compiletime_func = false,
    count = 0,
    result = {}
}

__require_list = {}
__original_require = _G.require
function require(module)
    if not __compile_data.inside_compiletime_func then
        table.insert(require_list, module)
    end
    return __original_require(module)
end

__is_inside_compiletime_func = false
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
    __compile_data.count = __compile_data.count + 1
    if type(body) == \'function\' then
        __compile_data.result[__compile_data.count] = body(...)
    else
        __compile_data.result[__compile_data.count] = body
    end
    __compile_data.inside_compiletime_func = false
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


LUA_REQUIRE_FUNC = \
    '''
    __require_data.module['name'] = function()
    end
    '''