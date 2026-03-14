.PHONY: lint format format-check test

lint:
	luacheck lua plugin tests
format:
	stylua lua/ tests/

test:
	nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/" -c "qa"

format-check:
	stylua --check lua/ tests/

check: format-check lint

all: format-check lint test
