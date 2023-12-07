import 'package:app4training/l10n/l10n.dart';
import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.about)),
      body: SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(context.l10n.appDescription,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 10),
                Text(context.l10n.matthew10_8,
                    style: const TextStyle(fontStyle: FontStyle.italic)),
                const SizedBox(height: 10),
                Text(context.l10n.noCopyright),
                const SizedBox(height: 20),
                Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      context.l10n.trustworthy,
                      style: Theme.of(context).textTheme.titleLarge,
                    )),
                const SizedBox(height: 10),
                Text(context.l10n.trustworthyText),
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
                    child: Text(context.l10n.contributing,
                        style: Theme.of(context).textTheme.titleLarge)),
                const SizedBox(height: 10),
                Text(context.l10n.contributingText),
                const SizedBox(height: 20),
                Align(
                    alignment: Alignment.topLeft,
                    child: Text(context.l10n.openSource,
                        style: Theme.of(context).textTheme.titleLarge)),
                const SizedBox(height: 10),
                Text(context.l10n.openSourceText),
                const SizedBox(height: 20),
                Align(
                    alignment: Alignment.topLeft,
                    child: Text(context.l10n.version,
                        style: Theme.of(context).textTheme.titleLarge)),
                const SizedBox(height: 10),
                const Align(
                    alignment: Alignment.topLeft, child: Text('0.5')), // TODO
              ],
            )),
      ),
    );
  }
}
