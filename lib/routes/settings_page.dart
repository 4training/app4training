import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:four_training/data/globals.dart';
import 'package:four_training/l10n/l10n.dart';
import 'package:four_training/widgets/check_now_button.dart';
import 'package:four_training/widgets/dropdownbutton_theme.dart';
import 'package:four_training/widgets/languages_table.dart';
import '../data/languages.dart';
import '../widgets/dropdownbutton_app_language.dart';
import '../widgets/dropdownbutton_check_frequency.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
            child: Column(children: [
          // Set app language
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.l10n.appLanguage,
                  style: Theme.of(context).textTheme.bodyMedium),
              const DropdownButtonAppLanguage(),
            ],
          ),
          const SizedBox(height: 10),
          const LanguageSettings(),
          const UpdateSettings()
          // const SizedBox(height: 10),
          // const DesignSettings()
        ])),
      ),
    );
  }
}

/// All settings regarding languages.
/// The main part of this is in [LanguagesTable]
class LanguageSettings extends ConsumerWidget {
  const LanguageSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO move this calculation somewhere else?
    int sizeInKB = 0;
    for (String langCode in Globals.availableLanguages) {
      sizeInKB += ref.watch(languageProvider(langCode)).sizeInKB;
    }

    return Column(children: [
      Align(
          alignment: Alignment.topLeft,
          child: Text(
            context.l10n.languages,
            style: Theme.of(context).textTheme.titleLarge,
          )),
      const SizedBox(height: 10),
      Text(
        context.l10n.languagesText,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 10),
      const LanguagesTable(),
      Text(
        "${context.l10n.diskUsage}: $sizeInKB kB",
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 10),
    ]);
  }
}

/// All settings about checking for updates
class UpdateSettings extends ConsumerWidget {
  const UpdateSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO
    // DateTime lastCheck = ref.watch(updatesAvailableProvider);
    // Convert into human readable string in local time
    // DateTime localTime = lastCheck.add(DateTime.now().timeZoneOffset);
    // String timestamp = DateFormat('yyyy-MM-dd HH:mm').format(localTime);
    String timestamp = 'TODO see #87';

    return Column(children: [
      Align(
          alignment: Alignment.topLeft,
          child: Text(context.l10n.automaticUpdate,
              style: Theme.of(context).textTheme.titleLarge)),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(context.l10n.updateText,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
      const SizedBox(height: 10),
      const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          DropdownButtonCheckFrequency(),
        ],
      ),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text("${context.l10n.lastTime} ",
            style: Theme.of(context).textTheme.bodyMedium),
        Text(timestamp, style: Theme.of(context).textTheme.bodyMedium)
      ]),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CheckNowButton(buttonText: context.l10n.checkNow, callback: () {})
        ],
      )
    ]);
  }
}

/// TODO select light / dark theme
class DesignSettings extends StatelessWidget {
  const DesignSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(context.l10n.theme, style: Theme.of(context).textTheme.bodyMedium),
        const DropDownButtonTheme(),
      ],
    );
  }
}
