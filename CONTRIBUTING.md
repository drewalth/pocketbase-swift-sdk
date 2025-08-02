# Contributing

Any and all contributions are welcome!

## How to contribute

1. Clone the repository
2. Create a new branch
3. Make your changes and commit using the [conventional commit](https://www.conventionalcommits.org/en/v1.0.0/) message format. Note: currently there is no linting for commit messages, but I plan to add it in the future. This will help generate changelogs and release notes. For now, try to follow the format as closely as possible.
4. Push your branch to the repository
5. Create a pull request
6. Pull requests should be titled in the format of `feat: <description>` or `fix: <description>`
7. Pull requests should include a description of the changes made and a link to the issue that the pull request is addressing if applicable.

## How to run the project

1. Clone the repository
2. Open the project in your Terminal
3. Open the example project in Xcode. `cd example/ && xed .`
4. Start the dev server. `cd test-server && go run . serve --dir="./test_pb_data"`
