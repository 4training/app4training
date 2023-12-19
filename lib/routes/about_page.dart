import 'dart:async';

import 'package:app4training/data/globals.dart';
import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/routes/onboarding/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_linkify/flutter_linkify.dart';

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.about)),
      body: SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const PromoBlock(),
                const SizedBox(height: 20),
                Linkify(
                    text: context.l10n.appDescription,
                    // ignore: deprecated_member_use
                    textScaleFactor: MediaQuery.of(context).textScaleFactor,
                    style: Theme.of(context).textTheme.bodyMedium,
                    onOpen: (link) async {
                      unawaited(launchUrl(Uri.parse(link.url)));
                    }),
                const SizedBox(height: 10),
                Text(context.l10n.matthew10_8,
                    style: const TextStyle(fontStyle: FontStyle.italic)),
                const SizedBox(height: 10),
                Text(context.l10n.noCopyright),
                const SizedBox(height: 20),
                Align(
                    alignment: Alignment.topLeft,
                    child: Text(context.l10n.worksOffline,
                        style: Theme.of(context).textTheme.titleLarge)),
                const SizedBox(height: 10),
                Text(context.l10n.worksOfflineText),
                const SizedBox(height: 20),
                Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      context.l10n.secure,
                      style: Theme.of(context).textTheme.titleLarge,
                    )),
                const SizedBox(height: 10),
                Text(context.l10n.secureText),
                const SizedBox(height: 20),
                Align(
                    alignment: Alignment.topLeft,
                    child: Text(context.l10n.contributing,
                        style: Theme.of(context).textTheme.titleLarge)),
                const SizedBox(height: 10),
                Linkify(
                    text: context.l10n.contributingText,
                    // ignore: deprecated_member_use
                    textScaleFactor: MediaQuery.of(context).textScaleFactor,
                    style: Theme.of(context).textTheme.bodyMedium,
                    onOpen: (link) async {
                      unawaited(launchUrl(Uri.parse(link.url)));
                    }),
                const SizedBox(height: 20),
                Align(
                    alignment: Alignment.topLeft,
                    child: Text(context.l10n.openSource,
                        style: Theme.of(context).textTheme.titleLarge)),
                const SizedBox(height: 10),
                Linkify(
                    text: context.l10n.openSourceText,
                    // ignore: deprecated_member_use
                    textScaleFactor: MediaQuery.of(context).textScaleFactor,
                    style: Theme.of(context).textTheme.bodyMedium,
                    onOpen: (link) async {
                      unawaited(launchUrl(Uri.parse(link.url)));
                    }),
                const SizedBox(height: 20),
                Align(
                    alignment: Alignment.topLeft,
                    child: Text(context.l10n.version,
                        style: Theme.of(context).textTheme.titleLarge)),
                const SizedBox(height: 10),
                Align(
                    alignment: Alignment.topLeft,
                    child: Text(ref.read(packageInfoProvider).version))
              ],
            )),
      ),
    );
  }
}
