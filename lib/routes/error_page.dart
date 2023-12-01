import 'package:app4training/routes/view_page.dart';
import 'package:app4training/widgets/main_drawer.dart';
import 'package:flutter/material.dart';

/// This error page is shown in case of unexpected exceptions (non-fatal)
class ErrorPage extends StatelessWidget {
  final String message;
  const ErrorPage(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(ViewPage.title)),
      drawer: const MainDrawer(null, null),
      body: Center(child: Text(message)),
    );
  }
}
