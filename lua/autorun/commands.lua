local commands = {}

function commands.setup()
	local augroup = vim.api.nvim_create_augroup("AutoRun", { clear = true })
	local runners = require("autorun.runners")

	vim.api.nvim_create_autocmd("FileType", {
		pattern = runners.supported(),
		group = augroup,
		callback = function(event)
			vim.keymap.set("n", "<leader>rr", function() runners.run(event.match) end, {
				buffer = event.buf,
				desc = "autorun: run file",
				silent = true,
			})
		end,
	})
end

return commands
