import 'package:app4training/data/app_language.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/widgets/languages_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Second onboarding screen:
/// Download languages - show the LanguagesTable full screen
class DownloadLanguagesPage extends ConsumerWidget {
  const DownloadLanguagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLanguage appLanguage = ref.watch(appLanguageProvider);
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
                  Expanded(flex: 2, child: Container()),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/onboarding/1');
                    },
                    child: Text(context.l10n.back),
                  ),
                  Expanded(child: Container()),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () async {
                      // Show warning if user hasn't downloaded his app language
                      if (!ref
                          .read(languageProvider(appLanguage.languageCode))
                          .downloaded) {
                        bool result = await showDialog(
                            context: context,
                            builder: (context) {
                              return const MissingAppLanguageDialog();
                            });
                        if (!result) return;
                      }
                      if (!context.mounted) return;
                      Navigator.pushReplacementNamed(context, '/onboarding/3');
                    },
                    child: Text(context.l10n.continueText),
                  ),
                  Expanded(flex: 2, child: Container()),
                ])
              ],
            )));
  }
}

/// Shows a dialog when a user tries to proceed without
/// having downloaded his app language
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
          TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(context.l10n.ignore))
        ]);
  }
}
