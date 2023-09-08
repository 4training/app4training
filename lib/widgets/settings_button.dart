import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:four_training/data/globals.dart';

/// Button in the top right corner of the main view to open the settings page
/// Adds a colorful mark to the icon in case there are updates available
class SettingsButton extends ConsumerWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool updatesAvailable = ref.watch(updatesAvailableProvider);
    Widget settingsIcon = Icon(
      Icons.settings,
      color: Theme.of(context).colorScheme.onPrimary,
    );
    if (updatesAvailable) {
      settingsIcon = Stack(
        children: [
          Icon(
            Icons.settings,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          Positioned(
              top: 0,
              right: 0,
              child: Icon(Icons.brightness_1,
                  size: 10, color: Theme.of(context).colorScheme.error))
        ],
      );
    }

    return IconButton(
      tooltip: 'Settings',
      icon: settingsIcon,
      onPressed: () {
        Navigator.pushNamed(context, '/settings');
      },
    );
  }
}
