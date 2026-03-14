local M = {}

local defaults = {
  prefered_compilers = {
    c = "gcc",
    cpp = "g++",
  },
  window = {
    type = "float",
    split_opts = {
      style = "vertical",
      direction = "right",
      size_ratio = 0.2,
    },
    float_opts = {
      width_ratio = 0.8,
      height_ratio = 0.8,
      border = "rounded",
    },
  },
}

M.options = vim.deepcopy(defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", defaults, opts or {})
end

return M
