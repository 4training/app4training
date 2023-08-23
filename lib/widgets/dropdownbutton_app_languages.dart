import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:four_training/data/globals.dart';

class DropDownButtonAppLanguage extends ConsumerWidget {
  const DropDownButtonAppLanguage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DropdownButton(
        // TODO reading from appLanguageProvider should also be fine here
        value: ref.read(sharedPreferencesProvider).getString('appLanguage'),
        items: GlobalData.availableAppLanguages
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value.toUpperCase()),
          );
        }).toList(),
        onChanged: (String? value) {
          String selectedLanguageCode = value!;

          // Persist the selection in the SharedPreferences TODO move this into the AppLanguageNotifier class
          ref
              .read(sharedPreferencesProvider)
              .setString("appLanguage", selectedLanguageCode);

          ref
              .read(appLanguageProvider.notifier)
              .setLocale(selectedLanguageCode);
        });
  }
}
