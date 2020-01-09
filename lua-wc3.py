#!/usr/bin/env python

''' Some info
'''


import os
import sys
import shutil
import lupa

src_dir = sys.argv[1]
dst_dir = sys.argv[2]
war3_exe = None
if len(sys.argv) > 3:
    war3_exe = sys.argv[3]

print('')
if not war3_exe is None:
    print('Warcraft III.exe path:\n  ' + war3_exe)
print('Sources: ' + src_dir)
print('Build: ' + dst_dir)

# Copy non-lua files.
for (root, subdir, dir_files) in os.walk(src_dir):
    rel_root = root[len(src_dir) + 1:]
    for f_name in dir_files:
        if f_name.endswith('.lua'):
            continue
        dst = os.path.join(dst_dir, rel_root)
        if not os.path.exists(dst):
            os.mkdir(dst)
        shutil.copyfile(os.path.join(root, f_name), os.path.join(dst_dir, rel_root, f_name))

cur_dir = os.path.dirname(os.path.abspath(__file__))
with open(os.path.join(cur_dir, 'lua_wc3.lua'), 'r') as file:
    lua_wc3 = file.read()

os.chdir(src_dir)
lua = lupa.LuaRuntime(unpack_returned_tuples=True)
lua.execute('local lua_wc3 = function()\n' + lua_wc3 + '\nend\nlocal Compile = lua_wc3()\nCompile(\'{0}\', \'{1}\')'.format(src_dir, dst_dir).replace('\\', '\\\\'))