import 'package:app4training/data/globals.dart';
import 'package:app4training/data/updates.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/widgets/dropdownbutton_automatic_updates.dart';
import 'package:app4training/widgets/dropdownbutton_check_frequency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Third onboarding screen:
/// Set update preferences
class SetUpdatePrefsPage extends ConsumerWidget {
  const SetUpdatePrefsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        appBar: AppBar(title: Text(context.l10n.updates)),
        body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                Text(context.l10n.updatesExplanation),
                const Spacer(flex: 2),
                Text(context.l10n.checkFrequency,
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 10),
                const DropdownButtonCheckFrequency(),
                const Spacer(flex: 2),
                Text(context.l10n.doAutomaticUpdates,
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 10),
                const DropdownButtonAutomaticUpdates(),
                const Spacer(flex: 8),
                Row(children: [
                  const Spacer(flex: 2),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/onboarding/2');
                    },
                    child: Text(context.l10n.back),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () {
                      // Make sure settings are saved
                      // so that this page won't be shown again
                      ref.read(automaticUpdatesProvider.notifier).persistNow();
                      ref.read(checkFrequencyProvider.notifier).persistNow();
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    child: Text(context.l10n.letsGo),
                  ),
                  const Spacer(flex: 2),
                ])
              ],
            )));
  }
}
