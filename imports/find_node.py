'''
    Ast to string convertion functions.
'''

from luaparser import ast

def change_node(tree, src, dst):
    attr_list = dir(tree)
    for attr in attr_list:
        if attr.startswith('__'):
            continue

        val = getattr(tree, attr)
        if val == src:
            setattr(tree, attr, dst)
            val = getattr(tree, attr)

        if isinstance(val, ast.Node):
            change_node(val, src, dst)

        if type(val) == list:
            for i, elem in enumerate(val):
                if elem == src:
                    val[i] = dst
                    elem = dst

                if isinstance(elem, ast.Node):
                    change_node(elem, src, dst)