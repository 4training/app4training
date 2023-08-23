import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:four_training/routes/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/globals.dart';
import 'design/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // The InheritedWidget holding our global state
  // needs to be at the root of the widget tree
  runApp(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: GlobalData(child: const MyApp())));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLanguage appLanguage = ref.watch(appLanguageProvider);
    return MaterialApp(
      title: '4training',
      darkTheme: darkTheme,
      theme: lightTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/',
      onGenerateRoute: (settings) => generateRoutes(settings, context),
      locale: appLanguage.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
