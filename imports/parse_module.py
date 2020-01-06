'''

'''
import os
import platform

import pathlib
from luaparser import ast

from . import lua_code
from . import ast_to_string as ats
from . import find_node
from . import call_lua as cl




def compile_lua(src_path, dst_path):
    # Register compiletime vars and funcs.
    lua = cl.init_lua(src_path)
    cl.execute(lua, 'lua_wc3 = function() ' + lua_code.LUA_COMPILETIME + 'end')
    cl.execute(lua, 'lua_wc3 = lua_wc3()')
    cl.execute(lua, 'lua_wc3.init(\'{0}\', \'{1}\')'.format(src_path, dst_path))
    cl.execute(lua, 'require(\'war3map\')')