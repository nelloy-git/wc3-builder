# wc3-builder
Lua builder for warcraf3

How to use:
lua53.exe main.lua

Builder will run config.lua and main.lua files in src folder. It does not recognize wc3 API.
There are some extra global functions available:

Works almost like default require. String value are allowed only. Available both in buildtime and runtime.

require(mode)



Is running inside builder or not. Available both in buildtime and runtime.
return boolean

IsGame()



Returns relative source dir path. Available both in buildtime.
return string

GetSrc()



Returns relative result dir path. Available both in buildtime.
return string

GetDst()



Macro functions are replaced with their results after all lua code is done.
If string or number is used as argument code will be changed in result script "Macro(arg)" -> "arg"
If table is used it must contain strings and numbers or other tables with strings and numbers etc.
If "body"'s type is function vararg must contain arguments for this function. Example: "Macro(math.abs, -1)" -> "1"
This function is available in buildtime only.

param body fun | table | string | number
Macro(body, ...)



Adds function to list which is going be executed at the end of the building.
In runtime it works like fun(...)
MacroFinal(func, ...)
