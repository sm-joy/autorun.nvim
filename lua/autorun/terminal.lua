local config = require("autorun.config")
local M = {}

function M.run(command)
	vim.cmd("rightbelow vnew")
	if config.options.term_style then
		local term_style_cmd = config.options.term_style .. " resize " .. config.options.term_size
		vim.cmd(term_style_cmd)
	end

	vim.cmd("term " .. command)
	vim.wo.number = false
	vim.wo.relativenumber = false
	vim.cmd("startinsert")

	vim.api.nvim_create_autocmd("BufEnter", {
		buffer = 0,
		command = "startinsert",
	})
end

return M
