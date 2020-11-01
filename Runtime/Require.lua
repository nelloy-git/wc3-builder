__required_packages = {}
do
    local loaded_packages = {}
    local loading_packages = {}

    function require(package_name)
        if loading_packages[package_name] then
            error('Recursive require detected.')
        end

        if not loaded_packages[package_name] then
            if not __required_packages[package_name] then
                error('Can not find module '..package_name, 2)
            end

            loading_packages[package_name] = true
            loaded_packages[package_name] = __required_packages[package_name]() or true
            loading_packages[package_name] = nil
        end

        return loaded_packages[package_name]
    end
end