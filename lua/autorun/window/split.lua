local config = require("autorun.config")
local split = {}

split.valid_directions = {
  vertical = { "left", "right" },
  horizontal = { "above", "below" },
}

local function is_valid_direction(direction, valid_directions)
  for _, d in ipairs(valid_directions) do
    if direction == d then
      return true
    end
  end
  return false
end

function split.create_win(buf)
  local opts = config.options.window.split_opts
  local valid_directions = split.valid_directions[opts.style]
  if not valid_directions then
    vim.notify("autorun: split style is not valid, fallback to default", vim.log.levels.WARN)
    valid_directions = split.valid_directions["vertical"]
    opts.style = "vertical"
  end

  local direction = opts.direction
  if not is_valid_direction(direction, valid_directions) then
    vim.notify("autorun: direction is not valid, fallback to default", vim.log.levels.WARN)
    if opts.style == "vertical" then
      direction = "right"
      opts.direction = "right"
    else
      direction = "below"
      opts.direction = "below"
    end
  end

  local win_config = {
    split = direction,
  }
  local size_ratio = opts.size_ratio
  if opts.style == "vertical" then
    win_config.width = math.floor(vim.o.columns * size_ratio)
  else
    win_config.height = math.floor(vim.o.lines * size_ratio)
  end

  local win = vim.api.nvim_open_win(buf, true, win_config)

  vim.wo[win].wrap = false
  vim.wo[win].cursorline = true
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false

  return win
end

return split
