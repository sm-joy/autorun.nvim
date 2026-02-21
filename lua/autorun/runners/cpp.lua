local config = require("autorun.config")
local M = {}

M.config = {
  compiler_path = nil,
}

local compilers = { "g++", "clang++", "clang-cl", "cl" }

local function locate_compiler_path()
  if config.prefered_cpp_compiler and vim.fn.executable(config.prefered_cpp_compiler) == 1 then
    return vim.fn.exepath(config.prefered_cpp_compiler)
  end

  for _, compiler in ipairs(compilers) do
    if vim.fn.executable(compiler) == 1 then
      return vim.fn.exepath(compiler)
    end
  end

  return nil
end

local function check_config(config)
  if not config.compiler_path or config.compiler_path == "" then
    vim.notify("autorun: Compiler executable not found in PATH", vim.log.levels.ERROR)
    return false
  end

  return true
end

function M.setup()
  M.config.compiler_path = locate_compiler_path()
  check_config(M.config)
end

function M.get_command()
  if not check_config(M.config) then
    return nil
  end

  local filename = vim.fn.expand("%:p")
  local target = vim.fn.expand("%:t:r") .. (vim.fn.has("win32") == 1 and ".exe" or "")
  local run_prefix = vim.fn.has("win32") == 1 and ".\\" or "./"
  return string.format('"%s" "%s" -o "%s" && %s"%s"', M.config.compiler_path, filename, target, run_prefix, target)
end

return M
