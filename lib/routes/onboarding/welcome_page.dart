import 'package:app4training/data/app_language.dart';
import 'package:app4training/data/categories.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/widgets/dropdownbutton_app_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// First onboarding screen:
/// Welcome and select the app language. The upper half has some promo
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text(Globals.appTitle)),
        body: const WelcomeScreen());
  }
}

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(),
            ),
            Text(context.l10n.welcome,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
            Expanded(child: Container()),
            Text(context.l10n.selectAppLanguage),
            const SizedBox(height: 20),
            const DropdownButtonAppLanguage(),
            Expanded(
              child: Container(),
            ),
            const Divider(),
            const PromoBlock(),
            Expanded(
              flex: 2,
              child: Container(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: const StadiumBorder(),
              ),
              onPressed: () {
                // Make sure appLanguage is now saved
                // so that WelcomePage won't be shown again next time
                ref.read(appLanguageProvider.notifier).persistNow();
                Navigator.pushReplacementNamed(context, '/onboarding/2');
              },
              child: Text(context.l10n.continueText),
            ),
          ],
        ));
  }
}

/// Show logo and some nice features of our app
///
/// TODO: implement the bullet points of the features as a real list
/// that does correct line break in case a line is too long.
///
/// Currently it would wrap
/// • This feature is very
/// long to describe
/// Instead of
/// • This feature is very
///   long to describe
/// See https://stackoverflow.com/questions/51690067/how-can-i-write-a-paragraph-with-bullet-points-using-flutter
/// but I had problems centering the result
class PromoBlock extends StatelessWidget {
  const PromoBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Image.asset('assets/for_training.png', width: 100, height: 100),
        Center(
            child: Text(context.l10n.appName,
                style: Theme.of(context).textTheme.headlineMedium)),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.center,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align children to the left
            children: [
              Text(
                '• $countAvailableLanguages ${context.l10n.languages}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                '• ${context.l10n.promoFeature1(worksheetCategories.length)}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                '• ${context.l10n.promoFeature2}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                '• ${context.l10n.promoFeature3}',
                style: Theme.of(context).textTheme.bodyLarge,
              )
            ],
          ),
        )
      ],
    );
  }
}
