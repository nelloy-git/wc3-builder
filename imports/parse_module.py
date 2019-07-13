'''

'''
import os

import pathlib
from luaparser import ast

from . import lua_code
from . import ast_to_string as ats
from . import find_node
from . import call_lua as cl
import copy


def read_content(main_path, src_dir, file_list, content_list):
    '''
        Function reads content of all required modules.
          main_path    - relative path inside source directory
          src_dir      - path of source directory
          file_list    - list to add requireed files
          content_list - list to add file content (ast tree)

        Returns files list, contents list including the module.
    '''

    # Read file.
    full_src_path = os.path.join(src_dir, main_path)
    with open(full_src_path, 'r') as file:
        module = file.read()
    tree = ast.parse(module)

    file_list.append(main_path)
    content_list.append(tree)
    # Searching depencies.
    for node in ast.walk(tree):
        if isinstance(node, ast.Call) and ats.node_to_str(node.func) == 'require':
            if len(node.args) != 1 or not isinstance(node.args[0], ast.String):
                print('Error: require function can have only one constant string argument.')
                raise SystemExit

            # Prepare depency.
            path = ats.name_to_module_path(node.args[0].s)
            if path in file_list:
                continue
            read_content(path, src_dir, file_list, content_list)


def get_contents(main_path, src_dir):
    file_list = []
    content_list = []
    read_content(main_path, src_dir, file_list, content_list)
    file_list.reverse()
    content_list.reverse()
    return file_list, content_list


def content_to_function(file_path, content):
    module_name = file_path[:-4].replace('/', '.')
    res = content
    if module_name != 'war3map':
        func_tree = ast.parse(lua_code.LUA_REQUIRE_FUNC).body.body[0]
        func_tree.values[0].body = content.body
        func_tree.targets[0].idx = ast.String(module_name)
        res = func_tree
    return res


def fix_content_return(file_path, content):
    module_name = ats.path_to_module_name(file_path)
    for pos, node in enumerate(content.body.body):
        if isinstance(node, ast.Return):
            func = ast.Function(ast.Name(str(module_name) + '_return'), [], node.body)
            content.body.body.pop(pos)
            #content.body.body[pos] = func
            content.body.body.append(func)


def compiletime_execution(content, src_path):
    # Run module to get compiletime results list.
    lua = cl.init_lua(src_path)
    compiletime_tree = ast.parse(lua_code.LUA_COMPILETIME)
    cl.execute(lua, ats.node_to_str(compiletime_tree))
    cl.execute(lua, ats.node_to_str(content))

    # Get compiletime results.
    tree_visitor = ast.WalkVisitor()
    tree_visitor.visit(content)
    num = 0
    for node in tree_visitor.nodes:
        if isinstance(node, ast.Call) and ats.node_to_str(node.func) == 'compiletime':
            #val = cl.eval(lua, ats.node_to_str(ast.Block(node.args)))
            num += 1
            val = cl.get_compile_res(lua, num)
            find_node.change_node(content, node, val)
            #print(ats.node_to_str(val))
    #print('\n\n')
    #print(ats.node_to_str(content))


def add_extension_functions(file_list, content_list):
    require_tree = ast.parse(lua_code.LUA_REQUIRE)
    content_list.insert(0, require_tree)
    file_list.insert(0, 'Require function')


def link_content(content_list):
    block = ast.Block(content_list)
    return block

