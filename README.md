<a href="https://github.com/holybiber/forTraining/actions"><img src="https://github.com/holybiber/forTraining/actions/workflows/main.yaml/badge.svg" alt="Tests Status"></a>
<a href="https://codecov.io/gh/holybiber/forTraining"><img src="https://codecov.io/gh/holybiber/forTraining/branch/main/graph/badge.svg" alt="Code Coverage (codecov)"></a>
# 4training
This app is an offline version of the website [4training.net](www.4training.net).

Both, the app and the website are projects by [holydevelopers.net](https://holydevelopers.net/).

## Testing and ensuring good code quality
For formatting code, we follow the dart guidelines by using the standard [dart format](https://dart.dev/tools/dart-format) tool. For linting we use [dart analyze](https://dart.dev/tools/dart-analyze) together with [riverpod lint](https://pub.dev/packages/riverpod_lint). Finally we have a test suite and upload coverage data to [codecov.io](https://codecov.io) - you can see the results in the codecov badge at the top here on the repo page. All that is run via Github Actions on any push or pull request (see [our Github Workflow](.github/workflows/main.yaml))

Before committing, please run the following commands and make sure they don't show any issues so that our tests will pass:
* `dart format .`
* `dart analyze`
* `dart run custom_lint`
* `flutter test`
