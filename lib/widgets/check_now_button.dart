import 'package:app4training/data/languages.dart';
import 'package:app4training/l10n/generated/app_localizations.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app4training/data/updates.dart';
import '../data/globals.dart';

/// Button on the settings page to check for available updates
class CheckNowButton extends ConsumerStatefulWidget {
  final String buttonText;
  const CheckNowButton({super.key, required this.buttonText});

  @override
  ConsumerState<CheckNowButton> createState() => _CheckNowButtonState();
}

/// While we're checking for updates a loading animation is shown in the button
class _CheckNowButtonState extends ConsumerState<CheckNowButton> {
  bool _isLoading = false; // our state

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(), fixedSize: const Size(150, 36)),
        onPressed: () async {
          setState(() {
            _isLoading = true;
          });

          bool hasError = false;
          bool exceededLimit = false;
          int countAvailableUpdates = 0;
          // Get l10n now as we can't access context after async gap later
          AppLocalizations l10n = context.l10n;

          for (String languageCode in ref.read(availableLanguagesProvider)) {
            // We don't check languages that are not downloaded
            if (!ref.read(languageProvider(languageCode)).downloaded) continue;
            int result = await ref
                .read(languageStatusProvider(languageCode).notifier)
                .check();
            if (result < 0) {
              hasError = true;
              if (result == apiRateLimitExceeded) {
                exceededLimit = true;
                break;
              }
            }
            if (result > 0) countAvailableUpdates++;
          }

          if (!hasError) {
            ref.watch(scaffoldMessengerProvider).showSnackBar(SnackBar(
                content: Text(l10n.nUpdatesAvailable(countAvailableUpdates))));
          } else {
            if (exceededLimit) {
              ref.watch(scaffoldMessengerProvider).showSnackBar(
                  SnackBar(content: Text(l10n.checkingUpdatesLimit)));
            } else {
              ref.watch(scaffoldMessengerProvider).showSnackBar(
                  SnackBar(content: Text(l10n.checkingUpdatesError)));
            }
          }
          setState(() {
            _isLoading = false;
          });
        },
        child: _isLoading // Show Text or loading animation depending on state
            ? const SizedBox(
                height: 25, width: 25, child: CircularProgressIndicator())
            : Text(widget.buttonText));
  }
}
