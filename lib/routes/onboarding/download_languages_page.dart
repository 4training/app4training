import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/widgets/languages_table.dart';
import 'package:flutter/material.dart';

/// Second onboarding screen:
/// Download languages - show the LanguagesTable full screen
class DownloadLanguagesPage extends StatelessWidget {
  const DownloadLanguagesPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                const Expanded(child: LanguagesTable()),
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
                    onPressed: () {
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
