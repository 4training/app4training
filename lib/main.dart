import 'package:flutter/material.dart';
import 'package:four_training/routes/routes.dart';
import 'data/globals.dart';
import 'design/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  // The InheritedWidget holding our global state
  // needs to be at the root of the widget tree
  runApp(GlobalData(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        // rebuild when locale changes
        listenable: context.global.appLanguageCode,
        builder: (context, child) {
          return MaterialApp(
            title: '4training',
            darkTheme: darkTheme,
            theme: lightTheme,
            themeMode: ThemeMode.system,
            initialRoute: '/',
            onGenerateRoute: (settings) => generateRoutes(settings, context),
            locale: context.global.appLanguageCode.value,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          );
        });
  }
}
