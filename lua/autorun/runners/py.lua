local M = {}

M.config = {
  python_path = nil,
}

local function locate_python_exe()
  local cwd = vim.loop.cwd()
  local venv_paths = {
    cwd .. "/.venv/bin/python",
    cwd .. "/.venv/bin/python3",
    cwd .. "/.venv/bin/python.exe",
    cwd .. "/.venv/bin/python3.exe",
  }

  for _, path in ipairs(venv_paths) do
    if vim.fn.executable(path) == 1 then
      return path
    end
  end

  if vim.fn.executable("python") == 1 then
    return vim.fn.exepath("python")
  end

  if vim.fn.executable("python3") == 1 then
    return vim.fn.exepath("python3")
  end

  return nil
end

local function check_config(cfg)
  if not cfg.python_path or cfg.python_path == "" then
    vim.notify("autorun: Python executable not found in PATH", vim.log.levels.ERROR)
    return false
  end

  return true
end

function M.setup()
  M.config.python_path = locate_python_exe()
  check_config(M.config)
end

function M.get_command()
  if not check_config(M.config) then
    return nil
  end

  local filename = vim.fn.expand("%:p")
  return string.format('"%s" "%s"', M.config.python_path, filename)
end

return M
