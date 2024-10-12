import 'package:app4training/routes/about_page.dart';
import 'package:app4training/routes/error_page.dart';
import 'package:app4training/routes/feedback_page.dart';
import 'package:app4training/routes/home_page.dart';
import 'package:app4training/routes/onboarding/download_languages_page.dart';
import 'package:app4training/routes/onboarding/set_update_prefs_page.dart';
import 'package:app4training/routes/onboarding/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:app4training/routes/settings_page.dart';
import 'package:app4training/routes/startup_page.dart';
import 'package:app4training/routes/view_page.dart';

Route<Object?> generateRoutes(RouteSettings settings) {
  debugPrint('Handling route "${settings.name}"');
  if ((settings.name == null) || (settings.name == '/')) {
    return MaterialPageRoute<void>(
      settings: settings, // Necessary for the NavigatorObserver while testing
      builder: (_) => const StartupPage(),
    );
  } else if (settings.name == '/home') {
    return MaterialPageRoute<void>(
        settings: settings, builder: (_) => const HomePage());
  } else if (settings.name!.startsWith('/view')) {
    // route should be /view/pageName/langCode - deep linking is possible
    final List<String> parts = settings.name!.split('/');
    if ((parts.length <= 3) || (parts[2] == '') || (parts[3] == '')) {
      debugPrint('Unexpected route ${settings.name} - redirecting to /home');
      return MaterialPageRoute<void>(
          settings: settings, builder: (_) => const HomePage());
    }
    String page = parts[2];
    String langCode = parts[3];
    return MaterialPageRoute<void>(
        settings: settings, builder: (_) => ViewPage(page, langCode));
  } else if (settings.name == '/settings') {
    return MaterialPageRoute<void>(
        settings: settings, builder: (_) => const SettingsPage());
  } else if (settings.name == '/about') {
    return MaterialPageRoute<void>(
        settings: settings, builder: (_) => const AboutPage());
  } else if (settings.name == '/feedback') {
    return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => FeedbackPage(
            worksheetPage: settings.arguments is FeedbackArguments
                ? (settings.arguments as FeedbackArguments).worksheetPage
                : null,
            langCode: settings.arguments is FeedbackArguments
                ? (settings.arguments as FeedbackArguments).langCode
                : null));
  } else if (settings.name!.startsWith('/onboarding')) {
    final List<String> parts = settings.name!.split('/');
    String step = '1';
    if ((parts.length > 2) && (parts[2] != '')) step = parts[2];
    if (step == '1') {
      return MaterialPageRoute<void>(
          settings: settings, builder: (_) => const WelcomePage());
    } else if (step == '2') {
      return MaterialPageRoute<void>(
          settings: settings, builder: (_) => const DownloadLanguagesPage());
    } else if (step == '3') {
      return MaterialPageRoute<void>(
          settings: settings, builder: (_) => const SetUpdatePrefsPage());
    }
  }

  return MaterialPageRoute<void>(
    settings: settings,
    builder: (_) => ErrorPage('Unknown route ${settings.name}'),
  );
}
