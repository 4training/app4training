import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:http/http.dart' as http;

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
  void setCheckFrequency(String selection) {
    state = CheckFrequency.fromString(selection);
    ref.read(sharedPrefsProvider).setString('checkFrequency', state.name);
  }
}

final checkFrequencyProvider =
    NotifierProvider<CheckFrequencyNotifier, CheckFrequency>(() {
  return CheckFrequencyNotifier();
});

/// Status of one language: Are there updates available?
/// When did we check the remote repository last time?
@immutable
class LanguageStatus {
  final bool updatesAvailable;
  final DateTime lastCheckedTimestamp; // UTC
  const LanguageStatus(this.updatesAvailable, this.lastCheckedTimestamp);
}

/// Holds the checking-for-updates function for one language
class LanguageStatusNotifier extends FamilyNotifier<LanguageStatus, String> {
  String _languageCode = '';
  @override
  LanguageStatus build(String arg) {
    _languageCode = arg;
    DateTime timestamp = ref.watch(languageProvider(arg)).downloadTimestamp;
    assert(timestamp.isUtc);
    debugPrint('Language $arg: lastCheckedTimestamp = $timestamp (UTC)');
    return LanguageStatus(false, timestamp);
  }

  /// Query git html repository whether there are updates available:
  /// How many commits are in our data repository since the last time we checked
  /// Return values: 0 = no updates available; > 0: updates available; -1: error
  Future<int> check() async {
    assert(_languageCode != '');
    // since = since.subtract(const Duration(days: 100)); // for testing
    var uri =
        Globals.getCommitsSince(_languageCode, state.lastCheckedTimestamp);
    debugPrint(uri);
    final response = await http.get(Uri.parse(uri));

    if (response.statusCode == 200) {
      int commits = json.decode(response.body).length;
      debugPrint("Found $commits new commits ($_languageCode)");
      if (commits > 0) {
        ref.read(updatesAvailableProvider.notifier).state = true;
      }
      state = LanguageStatus(commits > 0, DateTime.now().toUtc());
      return commits;
    } else {
      debugPrint("Failed to fetch latest commits ${response.statusCode}");
      return -1;
    }
  }
}

/// Usage:
/// Are there updates available for German?
/// ref.watch(languageStatusProvider('de')).updatesAvailable
/// Check for updates for English
/// ref.watch(languageProvider('en').notifier).check()
final languageStatusProvider =
    NotifierProvider.family<LanguageStatusNotifier, LanguageStatus, String>(() {
  return LanguageStatusNotifier();
});

/// Are there updates available in any of our languages?
final updatesAvailableProvider = StateProvider<bool>((ref) => false);

/// When was the last time we checked for updates? (UTC)
/// We have this property for each language in the LanguageStatus,
/// here we have the summary: the oldest of these (in case they're not the same)
final lastCheckedProvider = StateProvider<DateTime>((ref) {
  DateTime timestamp = DateTime.now().toUtc();
  bool downloadedSomeLanguage = false;
  for (String languageCode in ref.read(availableLanguagesProvider)) {
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
