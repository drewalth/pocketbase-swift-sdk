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

.PHONY: pretty lint preflight start_test_server

