local config = require("autorun.config")
local float = {}

function float.create_win(buf)
  local width = math.floor(vim.o.columns * config.options.window.float_opts.width_ratio)
  local height = math.floor(vim.o.lines * config.options.window.float_opts.height_ratio)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win_config = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = config.options.window.float_opts.border,
    title = "AutoRun",
    title_pos = "center",
    footer = " <Esc><Esc> to close ",
    footer_pos = "center",
  }

  local win = vim.api.nvim_open_win(buf, true, win_config)

  vim.wo[win].wrap = false
  vim.wo[win].cursorline = true
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].winhl = "Normal:AutoRunNormal,FloatBorder:AutoRunNormal"

  return win
end

return float
