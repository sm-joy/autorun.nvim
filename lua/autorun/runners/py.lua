local terminal = require("autorun.terminal")
local M = {}

function M.run()
	local filename = vim.fn.expand("%")
	local command = string.format("python %s", filename)
	terminal.run(command)
end

return M
