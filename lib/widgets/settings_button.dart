import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:four_training/data/globals.dart';

class SettingsButton extends ConsumerWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool newCommitsAvailable = ref.watch(newCommitsAvailableProvider);
    Widget settingsIcon = Icon(
      Icons.settings,
      color: Theme.of(context).colorScheme.onPrimary,
    );
    if (newCommitsAvailable) {
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
