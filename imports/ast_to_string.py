'''
    Ast to string convertion functions.
'''

from luaparser import ast


def chunk_to_str(node, lvl):
    ''' Converts ast.Chunk to str. '''
    return node_to_str(node.body, lvl)


def block_to_str(node, lvl=0):
    ''' Converts ast.Block to str. '''
    res = ''
    for line in node.body:
        res += '  ' * lvl + node_to_str(line, lvl + 1) + '\n'
    res = res[:-1]
    return res


def name_to_str(node, _):
    ''' Converts ast.Name to str. '''
    return node.id


def index_to_str(node, lvl):
    ''' Converts ast.Index to str. '''
    if isinstance(node.idx, ast.String):
        if '.' in node.idx.s:
            return node_to_str(node.value, lvl) + '[' + node_to_str(node.idx, lvl) + ']'
        return node_to_str(node.value, lvl) + '.' + node_to_str(node.idx, lvl)[1:-1]
    #if isinstance(node.idx, ast.Name):
        #return node_to_str(node.value, lvl) + '.' + node_to_str(node.idx, lvl)
    return node_to_str(node.value, lvl) + '[' + node_to_str(node.idx, lvl) + ']'


def assign_to_str(node, lvl):
    ''' Converts ast.Assign to str. '''
    s_targ = ''
    for targ in node.targets:
        s_targ += node_to_str(targ, lvl) + ', '
    s_targ = s_targ[:-2]

    s_val = ''
    for val in node.values:
        s_val += node_to_str(val, lvl) + ', '
    s_val = s_val[:-2]

    if s_val != '':
        s_targ += ' = '

    return s_targ + s_val


def loc_assign_to_str(node, lvl):
    ''' Converts ast.LocalAssign to str. '''
    s_targ = ''
    for targ in node.targets:
        s_targ += node_to_str(targ, lvl) + ', '
    s_targ = s_targ[:-2]

    s_val = ''
    for val in node.values:
        s_val += node_to_str(val, lvl) + ', '
    s_val = s_val[:-2]

    if s_val != '':
        s_targ += ' = '

    return 'local ' + s_targ + s_val


def while_to_str(node, lvl):
    ''' Converts ast.While to str. '''
    return 'while(' + node_to_str(node.test) + ') do\n' + \
            node_to_str(node.body, lvl) + '\n' + ('  ' * (lvl-1)) + 'end'


def do_to_str(node, lvl):
    ''' Converts ast.Do to str. '''
    return 'do\n' + node_to_str(node, lvl) + '\n' + ('  ' * (lvl-1)) + 'end'


def repeat_to_str(node, lvl):
    ''' Converts ast.Repeat to str. '''
    return 'repeat\n' + node_to_str(node.body, lvl) + '\n' + \
            ('  ' * (lvl-1)) + 'until(' + node_to_str(node.test, lvl) + ')'


def else_if_to_str(node, lvl):
    ''' Converts ast.ElseIf to str. '''
    s_if = 'elseif (' + node_to_str(node.test, lvl) + ') then\n' + \
            node_to_str(node.body, lvl) + '\n' + ('  ' * (lvl-1))
    if node.orelse is not None:
        if isinstance(node.orelse, ast.ElseIf):
            s_if += node_to_str(node.orelse, lvl) + '\n'
        else:
            s_if += 'else\n' + node_to_str(node.orelse, lvl) + '\n'
            s_if += ('  ' * (lvl-1)) + 'end'
    else:
        s_if += 'end'
    return s_if


def if_to_str(node, lvl):
    ''' Converts ast.If to str. '''
    s_if = 'if (' + node_to_str(node.test, lvl) + ') then\n' + \
            node_to_str(node.body, lvl) + '\n' + ('  ' * (lvl-1))
    if node.orelse is not None:
        if isinstance(node.orelse, ast.ElseIf):
            s_if += node_to_str(node.orelse, lvl) + '\n'
        else:
            s_if += 'else\n' + node_to_str(node.orelse, lvl) + '\n'
            s_if += ('  ' * (lvl-1)) + 'end'
    else:
        s_if += 'end'
    return s_if


def label_to_str(node, _):
    ''' Converts ast.Label to str. '''
    return '::' + node.id + '::'


def goto_to_str(node, lvl):
    ''' Converts ast.Goto to str. '''
    return 'goto ' + node_to_str(node.label, lvl)


def semicolon_to_str(_node, _lvl):
    ''' Converts ast.SemiColon to str. '''
    return ''


def break_to_str(_node, _lvl):
    ''' Converts ast.Break to str. '''
    return 'break'


def return_to_str(node, lvl):
    ''' Converts ast.Return to str. '''
    s_val = ''
    for val in node.values:
        s_val += node_to_str(val, lvl) + ', '
    s_val = s_val[:-2]

    return 'return ' + s_val


def fornum_to_str(node, lvl):
    ''' Converts ast.Fornum to str. '''
    s_for = 'for ' + node_to_str(node.target, lvl) + ' = ' + node_to_str(node.start, lvl) + \
            ', ' + node_to_str(node.stop, lvl)
    if node.step != 1:
        s_for += ', ' + node_to_str(node.step, lvl)
    s_for += ' do\n' + node_to_str(node.body, lvl) + '\n' + ('  ' * (lvl-1)) + 'end'
    return s_for


def forin_to_str(node, lvl):
    ''' Converts ast.Forin to str. '''
    s_for = 'for ' + node_to_str(node.targets, lvl) + ' in ' + node_to_str(node.iter) + ' do\n' + \
            node_to_str(node.body, lvl) + '\n' + ('  ' * (lvl-1)) + 'end'
    return s_for


def call_to_str(node, lvl):
    ''' Converts ast.Call to str. '''
    s_arg = ''
    for arg in node.args:
        s_arg += node_to_str(arg, lvl) + ', '
    s_arg = s_arg[:-2]
    return node_to_str(node.func, lvl) + '(' + s_arg + ')'


def invoke_to_str(node, lvl):
    ''' Converts ast.invoke to str. '''
    s_arg = ''
    for arg in node.args:
        s_arg += node_to_str(arg, lvl) + ', '
    s_arg = s_arg[:-2]

    return node_to_str(node.source, lvl) + ':' + node_to_str(node.func, lvl) + '(' + s_arg + ')'


def func_to_str(node, lvl):
    ''' Converts ast.Function to str. '''
    s_arg = ''
    for arg in node.args:
        s_arg += node_to_str(arg) + ', '
    s_arg = s_arg[:-2]
    return 'function ' + node_to_str(node.name, lvl) + '(' + s_arg + ')\n' + \
            node_to_str(node.body, lvl) + '\n' + ('  ' * (lvl-1)) + 'end'


def loc_func_to_str(node, lvl):
    ''' Converts ast.LocalFunction to str. '''
    s_arg = ''
    for arg in node.args:
        s_arg += node_to_str(arg) + ', '
    s_arg = s_arg[:-2]
    return 'local function ' + node_to_str(node.name, lvl) + '(' + s_arg + ')\n' + \
            node_to_str(node.body, lvl) + '\n' + ('  ' * (lvl-1)) + 'end'


def method_to_str(node, lvl):
    ''' Converts ast.Method to str. '''
    s_arg = ''
    for arg in node.args:
        s_arg += node_to_str(arg) + ', '
    s_arg = s_arg[:-2]
    return 'function ' + node_to_str(node.source, lvl) + ':' + node_to_str(node.name, lvl) + \
            '(' + s_arg + ')\n' + node_to_str(node.body, lvl) + '\n' + ('  ' * (lvl-1)) + 'end'


def nil_to_str(_node, _lvl):
    ''' Converts ast.Nil to str. '''
    return 'nil'


def true_expr_to_str(_node, _lvl):
    ''' Converts ast.TrueExpr to str. '''
    return 'true'


def false_expr_to_str(_node, _lvl):
    ''' Converts ast.TrueExpr to str. '''
    return 'false'


def number_to_str(node, _lvl):
    ''' Converts ast.Number to str. '''
    return str(node.n)


def varargs_to_str(_node, _lvl):
    ''' Converts ast.Varargs to str. '''
    return '...'


def string_to_str(node, _lvl):
    ''' Converts ast.String to str. '''
    return '\"' + node.s + '\"'


def field_to_str(node, _lvl):
    ''' Converts ast.Field to str. '''
    return node_to_str(node.key) + ' = ' + node_to_str(node.value)


def table_to_str(node, lvl):
    ''' Converts ast.Table to str. '''
    s_fields = ''
    for field in node.fields:
        s_fields += node_to_str(field, lvl) + ', '
    s_fields = s_fields[:-2]
    return '{' + s_fields + '}'


def dots_to_str(_node, _lvl):
    ''' Converts ast.Dots to str. '''
    return 'Can not parse dots'


def anon_func_to_str(node, lvl):
    ''' Converts ast.AnonymousFunction to str. '''
    s_arg = ''
    for arg in node.args:
        s_arg += node_to_str(arg) + ', '
    s_arg = s_arg[:-2]

    return 'function(' + s_arg + ')\n' + node_to_str(node.body, lvl + 1) + '\n' + \
            ('  ' * (lvl-1)) + 'end'


def add_to_str(node, lvl):
    ''' Converts ast.AddOp to str. '''
    return node_to_str(node.left, lvl) + '+' + node_to_str(node.right, lvl)


def sub_to_str(node, lvl):
    ''' Converts ast.SubOp to str. '''
    return node_to_str(node.left, lvl) + '-' + node_to_str(node.right, lvl)


def mult_to_str(node, lvl):
    ''' Converts ast.MultOp to str. '''
    return node_to_str(node.left, lvl) + '*' + node_to_str(node.right, lvl)


def float_div_to_str(node, lvl):
    ''' Converts ast.FloatDivOp to str. '''
    return node_to_str(node.left, lvl) + '/' + node_to_str(node.right, lvl)


def floor_div_to_str(node, lvl):
    ''' Converts ast.FloorDivOp to str. '''
    return node_to_str(node.left, lvl) + '//' + node_to_str(node.right, lvl)


def mod_to_str(node, lvl):
    ''' Converts ast.ModOp to str. '''
    return node_to_str(node.left, lvl) + '%' + node_to_str(node.right, lvl)


def expo_to_str(node, lvl):
    ''' Converts ast.Dots to str. '''
    return node_to_str(node.left, lvl) + '^' + node_to_str(node.right, lvl)


def and_bit_to_str(node, lvl):
    ''' Converts ast.BandOp to str. '''
    return node_to_str(node.left, lvl) + '&' + node_to_str(node.right, lvl)


def or_bit_to_str(node, lvl):
    ''' Converts ast.BorOp to str. '''
    return node_to_str(node.left, lvl) + '|' + node_to_str(node.right, lvl)


def xor_bit_to_str(node, lvl):
    ''' Converts ast.BxorOp to str. '''
    return node_to_str(node.left, lvl) + '^^' + node_to_str(node.right, lvl)


def shiftr_bit_to_str(node, lvl):
    ''' Converts ast.BshiftROp to str. '''
    return node_to_str(node.left, lvl) + ' >> ' + node_to_str(node.right, lvl)


def shiftl_bit_to_str(node, lvl):
    ''' Converts ast.BshiftLOp to str. '''
    return node_to_str(node.left, lvl) + ' << ' + node_to_str(node.right, lvl)


def less_to_str(node, lvl):
    ''' Converts ast.LessThanOp to str. '''
    return node_to_str(node.left, lvl) + ' < ' + node_to_str(node.right, lvl)


def greater_to_str(node, lvl):
    ''' Converts ast.GreaterThanOp to str. '''
    return node_to_str(node.left, lvl) + ' > ' + node_to_str(node.right, lvl)


def less_or_eq_to_str(node, lvl):
    ''' Converts ast.LessOrEqThanOp to str. '''
    return node_to_str(node.left, lvl) + ' <= ' + node_to_str(node.right, lvl)


def greater_or_eq_to_str(node, lvl):
    ''' Converts ast.GreaterOrEqThanOp to str. '''
    return node_to_str(node.left, lvl) + ' >= ' + node_to_str(node.right, lvl)


def equal_to_str(node, lvl):
    ''' Converts ast.EqToOp to str. '''
    return node_to_str(node.left, lvl) + ' == ' + node_to_str(node.right, lvl)


def not_equal_to_str(node, lvl):
    ''' Converts ast.NotEqToOp to str. '''
    return node_to_str(node.left, lvl) + ' ~= ' + node_to_str(node.right, lvl)


def and_to_str(node, lvl):
    ''' Converts ast.AndLoOp to str. '''
    return node_to_str(node.left, lvl) + ' and ' + node_to_str(node.right, lvl)


def or_to_str(node, lvl):
    ''' Converts ast.OrLoOp to str. '''
    return node_to_str(node.left, lvl) + ' or ' + node_to_str(node.right, lvl)


def concat_to_str(node, lvl):
    ''' Converts ast.Concat to str. '''
    return node_to_str(node.left, lvl) + '..' + node_to_str(node.right, lvl)


def unary_minus_to_str(node, lvl):
    ''' Converts ast. to str. '''
    return '-' + node_to_str(node.operand, lvl)


def not_bit_to_str(node, lvl):
    ''' Converts ast. to str. '''
    return '~' + node_to_str(node.operand, lvl)


def not_to_str(node, lvl):
    ''' Converts ast. to str. '''
    return 'not ' + node_to_str(node.operand, lvl)


def length_to_str(node, lvl):
    ''' Converts ast. to str. '''
    return '#' + node_to_str(node.operand, lvl)


AST_LIST = [
    (ast.Chunk, chunk_to_str),
    (ast.Block, block_to_str),
    (ast.Name, name_to_str),
    (ast.Index, index_to_str),
    (ast.LocalAssign, loc_assign_to_str),
    (ast.Assign, assign_to_str),
    (ast.While, while_to_str),
    (ast.Do, do_to_str),
    (ast.Repeat, repeat_to_str),
    (ast.ElseIf, else_if_to_str),
    (ast.If, if_to_str),
    (ast.Label, label_to_str),
    (ast.Goto, goto_to_str),
    (ast.SemiColon, semicolon_to_str),
    (ast.Break, break_to_str),
    (ast.Return, return_to_str),
    (ast.Fornum, fornum_to_str),
    (ast.Forin, forin_to_str),
    (ast.Call, call_to_str),
    (ast.Invoke, invoke_to_str),
    (ast.LocalFunction, loc_func_to_str),
    (ast.Function, func_to_str),
    (ast.Method, method_to_str),
    (ast.Nil, nil_to_str),
    (ast.TrueExpr, true_expr_to_str),
    (ast.FalseExpr, false_expr_to_str),
    (ast.Number, number_to_str),
    (ast.Varargs, varargs_to_str),
    (ast.String, string_to_str),
    (ast.Field, field_to_str),
    (ast.Table, table_to_str),
    (ast.Dots, dots_to_str),
    (ast.AnonymousFunction, anon_func_to_str),
    # Arithmetic operators.
    (ast.AddOp, add_to_str),
    (ast.SubOp, sub_to_str),
    (ast.MultOp, mult_to_str),
    (ast.FloatDivOp, float_div_to_str),
    (ast.FloorDivOp, floor_div_to_str),
    (ast.ModOp, mod_to_str),
    (ast.ExpoOp, expo_to_str),
    # Bitwise operators.
    (ast.BAndOp, and_bit_to_str),
    (ast.BOrOp, or_bit_to_str),
    (ast.BXorOp, xor_bit_to_str),
    (ast.BShiftROp, shiftr_bit_to_str),
    (ast.BShiftLOp, shiftl_bit_to_str),
    # Relational operators.
    (ast.LessThanOp, less_to_str),
    (ast.GreaterThanOp, greater_to_str),
    (ast.LessOrEqThanOp, less_or_eq_to_str),
    (ast.GreaterOrEqThanOp, greater_or_eq_to_str),
    (ast.EqToOp, equal_to_str),
    (ast.NotEqToOp, not_equal_to_str),
    (ast.AndLoOp, and_to_str),
    (ast.OrLoOp, or_to_str),
    # Concate operator.
    (ast.Concat, concat_to_str),
    # Unary operators.
    (ast.UMinusOp, unary_minus_to_str),
    (ast.UBNotOp, not_bit_to_str),
    (ast.ULNotOp, not_to_str),
    (ast.ULengthOP, length_to_str),
]


def node_to_str(node, lvl=0):
    ''' Converts node to string. '''
    for node_type in AST_LIST:
        if type(node) == node_type[0]:
            return node_type[1](node, lvl)
    return 'Not parsed'


def get_index_name(node):
    if type(node) == ast.Name:
        return node
    return get_index_name(node.value)


def rename(new, old, tree):
    ''' Rename variable. '''
    for node in ast.walk(tree):
        if isinstance(node, (ast.LocalAssign, ast.Assign)):
            for targ in node.targets:
                if isinstance(targ, ast.Name) and targ.id == old:
                    targ.id = new
                if isinstance(targ, ast.Index):
                    name = get_index_name(targ)
                    if name.id == old:
                        name.id = new


def path_to_module_name(path):
    ''' Converts module path to module name. '''
    return path.replace('.', '_').replace('/', '_')[:-4]


def name_to_module_path(path):
    ''' Converts module name to module path. '''
    return path.replace('.', '/') + '.lua'
