import 'dart:async';

import 'package:app4training/background/background_scheduler.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/data/startup_stage.dart';
import 'package:app4training/l10n/generated/app_localizations.dart';
import 'package:app4training/l10n/generated/app_localizations_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app4training/routes/startup_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'background_scheduler_test.dart';
import 'languages_test.dart';

/// Records which languages a full init() was requested for and lets the
/// test decide when each of them finishes loading
class GatedLanguageController extends TestLanguageController {
  GatedLanguageController(
    this.initCalls,
    this.gates, {
    super.downloadedLanguages,
    this.lazyInitGate,
  }) : super(initReturns: true);

  final List<String> initCalls;
  final Map<String, Completer<void>> gates;

  /// If set, every lazyInit() waits for this before answering
  final Completer<void>? lazyInitGate;

  @override
  Future<bool> init() async {
    initCalls.add(languageCode);
    await gates[languageCode]!.future;
    return super.init();
  }

  @override
  Future<bool> lazyInit() async {
    if (lazyInitGate != null) await lazyInitGate!.future;
    return super.lazyInit();
  }
}

void main() {
  // Mocking the globalInit() function:
  // We want to be able to test all the different outcomes of the future
  Completer<String> completer = Completer<String>();
  Future<String> mockInitFunction() {
    return completer.future;
  }

  // For tracking route changes
  String? route; // make sure to reset the variable before the next test
  Route<Object?> generateRoutes(RouteSettings settings) {
    route = settings.name;
    return MaterialPageRoute<void>(builder: (_) => const Text('Mock'));
  }

  testWidgets('Test normal behaviour', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'appLanguage': 'de',
      'checkFrequency': 'weekly',
    });
    final prefs = await SharedPreferences.getInstance();
    expect(route, isNull);
    final ref = ProviderContainer(
      overrides: [
        languageProvider.overrideWith2(
          (languageCode) => TestLanguageController(initReturns: true),
        ),
        backgroundSchedulerProvider.overrideWith(
          () => TestBackgroundScheduler(),
        ),
        sharedPrefsProvider.overrideWith((ref) => prefs),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ref,
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const StartupPage(),
          onGenerateRoute: generateRoutes,
        ),
      ),
    );
    // First there should be the loading animation, in the app language
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Wird geladen'), findsOneWidget);
    await tester.pump();
    expect(route, equals('/home')); // Now we went on to this route
    expect(ref.read(backgroundSchedulerProvider), true);
  });

  testWidgets('Test different routing when no languages are downloaded', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'appLanguage': 'de'});
    final prefs = await SharedPreferences.getInstance();
    route = null;
    final ref = ProviderContainer(
      overrides: [
        languageProvider.overrideWith2(
          (languageCode) => TestLanguageController(downloadedLanguages: []),
        ),
        backgroundSchedulerProvider.overrideWith(
          () => TestBackgroundScheduler(),
        ),
        sharedPrefsProvider.overrideWith((ref) => prefs),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ref,
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const StartupPage(),
          onGenerateRoute: generateRoutes,
        ),
      ),
    );
    expect(route, equals('/onboarding/2'));
    expect(ref.read(backgroundSchedulerProvider), false);
  });

  testWidgets('Test continuing to third onboarding step', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'appLanguage': 'de'});
    final prefs = await SharedPreferences.getInstance();
    route = null;
    final ref = ProviderContainer(
      overrides: [
        languageProvider.overrideWith2(
          (languageCode) => TestLanguageController(initReturns: true),
        ),
        sharedPrefsProvider.overrideWith((ref) => prefs),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ref,
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const StartupPage(),
          onGenerateRoute: generateRoutes,
        ),
      ),
    );
    await tester.pump();
    expect(route, equals('/onboarding/3'));
    expect(ref.read(backgroundSchedulerProvider), false);
  });

  testWidgets('Only the languages of the first screen delay the navigation', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'appLanguage': 'en',
      'checkFrequency': 'weekly',
      'recentPage': 'Healing',
      'recentLang': 'de',
    });
    final prefs = await SharedPreferences.getInstance();
    route = null;
    final initCalls = <String>[];
    final gates = {
      for (final languageCode in ['en', 'de', 'fr'])
        languageCode: Completer<void>(),
    };
    final ref = ProviderContainer(
      overrides: [
        languageProvider.overrideWith2(
          (languageCode) => GatedLanguageController(
            initCalls,
            gates,
            downloadedLanguages: ['en', 'de', 'fr'],
          ),
        ),
        backgroundSchedulerProvider.overrideWith(
          () => TestBackgroundScheduler(),
        ),
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ref,
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const StartupPage(),
          onGenerateRoute: generateRoutes,
        ),
      ),
    );

    // Only the app language and the language of the recent page are loaded
    // before we can leave the loading screen - not all 34 languages
    await tester.pump();
    expect(initCalls.toSet(), equals({'en', 'de'}));
    expect(route, isNull);

    // As soon as those two are there we navigate - even though the other
    // downloaded language is still being loaded in the background
    gates['en']!.complete();
    gates['de']!.complete();
    await tester.pump();
    expect(route, equals('/view/Healing/de'));
    expect(initCalls.toSet(), equals({'en', 'de', 'fr'}));

    // Languages that aren't on the device are never fully loaded
    gates['fr']!.complete();
    await tester.pumpAndSettle();
    expect(initCalls.length, 3);
  });

  testWidgets('The caption names the stage init() is in', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'appLanguage': 'en',
      'checkFrequency': 'weekly',
      'recentPage': 'Healing',
      'recentLang': 'de',
    });
    final prefs = await SharedPreferences.getInstance();
    route = null;
    final l10n = AppLocalizationsEn();
    final initCalls = <String>[];
    final lazyInitGate = Completer<void>();
    final gates = {
      for (final languageCode in ['en', 'de']) languageCode: Completer<void>(),
    };
    final ref = ProviderContainer(
      overrides: [
        languageProvider.overrideWith2(
          (languageCode) => GatedLanguageController(
            initCalls,
            gates,
            downloadedLanguages: ['en', 'de'],
            lazyInitGate: lazyInitGate,
          ),
        ),
        backgroundSchedulerProvider.overrideWith(
          () => TestBackgroundScheduler(),
        ),
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ref,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const StartupPage(),
          onGenerateRoute: generateRoutes,
        ),
      ),
    );

    // Stage 1: finding out which languages are on the device
    await tester.pump();
    expect(find.text(l10n.startupCheckingLanguages), findsOneWidget);
    expect(initCalls, isEmpty);

    // Stage 2: loading the app language
    lazyInitGate.complete();
    await tester.pump();
    expect(find.text(l10n.startupLoadingAppLanguage), findsOneWidget);
    expect(initCalls.toSet(), equals({'en', 'de'}));
    expect(route, isNull);

    // Stage 3: the app language is in, the worksheet's language isn't yet
    gates['en']!.complete();
    await tester.pump();
    expect(find.text(l10n.startupLoadingRecentPage), findsOneWidget);
    expect(route, isNull);

    gates['de']!.complete();
    await tester.pump();
    expect(route, equals('/view/Healing/de'));
  });

  testWidgets('The recent-page stage is not claimed once nothing is left', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'appLanguage': 'en',
      'checkFrequency': 'weekly',
      'recentPage': 'Healing',
      'recentLang': 'de',
    });
    final prefs = await SharedPreferences.getInstance();
    route = null;
    final l10n = AppLocalizationsEn();
    final gates = {
      for (final languageCode in ['en', 'de']) languageCode: Completer<void>(),
    };
    final ref = ProviderContainer(
      overrides: [
        languageProvider.overrideWith2(
          (languageCode) => GatedLanguageController(
            [],
            gates,
            downloadedLanguages: ['en', 'de'],
          ),
        ),
        backgroundSchedulerProvider.overrideWith(
          () => TestBackgroundScheduler(),
        ),
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ref,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const StartupPage(),
          onGenerateRoute: generateRoutes,
        ),
      ),
    );
    await tester.pump();
    expect(find.text(l10n.startupLoadingAppLanguage), findsOneWidget);

    // The worksheet's language lands first: we're still on the app language
    gates['de']!.complete();
    await tester.pump();
    expect(find.text(l10n.startupLoadingAppLanguage), findsOneWidget);
    expect(route, isNull);

    // ... and when that arrives there is nothing left to wait for
    gates['en']!.complete();
    await tester.pump();
    expect(route, equals('/view/Healing/de'));
    expect(find.text(l10n.startupLoadingRecentPage), findsNothing);
  });

  testWidgets(
    'Reporting a stage changes the caption but does not restart init',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({'appLanguage': 'de'});
      final prefs = await SharedPreferences.getInstance();
      route = null;
      final l10n = AppLocalizationsEn();
      int initCalls = 0;
      final Completer<String> gate = Completer<String>();
      Future<String> countingInit() {
        initCalls++;
        return gate.future;
      }

      final ref = ProviderContainer(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: ref,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: StartupPage(initFunction: countingInit),
            onGenerateRoute: generateRoutes,
          ),
        ),
      );
      await tester.pump();
      expect(find.text(l10n.loading), findsOneWidget);
      expect(initCalls, 1);

      ref
          .read(startupStageProvider.notifier)
          .report(StartupStage.loadingAppLanguage);
      await tester.pump();
      expect(find.text(l10n.startupLoadingAppLanguage), findsOneWidget);
      expect(find.text(l10n.loading), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(initCalls, 1);
      expect(route, isNull);

      gate.complete('/home');
      await tester.pump();
      expect(route, equals('/home'));
      expect(initCalls, 1);
    },
  );

  testWidgets('Test failing initFunction', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'appLanguage': 'de'});
    final prefs = await SharedPreferences.getInstance();
    completer = Completer();
    route = null;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPrefsProvider.overrideWith((ref) => prefs)],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StartupPage(initFunction: mockInitFunction),
          onGenerateRoute: generateRoutes,
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading'), findsOneWidget);
    completer.completeError("Failed");
    await tester.pump();
    expect(find.text('Loading'), findsNothing);
    expect(find.textContaining('Failed'), findsOneWidget);
    expect(route, isNull);
  });

  group('Test loading recent page from SharedPreferences', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'appLanguage': 'en',
        'checkFrequency': 'weekly',
        'recentPage': 'Healing',
        'recentLang': 'de',
      });
    });
    testWidgets('Recent page should be loaded', (WidgetTester tester) async {
      final prefs = await SharedPreferences.getInstance();
      route = null;
      final ref = ProviderContainer(
        overrides: [
          languageProvider.overrideWith2(
            (languageCode) => TestLanguageController(initReturns: true),
          ),
          backgroundSchedulerProvider.overrideWith(
            () => TestBackgroundScheduler(),
          ),
          sharedPrefsProvider.overrideWithValue(prefs),
        ],
      );
      expect(ref.read(backgroundSchedulerProvider), false);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: ref,
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const StartupPage(),
            onGenerateRoute: generateRoutes,
          ),
        ),
      );

      await tester.pump();
      expect(route, equals('/view/Healing/de'));
      expect(ref.read(backgroundSchedulerProvider), true);
    });
    testWidgets("Recent page should get ignored because German isn't loaded", (
      WidgetTester tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();
      route = null;
      final ref = ProviderContainer(
        overrides: [
          languageProvider.overrideWith2(
            (languageCode) => TestLanguageController(
              downloadedLanguages: ['en'],
              initReturns: true,
            ),
          ),
          backgroundSchedulerProvider.overrideWith(
            () => TestBackgroundScheduler(),
          ),
          sharedPrefsProvider.overrideWithValue(prefs),
        ],
      );
      expect(ref.read(backgroundSchedulerProvider), false);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: ref,
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const StartupPage(),
            onGenerateRoute: generateRoutes,
          ),
        ),
      );

      await tester.pump();
      expect(route, equals('/home'));
      expect(ref.read(backgroundSchedulerProvider), true);
    });
  });
}
