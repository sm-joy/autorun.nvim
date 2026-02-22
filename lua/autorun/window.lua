local window = {}
window.has_footer = vim.fn.has("nvim-0.10") == 1

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

local function create_win(buf)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win_config = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = "AutoRun",
    title_pos = "center",
  }

  if window.has_footer then
    win_config.footer = " <Esc><Esc> to close "
    win_config.footer_pos = "center"
  end

  local win = vim.api.nvim_open_win(buf, true, win_config)

  vim.wo[win].wrap = false
  vim.wo[win].cursorline = true
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].winhl = "Normal:AutoRunNormal,FloatBorder:AutoRunNormal"

  return win
end

function window.run(cmd)
  if not cmd or cmd == "" then
    vim.notify("autorun: no command provided", vim.log.levels.WARN)
    return
  end

  local on_process_exit

  local buf = create_buf()
  local win = create_win(buf)
  local chan = vim.fn.termopen(cmd, {
    on_exit = function()
      vim.schedule(function()
        on_process_exit()
        vim.cmd("stopinsert")
        if vim.api.nvim_win_is_valid(win) then
          if window.has_footer then
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
