local autorun = {}


function autorun.setup(opts)
    require("autorun.config").setup(opts)
    require("autorun.commands").setup()
end

return autorun
