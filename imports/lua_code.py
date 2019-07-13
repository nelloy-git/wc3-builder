'''
    Lua code lib.
'''


LUA_COMPILETIME = \
'''
is_compiletime = true
__compile_data = {
    count = 0,
    result = {}
}

function compiletime(body, ...)
    if is_compiletime == false then
        print('Compiletime function is trying run in runtime')
        return nil
    end
    
    __compile_data.count = __compile_data.count + 1
    if type(body) == \'function\' then
        __compile_data.result[__compile_data.count] = body(...)
    else
        __compile_data.result[__compile_data.count] = body
    end
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