local commands = {}

function commands.setup()
  local augroup = vim.api.nvim_create_augroup("AutoRun", { clear = true })
  local runners = require("autorun.runners")

  vim.api.nvim_create_autocmd("FileType", {
    pattern = runners.supported(),
    group = augroup,
    callback = function(event)
      local opts = { buffer = event.buf, silent = true }
      vim.keymap.set("n", "<leader>rr", function()
        runners.run(event.match)
      end, vim.tbl_extend("force", opts, { desc = "autorun: run file" }))
    end,
  })
end

return commands
