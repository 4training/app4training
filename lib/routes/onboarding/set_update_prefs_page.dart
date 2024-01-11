import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/widgets/dropdownbutton_automatic_updates.dart';
import 'package:app4training/widgets/dropdownbutton_check_frequency.dart';
import 'package:flutter/material.dart';

/// Third onboarding screen:
/// Set update preferences
class SetUpdatePrefsPage extends StatelessWidget {
  const SetUpdatePrefsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                      Navigator.pushReplacementNamed(context, '/view');
                    },
                    child: Text(context.l10n.letsGo),
                  ),
                  const Spacer(flex: 2),
                ])
              ],
            )));
  }
}
