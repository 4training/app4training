import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/widgets/main_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/globals.dart';

/// Our "home" page (route: /home)
/// Shows kind of the same stuff as the main menu
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // When we're finished with loading: Go to the recently opened page
    return Scaffold(
        appBar: AppBar(
          title: const Text(Globals.appTitle),
        ),
        drawer: const MainDrawer(null, null),
        body: TableOfContent(null, null,
            header: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Text(context.l10n.homeExplanation))));
  }
}
