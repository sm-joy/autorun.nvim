local M = {}

function M.setup()
	local augroup = vim.api.nvim_create_augroup("AutoRun", { clear = true })
	local py_runner = require("autorun.runners.py")

	vim.api.nvim_create_autocmd("FileType", {
		pattern = "python",
		group = augroup,
		callback = function()
			vim.keymap.set("n", "<leader>rr", py_runner.run, { buffer = true })
		end,
	})
end

return M
