import 'package:app4training/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations_en.dart';

abstract class App4TrainingException {
  String toLocalizedString(BuildContext context);
}

/// "Milder" exception: A language is not downloaded when we expected it to be
class LanguageNotDownloadedException extends App4TrainingException
    implements Exception {
  final String languageCode;
  LanguageNotDownloadedException(this.languageCode);

  @override
  String toString() => AppLocalizationsEn().languageNotDownloaded(languageCode);

  @override
  String toLocalizedString(BuildContext context) => context.l10n
      .languageNotDownloaded(context.l10n.getLanguageName(languageCode));
}

/// "Milder" exception: A page is not existing -> probably some internal error,
/// there should never have been a link here...
class PageNotFoundException extends App4TrainingException implements Exception {
  final String page;
  final String languageCode;
  PageNotFoundException(this.page, this.languageCode);

  @override
  String toString() => AppLocalizationsEn().pageNotFound(page, languageCode);

  @override
  String toLocalizedString(BuildContext context) =>
      context.l10n.pageNotFound(page, languageCode);
}

/// Some more serious exception: Somehow our language seems to be corrupted.
/// Like inconsistencies in our Language object or file system issues.
/// Hopefully this gets resolved by deleting the language and re-downloading it
class LanguageCorruptedException extends App4TrainingException
    implements Exception {
  final String languageCode;
  final String message;
  final Exception? exception;

  LanguageCorruptedException(this.languageCode, this.message, [this.exception]);

  @override
  String toString() => AppLocalizationsEn().languageCorrupted(languageCode,
      (exception == null) ? message : '$message (${exception.toString()})');

  @override
  String toLocalizedString(BuildContext context) =>
      context.l10n.languageCorrupted(context.l10n.getLanguageName(languageCode),
          (exception == null) ? message : '$message (${exception.toString()})');
}
