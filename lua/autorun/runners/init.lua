local terminal = require("autorun.terminal")
local runners = {}

runners.supported_runners = {
	python = "autorun.runners.py",
	c = "autorun.runners.c",
	cpp = "autorun.runners.cpp",
}

runners.loaded_runners = {}

local function get(filetype)
	if runners.loaded_runners[filetype] then
		return runners.loaded_runners[filetype]
	end

	local runner_path = runners.supported_runners[filetype]
	if not runner_path then
		vim.notify("autorun: no runner registered for " .. filetype, vim.log.levels.ERROR)
		return nil
	end

	local ok, runner = pcall(require, runner_path)
	if not ok then
		vim.notify("autorun: failed to load runner for " .. filetype, vim.log.levels.ERROR)
		return nil
	end

	if runner.setup then
		runner.setup()
	end

	runners.loaded_runners[filetype] = runner
	return runner
end

function runners.supported()
	return vim.tbl_keys(runners.supported_runners)
end

function runners.run(filetype)
	if vim.fn.expand("%") == "" then
		vim.notify("autorun: save the file before running", vim.log.levels.WARN)
		return
	end

	local runner = get(filetype)
	if not runner then
		return
	end

	local command = runner.get_command()
	if not command then
		return
	end

	vim.cmd("silent! write")
	terminal.run(command)
end

return runners
