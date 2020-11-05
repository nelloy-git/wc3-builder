local sep = package.config:sub(1,1)
local this_file_path = debug.getinfo(1, "S").source:sub(2)
local this_dir_path = this_file_path:sub(1, this_file_path:match('^.*()'..sep))

-- Add builder dir to packages list
local package_path = package.path
package.path = package.path..';'..this_dir_path..sep.."?.lua"

local Process = require('Buildtime.Process')

package.path = package_path

-- TODO argparse

Process.build(arg[1], arg[2])