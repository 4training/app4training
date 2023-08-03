class AppLanguage {
  final String languageCode;
  final List<dynamic> pages;

  const AppLanguage({required this.languageCode, required this.pages});

  factory AppLanguage.fromJson(Map<String, dynamic> json) {
    return AppLanguage(
        languageCode: json['languageCode'] as String,
        pages: json['pages'] as List<dynamic>);

  }
}