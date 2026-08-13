## help: print this help message
.PHONY: help
help:
	@echo 'Usage:'
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' |  sed -e 's/^/ /'

## all: lint and run tests
.PHONY: all
all: lint test

## test: run tests
.PHONY: test
test:
	./run_tests.sh

## lint: run linters and LuaLS typechecking
.PHONY: lint
lint: scripts/nvim-typecheck-action fastlint
	./scripts/nvim-typecheck-action/typecheck.sh --workdir scripts/nvim-typecheck-action lua

## fastlint: run only fast linters
.PHONY: fastlint
fastlint:
	luacheck lua tests --formatter plain
	stylua --check lua tests

scripts/nvim-typecheck-action:
	git clone https://github.com/stevearc/nvim-typecheck-action scripts/nvim-typecheck-action

## clean: reset the repository to a clean state
.PHONY: clean
clean:
	rm -rf scripts/nvim-typecheck-action
