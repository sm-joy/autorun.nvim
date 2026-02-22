.PHONY: lint format format-check test

lint:
	luacheck lua/autorun/commands.lua lua/autorun/config.lua lua/autorun/init.lua lua/autorun/window.lua lua/autorun/runners/c.lua lua/autorun/runners/cpp.lua lua/autorun/runners/init.lua lua/autorun/runners/py.lua plugin/autorun.lua tests/autorun_spec.lua

test:
	nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/" -c "qa"

format:
	stylua lua/ tests/

format-check:
	stylua --check lua/ tests/

check: format-check lint

all: format-check lint test
