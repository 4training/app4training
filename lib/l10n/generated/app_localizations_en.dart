// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'Settings';

  @override
  String get appLanguage => 'App language';

  @override
  String get languages => 'Languages';

  @override
  String get languagesText =>
      'These are the languages available. You can download, update or delete them manually.';

  @override
  String get allLanguages => 'All languages';

  @override
  String get updates => 'Updates';

  @override
  String get checkFrequency => 'Check for updates';

  @override
  String get never => 'never';

  @override
  String get daily => 'daily';

  @override
  String get weekly => 'weekly';

  @override
  String get monthly => 'monthly';

  @override
  String get testinterval => '15min (Test)';

  @override
  String get lastCheck => 'Last check:';

  @override
  String get checkNow => 'Check now';

  @override
  String get doAutomaticUpdates => 'Do automatic updates';

  @override
  String get requireConfirmation => 'require confirmation';

  @override
  String get onlyOnWifi => 'yes, but only when in wifi';

  @override
  String get yesAlways => 'yes, also via mobile data';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get light => 'light';

  @override
  String get dark => 'dark';

  @override
  String get language_tr => 'Turkish';

  @override
  String get language_zh => 'Chinese';

  @override
  String get language_vi => 'Vietnamese';

  @override
  String get language_ro => 'Romanian';

  @override
  String get language_ky => 'Kyrgyz';

  @override
  String get language_pl => 'Polish';

  @override
  String get language_id => 'Indonesian';

  @override
  String get language_xh => 'Xhosa';

  @override
  String get language_uz => 'Uzbek';

  @override
  String get language_af => 'Afrikaans';

  @override
  String get language_ta => 'Tamil';

  @override
  String get language_sr => 'Serbian';

  @override
  String get language_ms => 'Malay';

  @override
  String get language_az => 'Azerbaijani';

  @override
  String get language_ti => 'Tigrinya';

  @override
  String get language_sw => 'Swahili';

  @override
  String get language_nb => 'Norwegian';

  @override
  String get language_ku => 'Kurmanji';

  @override
  String get language_sv => 'Swedish';

  @override
  String get language_ml => 'Malayalam';

  @override
  String get language_hi => 'Hindi';

  @override
  String get language_lg => 'Luganda';

  @override
  String get language_kn => 'Kannada';

  @override
  String get language_it => 'Italian';

  @override
  String get language_cs => 'Czech';

  @override
  String get language_fa => 'Persian';

  @override
  String get language_ar => 'Arabic';

  @override
  String get language_ru => 'Russian';

  @override
  String get language_nl => 'Dutch';

  @override
  String get language_fr => 'French';

  @override
  String get language_es => 'Spanish';

  @override
  String get language_sq => 'Albanian';

  @override
  String get language_en => 'English';

  @override
  String get language_de => 'German';

  @override
  String get diskUsage => 'Disk usage';

  @override
  String countLanguages(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'languages',
      one: 'language',
      zero: 'languages',
    );
    return '($countString $_temp0)';
  }

  @override
  String get warning => 'Warning';

  @override
  String get warnBeforeDelete =>
      'You are trying to delete the currently selected app language. Are you sure?';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String deletedLanguage(String languageName) {
    return '$languageName was deleted';
  }

  @override
  String deletedNLanguages(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    return '$countString languages deleted';
  }

  @override
  String downloadedLanguage(String languageName) {
    return '$languageName is now available';
  }

  @override
  String downloadedNLanguages(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    return '$countString languages downloaded';
  }

  @override
  String get downloadError =>
      'Download failed. Please check your internet connection and try again later';

  @override
  String updatedLanguage(String languageName) {
    return '$languageName is now up-to-date';
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
      other: ', $errorString failed',
      zero: '',
    );
    return '$countString languages updated$_temp0';
  }

  @override
  String get updateError => 'Update failed. Please try again later.';

  @override
  String nUpdatesAvailable(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Updates available in $countString languages',
      one: 'Language update available',
      zero: 'Languages are already up-to-date',
    );
    return '$_temp0';
  }

  @override
  String get checkingUpdatesLimit =>
      'Error: You checked for updates too often. Please wait an hour.';

  @override
  String get checkingUpdatesError =>
      'Error while checking updates. Please try again later';

  @override
  String get languageSelectionHeader => 'Show current page in:';

  @override
  String get manageLanguages => 'Manage languages';

  @override
  String get content => 'Content';

  @override
  String translationAvailableHint(String language) {
    return ': Available in $language';
  }

  @override
  String get essentials => 'Essentials';

  @override
  String get essentialsForTrainers => 'Essentials - for trainers';

  @override
  String get innerHealing => 'Inner Healing';

  @override
  String get innerHealingForTrainers => 'Inner Healing - for trainers';

  @override
  String get sorry => 'We\'re sorry';

  @override
  String notTranslated(Object language) {
    return 'The requested page is not yet translated into $language.\nIf you can help with translation, please contact us!';
  }

  @override
  String get okay => 'Okay';

  @override
  String get translationAvailable => 'Translation available';

  @override
  String translationAvailableText(String page, String language) {
    return 'Page \"$page\" is available in $language.';
  }

  @override
  String languageChangedBack(String page, String language, String appLanguage) {
    return 'Page \"$page\" is not available in $language. Language changed back to $appLanguage';
  }

  @override
  String get close => 'Close';

  @override
  String get showPage => 'Show page';

  @override
  String get error => 'Error';

  @override
  String get reason => 'Reason: ';

  @override
  String internalError(String errorMessage) {
    return 'Oops, we\'re sorry. Something unexpected happened. Please tell us about the issue so that we can fix it.\nInternal error: $errorMessage';
  }

  @override
  String cantDisplayPage(String page, String language) {
    return 'Can\'t display page \"$page\" in $language.';
  }

  @override
  String languageNotDownloaded(String language) {
    return 'Language isn\'t available. Please go to the settings and download $language.';
  }

  @override
  String pageNotFound(String page, String languageCode) {
    return 'Page $page/$languageCode not found. Maybe you followed an errorneous link and the page isn\'t translated yet.';
  }

  @override
  String languageCorrupted(String language, String errorMessage) {
    return 'Language data for \'$language\' seems to be corrupted: $errorMessage\nGo to the settings and try to delete and re-download this language. Please let us know if the issue still persists.';
  }

  @override
  String get about => 'About';

  @override
  String get appDescription =>
      'This is the app of the https://www.4training.net website. Our goal is to provide you with great resources in many languages.';

  @override
  String get matthew10_8 =>
      'Matthew 10:8, “Freely you have received; freely give.”';

  @override
  String get noCopyright =>
      'All contents are copyright-free! You may use, copy or adapt them without restrictions (CC0).';

  @override
  String get secure => 'Secure';

  @override
  String get secureText =>
      'This app does no tracking, shows no adverts and doesn\'t send any information anywhere. As you may have noticed it doesn\'t need any permissions. You can\'t get more security 😀\nResources are downloaded SSL-encrypted from github.com.';

  @override
  String get worksOffline => 'Works offline';

  @override
  String get worksOfflineText =>
      'After you downloaded the languages you\'re interested in, the app doesn\'t need an internet connection. You\'ll only need internet if you want to check for updates or download another language.';

  @override
  String get contributing => 'Contributing';

  @override
  String get contributingText =>
      'Many people contributed their time, skills and finances to make this vision happen. Thank you! There is many areas and ways you can contribute: Translating, programming, donating, design, correcting errors, ...\nPlease write us at contact@4training.net – we\'re happy to hear your ideas and feedback!';

  @override
  String get openSource => 'Open Source';

  @override
  String get openSourceText =>
      'This app is open source. You have the freedom to use it, study it, share it and improve it. Sourcecode, roadmap and more information:\nhttps://github.com/4training/app4training';

  @override
  String get version => 'Version';

  @override
  String get welcome => 'Welcome!';

  @override
  String get selectAppLanguage =>
      'Please select the app language. This is the language the menu and all settings will be in.';

  @override
  String get continueText => 'Continue';

  @override
  String get back => 'Back';

  @override
  String get appName => '4training.net App';

  @override
  String promoFeature1(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    return '$countString Worksheets';
  }

  @override
  String get promoFeature2 => 'Works offline';

  @override
  String get promoFeature3 => 'No copyright';

  @override
  String get downloadLanguages => 'Download languages';

  @override
  String get downloadLanguagesExplanation =>
      'Which languages do you want to use? Download them now and then they\'re available offline. One language uses less than 4 MB.';

  @override
  String get warnMissingAppLanguage =>
      'Please download English (en) before you proceed. In order to do something with the app you need to download the app language.';

  @override
  String get gotit => 'Got it';

  @override
  String get ignore => 'Ignore';

  @override
  String get updatesExplanation =>
      'From time to time the resources get updated: We release a new version of a worksheet or add a new translation.\nWe want you to not worry about that but be always ready to use the latest versions. Therefore the app can check for updates in the background and download them automatically if you want.';

  @override
  String get letsGo => 'Let\'s go!';

  @override
  String get homeExplanation =>
      'God is building His kingdom all around the world. He wants us to join in His work and make disciples!\nThis app wants to serve you and make your job easier: We equip you with good training worksheets. The best thing is: You can access the same worksheet in different languages so that you always know what it means, even if you don\'t understand the language.\n\nAll this content is now available offline, always ready on your phone:';

  @override
  String get foundBgActivity => 'Searched for updates in the background';

  @override
  String get sharePdf => 'Share PDF';

  @override
  String get openPdf => 'Open PDF';

  @override
  String get openInBrowser => 'Open in browser';

  @override
  String get shareLink => 'Share link';

  @override
  String get pdfNotAvailable =>
      'Unfortunately there is no PDF available yet for this worksheet. If you want to help make this change soon, please contact us!';
}
