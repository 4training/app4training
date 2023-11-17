import 'package:app4training/widgets/dropdownbutton_automatic_updates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app4training/data/updates.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/widgets/check_now_button.dart';
import 'package:app4training/widgets/dropdownbutton_theme.dart';
import 'package:app4training/widgets/languages_table.dart';
import 'package:intl/intl.dart';
import '../data/languages.dart';
import '../widgets/dropdownbutton_app_language.dart';
import '../widgets/dropdownbutton_check_frequency.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settings)),
      body: Padding(
        padding: const EdgeInsets.all(16),
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
          const Expanded(child: LanguageSettings()),
          const UpdateSettings()
          // const SizedBox(height: 10),
          // const DesignSettings()
        ]),
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
    int sizeInKB = ref.watch(diskUsageProvider);
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
      const Expanded(child: LanguagesTable()),
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
    DateTime lastCheck = ref.watch(lastCheckedProvider);
    // Convert into human readable string in local time
    DateTime localTime = lastCheck.add(DateTime.now().timeZoneOffset);
    String timestamp = DateFormat('yyyy-MM-dd HH:mm').format(localTime);

    return Column(children: [
      // Updates (headline)
      Align(
          alignment: Alignment.topLeft,
          child: Text(context.l10n.updates,
              style: Theme.of(context).textTheme.titleLarge)),
      // Check for updates
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
              child: Text(context.l10n.checkFrequency,
                  style: Theme.of(context).textTheme.bodyMedium)),
          const SizedBox(width: 20),
          const DropdownButtonCheckFrequency(),
        ],
      ),
      const SizedBox(height: 10),
      // Last check with date
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text("${context.l10n.lastCheck} ",
            style: Theme.of(context).textTheme.bodyMedium),
        Text(timestamp, style: Theme.of(context).textTheme.bodyMedium)
      ]),
      const SizedBox(height: 10),
      // Check now
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [CheckNowButton(buttonText: context.l10n.checkNow)],
      ),
      const SizedBox(height: 10),

      // Do automatic updates
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
              child: Text(context.l10n.doAutomaticUpdates,
                  style: Theme.of(context).textTheme.bodyMedium)),
          const SizedBox(width: 20),
          const DropdownButtonAutomaticUpdates(),
        ],
      ),
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
