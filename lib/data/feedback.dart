import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app_language.dart';

enum FeedbackType { question, feedback, trainer }

enum ResponseOption { email, app }

class FeedbackDetails {
  FeedbackType type;
  String? subtype;
  String message;
  String? email;
  ResponseOption? responseType;
  String? worksheet;
  String? worksheetLang;

  FeedbackDetails({
    required this.type,
    this.subtype,
    this.responseType,
    required this.message,
    this.email,
    this.worksheet,
    this.worksheetLang,
  });

  Future<Map<String, Object?>> toJson(WidgetRef ref) async {
    return {
      "type": type == FeedbackType.question
          ? "question"
          : type == FeedbackType.feedback
              ? "feedback"
              : type == FeedbackType.trainer
                  ? "trainer"
                  : null,
      "sub-type": subtype ?? null,
      "message": message,
      "e-mail": email ?? null,
      "response-type": responseType == ResponseOption.app
          ? "app"
          : responseType == ResponseOption.email
              ? "email"
              : "none",
      "worksheet": worksheet ?? null,
      "worksheet-lang": worksheetLang ?? null,
      "user-lang": ref.read(appLanguageProvider.notifier).build().languageCode,
      "app-version": (await PackageInfo.fromPlatform()).buildNumber
    };
  }
}
