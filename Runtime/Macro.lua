do
    Macro = function()
        error('Macro function is disabled in runtime', 2)
    end

    BuildFinalFinal = function(func, ...) return func(...) end
end