-- tests/autorun_spec.lua

-- ============================================================
-- helpers
-- ============================================================

local function clear_modules()
  local mods = {
    "autorun",
    "autorun.config",
    "autorun.commands",
    "autorun.terminal",
    "autorun.runners",
    "autorun.runners.py",
    "autorun.runners.c",
    "autorun.runners.cpp",
  }
  for _, m in ipairs(mods) do
    package.loaded[m] = nil
  end
  -- suppress notify noise during tests
  vim.notify = function() end
end

-- mock vim.fn functions, returns a restore function
local function mock_fn(overrides)
  local original = {}
  for k, v in pairs(overrides) do
    original[k] = vim.fn[k]
    vim.fn[k] = v
  end
  return function()
    for k, v in pairs(original) do
      vim.fn[k] = v
    end
  end
end

-- ============================================================
-- config
-- ============================================================

describe("config", function()
  before_each(clear_modules)

  it("has correct defaults", function()
    require("autorun").setup({})
    local cfg = require("autorun.config")
    assert.equals("vertical", cfg.options.window.split_opts.style)
    assert.equals(0.2, cfg.options.window.split_opts.size_ratio)
  end)

  it("merges user opts over defaults", function()
    require("autorun").setup({
      window = {
        split_opts = {
          size_ratio = 0.6,
        },
      },
    })
    local cfg = require("autorun.config")
    assert.equals(0.6, cfg.options.window.split_opts.size_ratio)
    assert.equals("vertical", cfg.options.window.split_opts.style) -- default preserved
  end)

  it("setup() runs without errors with empty opts", function()
    assert.has_no.errors(function()
      require("autorun").setup({})
    end)
  end)
end)

-- ============================================================
-- runner registry
-- ============================================================

describe("runner registry", function()
  before_each(clear_modules)

  it("supported() contains python, c, cpp", function()
    local runners = require("autorun.runners")
    local s = runners.supported()
    assert.is_true(vim.tbl_contains(s, "python"))
    assert.is_true(vim.tbl_contains(s, "c"))
    assert.is_true(vim.tbl_contains(s, "cpp"))
  end)

  it("returns nil for unregistered filetype", function()
    local runners = require("autorun.runners")
    assert.is_nil(runners.supported_runners["cobol"])
  end)

  it("loads runner module without errors", function()
    local restore = mock_fn({
      executable = function(_)
        return 0
      end,
      exepath = function(_)
        return ""
      end,
    })

    assert.has_no.errors(function()
      require("autorun.runners.py")
      require("autorun.runners.c")
      require("autorun.runners.cpp")
    end)

    restore()
  end)
end)

-- ============================================================
-- runners.run() integration
-- ============================================================

describe("runners.run()", function()
  it("does not call terminal when buffer has no filename", function()
    clear_modules()

    -- mock terminal to detect if it gets called
    local terminal_called = false
    package.loaded["autorun.terminal"] = {
      run = function(_)
        terminal_called = true
      end,
    }

    local orig_expand = vim.fn.expand
    vim.fn.expand = function(arg)
      if arg == "%" then
        return ""
      end -- unnamed buffer
      return orig_expand(arg)
    end

    local runners = require("autorun.runners")
    runners.run("python")

    assert.is_false(terminal_called)

    vim.fn.expand = orig_expand
  end)

  it("does not call terminal when runner has no compiler", function()
    clear_modules()

    local terminal_called = false
    package.loaded["autorun.terminal"] = {
      run = function(_)
        terminal_called = true
      end,
    }

    local restore = mock_fn({
      executable = function(_)
        return 0
      end, -- no compiler
      exepath = function(_)
        return ""
      end,
      expand = function(arg)
        if arg == "%" then
          return "/home/user/main.cpp"
        end
        return "/home/user/main.cpp"
      end,
      has = function(_)
        return 0
      end,
    })

    local orig_cwd = vim.loop.cwd
    vim.loop.cwd = function()
      return "/home/user"
    end

    local runners = require("autorun.runners")
    runners.run("cpp")

    assert.is_false(terminal_called)

    vim.loop.cwd = orig_cwd
    restore()
  end)
end)
