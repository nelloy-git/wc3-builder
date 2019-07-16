#!/usr/bin/env python

''' Some info
'''


import os
import sys
import shutil

import imports.parse_module as pm
import imports.ast_to_string as ats

src_dir = sys.argv[1]
dst_dir = sys.argv[2]
war3_exe = None
if len(sys.argv) > 3:
    war3_exe = sys.argv[3]

print('')
if not war3_exe is None:
    print('Warcraft III.exe path:\n  ' + war3_exe)
print('Source dir path:\n  ' + src_dir)
print('Destination dir path:\n  ' + dst_dir)

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

pm.compile_lua('war3map.lua', src_dir, dst_dir)

# file_list, content_list = pm.get_contents('war3map.lua', src_dir)
# 
# print('\nUsed files:')
# for f in file_list:
#     print('  ' + f)
# 
# for i, file_path in enumerate(file_list):
#     content_list[i] = pm.content_to_function(file_path, content_list[i])
# 
# full_content = pm.link_content(content_list)
# pm.add_extension_functions(file_list, content_list)
# 
# pm.compiletime_execution(full_content, src_dir, dst_dir)
# 
# if not os.path.exists(dst_dir):
#     os.mkdir(dst_dir)
# 
# with open(os.path.join(dst_dir, 'war3map.lua'), 'w') as file:
#     file.write(ats.node_to_str(full_content))
# 