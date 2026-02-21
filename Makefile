.PHONY: test lint format format-check

test:
	nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/" -c "qa"

lint:
	lua C:\Users\zihad\AppData\Roaming\luarocks\bin\luacheck lua/ tests/

format:
	stylua lua/ tests/

format-check:
	stylua --check lua/ tests/
