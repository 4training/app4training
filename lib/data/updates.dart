import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:http/http.dart' as http;

final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

// https://docs.github.com/en/rest/using-the-rest-api/getting-started-with-the-rest-api?apiVersion=2022-11-28#rate-limiting
// unauthenticated API requests are limited to 60 per hour
const int apiRateLimitExceeded = -403;

/// How often should the app check for updates?
enum CheckFrequency {
  never,
  daily,
  weekly,
  monthly;

  /// Safe conversion method that handles invalid values as well as null
  /// Default value is CheckFrequency.weekly
  static CheckFrequency fromString(String? selection) {
    if (selection == null) return CheckFrequency.weekly;
    try {
      return CheckFrequency.values.byName(selection);
    } on ArgumentError {
      return CheckFrequency.weekly;
    }
  }

  static String getLocalized(BuildContext context, CheckFrequency value) {
    switch (value) {
      case CheckFrequency.never:
        return context.l10n.never;
      case CheckFrequency.daily:
        return context.l10n.daily;
      case CheckFrequency.weekly:
        return context.l10n.weekly;
      case CheckFrequency.monthly:
        return context.l10n.monthly;
    }
  }
}

/// Handling our CheckFrequency and persisting it to the SharedPreferences
class CheckFrequencyNotifier extends Notifier<CheckFrequency> {
  @override
  CheckFrequency build() {
    return CheckFrequency.fromString(
        ref.read(sharedPrefsProvider).getString('checkFrequency'));
  }

  /// Our one function to change our global setting
  void setCheckFrequency(String? selection) {
    state = CheckFrequency.fromString(selection);
    ref.read(sharedPrefsProvider).setString('checkFrequency', state.name);
  }
}

final checkFrequencyProvider =
    NotifierProvider<CheckFrequencyNotifier, CheckFrequency>(() {
  return CheckFrequencyNotifier();
});

/// Status of one language: Are there updates available?
/// LanguageStatusNotifier.build() is watching the languageProvider, which means
/// this gets rebuilt when we delete + download a language:
/// - a new LanguageStatus object is created
/// - updatesAvailable is set to false
@immutable
class LanguageStatus {
  /// Are there updates available?
  final bool updatesAvailable;

  /// Same as [Language.downloadTimestamp]; doesn't change here
  /// (but the whole LanguageStatusNotifier gets rebuild when we
  /// delete + download a language as it is watching the languageProvider)
  final DateTime downloadTimestamp; // UTC

  /// When did we check the remote repository last time?
  final DateTime lastCheckedTimestamp; // UTC
  const LanguageStatus(
      this.updatesAvailable, this.downloadTimestamp, this.lastCheckedTimestamp);

  @override
  String toString() {
    return 'Updates available: $updatesAvailable '
        '(downloaded: $downloadTimestamp, last checked: $lastCheckedTimestamp)';
  }
}

/// Holds the checking-for-updates function for one language
/// The timestamp of the last check for updates and whether there are updates
/// available is persisted into the SharedPreferences
///
/// In case the language is not downloaded updatesAvailable will always be false
class LanguageStatusNotifier extends FamilyNotifier<LanguageStatus, String> {
  String _languageCode = '';
  @override
  LanguageStatus build(String arg) {
    _languageCode = arg;
    if (!ref.watch(languageProvider(arg)).downloaded) {
      // Remove all SharedPrefs if language is not even downloaded
      ref.read(sharedPrefsProvider).remove('updatesAvailable-$_languageCode');
      ref.read(sharedPrefsProvider).remove('lastChecked-$_languageCode');
      return LanguageStatus(false, DateTime.utc(2023), DateTime.utc(2023));
    }

    // download timestamp: When was the language downloaded to the device?
    DateTime dlTimestamp = ref.watch(languageProvider(arg)).downloadTimestamp;
    assert(dlTimestamp.isUtc);
    bool updatesAvailable = false;
    DateTime? lcTimestamp;

    // are there updates available for this language?
    updatesAvailable = ref
            .read(sharedPrefsProvider)
            .getBool('updatesAvailable-$_languageCode') ??
        false;

    // last checked timestamp: When did we check for updates the last time?
    String? lcRaw =
        ref.read(sharedPrefsProvider).getString('lastChecked-$_languageCode');
    if (lcRaw != null) {
      try {
        lcTimestamp = DateTime.parse(lcRaw).toUtc();
      } on FormatException {
        debugPrint('Error while trying to parse lastChecked timestamp: $lcRaw');
        lcTimestamp = null;
      }
    }
    if ((lcTimestamp == null) || (lcTimestamp.compareTo(DateTime.now()) > 0)) {
      // Invalid last checked timestamp: set to download timestamp
      lcTimestamp = dlTimestamp;
    } else if (lcTimestamp.compareTo(dlTimestamp) < 0) {
      // it seems that the language just got downloaded:
      // reset lastCheckedTimestamp and updatesAvailable, also in sharedPrefs
      lcTimestamp = dlTimestamp;
      updatesAvailable = false;
      ref
          .read(sharedPrefsProvider)
          .setBool('updatesAvailable-$_languageCode', false);
      ref.read(sharedPrefsProvider).setString(
          'lastChecked-$_languageCode', lcTimestamp.toIso8601String());
    }

    final status = LanguageStatus(updatesAvailable, dlTimestamp, lcTimestamp);
    debugPrint('Language $arg: $status');
    return status;
  }

  /// Query git html repository whether there are updates available:
  /// How many commits are in our data repository since the download time
  /// Return values:
  ///   0: no updates available
  /// > 0: updates available
  /// < 0: error:
  /// apiRateLimitExceeded: exceeded api rate limit (60/hour)
  ///  -1: any other error
  Future<int> check() async {
    assert(_languageCode != '');
// TODO    assert(ref.read(languageProvider(_languageCode)).downloaded);
    // since = since.subtract(const Duration(days: 100)); // for testing
    var uri = Globals.getCommitsSince(_languageCode, state.downloadTimestamp);
    debugPrint(uri);
    try {
      final response = await ref.read(httpClientProvider).get(Uri.parse(uri));

      if (response.statusCode == 200) {
        int commits = json.decode(response.body).length;
        debugPrint('Found $commits new commits ($_languageCode)');
        DateTime now = DateTime.now().toUtc();
        // Persist to SharedPreferences
        await ref
            .read(sharedPrefsProvider)
            .setString('lastChecked-$_languageCode', now.toIso8601String());
        await ref
            .read(sharedPrefsProvider)
            .setBool('updatesAvailable-$_languageCode', commits > 0);

        state = LanguageStatus(commits > 0, state.downloadTimestamp, now);
        return commits;
      } else if (response.statusCode == 403) {
        debugPrint('Exceeded github API query limit. Please wait an hour');
        return apiRateLimitExceeded;
      } else {
        debugPrint('Failed to fetch latest commits: ${response.statusCode}');
        return -1;
      }
    } catch (e) {
      debugPrint('Failed to fetch latest commits: $e');
      return -1;
    }
  }
}

/// Usage:
/// Are there updates available for German?
/// ref.watch(languageStatusProvider('de')).updatesAvailable
/// Check for updates for English
/// ref.watch(languageStatusProvider('en').notifier).check()
final languageStatusProvider =
    NotifierProvider.family<LanguageStatusNotifier, LanguageStatus, String>(() {
  return LanguageStatusNotifier();
});

/// Are there updates available in any of our languages?
final updatesAvailableProvider = StateProvider<bool>((ref) {
  bool updatesAvailable = false;
  for (String languageCode in ref.watch(availableLanguagesProvider)) {
    if (ref.watch(languageStatusProvider(languageCode)).updatesAvailable) {
      updatesAvailable = true;
      // Don't break the loop - we need to watch all languageStatusProviders
    }
  }
  return updatesAvailable;
});

/// When was the last time we checked for updates? (UTC)
/// We have this property for each language in the LanguageStatus,
/// here we have the summary: the oldest of these (in case they're not the same)
final lastCheckedProvider = StateProvider<DateTime>((ref) {
  DateTime timestamp = DateTime.now().toUtc();
  bool downloadedSomeLanguage = false;
  for (String languageCode in ref.watch(availableLanguagesProvider)) {
    if (!ref.read(languageProvider(languageCode)).downloaded) continue;
    downloadedSomeLanguage = true;
    DateTime languageTimestamp =
        ref.read(languageStatusProvider(languageCode)).lastCheckedTimestamp;
    if (languageTimestamp.isBefore(timestamp)) timestamp = languageTimestamp;
  }
  // For the edge case that not a single language is downloaded
  if (!downloadedSomeLanguage) {
    return DateTime.utc(2023);
  }
  assert(timestamp.isUtc);
  debugPrint('Last checked for updates: $timestamp');
  return timestamp;
});
