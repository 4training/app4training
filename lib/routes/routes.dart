import 'package:flutter/material.dart';
import 'package:four_training/data/globals.dart';
import 'package:four_training/routes/settings_page.dart';
import 'package:four_training/routes/startup_page.dart';
import 'package:four_training/routes/view_page.dart';

/// TODO get rid of that page or change it in a way that it's not a dead end anymore
class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Error')),
    );
  }
}

Route<Object?> generateRoutes(RouteSettings settings) {
  debugPrint('Handling route "${settings.name}"');
  if ((settings.name == null) || (settings.name == '/')) {
    return MaterialPageRoute<void>(
      builder: (_) => const StartupPage(),
    );
  } else if (settings.name!.startsWith('/view')) {
    // route should be /view/pageName/langCode - deep linking is possible
    final List<String> parts = settings.name!.split('/');
    String page = defaultPage;
    String langCode = 'en';
    if ((parts.length > 2) && (parts[2] != '')) page = parts[2];
    if (parts.length > 3) langCode = parts[3];
    currentPage = page;
    return MaterialPageRoute<void>(builder: (_) => ViewPage(page, langCode));
  } else if (settings.name == '/settings') {
    return MaterialPageRoute<void>(
      builder: (_) => const SettingsPage(),
    );
  }

  debugPrint('Warning: unknown route ${settings.name}');
  return MaterialPageRoute<void>(
    builder: (_) => const ErrorPage(),
  );
}
