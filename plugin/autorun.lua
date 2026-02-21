if vim.g.loaded_autorun then
    return
end
vim .g.loaded_autorun = 1

require("autorun").setup()
