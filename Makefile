pretty:
	swiftformat . --config airbnb.swiftformat

upload_dysm_datadog:
	export DATADOG_API_KEY=d6c769a7df6172e6acaee3a7b524e147 && export DATADOG_SITE=us5.datadoghq.com && npx datadog-ci dsyms upload ~/Library/Developer/Xcode/DerivedData/

lint:
	swiftlint .
