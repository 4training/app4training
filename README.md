<a href="https://github.com/4training/app4training/actions"><img src="https://github.com/4training/app4training/actions/workflows/main.yaml/badge.svg" alt="Tests Status"></a>
<a href="https://codecov.io/gh/4training/app4training"><img src="https://codecov.io/gh/4training/app4training/branch/main/graph/badge.svg" alt="Code Coverage (codecov)"></a>
# app4training
This app is an offline version of the website [4training.net](www.4training.net) written in dart/flutter.

Both, the app and the website are projects by [holydevelopers.net](https://holydevelopers.net/).

## License
Jesus says in Matthew 10:8, “Freely you have received; freely give.”
We follow His example and believe His principles are well expressed in the developer world through free and open-source software.
That's why we want you to have the ["four freedoms"](https://fsfe.org/freesoftware/) to freely use, study, share and improve this software.
We only require you to release any derived work under the same conditions (you're not allowed to take this code, build upon it and make the result proprietary):

[GNU Affero General Public License v3.0](LICENSE) with [Apple app store exception](COPYING.iOS)

The AGPL is essentially the same as the GPL with one additional paragraph allowing users who interact with the software over a network to receive the source for that program.
This is relevant for any web application where the way of software distribution is different than what was normal back when the GNU Public License was created.
The GPL wasn't aware of this form of distribution which is now so common. The AGPL fixes this "web services loophole".

Thanks to the people from the Nextcloud iOS app to [find and explain a solution](https://nextcloud.com/it/blog/nextcloud-ios-app-open-sourced/) to the restrictive policies of the Apple App Store which are not fully compatible with the GNU Public licenses.

## Testing and ensuring good code quality
For formatting code, we follow the dart guidelines by using the standard [dart format](https://dart.dev/tools/dart-format) tool. For linting we use [dart analyze](https://dart.dev/tools/dart-analyze) together with [riverpod lint](https://pub.dev/packages/riverpod_lint). Finally we have a test suite and upload coverage data to [codecov.io](https://codecov.io) - you can see the results in the codecov badge at the top here on the repo page. All that is run via Github Actions on any push or pull request (see [our Github Workflow](.github/workflows/main.yaml))

Before committing, please run the following commands and make sure they don't show any issues so that our tests will pass:
* `dart format .`
* `dart analyze`
* `dart run custom_lint`
* `flutter test`

## Contributing
By contributing you release your contributed code under the licensing terms explained above. Thank you!
