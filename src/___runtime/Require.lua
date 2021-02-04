__required_packages = {}
do
    local loaded_packages = {}
    local loading_packages = {}
    local current = {}

    function require(package_name)
        if loading_packages[package_name] then
            error('Recursive require detected.')
        end

        if not loaded_packages[package_name] then
            if not __required_packages[package_name] then
                if not __required_packages[package_name..'.index'] then
                    error('Can not find module '..package_name, 2)
                end
                package_name = package_name..'.index'
            end

            loading_packages[package_name] = true
            table.insert(current, package_name)
            loaded_packages[package_name] = __required_packages[package_name]() or true
            table.remove(current, #current)
            loading_packages[package_name] = nil
        end

        return loaded_packages[package_name]
    end

    _G.getLoadingPackage = function(depth)
        error('getLoadingPackage function is disabled in runtime', 2)
    end
end