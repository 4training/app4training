import 'package:app4training/data/globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DropdownButtonAutomaticUpdates extends ConsumerWidget {
  const DropdownButtonAutomaticUpdates({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AutomaticUpdates setting = ref.watch(automaticUpdatesProvider);

    return DropdownButton(
        value: setting.name,
        items: [
          for (var option in AutomaticUpdates.values)
            DropdownMenuItem<String>(
              value: option.name,
              child: Text(AutomaticUpdates.getLocalized(context, option)),
            )
        ],
        onChanged: (String? value) {
          ref
              .read(automaticUpdatesProvider.notifier)
              .setAutomaticUpdates(value);
        });
  }
}
