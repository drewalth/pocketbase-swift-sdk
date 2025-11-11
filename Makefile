pretty:
	@swiftformat . --config airbnb.swiftformat
	@swiftlint --config .swiftlint.yml --fix --format

lint:
	swiftlint . --config .swiftlint.yml

preflight:
	$(MAKE) lint
	xcrun swift package clean
	xcrun swift build
	$(MAKE) test_ci
	@echo "All checks passed"

test_ci:
	$(MAKE) start_test_server & sleep 10 && xcrun swift package clean && xcrun swift test

start_test_server:
	cd ./test-server && go run . serve --dir="./test_pb_data"

setup:
	$(MAKE) install_homebrew
	$(MAKE) install_swiftlint
	$(MAKE) install_swiftformat
	$(MAKE) install_go_dependencies

install_swiftlint: install_homebrew
	@which swiftlint || brew install swiftlint

install_swiftformat: install_homebrew
	@which swiftformat || brew install swiftformat

install_homebrew:
	@which brew || /bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

install_go: install_homebrew
	@which go || brew install go

install_go_dependencies:
	cd ./test-server && go get ./...

.PHONY: pretty lint preflight start_test_server setup install_swiftlint install_swiftformat install_go_dependencies install_homebrew install_go

