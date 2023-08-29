import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_language.dart';

class DropdownButtonAppLanguage extends ConsumerWidget {
  const DropdownButtonAppLanguage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLanguage appLanguage = ref.watch(appLanguageProvider);
    return DropdownButton(
        value: appLanguage.toString(),
        items: [
          for (var value in AppLanguage.availableAppLanguages)
            DropdownMenuItem<String>(
              value: value,
              child: Text(value.toUpperCase()),
            )
        ],
        onChanged: (String? value) {
          ref.read(appLanguageProvider.notifier).setLocale(value!);
        });
  }
}
