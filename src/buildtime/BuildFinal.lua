---@class BuilderBuildFinal
local BuilderBuildFinal = {}

local build_final_list

local function buildFinalFunc(func, ...)
    table.insert(build_final_list, {f = func, a = {...}})
end

---@param flag boolean
function BuilderBuildFinal.enable(flag)
    if flag then
        build_final_list = {}
        _G.BuildFinal = buildFinalFunc
    else
        for i = 1, #build_final_list do
            build_final_list[i].f(table.unpack(build_final_list[i].a))
        end
        _G.BuildFinal = nil
    end
end

return BuilderBuildFinal