import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app4training/data/updates.dart';

class DropdownButtonCheckFrequency extends ConsumerWidget {
  const DropdownButtonCheckFrequency({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CheckFrequency checkFrequency = ref.watch(checkFrequencyProvider);

    return DropdownButton(
        value: checkFrequency.name,
        items: [
          for (var frequency in CheckFrequency.values)
            DropdownMenuItem<String>(
              value: frequency.name,
              child: Text(CheckFrequency.getLocalized(context, frequency)),
            )
        ],
        onChanged: (String? value) {
          ref.read(checkFrequencyProvider.notifier).setCheckFrequency(value!);
        });
  }
}
