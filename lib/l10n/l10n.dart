import 'package:flutter/material.dart';
import 'l10n.dart';

export 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Extension method on [BuildContext] to simplify code for accessing
/// translated messages.
/// Instead of AppLocalizations.of(context)!.appLanguage we can now write
/// context.l10n.appLanguage
extension AppLocalizationsExt on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
