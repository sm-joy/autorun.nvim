local M = {}

M.options = {}

local defaults = {
	term_style = "vertical",
	term_size = "40",
}

function M.setup(opts) 
    M.options = vim.tbl_deep_extend("force", defaults, opts or {})
end

return M
