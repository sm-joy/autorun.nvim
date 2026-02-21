local plugin = require("autorun")
local config = require("autorun.config")

describe("autorun", function()
	before_each(function()
		package.loaded["autorun"] = nil
		package.loaded["autorun.config"] = nil
		package.loaded["autorun.commands"] = nil
		package.loaded["autorun.terminal"] = nil
		package.loaded["autorun.runners.py"] = nil
	end)

	describe("setup()", function()
		it("runs without errors with no opts", function()
			assert.has_no.errors(function()
				require("autorun").setup({})
			end)
		end)

		it("uses default options when no opts passed", function()
			require("autorun").setup({})
			local cfg = require("autorun.config")
			assert.equals("vertical", cfg.options.term_style)
			assert.equals("40", cfg.options.term_size)
		end)

		it("merges user opts over defaults", function()
			require("autorun").setup({ term_size = "60" })
			local cfg = require("autorun.config")
			assert.equals("60", cfg.options.term_size)
			assert.equals("vertical", cfg.options.term_style)
		end)
	end)

	describe("runners.py", function()
		it("loads without errors", function()
			assert.has_no.errors(function()
				require("autorun.runners.py")
			end)
		end)
	end)
end)
