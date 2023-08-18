import 'package:flutter/material.dart';
import 'package:four_training/data/globals.dart';

Widget settingsButton(BuildContext ctx) {
  Widget settingsIcon = Icon(
    Icons.settings,
    color: Theme.of(ctx).colorScheme.onPrimary,
  );
  if (ctx.global.newCommitsAvailable) {
    settingsIcon = Stack(
      children: [
        Icon(
          Icons.settings,
          color: Theme.of(ctx).colorScheme.onPrimary,
        ),
        Positioned(
            top: 0,
            right: 0,
            child: Icon(Icons.brightness_1,
                size: 10, color: Theme.of(ctx).colorScheme.error))
      ],
    );
  }

  return IconButton(
    tooltip: 'Settings',
    icon: settingsIcon,
    onPressed: () {
      Navigator.pushNamed(ctx, '/settings');
    },
  );
}
