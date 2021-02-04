---@class BuildtimeFinal
local BuilderBuildFinal = {}

local src_dir
local dst_dir
local build_final_list

---@param func function
local function buildFinalFunc(func, ...)
    table.insert(build_final_list, {f = func, a = {...}})
end

---@param src string
---@param dst string
function BuilderBuildFinal.enable(src, dst)
    src_dir = src
    dst_dir = dst

    build_final_list = {}
    _G.BuildFinal = buildFinalFunc
end

function BuilderBuildFinal.disable()
    src_dir = nil
    dst_dir = nil

    for i = 1, #build_final_list do
        local f = build_final_list[i].f
        local args = build_final_list[i].a
        -- print(f, args, table.unpack)
        f(table.unpack(args))
    end
    _G.BuildFinal = nil
end

return BuilderBuildFinal