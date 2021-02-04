do
    function main()
        local success, result = pcall(require, 'main')
        if not success then
            print(result)
        end
    end

    function config()
        local success, result = pcall(require, 'config')
        if not success then
            print(result)
        end
    end
end