# wc3-builder
Lua builder for warcraf3

How to use:
lua53.exe main.lua src dst
  src - source dir
  dst - result dir
  map_data - path to map folder containing other map data like .w3u, w3a files.

Builder will run config.lua and main.lua files in src folder. 

Builder will run lua files init.lua and main.lua. It does not recognize wc3 API.

There are some extra global functions available:

Works almost like default require. Available both in buildtime and runtime.

require(mode)

Is running inside builder or not.
return boolean

IsGame()

Returns relative source dir path.
@return string

GetSrc()

Returns relative result dir path.
@return string

GetDst()

Macro functions are replaced with their results after all lua code is done.
Works like macro. If string or number is used as argument code will be changed in result script "Macro(arg)" -> "arg"
If table is used it must contain strings and numbers or other tables with strings and numbers.
If "body" type is function vararg must contain arguments for this function. Example: "Macro(math.abs, -1)" -> "1"
This function is available in buildtime only.
@param body fun | table | string | number

Macro(body, ...)