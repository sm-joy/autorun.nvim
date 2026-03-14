local config = require("autorun.config")
local window = {}

window.supported_win_types = {
  float = "autorun.window.float",
  split = "autorun.window.split",
}

window.active_win_mod = nil

function window.setup()
  local win_type = config.options.window.type
  local win_mod_path = window.supported_win_types[win_type]

  if not win_mod_path then
    vim.notify(
      "autorun: no supported window module for " .. win_type .. ". Falling back to default.",
      vim.log.levels.WARN
    )
    win_mod_path = window.supported_win_types["float"]
    config.options.window.type = "float"
  end

  local ok, win_mod = pcall(require, win_mod_path)
  if not ok then
    vim.notify("autorun: failed to load window type for " .. win_mod, vim.log.levels.ERROR)
    return
  end

  window.active_win_mod = win_mod
end

local function close_win(buf, win, chan)
  if chan and chan > 0 and vim.fn.jobwait({ chan }, 0)[1] == -1 then
    vim.fn.jobstop(chan)
  end

  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end

  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end

local function set_keymaps(buf, win, chan)
  local opts = { noremap = true, silent = true, nowait = true, buffer = buf }
  vim.keymap.set("t", "<Esc><Esc>", function()
    close_win(buf, win, chan)
  end, opts)

  vim.keymap.set("n", "q", function()
    close_win(buf, win, chan)
  end, opts)

  vim.keymap.set("n", "<Esc>", function()
    close_win(buf, win, chan)
  end, opts)

  local on_process_exit = function()
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    pcall(vim.keymap.del, "t", "<Esc><Esc>", { buffer = buf })
    for _, key in ipairs({ "i", "a", "A", "o", "O", "I", "s", "S", "c", "C" }) do
      vim.keymap.set("n", key, "<Nop>", opts)
    end
  end

  return on_process_exit
end

local function create_buf()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = "autorun"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buflisted = false
  vim.bo[buf].swapfile = false

  return buf
end

function window.run(cmd)
  if not cmd or cmd == "" then
    vim.notify("autorun: no command provided", vim.log.levels.WARN)
    return
  end

  if not window.active_win_mod then
    vim.notify("autorun: window module not loaded", vim.log.levels.ERROR)
    return
  end

  local on_process_exit

  local buf = create_buf()
  local win = window.active_win_mod.create_win(buf)
  local chan = vim.fn.termopen(cmd, {
    on_exit = function()
      vim.schedule(function()
        on_process_exit()
        vim.cmd("stopinsert")
        if vim.api.nvim_win_is_valid(win) then
          if config.options.window.type == "float" then
            vim.api.nvim_win_set_config(win, {
              footer = " <q> or <Esc> to close ",
            })
          end
        end
      end)
    end,
  })
  if not chan or chan <= 0 then
    vim.notify("autorun: failed to run command: " .. cmd, vim.log.levels.ERROR)
    close_win(buf, win, chan)
    return
  end

  on_process_exit = set_keymaps(buf, win, chan)
  vim.cmd("startinsert")
end

return window
