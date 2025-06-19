import 'package:app4training/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Extension method on [BuildContext] to simplify code for accessing
/// translated messages.
/// Instead of AppLocalizations.of(context)!.appLanguage we can now write
/// context.l10n.appLanguage
extension AppLocalizationsExt on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Get the translated name of a language together with the language code
/// in parentheses, for example getLanguageName('de') returns 'German (de)'
/// We need to implement this manually as flutter currently doesn't
/// have a way to access translations with dynamic keys:
/// https://github.com/flutter/flutter/issues/105672
extension GetLanguageNameExt on AppLocalizations {
  String getLanguageName(String languageCode) {
    final languageMap = <String, String>{
      'tr': language_tr,
      'zh': language_zh,
      'vi': language_vi,
      'ro': language_ro,
      'ky': language_ky,
      'pl': language_pl,
      'id': language_id,
      'xh': language_xh,
      'uz': language_uz,
      'af': language_af,
      'ta': language_ta,
      'sr': language_sr,
      'ms': language_ms,
      'az': language_az,
      'ti': language_ti,
      'sw': language_sw,
      'nb': language_nb,
      'ku': language_ku,
      'sv': language_sv,
      'ml': language_ml,
      'hi': language_hi,
      'lg': language_lg,
      'kn': language_kn,
      'it': language_it,
      'cs': language_cs,
      'fa': language_fa,
      'ar': language_ar,
      'ru': language_ru,
      'nl': language_nl,
      'fr': language_fr,
      'es': language_es,
      'sq': language_sq,
      'en': language_en,
      'de': language_de
    };
    if (languageMap.containsKey(languageCode)) {
      return "${languageMap[languageCode]!} ($languageCode)";
    }
    debugPrint("Warning: getLanguageName('$languageCode') is not defined");
    return languageCode.toUpperCase();
  }
}
