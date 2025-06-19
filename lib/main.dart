import 'package:app4training/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app4training/routes/routes.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/app_language.dart';
import 'data/globals.dart';
import 'design/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final packageInfo = await PackageInfo.fromPlatform();

  // Run initialization for our background task TODO enable in version 0.9
  // await Workmanager().initialize(backgroundTask, isInDebugMode: false);

  runApp(ProviderScope(overrides: [
    sharedPrefsProvider.overrideWithValue(prefs),
    packageInfoProvider.overrideWithValue(packageInfo)
  ], child: const App4Training()));
}

class App4Training extends ConsumerWidget {
  const App4Training({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLanguage appLanguage = ref.watch(appLanguageProvider);
    return MaterialApp(
      title: Globals.appTitle,
      darkTheme: darkTheme,
      theme: lightTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/',
      onGenerateRoute: (settings) => generateRoutes(settings),
      locale: appLanguage.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      scaffoldMessengerKey: ref.watch(scaffoldMessengerKeyProvider),
    );
  }
}
