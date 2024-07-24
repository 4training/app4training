import 'dart:async';

import 'package:app4training/data/app_language.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/widgets/languages_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Second onboarding screen:
/// Download languages - show the LanguagesTable full screen.
/// The user needs to download the app language to be able to continue
/// (otherwise the continue button is greyed out and shows a warning)
class DownloadLanguagesPage extends ConsumerWidget {
  const DownloadLanguagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLanguage appLanguage = ref.watch(appLanguageProvider);
    final bool appLanguageDownloaded =
        ref.watch(languageProvider(appLanguage.languageCode)).downloaded;

    // unfortunately an ElevatedButton only looks greyed out when setting
    // onPressed to null - so create a greyed-out style by hand so that
    // we can have a clickable greyed-out button.
    ButtonStyle buttonStyle = appLanguageDownloaded
        ? ElevatedButton.styleFrom(shape: const StadiumBorder())
        : ElevatedButton.styleFrom(
            // https://api.flutter.dev/flutter/material/ElevatedButton/defaultStyleOf.html
            backgroundColor:
                Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
            foregroundColor:
                Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
            elevation: 0,
            shape: const StadiumBorder(),
          );

    return Scaffold(
        appBar: AppBar(title: Text(context.l10n.downloadLanguages)),
        body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text(context.l10n.downloadLanguagesExplanation),
                const SizedBox(height: 20),
                Expanded(
                    child: LanguagesTable(
                  highlightLang: appLanguage.languageCode,
                )),
                const SizedBox(height: 20),
                Row(children: [
                  const Spacer(flex: 2),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/onboarding/1');
                    },
                    child: Text(context.l10n.back),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: buttonStyle,
                    onPressed: () async {
                      // Show warning if user hasn't downloaded his app language
                      if (!appLanguageDownloaded) {
                        await showDialog(
                            context: context,
                            builder: (context) {
                              return const MissingAppLanguageDialog();
                            });
                        return;
                      }
                      unawaited(Navigator.pushReplacementNamed(
                          context, getNextRoute(ref)));
                    },
                    child: Text(context.l10n.continueText),
                  ),
                  const Spacer(flex: 2),
                ])
              ],
            )));
  }

  /// Which route should we continue with after this?
  /// Currently (version 0.8) this is the last onboarding step and we proceed
  /// to the home screen.
  /// TODO for version 0.9:
  /// During onboarding (no automatic updates settings saved): go to third step,
  /// otherwise (user deleted all languages and ends up here): go to /home
  String getNextRoute(WidgetRef ref) {
    return '/home';
/*
    // TODO for version 0.9
    return ref.read(sharedPrefsProvider).getString('checkFrequency') == null
        ? '/onboarding/3'
        : '/home';
*/
  }
}

/// Shows a dialog when a user tries to proceed without
/// having downloaded his app language.
class MissingAppLanguageDialog extends StatelessWidget {
  const MissingAppLanguageDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: Text(context.l10n.warning),
        content: Text(context.l10n.warnMissingAppLanguage),
        actions: <Widget>[
          TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(context.l10n.gotit)),
        ]);
  }
}
