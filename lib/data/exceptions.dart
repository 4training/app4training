/// "Milder" exception: A language is not downloaded when we expected it to be
class LanguageNotDownloadedException implements Exception {
  final String languageCode;
  LanguageNotDownloadedException(this.languageCode);

  @override
  String toString() => "Language '$languageCode' is not downloaded.";
}

/// "Milder" exception: A page is not existing -> probably some internal error,
/// there should never have been a link here...
class PageNotFoundException implements Exception {
  final String page;
  final String languageCode;
  PageNotFoundException(this.page, this.languageCode);

  @override
  String toString() => "Couldn't find page $page/$languageCode.";
}

/// Some more serious exception: Somehow our language seems to be corrupted.
/// Like inconsistencies in our Language object or file system issues.
/// Hopefully this gets resolved by deleting the language and re-downloading it
class LanguageCorruptedException implements Exception {
  final String languageCode;
  final String message;
  final Exception? exception;

  LanguageCorruptedException(this.languageCode, this.message, [this.exception]);

  @override
  String toString() {
    String ret = "Language '$languageCode' seems to be corrupted: $message";
    if (exception != null) ret += ' (${exception.toString()})';
    return ret;
  }
}
