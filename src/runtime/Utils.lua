do
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
end