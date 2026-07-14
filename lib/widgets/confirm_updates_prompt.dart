import 'package:app4training/data/bulk_language_download.dart';
import 'package:app4training/data/globals.dart';
import 'package:app4training/data/languages.dart';
import 'package:app4training/data/updates.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Persistent prompt shown on the settings page when
/// [AutomaticUpdates.requireConfirmation] is set and the background task has
/// found updates it deliberately did not auto-download. Lets the user confirm
/// downloading them via the normal foreground download path.
///
/// Renders nothing unless [updatesNeedConfirmationProvider] is true, so it
/// silently disappears once the user has downloaded the updates (or under any
/// other AutomaticUpdates mode).
class ConfirmUpdatesPrompt extends ConsumerStatefulWidget {
  const ConfirmUpdatesPrompt({super.key});

  @override
  ConsumerState<ConfirmUpdatesPrompt> createState() =>
      _ConfirmUpdatesPromptState();
}

class _ConfirmUpdatesPromptState extends ConsumerState<ConfirmUpdatesPrompt> {
  bool _isLoading = false;

  Future<void> _downloadUpdates() async {
    setState(() => _isLoading = true);
    // Get l10n now as we can't access context after the async gap
    final l10n = context.l10n;
    final codesToUpdate = [
      for (final languageCode in ref.read(availableLanguagesProvider))
        if (ref.read(languageStatusProvider(languageCode)).updatesAvailable &&
            ref.read(languageProvider(languageCode)).downloaded)
          languageCode,
    ];
    final result = await downloadLanguagesInParallel(
      codesToUpdate,
      download: (code) => ref.read(languageProvider(code).notifier).download(),
    );
    if (result.successCount > 0) {
      final text =
          (result.successCount == 1)
              ? l10n.updatedLanguage(
                l10n.getLanguageName(result.lastSuccessCode),
              )
              : l10n.updatedNLanguages(result.successCount, result.errorCount);
      ref
          .read(scaffoldMessengerProvider)
          .showSnackBar(SnackBar(content: Text(text)));
    } else if (result.errorCount > 0) {
      ref
          .read(scaffoldMessengerProvider)
          .showSnackBar(SnackBar(content: Text(l10n.updateError)));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // Only surface anything when updates await the user's confirmation
    if (!ref.watch(updatesNeedConfirmationProvider)) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            context.l10n.updatesReadyToDownload,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: 10),
        _isLoading
            ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(),
            )
            : ElevatedButton(
              style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
              onPressed: _downloadUpdates,
              child: Text(context.l10n.downloadUpdatesNow),
            ),
      ],
    );
  }
}
