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
    assert.equals("vertical", cfg.options.term_style)
    assert.equals("40", cfg.options.term_size)
  end)

  it("merges user opts over defaults", function()
    require("autorun").setup({ term_size = "60" })
    local cfg = require("autorun.config")
    assert.equals("60", cfg.options.term_size)
    assert.equals("vertical", cfg.options.term_style) -- default preserved
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
-- py runner
-- ============================================================

describe("py runner", function()
  before_each(clear_modules)

  it("setup() finds venv python when available", function()
    local cwd = "/home/user/project"
    local venv_python = cwd .. "/.venv/bin/python"

    local restore = mock_fn({
      executable = function(path)
        return path == venv_python and 1 or 0
      end,
      exepath = function(_)
        return venv_python
      end,
    })

    -- mock vim.loop.cwd
    local orig_cwd = vim.loop.cwd
    vim.loop.cwd = function()
      return cwd
    end

    local runner = require("autorun.runners.py")
    runner.setup()
    assert.equals(venv_python, runner.config.python_path)

    vim.loop.cwd = orig_cwd
    restore()
  end)

  it("setup() falls back to system python when no venv", function()
    local restore = mock_fn({
      executable = function(cmd)
        -- no venv paths, only system python
        if cmd == "python" then
          return 1
        end
        return 0
      end,
      exepath = function(_)
        return "/usr/bin/python"
      end,
    })

    local orig_cwd = vim.loop.cwd
    vim.loop.cwd = function()
      return "/home/user/project"
    end

    local runner = require("autorun.runners.py")
    runner.setup()
    assert.equals("/usr/bin/python", runner.config.python_path)

    vim.loop.cwd = orig_cwd
    restore()
  end)

  it("setup() falls back to python3 when python not found", function()
    local restore = mock_fn({
      executable = function(cmd)
        if cmd == "python3" then
          return 1
        end
        return 0
      end,
      exepath = function(_)
        return "/usr/bin/python3"
      end,
    })

    local orig_cwd = vim.loop.cwd
    vim.loop.cwd = function()
      return "/home/user/project"
    end

    local runner = require("autorun.runners.py")
    runner.setup()
    assert.equals("/usr/bin/python3", runner.config.python_path)

    vim.loop.cwd = orig_cwd
    restore()
  end)

  it("setup() sets nil when no python found", function()
    local restore = mock_fn({
      executable = function(_)
        return 0
      end,
      exepath = function(_)
        return ""
      end,
    })

    local orig_cwd = vim.loop.cwd
    vim.loop.cwd = function()
      return "/home/user/project"
    end

    local runner = require("autorun.runners.py")
    runner.setup()
    assert.is_nil(runner.config.python_path)

    vim.loop.cwd = orig_cwd
    restore()
  end)

  it("get_command() returns nil when python not found", function()
    local restore = mock_fn({
      executable = function(_)
        return 0
      end,
      exepath = function(_)
        return ""
      end,
    })

    local orig_cwd = vim.loop.cwd
    vim.loop.cwd = function()
      return "/home/user/project"
    end

    local runner = require("autorun.runners.py")
    runner.setup()
    assert.is_nil(runner.get_command())

    vim.loop.cwd = orig_cwd
    restore()
  end)

  it("get_command() wraps python path and filename in quotes", function()
    local restore = mock_fn({
      executable = function(cmd)
        return cmd == "python" and 1 or 0
      end,
      exepath = function(_)
        return "/usr/bin/python"
      end,
      expand = function(_)
        return "/home/user/script.py"
      end,
    })

    local orig_cwd = vim.loop.cwd
    vim.loop.cwd = function()
      return "/home/user/project"
    end

    local runner = require("autorun.runners.py")
    runner.setup()
    local cmd = runner.get_command()

    assert.equals('"/usr/bin/python" "/home/user/script.py"', cmd)

    vim.loop.cwd = orig_cwd
    restore()
  end)
end)

-- ============================================================
-- c runner
-- ============================================================

describe("c runner", function()
  before_each(clear_modules)

  it("setup() finds gcc when available", function()
    local restore = mock_fn({
      executable = function(cmd)
        return cmd == "gcc" and 1 or 0
      end,
      exepath = function(_)
        return "/usr/bin/gcc"
      end,
    })

    local runner = require("autorun.runners.c")
    runner.setup()
    assert.equals("/usr/bin/gcc", runner.config.compiler_path)

    restore()
  end)

  it("setup() respects preferred compiler from config", function()
    local restore = mock_fn({
      executable = function(cmd)
        return cmd == "clang" and 1 or 0
      end,
      exepath = function(_)
        return "/usr/bin/clang"
      end,
    })

    -- set preferred compiler in config before requiring runner
    local cfg = require("autorun.config")
    cfg.options = { prefered_c_compiler = "clang" }

    local runner = require("autorun.runners.c")
    runner.setup()
    assert.equals("/usr/bin/clang", runner.config.compiler_path)

    restore()
  end)

  it("setup() sets nil when no compiler found", function()
    local restore = mock_fn({
      executable = function(_)
        return 0
      end,
      exepath = function(_)
        return ""
      end,
    })

    local runner = require("autorun.runners.c")
    runner.setup()
    assert.is_nil(runner.config.compiler_path)

    restore()
  end)

  it("get_command() returns nil when no compiler", function()
    local restore = mock_fn({
      executable = function(_)
        return 0
      end,
      exepath = function(_)
        return ""
      end,
    })

    local runner = require("autorun.runners.c")
    runner.setup()
    assert.is_nil(runner.get_command())

    restore()
  end)

  it("get_command() produces correct command on linux", function()
    local restore = mock_fn({
      executable = function(cmd)
        return cmd == "gcc" and 1 or 0
      end,
      exepath = function(_)
        return "/usr/bin/gcc"
      end,
      expand = function(arg)
        if arg == "%:p" then
          return "/home/user/main.c"
        end
        if arg == "%:t:r" then
          return "main"
        end
        return ""
      end,
      has = function(_)
        return 0
      end, -- not win32
    })

    local runner = require("autorun.runners.c")
    runner.setup()
    local cmd = runner.get_command()

    assert.is_not_nil(cmd)
    assert.is_truthy(cmd:match("/usr/bin/gcc"))
    assert.is_truthy(cmd:match("main%.c"))
    assert.is_truthy(cmd:match('%./"main"')) -- linux run prefix

    restore()
  end)

  it("get_command() uses .exe and .\\ prefix on windows", function()
    local restore = mock_fn({
      executable = function(cmd)
        return cmd == "gcc" and 1 or 0
      end,
      exepath = function(_)
        return "C:/MinGW/bin/gcc.exe"
      end,
      expand = function(arg)
        if arg == "%:p" then
          return "C:/project/main.c"
        end
        if arg == "%:t:r" then
          return "main"
        end
        return ""
      end,
      has = function(_)
        return 1
      end, -- win32
    })

    local runner = require("autorun.runners.c")
    runner.setup()
    local cmd = runner.get_command()

    assert.is_not_nil(cmd)
    assert.is_truthy(cmd:match("main%.exe"))
    assert.is_truthy(cmd:match("%.\\")) -- windows run prefix

    restore()
  end)
end)

-- ============================================================
-- cpp runner
-- ============================================================

describe("cpp runner", function()
  before_each(clear_modules)

  it("setup() finds g++ when available", function()
    local restore = mock_fn({
      executable = function(cmd)
        return cmd == "g++" and 1 or 0
      end,
      exepath = function(_)
        return "/usr/bin/g++"
      end,
    })

    local runner = require("autorun.runners.cpp")
    runner.setup()
    assert.equals("/usr/bin/g++", runner.config.compiler_path)

    restore()
  end)

  it("setup() falls back to clang++ when g++ not found", function()
    local restore = mock_fn({
      executable = function(cmd)
        return cmd == "clang++" and 1 or 0
      end,
      exepath = function(_)
        return "/usr/bin/clang++"
      end,
    })

    local runner = require("autorun.runners.cpp")
    runner.setup()
    assert.equals("/usr/bin/clang++", runner.config.compiler_path)

    restore()
  end)

  it("setup() sets nil when no compiler found", function()
    local restore = mock_fn({
      executable = function(_)
        return 0
      end,
      exepath = function(_)
        return ""
      end,
    })

    local runner = require("autorun.runners.cpp")
    runner.setup()
    assert.is_nil(runner.config.compiler_path)

    restore()
  end)

  it("get_command() returns nil when no compiler", function()
    local restore = mock_fn({
      executable = function(_)
        return 0
      end,
      exepath = function(_)
        return ""
      end,
    })

    local runner = require("autorun.runners.cpp")
    runner.setup()
    assert.is_nil(runner.get_command())

    restore()
  end)

  it("get_command() produces correct command on linux", function()
    local restore = mock_fn({
      executable = function(cmd)
        return cmd == "g++" and 1 or 0
      end,
      exepath = function(_)
        return "/usr/bin/g++"
      end,
      expand = function(arg)
        if arg == "%:p" then
          return "/home/user/main.cpp"
        end
        if arg == "%:t:r" then
          return "main"
        end
        return ""
      end,
      has = function(_)
        return 0
      end, -- not win32
    })

    local runner = require("autorun.runners.cpp")
    runner.setup()
    local cmd = runner.get_command()

    assert.is_not_nil(cmd)
    assert.is_truthy(cmd:match("/usr/bin/g%+%+"))
    assert.is_truthy(cmd:match("main%.cpp"))
    assert.is_truthy(cmd:match('%./"main"')) -- linux run prefix

    restore()
  end)

  it("get_command() uses .exe and .\\ prefix on windows", function()
    local restore = mock_fn({
      executable = function(cmd)
        return cmd == "g++" and 1 or 0
      end,
      exepath = function(_)
        return "C:/MinGW/bin/g++.exe"
      end,
      expand = function(arg)
        if arg == "%:p" then
          return "C:/project/main.cpp"
        end
        if arg == "%:t:r" then
          return "main"
        end
        return ""
      end,
      has = function(_)
        return 1
      end, -- win32
    })

    local runner = require("autorun.runners.cpp")
    runner.setup()
    local cmd = runner.get_command()

    assert.is_not_nil(cmd)
    assert.is_truthy(cmd:match("main%.exe"))
    assert.is_truthy(cmd:match("%.\\")) -- windows run prefix

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
