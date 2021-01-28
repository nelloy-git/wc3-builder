local Utils = {}

local jass_available = (_G.debug == nil and
                        GetDestructableX ~= nil and
                        GetDestructableY ~= nil and
                        GetUnitX ~= nil and
                        GetUnitY ~= nil)

---@return boolean
function IsGame()
    return jass_available
end

local src_dir
local dst_dir

---@return string|nil
function GetSrc()
    return src_dir
end

---@return string|nil
function GetDst()
    return dst_dir
end

if (not IsGame()) then

    ---@param path string
    function Utils.SetSrc(path)
        src_dir = path
    end

    ---@param path string
    function Utils.SetDst(path)
        dst_dir = path
    end

end

return Utils