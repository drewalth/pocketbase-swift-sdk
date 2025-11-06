pretty:
	@swiftformat . --config airbnb.swiftformat
	@swiftlint --config .swiftlint.yml --fix --format

lint:
	swiftlint . --config .swiftlint.yml
