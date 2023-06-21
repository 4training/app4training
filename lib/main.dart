import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:four_training/routes/assets_page.dart';
import 'package:four_training/routes/startup_page.dart';
import 'package:four_training/routes/settings.dart';
import 'design/theme.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '4training',
      darkTheme: darkTheme,
      theme: lightTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => const StartupPage(),
        '/asset': (context) => const AssetsPage(),
        '/settings': (context) => const Settings(),
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // english, no country code
        Locale('de', ''), // german, no country code
      ],
    );
  }
}
