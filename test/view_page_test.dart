import 'package:app4training/data/app_language.dart';
import 'package:app4training/data/exceptions.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/features/share/share_button.dart';
import 'package:app4training/l10n/generated/app_localizations.dart';
import 'package:app4training/routes/routes.dart';
import 'package:app4training/routes/view_page.dart';
import 'package:app4training/widgets/language_selection_button.dart';
import 'package:file/memory.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_language_test.dart';

/// German is on the device and knows the page 'Healing',
/// but its HTML file can't be read from local storage
class LanguageWithMissingHtml extends LanguageController {
  @override
  Language build() {
    return Language(
      'de',
      const {
        'Healing': Page('Healing', 'Heilung', 'Heilung.html', '1.0', null),
      },
      const ['Healing'],
      const {},
      '/de',
      DateTime.utc(2023),
    );
  }
}

/// Simplify testing of the ViewPage widget
class TestViewPage extends ConsumerWidget {
  static const languageCode = 'de';

  const TestViewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      locale: ref.read(appLanguageProvider).locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ViewPage('Healing', 'de'),
    );
  }
}

void main() {
  testWidgets('Test normal behaviour', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
          pageContentProvider.overrideWith((ref, page) async => 'TestContent'),
          sharedPrefsProvider.overrideWith((ref) => prefs),
        ],
        child: const TestViewPage(),
      ),
    );

    expect(prefs.getString('recentPage'), isNull);
    expect(prefs.getString('recentLang'), isNull);
    // First there should be the loading animation
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Inhalt wird geladen...'), findsOneWidget);
    // In Riverpod v3, FutureProvider needs additional frames to settle
    await tester.pumpAndSettle();

    // Now our content should be shown
    expect(find.textContaining('TestContent'), findsOneWidget);
    // recentPage and recentLang should be set in SharedPreferences
    expect(prefs.getString('recentPage'), 'Healing');
    expect(prefs.getString('recentLang'), 'de');

    // Our two action buttons should be visible
    expect(find.byType(LanguageSelectionButton), findsOneWidget);
    expect(find.byType(ShareButton), findsOneWidget);
  });

  testWidgets('switching to dark mode keeps the page on screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
          pageContentProvider.overrideWith((ref, page) async => 'TestContent'),
          sharedPrefsProvider.overrideWith((ref) => prefs),
        ],
        child: MaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          darkTheme: ThemeData(brightness: Brightness.dark),
          themeMode: ThemeMode.system,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // Through the app's routes: they build a new ViewPage whenever the
          // route's dependencies (like the theme) change
          onGenerateRoute: generateRoutes,
          onGenerateInitialRoutes:
              (_) => [
                generateRoutes(const RouteSettings(name: '/view/Healing/de')),
              ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('TestContent'), findsOneWidget);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    // Every frame of the theme animation: no loading spinner, no reload
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 30));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('TestContent'), findsOneWidget);
    }
  });

  testWidgets('shows the new content when the page gets updated', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final version = NotifierProvider<_Version, int>(_Version.new);
    final container = ProviderContainer(
      overrides: [
        appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
        pageContentProvider.overrideWith(
          (ref, page) async => 'Content version ${ref.watch(version)}',
        ),
        sharedPrefsProvider.overrideWith((ref) => prefs),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TestViewPage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Content version 1'), findsOneWidget);

    // e.g. a language update while the page is open
    container.read(version.notifier).increment();
    await tester.pumpAndSettle();

    expect(find.textContaining('Content version 2'), findsOneWidget);
  });

  testWidgets('recovers from an error once the content is available', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final version = NotifierProvider<_Version, int>(_Version.new);
    final container = ProviderContainer(
      overrides: [
        appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
        pageContentProvider.overrideWith((ref, page) async {
          if (ref.watch(version) == 1) {
            throw LanguageNotDownloadedException('de');
          }
          return 'Downloaded content';
        }),
        sharedPrefsProvider.overrideWith((ref) => prefs),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TestViewPage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Warnung'), findsOneWidget);

    // e.g. the language finished downloading in the background
    container.read(version.notifier).increment();
    await tester.pumpAndSettle();

    expect(find.textContaining('Downloaded content'), findsOneWidget);
  });

  testWidgets('Test LanguageNotDownloadedException handling', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
          pageContentProvider.overrideWith(
            (ref, arg) async => throw LanguageNotDownloadedException('de'),
          ),
          sharedPrefsProvider.overrideWith((ref) => prefs),
        ],
        child: const TestViewPage(),
      ),
    );
    await tester.pumpAndSettle();

    // Now we should see a warning (in German)
    expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    expect(find.text('Warnung'), findsOneWidget);
    expect(
      find.textContaining(
        'Kann Seite "Healing" nicht auf Deutsch (de) anzeigen',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Sprache ist nicht verfügbar'), findsOneWidget);
  });

  testWidgets('Test PageNotFoundException handling', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
          pageContentProvider.overrideWith(
            (ref, page) async => throw PageNotFoundException('Healing', 'de'),
          ),
          sharedPrefsProvider.overrideWith((ref) => prefs),
        ],
        child: const TestViewPage(),
      ),
    );
    await tester.pumpAndSettle();

    // Now we should see a warning (in German)
    expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    expect(find.text('Warnung'), findsOneWidget);
    expect(
      find.textContaining(
        'Kann Seite "Healing" nicht auf Deutsch (de) anzeigen',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('Seite Healing/de konnte nicht gefunden werden'),
      findsOneWidget,
    );
  });

  testWidgets('Test LanguageCorruptedException handling', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLanguageProvider.overrideWith(() => TestAppLanguage('en')),
          pageContentProvider.overrideWith(
            (ref, page) async =>
                throw LanguageCorruptedException('de', 'BadLuck'),
          ),
          sharedPrefsProvider.overrideWith((ref) => prefs),
        ],
        child: const TestViewPage(),
      ),
    );
    await tester.pumpAndSettle();

    // Now we should see an error message in German
    expect(find.byIcon(Icons.error), findsOneWidget);
    expect(find.text('Error'), findsOneWidget);
    expect(
      find.textContaining(
        "Language data for 'German (de)' seems to be corrupted",
      ),
      findsOneWidget,
    );
  });

  testWidgets('Test unexpected exception handling', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLanguageProvider.overrideWith(() => TestAppLanguage('de')),
          pageContentProvider.overrideWith(
            (ref, arg) async => throw TestFailure,
          ),
          sharedPrefsProvider.overrideWith((ref) => prefs),
        ],
        child: const TestViewPage(),
      ),
    );
    await tester.pumpAndSettle();

    // Now we should see an error (internalError in German)
    expect(find.byIcon(Icons.error), findsOneWidget);
    expect(find.text('Fehler'), findsOneWidget);
    expect(find.textContaining('Ups, das tut uns leid.'), findsOneWidget);
    expect(find.textContaining('TestFailure'), findsOneWidget);
  });

  testWidgets('Shows an error instead of loading forever when the HTML file '
      "can't be read", (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLanguageProvider.overrideWith(() => TestAppLanguage('en')),
          fileSystemProvider.overrideWith((ref) => MemoryFileSystem()),
          languageProvider.overrideWith2(
            (langCode) => LanguageWithMissingHtml(),
          ),
          sharedPrefsProvider.overrideWith((ref) => prefs),
        ],
        child: const TestViewPage(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      find.textContaining(
        "Language data for 'German (de)' seems to be corrupted",
      ),
      findsOneWidget,
    );
  });

  testWidgets("Doesn't keep trying to read an HTML file that can't be read", (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    int readAttempts = 0;
    final fileSystem = MemoryFileSystem(
      opHandle: (String context, FileSystemOp operation) {
        if (operation == FileSystemOp.read && context.endsWith('.html')) {
          readAttempts++;
        }
      },
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLanguageProvider.overrideWith(() => TestAppLanguage('en')),
          fileSystemProvider.overrideWith((ref) => fileSystem),
          languageProvider.overrideWith2(
            (langCode) => LanguageWithMissingHtml(),
          ),
          sharedPrefsProvider.overrideWith((ref) => prefs),
        ],
        child: const TestViewPage(),
      ),
    );
    // Long enough for any retry to have happened
    await tester.pump(const Duration(minutes: 2));

    expect(readAttempts, 1);
  });
}

class _Version extends Notifier<int> {
  @override
  int build() => 1;

  void increment() => state++;
}
