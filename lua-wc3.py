#!/usr/bin/env python

''' Some info
'''

import os
import sys

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

file_list, content_list = pm.get_contents('war3map.lua', src_dir)

print('\nUsed files:')
for f in file_list:
    print('  ' + f)

for i, file_path in enumerate(file_list):
    content_list[i] = pm.content_to_function(file_path, content_list[i])

full_content = pm.link_content(content_list)
pm.add_extension_functions(file_list, content_list)

#with open(os.path.join(dst_dir, 'before_compiletime_war3map.lua'), 'w') as file:
#    file.write(ats.node_to_str(full_content))

#print('\nCompiletime output:')
pm.compiletime_execution(full_content, src_dir)

with open(os.path.join(dst_dir, 'war3map.lua'), 'w') as file:
    file.write(ats.node_to_str(full_content))
    
map_files = [
    'war3map.lua',
    'war3map.doo',
    'war3map.mmp',
    'war3map.shd',
    'war3map.w3c',
    'war3map.w3e',
    'war3map.w3i',
    'war3map.w3r',
    'war3map.wct',
    'war3map.wpm',
    'war3map.wtg',
    'war3map.wts',
    'war3mapMap.blp',
    'war3mapUnits.doo',
]

map_folders = [
    'war3mapImported'
]

#input("Press Enter to continue...")
#path = build_dir + '/map.w3x'
#subprocess.run(['./MPQEditor.exe', 'new', path])
#for f in map_files:
#    subprocess.run(['./MPQEditor.exe', 'add', path, build_dir + '/' + f, f, ' /auto'])
#for folder in map_folders:
#    subprocess.run('./MPQEditor.exe' + ' add ' + path + ' ' + build_dir + '/' + folder + ' ' + folder + ' /auto')

#war3_exe = 'C:\\Program Files\\Warcraft III\\x86_64\\Warcraft III.exe'
#print(os.getcwd() + '\\build\\map.w3x')
#subprocess.call(war3_exe + ' -loadfile ' + os.getcwd() + '\\' + path)