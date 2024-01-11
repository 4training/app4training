import 'dart:async';

import 'package:app4training/data/app_language.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/widgets/languages_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Second onboarding screen:
/// Download languages - show the LanguagesTable full screen
class DownloadLanguagesPage extends ConsumerWidget {
  /// Don't show the back button
  final bool noBackButton;

  /// Which route should be shown after user clicks on 'Continue'
  final String continueTarget;

  const DownloadLanguagesPage(
      {this.noBackButton = false,
      this.continueTarget = '/home',
// TODO version 0.8     this.continueTarget = '/onboarding/3',
      super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLanguage appLanguage = ref.watch(appLanguageProvider);

    List<Widget> backButton = noBackButton
        ? []
        : [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: const StadiumBorder(),
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/onboarding/1');
              },
              child: Text(context.l10n.back),
            ),
            const Spacer()
          ];

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
                  ...backButton,
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
                      unawaited(Navigator.pushReplacementNamed(
                          context, continueTarget));
                    },
                    child: Text(context.l10n.letsGo),
// TODO version 0.8                   child: Text(context.l10n.continueText),
                  ),
                  const Spacer(flex: 2),
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
