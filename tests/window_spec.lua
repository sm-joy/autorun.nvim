local function clear_modules()
  package.loaded["autorun.window"] = nil
  package.loaded["autorun.window.float"] = nil
  package.loaded["autorun.window.split"] = nil
  package.loaded["autorun.config"] = nil
end

local function make_config(overrides)
  local base = {
    options = {
      window = {
        type = "float",
        float_opts = {
          width_ratio = 0.8,
          height_ratio = 0.6,
          border = "rounded",
        },
        split_opts = {
          style = "vertical",
          direction = "right",
          size_ratio = 0.4,
        },
      },
    },
  }
  if overrides then
    for k, v in pairs(overrides) do
      base.options.window[k] = v
    end
  end
  return base
end

local function get_autorun_wins()
  local wins = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "autorun" then
      table.insert(wins, win)
    end
  end
  return wins
end

local function get_autorun_bufs()
  local bufs = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "autorun" then
      table.insert(bufs, buf)
    end
  end
  return bufs
end

local function close_autorun_wins()
  for _, win in ipairs(get_autorun_wins()) do
    pcall(vim.api.nvim_win_close, win, true)
  end
end

-- ============================================================================
describe("autorun.window.float", function()
  after_each(function()
    close_autorun_wins()
    clear_modules()
  end)

  describe("float.create_win()", function()
    it("opens a floating window with relative = 'editor'", function()
      package.loaded["autorun.config"] = make_config({ type = "float" })
      local float = require("autorun.window.float")
      local buf = vim.api.nvim_create_buf(false, true)
      float.create_win(buf)
      local cfg = vim.api.nvim_win_get_config(vim.api.nvim_get_current_win())
      assert.equals("editor", cfg.relative)
    end)

    it("sizes width according to width_ratio", function()
      package.loaded["autorun.config"] = make_config({
        type = "float",
        float_opts = { width_ratio = 0.8, height_ratio = 0.6, border = "rounded" },
      })
      local float = require("autorun.window.float")
      local buf = vim.api.nvim_create_buf(false, true)
      local win = float.create_win(buf)
      local cfg = vim.api.nvim_win_get_config(win)
      local expected = math.floor(vim.o.columns * 0.8)
      assert.equals(expected, cfg.width)
    end)

    it("sizes height according to height_ratio", function()
      package.loaded["autorun.config"] = make_config({
        type = "float",
        float_opts = { width_ratio = 0.8, height_ratio = 0.6, border = "rounded" },
      })
      local float = require("autorun.window.float")
      local buf = vim.api.nvim_create_buf(false, true)
      local win = float.create_win(buf)
      local cfg = vim.api.nvim_win_get_config(win)
      local expected = math.floor(vim.o.lines * 0.6)
      assert.equals(expected, cfg.height)
    end)

    it("centres the window horizontally", function()
      package.loaded["autorun.config"] = make_config()
      local float = require("autorun.window.float")
      local buf = vim.api.nvim_create_buf(false, true)
      local win = float.create_win(buf)
      local cfg = vim.api.nvim_win_get_config(win)
      local w = math.floor(vim.o.columns * 0.8)
      local expected_col = math.floor((vim.o.columns - w) / 2)
      assert.equals(expected_col, cfg.col)
    end)

    it("centres the window vertically", function()
      package.loaded["autorun.config"] = make_config()
      local float = require("autorun.window.float")
      local buf = vim.api.nvim_create_buf(false, true)
      local win = float.create_win(buf)
      local cfg = vim.api.nvim_win_get_config(win)
      local h = math.floor(vim.o.lines * 0.6)
      local expected_row = math.floor((vim.o.lines - h) / 2)
      assert.equals(expected_row, cfg.row)
    end)

    it("disables line numbers on the window", function()
      package.loaded["autorun.config"] = make_config()
      local float = require("autorun.window.float")
      local buf = vim.api.nvim_create_buf(false, true)
      local win = float.create_win(buf)
      assert.is_false(vim.wo[win].number)
      assert.is_false(vim.wo[win].relativenumber)
    end)

    it("enables cursorline", function()
      package.loaded["autorun.config"] = make_config()
      local float = require("autorun.window.float")
      local buf = vim.api.nvim_create_buf(false, true)
      local win = float.create_win(buf)
      assert.is_true(vim.wo[win].cursorline)
    end)

    it("disables line wrap", function()
      package.loaded["autorun.config"] = make_config()
      local float = require("autorun.window.float")
      local buf = vim.api.nvim_create_buf(false, true)
      local win = float.create_win(buf)
      assert.is_false(vim.wo[win].wrap)
    end)
  end)
end)

-- ============================================================================
describe("autorun.window.split", function()
  after_each(function()
    close_autorun_wins()
    clear_modules()
  end)

  describe("split.create_win()", function()
    it("opens a vertical split to the right", function()
      package.loaded["autorun.config"] = make_config({
        split_opts = { style = "vertical", direction = "right", size_ratio = 0.4 },
      })
      local split = require("autorun.window.split")
      local buf = vim.api.nvim_create_buf(false, true)
      split.create_win(buf)
      -- a new window should now exist
      assert.is_true(#vim.api.nvim_list_wins() >= 2)
    end)

    it("opens a vertical split to the left", function()
      package.loaded["autorun.config"] = make_config({
        split_opts = { style = "vertical", direction = "left", size_ratio = 0.4 },
      })
      local split = require("autorun.window.split")
      local buf = vim.api.nvim_create_buf(false, true)
      split.create_win(buf)
      assert.is_true(#vim.api.nvim_list_wins() >= 2)
    end)

    it("opens a horizontal split below", function()
      package.loaded["autorun.config"] = make_config({
        split_opts = { style = "horizontal", direction = "below", size_ratio = 0.3 },
      })
      local split = require("autorun.window.split")
      local buf = vim.api.nvim_create_buf(false, true)
      split.create_win(buf)
      assert.is_true(#vim.api.nvim_list_wins() >= 2)
    end)

    it("opens a horizontal split above", function()
      package.loaded["autorun.config"] = make_config({
        split_opts = { style = "horizontal", direction = "above", size_ratio = 0.3 },
      })
      local split = require("autorun.window.split")
      local buf = vim.api.nvim_create_buf(false, true)
      split.create_win(buf)
      assert.is_true(#vim.api.nvim_list_wins() >= 2)
    end)

    it("sets width for a vertical split from size_ratio", function()
      package.loaded["autorun.config"] = make_config({
        split_opts = { style = "vertical", direction = "right", size_ratio = 0.4 },
      })
      local split = require("autorun.window.split")
      local buf = vim.api.nvim_create_buf(false, true)
      local win = split.create_win(buf)
      local expected = math.floor(vim.o.columns * 0.4)
      assert.equals(expected, vim.api.nvim_win_get_width(win))
    end)

    it("sets height for a horizontal split from size_ratio", function()
      package.loaded["autorun.config"] = make_config({
        split_opts = { style = "horizontal", direction = "below", size_ratio = 0.3 },
      })
      local split = require("autorun.window.split")
      local buf = vim.api.nvim_create_buf(false, true)
      local win = split.create_win(buf)
      local expected = math.floor(vim.o.lines * 0.3)
      assert.equals(expected, vim.api.nvim_win_get_height(win))
    end)

    it("disables line numbers", function()
      package.loaded["autorun.config"] = make_config()
      local split = require("autorun.window.split")
      local buf = vim.api.nvim_create_buf(false, true)
      local win = split.create_win(buf)
      assert.is_false(vim.wo[win].number)
      assert.is_false(vim.wo[win].relativenumber)
    end)

    it("enables cursorline", function()
      package.loaded["autorun.config"] = make_config()
      local split = require("autorun.window.split")
      local buf = vim.api.nvim_create_buf(false, true)
      local win = split.create_win(buf)
      assert.is_true(vim.wo[win].cursorline)
    end)

    it("disables wrap", function()
      package.loaded["autorun.config"] = make_config()
      local split = require("autorun.window.split")
      local buf = vim.api.nvim_create_buf(false, true)
      local win = split.create_win(buf)
      assert.is_false(vim.wo[win].wrap)
    end)

    it("warns and falls back to vertical for an invalid style", function()
      local warned = false
      local orig_notify = vim.notify
      vim.notify = function(msg, level)
        if level == vim.log.levels.WARN and msg:find("split style is not valid") then
          warned = true
        end
      end
      package.loaded["autorun.config"] = make_config({
        split_opts = { style = "diagonal", direction = "right", size_ratio = 0.4 },
      })
      local split = require("autorun.window.split")
      local buf = vim.api.nvim_create_buf(false, true)
      split.create_win(buf)
      assert.is_true(warned)
      vim.notify = orig_notify
    end)

    it("warns and falls back for a direction invalid for the style", function()
      local warned = false
      local orig_notify = vim.notify
      vim.notify = function(msg, level)
        if level == vim.log.levels.WARN and msg:find("direction is not valid") then
          warned = true
        end
      end
      package.loaded["autorun.config"] = make_config({
        split_opts = { style = "vertical", direction = "below", size_ratio = 0.4 },
      })
      local split = require("autorun.window.split")
      local buf = vim.api.nvim_create_buf(false, true)
      split.create_win(buf)
      assert.is_true(warned)
      vim.notify = orig_notify
    end)
  end)
end)

-- ============================================================================
describe("autorun.window", function()
  after_each(function()
    close_autorun_wins()
    clear_modules()
  end)

  describe("window.setup()", function()
    it("loads the float module when type is 'float'", function()
      package.loaded["autorun.config"] = make_config({ type = "float" })
      local window = require("autorun.window")
      window.setup()
      assert.is_not_nil(window.active_win_mod)
    end)

    it("loads the split module when type is 'split'", function()
      package.loaded["autorun.config"] = make_config({ type = "split" })
      local window = require("autorun.window")
      window.setup()
      assert.is_not_nil(window.active_win_mod)
    end)

    it("warns and falls back to float for an unsupported window type", function()
      local warned = false
      local orig_notify = vim.notify
      vim.notify = function(msg, level)
        if level == vim.log.levels.WARN and msg:find("no supported window module") then
          warned = true
        end
      end
      package.loaded["autorun.config"] = make_config({ type = "teleport" })
      local window = require("autorun.window")
      window.setup()
      assert.is_true(warned)
      assert.is_not_nil(window.active_win_mod)
      vim.notify = orig_notify
    end)
  end)

  describe("window.run()", function()
    it("does nothing and warns if cmd is nil", function()
      local warned = false
      local orig_notify = vim.notify
      vim.notify = function(_, level)
        if level == vim.log.levels.WARN then
          warned = true
        end
      end
      package.loaded["autorun.config"] = make_config()
      local window = require("autorun.window")
      window.setup()
      window.run(nil)
      assert.is_true(warned)
      vim.notify = orig_notify
    end)

    it("does nothing and warns if cmd is empty", function()
      local warned = false
      local orig_notify = vim.notify
      vim.notify = function(_, level)
        if level == vim.log.levels.WARN then
          warned = true
        end
      end
      package.loaded["autorun.config"] = make_config()
      local window = require("autorun.window")
      window.setup()
      window.run("")
      assert.is_true(warned)
      vim.notify = orig_notify
    end)

    it("does nothing and errors if active_win_mod is not loaded", function()
      local errored = false
      local orig_notify = vim.notify
      vim.notify = function(_, level)
        if level == vim.log.levels.ERROR then
          errored = true
        end
      end
      package.loaded["autorun.config"] = make_config()
      local window = require("autorun.window")
      -- intentionally skip setup()
      window.run("echo hello")
      assert.is_true(errored)
      vim.notify = orig_notify
    end)

    it("opens a floating window for float type", function()
      package.loaded["autorun.config"] = make_config({ type = "float" })
      local window = require("autorun.window")
      window.setup()
      window.run("echo hello")
      vim.wait(100)
      local found = false
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local cfg = vim.api.nvim_win_get_config(win)
        if cfg.relative == "editor" then
          found = true
          break
        end
      end
      assert.is_true(found)
    end)

    it("opens a split window for split type", function()
      package.loaded["autorun.config"] = make_config({ type = "split" })
      local window = require("autorun.window")
      local wins_before = #vim.api.nvim_list_wins()
      window.setup()
      window.run("echo hello")
      vim.wait(100)
      assert.is_true(#vim.api.nvim_list_wins() > wins_before)
    end)

    it("creates a buffer with filetype 'autorun'", function()
      package.loaded["autorun.config"] = make_config()
      local window = require("autorun.window")
      window.setup()
      window.run("echo hello")
      vim.wait(100)
      assert.is_true(#get_autorun_bufs() > 0)
    end)

    it("updates float footer to close hint after process exits", function()
      package.loaded["autorun.config"] = make_config({ type = "float" })
      local window = require("autorun.window")
      window.setup()
      window.run("echo hello")
      vim.wait(500)
      local footer_updated = false
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local cfg = vim.api.nvim_win_get_config(win)
        if cfg.relative == "editor" and cfg.footer then
          local footer_text = type(cfg.footer) == "string" and cfg.footer
            or (type(cfg.footer) == "table" and cfg.footer[1] and cfg.footer[1][1])
          if footer_text and (footer_text:find("<q>") or footer_text:find("<Esc>")) then
            footer_updated = true
          end
        end
      end
      assert.is_true(footer_updated)
    end)

    it("buffer with filetype autorun is still valid after process exits", function()
      package.loaded["autorun.config"] = make_config()
      local window = require("autorun.window")
      window.setup()
      window.run("echo hello")
      vim.wait(500)
      -- user hasn't pressed close yet — buffer should still be around
      assert.is_true(#get_autorun_bufs() > 0)
    end)
  end)
end)
