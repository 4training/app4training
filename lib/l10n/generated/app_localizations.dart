import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguage;

  /// No description provided for @languages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languages;

  /// No description provided for @languagesText.
  ///
  /// In en, this message translates to:
  /// **'These are the languages available. You can download, update or delete them manually.'**
  String get languagesText;

  /// No description provided for @allLanguages.
  ///
  /// In en, this message translates to:
  /// **'All languages'**
  String get allLanguages;

  /// Headline on the settings page
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updates;

  /// No description provided for @checkFrequency.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkFrequency;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'never'**
  String get never;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'monthly'**
  String get monthly;

  /// No description provided for @testinterval.
  ///
  /// In en, this message translates to:
  /// **'15min (Test)'**
  String get testinterval;

  /// No description provided for @lastCheck.
  ///
  /// In en, this message translates to:
  /// **'Last check:'**
  String get lastCheck;

  /// No description provided for @checkNow.
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get checkNow;

  /// No description provided for @doAutomaticUpdates.
  ///
  /// In en, this message translates to:
  /// **'Do automatic updates'**
  String get doAutomaticUpdates;

  /// Option for {doAutomaticUpdates}
  ///
  /// In en, this message translates to:
  /// **'require confirmation'**
  String get requireConfirmation;

  /// No description provided for @onlyOnWifi.
  ///
  /// In en, this message translates to:
  /// **'yes, but only when in wifi'**
  String get onlyOnWifi;

  /// Option for {doAutomaticUpdates}
  ///
  /// In en, this message translates to:
  /// **'yes, also via mobile data'**
  String get yesAlways;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'dark'**
  String get dark;

  /// No description provided for @language_tr.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get language_tr;

  /// No description provided for @language_zh.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get language_zh;

  /// No description provided for @language_vi.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get language_vi;

  /// No description provided for @language_ro.
  ///
  /// In en, this message translates to:
  /// **'Romanian'**
  String get language_ro;

  /// No description provided for @language_ky.
  ///
  /// In en, this message translates to:
  /// **'Kyrgyz'**
  String get language_ky;

  /// No description provided for @language_pl.
  ///
  /// In en, this message translates to:
  /// **'Polish'**
  String get language_pl;

  /// No description provided for @language_id.
  ///
  /// In en, this message translates to:
  /// **'Indonesian'**
  String get language_id;

  /// No description provided for @language_xh.
  ///
  /// In en, this message translates to:
  /// **'Xhosa'**
  String get language_xh;

  /// No description provided for @language_uz.
  ///
  /// In en, this message translates to:
  /// **'Uzbek'**
  String get language_uz;

  /// No description provided for @language_af.
  ///
  /// In en, this message translates to:
  /// **'Afrikaans'**
  String get language_af;

  /// No description provided for @language_ta.
  ///
  /// In en, this message translates to:
  /// **'Tamil'**
  String get language_ta;

  /// No description provided for @language_sr.
  ///
  /// In en, this message translates to:
  /// **'Serbian'**
  String get language_sr;

  /// No description provided for @language_ms.
  ///
  /// In en, this message translates to:
  /// **'Malay'**
  String get language_ms;

  /// No description provided for @language_az.
  ///
  /// In en, this message translates to:
  /// **'Azerbaijani'**
  String get language_az;

  /// No description provided for @language_ti.
  ///
  /// In en, this message translates to:
  /// **'Tigrinya'**
  String get language_ti;

  /// No description provided for @language_sw.
  ///
  /// In en, this message translates to:
  /// **'Swahili'**
  String get language_sw;

  /// No description provided for @language_nb.
  ///
  /// In en, this message translates to:
  /// **'Norwegian'**
  String get language_nb;

  /// No description provided for @language_ku.
  ///
  /// In en, this message translates to:
  /// **'Kurmanji'**
  String get language_ku;

  /// No description provided for @language_sv.
  ///
  /// In en, this message translates to:
  /// **'Swedish'**
  String get language_sv;

  /// No description provided for @language_ml.
  ///
  /// In en, this message translates to:
  /// **'Malayalam'**
  String get language_ml;

  /// No description provided for @language_hi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get language_hi;

  /// No description provided for @language_lg.
  ///
  /// In en, this message translates to:
  /// **'Luganda'**
  String get language_lg;

  /// No description provided for @language_kn.
  ///
  /// In en, this message translates to:
  /// **'Kannada'**
  String get language_kn;

  /// No description provided for @language_it.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get language_it;

  /// No description provided for @language_cs.
  ///
  /// In en, this message translates to:
  /// **'Czech'**
  String get language_cs;

  /// No description provided for @language_fa.
  ///
  /// In en, this message translates to:
  /// **'Persian'**
  String get language_fa;

  /// No description provided for @language_ar.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get language_ar;

  /// No description provided for @language_ru.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get language_ru;

  /// No description provided for @language_nl.
  ///
  /// In en, this message translates to:
  /// **'Dutch'**
  String get language_nl;

  /// No description provided for @language_fr.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get language_fr;

  /// No description provided for @language_es.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get language_es;

  /// No description provided for @language_sq.
  ///
  /// In en, this message translates to:
  /// **'Albanian'**
  String get language_sq;

  /// No description provided for @language_en.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language_en;

  /// No description provided for @language_de.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get language_de;

  /// No description provided for @diskUsage.
  ///
  /// In en, this message translates to:
  /// **'Disk usage'**
  String get diskUsage;

  /// right besides {diskUsage}
  ///
  /// In en, this message translates to:
  /// **'({count} {count, plural, =0{languages} =1{language} other{languages}})'**
  String countLanguages(num count);

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @warnBeforeDelete.
  ///
  /// In en, this message translates to:
  /// **'You are trying to delete the currently selected app language. Are you sure?'**
  String get warnBeforeDelete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Snackbar info message
  ///
  /// In en, this message translates to:
  /// **'{languageName} was deleted'**
  String deletedLanguage(String languageName);

  /// Snackbar message after clicking on the button to delete all languages and >1 language were deleted
  ///
  /// In en, this message translates to:
  /// **'{count} languages deleted'**
  String deletedNLanguages(num count);

  /// Snackbar info message
  ///
  /// In en, this message translates to:
  /// **'{languageName} is now available'**
  String downloadedLanguage(String languageName);

  /// Snackbar message after clicking on the button to download all languages and >1 language were downloaded.
  ///
  /// In en, this message translates to:
  /// **'{count} languages downloaded'**
  String downloadedNLanguages(num count);

  /// No description provided for @downloadError.
  ///
  /// In en, this message translates to:
  /// **'Download failed. Please check your internet connection and try again later'**
  String get downloadError;

  /// Snackbar info message
  ///
  /// In en, this message translates to:
  /// **'{languageName} is now up-to-date'**
  String updatedLanguage(String languageName);

  /// Snackbar message after clicking on the button to update all languages and >1 language were updated. Or if at least one update failed
  ///
  /// In en, this message translates to:
  /// **'{count} languages updated{error, plural, =0{} other{, {error} failed}}'**
  String updatedNLanguages(num count, num error);

  /// No description provided for @updateError.
  ///
  /// In en, this message translates to:
  /// **'Update failed. Please try again later.'**
  String get updateError;

  /// Whether updates are available in 0, 1 or more languages
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Languages are already up-to-date} =1{Language update available} other{Updates available in {count} languages}}'**
  String nUpdatesAvailable(num count);

  /// No description provided for @checkingUpdatesLimit.
  ///
  /// In en, this message translates to:
  /// **'Error: You checked for updates too often. Please wait an hour.'**
  String get checkingUpdatesLimit;

  /// No description provided for @checkingUpdatesError.
  ///
  /// In en, this message translates to:
  /// **'Error while checking updates. Please try again later'**
  String get checkingUpdatesError;

  /// Text shown before the list of languages when users taps the language selection button
  ///
  /// In en, this message translates to:
  /// **'Show current page in:'**
  String get languageSelectionHeader;

  /// Text shown below the list of languages when users taps the language selection button
  ///
  /// In en, this message translates to:
  /// **'Manage languages'**
  String get manageLanguages;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// Quick explanation in main drawer when we show a translated worksheet
  ///
  /// In en, this message translates to:
  /// **': Available in {language}'**
  String translationAvailableHint(String language);

  /// No description provided for @essentials.
  ///
  /// In en, this message translates to:
  /// **'Essentials'**
  String get essentials;

  /// No description provided for @essentialsForTrainers.
  ///
  /// In en, this message translates to:
  /// **'Essentials - for trainers'**
  String get essentialsForTrainers;

  /// No description provided for @innerHealing.
  ///
  /// In en, this message translates to:
  /// **'Inner Healing'**
  String get innerHealing;

  /// No description provided for @innerHealingForTrainers.
  ///
  /// In en, this message translates to:
  /// **'Inner Healing - for trainers'**
  String get innerHealingForTrainers;

  /// No description provided for @sorry.
  ///
  /// In en, this message translates to:
  /// **'We\'re sorry'**
  String get sorry;

  /// No description provided for @notTranslated.
  ///
  /// In en, this message translates to:
  /// **'The requested page is not yet translated into {language}.\nIf you can help with translation, please contact us!'**
  String notTranslated(Object language);

  /// No description provided for @okay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get okay;

  /// No description provided for @translationAvailable.
  ///
  /// In en, this message translates to:
  /// **'Translation available'**
  String get translationAvailable;

  /// Dialog when clicking on a translate icon, indicating that the page is translated into the currently selected language
  ///
  /// In en, this message translates to:
  /// **'Page \"{page}\" is available in {language}.'**
  String translationAvailableText(String page, String language);

  /// Snackbar message when user tries to open a page but it's not available in the currently selected other language
  ///
  /// In en, this message translates to:
  /// **'Page \"{page}\" is not available in {language}. Language changed back to {appLanguage}'**
  String languageChangedBack(String page, String language, String appLanguage);

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @showPage.
  ///
  /// In en, this message translates to:
  /// **'Show page'**
  String get showPage;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason: '**
  String get reason;

  /// User-facing error message
  ///
  /// In en, this message translates to:
  /// **'Oops, we\'re sorry. Something unexpected happened. Please tell us about the issue so that we can fix it.\nInternal error: {errorMessage}'**
  String internalError(String errorMessage);

  /// User-facing error message when a page can't be shown.
  ///
  /// In en, this message translates to:
  /// **'Can\'t display page \"{page}\" in {language}.'**
  String cantDisplayPage(String page, String language);

  /// Error message when trying to open a page but the language isn't downloaded
  ///
  /// In en, this message translates to:
  /// **'Language isn\'t available. Please go to the settings and download {language}.'**
  String languageNotDownloaded(String language);

  /// Error message when a page can't be found.
  ///
  /// In en, this message translates to:
  /// **'Page {page}/{languageCode} not found. Maybe you followed an errorneous link and the page isn\'t translated yet.'**
  String pageNotFound(String page, String languageCode);

  /// Error message when there are errors in a language object
  ///
  /// In en, this message translates to:
  /// **'Language data for \'{language}\' seems to be corrupted: {errorMessage}\nGo to the settings and try to delete and re-download this language. Please let us know if the issue still persists.'**
  String languageCorrupted(String language, String errorMessage);

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'This is the app of the https://www.4training.net website. Our goal is to provide you with great resources in many languages.'**
  String get appDescription;

  /// No description provided for @matthew10_8.
  ///
  /// In en, this message translates to:
  /// **'Matthew 10:8, “Freely you have received; freely give.”'**
  String get matthew10_8;

  /// No description provided for @noCopyright.
  ///
  /// In en, this message translates to:
  /// **'All contents are copyright-free! You may use, copy or adapt them without restrictions (CC0).'**
  String get noCopyright;

  /// No description provided for @secure.
  ///
  /// In en, this message translates to:
  /// **'Secure'**
  String get secure;

  /// No description provided for @secureText.
  ///
  /// In en, this message translates to:
  /// **'This app does no tracking, shows no adverts and doesn\'t send any information anywhere. As you may have noticed it doesn\'t need any permissions. You can\'t get more security 😀\nResources are downloaded SSL-encrypted from github.com.'**
  String get secureText;

  /// No description provided for @worksOffline.
  ///
  /// In en, this message translates to:
  /// **'Works offline'**
  String get worksOffline;

  /// No description provided for @worksOfflineText.
  ///
  /// In en, this message translates to:
  /// **'After you downloaded the languages you\'re interested in, the app doesn\'t need an internet connection. You\'ll only need internet if you want to check for updates or download another language.'**
  String get worksOfflineText;

  /// No description provided for @contributing.
  ///
  /// In en, this message translates to:
  /// **'Contributing'**
  String get contributing;

  /// No description provided for @contributingText.
  ///
  /// In en, this message translates to:
  /// **'Many people contributed their time, skills and finances to make this vision happen. Thank you! There is many areas and ways you can contribute: Translating, programming, donating, design, correcting errors, ...\nPlease write us at contact@4training.net – we\'re happy to hear your ideas and feedback!'**
  String get contributingText;

  /// No description provided for @openSource.
  ///
  /// In en, this message translates to:
  /// **'Open Source'**
  String get openSource;

  /// No description provided for @openSourceText.
  ///
  /// In en, this message translates to:
  /// **'This app is open source. You have the freedom to use it, study it, share it and improve it. Sourcecode, roadmap and more information:\nhttps://github.com/4training/app4training'**
  String get openSourceText;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcome;

  /// No description provided for @selectAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'Please select the app language. This is the language the menu and all settings will be in.'**
  String get selectAppLanguage;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'4training.net App'**
  String get appName;

  /// One feature shown on the screen on first startup of the app with number of worksheets available
  ///
  /// In en, this message translates to:
  /// **'{count} Worksheets'**
  String promoFeature1(num count);

  /// No description provided for @promoFeature2.
  ///
  /// In en, this message translates to:
  /// **'Works offline'**
  String get promoFeature2;

  /// No description provided for @promoFeature3.
  ///
  /// In en, this message translates to:
  /// **'No copyright'**
  String get promoFeature3;

  /// No description provided for @downloadLanguages.
  ///
  /// In en, this message translates to:
  /// **'Download languages'**
  String get downloadLanguages;

  /// No description provided for @downloadLanguagesExplanation.
  ///
  /// In en, this message translates to:
  /// **'Which languages do you want to use? Download them now and then they\'re available offline. One language uses less than 4 MB.'**
  String get downloadLanguagesExplanation;

  /// Hint for translators: Replace English (en) with your language. Description: Warning message when user tries to continue without having downloaded his app language
  ///
  /// In en, this message translates to:
  /// **'Please download English (en) before you proceed. In order to do something with the app you need to download the app language.'**
  String get warnMissingAppLanguage;

  /// No description provided for @gotit.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotit;

  /// No description provided for @ignore.
  ///
  /// In en, this message translates to:
  /// **'Ignore'**
  String get ignore;

  /// No description provided for @updatesExplanation.
  ///
  /// In en, this message translates to:
  /// **'From time to time the resources get updated: We release a new version of a worksheet or add a new translation.\nWe want you to not worry about that but be always ready to use the latest versions. Therefore the app can check for updates in the background and download them automatically if you want.'**
  String get updatesExplanation;

  /// No description provided for @letsGo.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go!'**
  String get letsGo;

  /// No description provided for @homeExplanation.
  ///
  /// In en, this message translates to:
  /// **'God is building His kingdom all around the world. He wants us to join in His work and make disciples!\nThis app wants to serve you and make your job easier: We equip you with good training worksheets. The best thing is: You can access the same worksheet in different languages so that you always know what it means, even if you don\'t understand the language.\n\nAll this content is now available offline, always ready on your phone:'**
  String get homeExplanation;

  /// No description provided for @foundBgActivity.
  ///
  /// In en, this message translates to:
  /// **'Searched for updates in the background'**
  String get foundBgActivity;

  /// No description provided for @sharePdf.
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get sharePdf;

  /// No description provided for @openPdf.
  ///
  /// In en, this message translates to:
  /// **'Open PDF'**
  String get openPdf;

  /// No description provided for @openInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get openInBrowser;

  /// No description provided for @shareLink.
  ///
  /// In en, this message translates to:
  /// **'Share link'**
  String get shareLink;

  /// No description provided for @pdfNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Unfortunately there is no PDF available yet for this worksheet. If you want to help make this change soon, please contact us!'**
  String get pdfNotAvailable;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
