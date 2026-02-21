.PHONY: test lint format format-check

test:
	nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/" -c "qa"

format:
	stylua lua/ tests/

format-check:
	stylua --check lua/ tests/
