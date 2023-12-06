import 'package:app4training/l10n/l10n.dart';
import 'package:app4training/routes/view_page.dart';
import 'package:app4training/widgets/error_message.dart';
import 'package:app4training/widgets/main_drawer.dart';
import 'package:flutter/material.dart';

/// This error page is shown to the user in case of internal errors.
class ErrorPage extends StatelessWidget {
  final String message;
  const ErrorPage(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('Internal error: $message');
    return Scaffold(
        appBar: AppBar(title: const Text(ViewPage.title)),
        drawer: const MainDrawer(null, null),
        body: ErrorMessage(
            context.l10n.error, context.l10n.internalError(message)));
  }
}
