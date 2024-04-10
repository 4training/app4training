import 'package:app4training/background/background_result.dart';
import 'package:app4training/data/exceptions.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/widgets/error_message.dart';
import 'package:app4training/widgets/html_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/widgets/loading_animation.dart';
import 'package:app4training/widgets/main_drawer.dart';
import 'package:app4training/widgets/language_selection.dart';

/// The standard view of this app:
/// Show a page (worksheet)
class ViewPage extends ConsumerWidget {
  final String page; // Name of the currently selected page
  final String langCode;
  const ViewPage(this.page, this.langCode, {super.key});

  /// First check whether the background process did something since
  /// the last time we checked.
  /// Then load the pageContent
  Future<String> checkAndLoad(BuildContext context, WidgetRef ref) async {
    // Get l10n now as we can't access context after async gap later
    AppLocalizations l10n = context.l10n;
    final foundActivity =
        await ref.read(backgroundResultProvider.notifier).checkForActivity();
    debugPrint("backgroundActivity: $foundActivity");
    if (foundActivity) {
      ref
          .watch(scaffoldMessengerProvider)
          .showSnackBar(SnackBar(content: Text(l10n.foundBgActivity)));
    }
    return ref
        .watch(pageContentProvider((name: page, langCode: langCode)).future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(Globals.appTitle),
          actions: const [LanguagesButton()],
        ),
        drawer: MainDrawer(page, langCode),
        body: FutureBuilder(
            future: checkAndLoad(context, ref),
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              debugPrint(snapshot.connectionState.toString());

              switch (snapshot.connectionState) {
                case ConnectionState.none:
                case ConnectionState.waiting:
                case ConnectionState.active:
                  return loadingAnimation("Loading content...");
                case ConnectionState.done:
                  debugPrint(
                      'Done, hasData: ${snapshot.hasData}, Error: ${snapshot.hasError}');
                  if (snapshot.hasError) {
                    final e = snapshot.error;
                    if (e is App4TrainingException) {
                      if ((e is PageNotFoundException) ||
                          (e is LanguageNotDownloadedException)) {
                        return ErrorMessage(
                            context.l10n.warning,
                            '${context.l10n.cantDisplayPage(page, context.l10n.getLanguageName(langCode))}\n'
                            '${context.l10n.reason} ${e.toLocalizedString(context)}',
                            icon: Icons.warning_amber,
                            iconColor: Colors.black);
                      } else if (e is LanguageCorruptedException) {
                        return ErrorMessage(
                            context.l10n.error, e.toLocalizedString(context));
                      }
                    }
                    // What happened?!
                    return ErrorMessage(context.l10n.error,
                        context.l10n.internalError(e.toString()));
                  } else {
                    String content = snapshot.data;
                    // Save the selected page to the SharedPreferences to continue here
                    // in case the user closes the app
                    ref.read(sharedPrefsProvider).setString('recentPage', page);
                    ref
                        .read(sharedPrefsProvider)
                        .setString('recentLang', langCode);
                    return HtmlView(
                        content,
                        (Globals.rtlLanguages.contains(langCode))
                            ? TextDirection.rtl
                            : TextDirection.ltr);
                  }
              }
            }));
  }
}
