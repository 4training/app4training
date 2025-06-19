// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get settings => 'Einstellungen';

  @override
  String get appLanguage => 'App-Sprache';

  @override
  String get languages => 'Sprachen';

  @override
  String get languagesText =>
      'Dies sind die verfügbaren Sprachen. Du kannst sie manuell herunterladen, aktualisieren und löschen.';

  @override
  String get allLanguages => 'Alle Sprachen';

  @override
  String get updates => 'Aktualisierungen';

  @override
  String get checkFrequency => 'Nach Aktualisierungen suchen';

  @override
  String get never => 'niemals';

  @override
  String get daily => 'täglich';

  @override
  String get weekly => 'wöchentlich';

  @override
  String get monthly => 'monatlich';

  @override
  String get testinterval => '15min (Test)';

  @override
  String get lastCheck => 'Letzte Überprüfung:';

  @override
  String get checkNow => 'Jetzt prüfen';

  @override
  String get doAutomaticUpdates => 'Automatische Aktualisierungen durchführen';

  @override
  String get requireConfirmation => 'Bestätigung verlangen';

  @override
  String get onlyOnWifi => 'ja, aber nur über WLAN';

  @override
  String get yesAlways => 'ja, auch über mobile Daten';

  @override
  String get appearance => 'Darstellung';

  @override
  String get theme => 'Design';

  @override
  String get light => 'hell';

  @override
  String get dark => 'dunkel';

  @override
  String get language_tr => 'Türkisch';

  @override
  String get language_zh => 'Chinesisch';

  @override
  String get language_vi => 'Vietnamesisch';

  @override
  String get language_ro => 'Rumänisch';

  @override
  String get language_ky => 'Kirgisisch';

  @override
  String get language_pl => 'Polnisch';

  @override
  String get language_id => 'Indonesisch';

  @override
  String get language_xh => 'Xhosa';

  @override
  String get language_uz => 'Usbekisch';

  @override
  String get language_af => 'Afrikaans';

  @override
  String get language_ta => 'Tamil';

  @override
  String get language_sr => 'Serbisch';

  @override
  String get language_ms => 'Malaiisch';

  @override
  String get language_az => 'Aserbaidschanisch';

  @override
  String get language_ti => 'Tigrinya';

  @override
  String get language_sw => 'Suaheli';

  @override
  String get language_nb => 'Norwegisch';

  @override
  String get language_ku => 'Kurmandschi';

  @override
  String get language_sv => 'Schwedisch';

  @override
  String get language_ml => 'Malayalam';

  @override
  String get language_hi => 'Hindi';

  @override
  String get language_lg => 'Luganda';

  @override
  String get language_kn => 'Kannada';

  @override
  String get language_it => 'Italienisch';

  @override
  String get language_cs => 'Tschechisch';

  @override
  String get language_fa => 'Persisch';

  @override
  String get language_ar => 'Arabisch';

  @override
  String get language_ru => 'Russisch';

  @override
  String get language_nl => 'Niederländisch';

  @override
  String get language_fr => 'Französisch';

  @override
  String get language_es => 'Spanisch';

  @override
  String get language_sq => 'Albanisch';

  @override
  String get language_en => 'Englisch';

  @override
  String get language_de => 'Deutsch';

  @override
  String get diskUsage => 'Speicherverbrauch';

  @override
  String countLanguages(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sprachen',
      one: 'Sprache',
      zero: 'Sprachen',
    );
    return '($countString $_temp0)';
  }

  @override
  String get warning => 'Warnung';

  @override
  String get warnBeforeDelete =>
      'Du versuchst, die aktuell ausgewählte App-Sprache zu löschen. Bist du sicher?';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String deletedLanguage(String languageName) {
    return '$languageName wurde gelöscht';
  }

  @override
  String deletedNLanguages(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    return '$countString Sprachen gelöscht';
  }

  @override
  String downloadedLanguage(String languageName) {
    return '$languageName ist nun verfügbar';
  }

  @override
  String downloadedNLanguages(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    return '$countString Sprachen heruntergeladen';
  }

  @override
  String get downloadError =>
      'Download fehlgeschlagen. Bitte überprüfe deine Internet-Verbindung und versuche es später noch einmal';

  @override
  String updatedLanguage(String languageName) {
    return '$languageName ist nun auf dem aktuellsten Stand';
  }

  @override
  String updatedNLanguages(num count, num error) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat errorNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String errorString = errorNumberFormat.format(error);

    String _temp0 = intl.Intl.pluralLogic(
      error,
      locale: localeName,
      other: ', $errorString fehlgeschlagen',
      zero: '',
    );
    return '$countString Sprachen aktualisiert$_temp0';
  }

  @override
  String get updateError =>
      'Aktualisierung fehlgeschlagen. Bitte versuche es später noch einmal.';

  @override
  String nUpdatesAvailable(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Updates für $countString Sprachen verfügbar',
      one: 'Sprachupdate verfügbar',
      zero: 'Alle Sprachen sind bereits aktuell',
    );
    return '$_temp0';
  }

  @override
  String get checkingUpdatesLimit =>
      'Fehler: Du hast zu häufig nach Aktualisierungen gesucht. Bitte warte eine Stunde.';

  @override
  String get checkingUpdatesError =>
      'Fehler beim Überprüfen auf Updates. Bitte versuche es später noch einmal.';

  @override
  String get languageSelectionHeader => 'Seite anzeigen auf:';

  @override
  String get manageLanguages => 'Sprachen verwalten';

  @override
  String get content => 'Inhalt';

  @override
  String translationAvailableHint(String language) {
    return ': Verfügbar auf $language';
  }

  @override
  String get essentials => 'Grundlagen';

  @override
  String get essentialsForTrainers => 'Grundlagen - für Trainer';

  @override
  String get innerHealing => 'Innere Heilung';

  @override
  String get innerHealingForTrainers => 'Innere Heilung - für Trainer';

  @override
  String get sorry => 'Tut uns leid';

  @override
  String notTranslated(Object language) {
    return 'Die gewünschte Seite ist leider noch nicht auf $language übersetzt.\nWenn du uns bei der Übersetzung helfen kannst, dann melde dich bitte!';
  }

  @override
  String get okay => 'Okay';

  @override
  String get translationAvailable => 'Übersetzung verfügbar';

  @override
  String translationAvailableText(String page, String language) {
    return 'Die Seite $page ist auf $language übersetzt.';
  }

  @override
  String languageChangedBack(String page, String language, String appLanguage) {
    return 'Seite \"$page\" ist nicht verfügbar auf $language. Sprache zurückgesetzt auf $appLanguage';
  }

  @override
  String get close => 'Schließen';

  @override
  String get showPage => 'Seite öffnen';

  @override
  String get error => 'Fehler';

  @override
  String get reason => 'Grund: ';

  @override
  String internalError(String errorMessage) {
    return 'Ups, das tut uns leid. Da muss ein Fehler passiert sein. Bitte sag uns Bescheid, damit wir das Problem beheben können. Interner Fehler: $errorMessage';
  }

  @override
  String cantDisplayPage(String page, String language) {
    return 'Kann Seite \"$page\" nicht auf $language anzeigen.';
  }

  @override
  String languageNotDownloaded(String language) {
    return 'Sprache ist nicht verfügbar. Bitte gehe in die Einstellungen und lade $language herunter.';
  }

  @override
  String pageNotFound(String page, String languageCode) {
    return 'Seite $page/$languageCode konnte nicht gefunden werden. Vielleicht bist du einem fehlerhaften Link gefolgt und die Seite ist noch nicht übersetzt.';
  }

  @override
  String languageCorrupted(String language, String errorMessage) {
    return 'Die Sprachdaten von \'$language\' scheinen beschädigt zu sein: $errorMessage\nGehe zu den Einstellungen und versuche, die Sprache zu löschen und erneut herunterzuladen. Gib uns Bescheid, wenn das Problem weiterhin auftritt.';
  }

  @override
  String get about => 'Über...';

  @override
  String get appDescription =>
      'Dies ist die App von https://www.4training.net. Unser Ziel ist es, dich mit hervorragenden Materialien in vielen Sprachen zu versorgen.';

  @override
  String get matthew10_8 =>
      'Matthäus 10,8: „Umsonst habt ihr es empfangen, umsonst gebt es weiter!”';

  @override
  String get noCopyright =>
      'Alle Inhalte sind copyright-frei und dürfen ohne Einschränkungen weitergegeben und weiterverarbeitet werden (CC0).';

  @override
  String get secure => 'Sicher';

  @override
  String get secureText =>
      'Diese App verwendet kein Tracking, zeigt keine Werbung und sendet keinerlei Daten irgendwohin. Wie du vielleicht bemerkt hast, benötigt sie keine Berechtigungen. Sicherer geht nicht 😀\nDie Materialien werden SSL-verschlüsselt von github.com heruntergeladen.';

  @override
  String get worksOffline => 'Funktioniert offline';

  @override
  String get worksOfflineText =>
      'Wenn du die gewählten Sprachen heruntergeladen hast, braucht die App keine Internet-Verbindung. Diese ist nur nötig, wenn du nach Updates suchst oder eine andere Sprache herunterladen möchtest.';

  @override
  String get contributing => 'Mitmachen';

  @override
  String get contributingText =>
      'Viele Menschen haben ihre Zeit, Fähigkeiten und Finanzen eingesetzt, um diese Vision Realität werden zu lassen. Vielen Dank! Es gibt viele Bereich, wo du dich einbringen kannst: Übersetzen, programmieren, spenden, Design, Fehlersuche, ...\nDu erreichst uns mit einer Mail an contact@4training.net – wir freuen uns über deine Ideen und dein Feedback!';

  @override
  String get openSource => 'Open Source';

  @override
  String get openSourceText =>
      'Diese App ist Open Source. Du hast die Freiheit, sie zu nutzen, zu analysieren, weiterzugeben und zu verbessern. Quellcode, geplante nächste Features und mehr Infos\nhttps://github.com/4training/app4training';

  @override
  String get version => 'Version';

  @override
  String get welcome => 'Herzlich Willkommen!';

  @override
  String get selectAppLanguage =>
      'Bitte wähle die App-Sprache aus. Das Menü und alle Einstellungen werden in dieser Sprache sein.';

  @override
  String get continueText => 'Weiter';

  @override
  String get back => 'Zurück';

  @override
  String get appName => '4training.net-App';

  @override
  String promoFeature1(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    return '$countString Arbeitsblätter';
  }

  @override
  String get promoFeature2 => 'Funktioniert offline';

  @override
  String get promoFeature3 => 'Kein Copyright';

  @override
  String get downloadLanguages => 'Sprachen herunterladen';

  @override
  String get downloadLanguagesExplanation =>
      'Welche Sprachen möchtest du nutzen? Lade sie jetzt herunter und dann sind sie offline verfügbar. Eine Sprache verbraucht weniger als 4 MB.';

  @override
  String get warnMissingAppLanguage =>
      'Bitte lade Deutsch (de) herunter, bevor du fortfährst. Damit du die App sinnvoll nutzen kannst, muss die App-Sprache heruntergeladen sein.';

  @override
  String get gotit => 'Verstanden';

  @override
  String get ignore => 'Ignorieren';

  @override
  String get updatesExplanation =>
      'Ab und zu werden manche Materialien aktualisiert: Wir veröffentlichen eine neue Version eines Arbeitsblattes oder fügen eine neue Übersetzung hinzu.\nUnser Ziel ist, dass du dir darüber keine Gedanken machen brauchst, sondern immer die aktuellsten Versionen einsatzbereit dabei hast. Deshalb kann die App im Hintergrund nach Aktualisierungen suchen und sie automatisch herunterladen, wenn du das möchtest.';

  @override
  String get letsGo => 'Los geht\'s!';

  @override
  String get homeExplanation =>
      'Gott baut sein Reich überall auf der Welt. Er möchte, dass wir dabei mitmachen und andere zu Jüngern machen!\nDiese App will dir diese Aufgabe erleichtern: Wir stellen dir gute Trainingsmaterialien zur Verfügung. Und das Beste ist: Du kannst dasselbe Arbeitsblatt in verschiedenen Sprachen anschauen, so dass du immer weißt, was es bedeutet, selbst wenn du eine Sprache nicht verstehst.\n\nAlle Inhalte sind nun offline verfügbar und jederzeit bereit auf deinem Handy:';

  @override
  String get foundBgActivity => 'Im Hintergrund wurde nach Updates gesucht';

  @override
  String get sharePdf => 'PDF teilen';

  @override
  String get openPdf => 'PDF öffnen';

  @override
  String get openInBrowser => 'Im Browser öffnen';

  @override
  String get shareLink => 'Link teilen';

  @override
  String get pdfNotAvailable =>
      'Für dieses Arbeitsblatt ist leider noch kein PDF verfügbar. Wenn du mithelfen möchtest, damit sich das bald ändert, dann melde dich bitte!';
}
