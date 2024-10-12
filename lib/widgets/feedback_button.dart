import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../routes/feedback_page.dart';

class FeedbackButton extends StatelessWidget {
  const FeedbackButton({super.key, this.page, this.langCode});

  final String? page;
  final String? langCode;

  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: () {
          Navigator.pushNamed(context, '/feedback',
              arguments:
                  FeedbackArguments(langCode: langCode, worksheetPage: page));
        },
        icon: const Icon(Icons.feedback_rounded));
  }
}
