import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

/// A class around all sharing functionality to enable testing
/// (Packages: share_plus, url_launcher, open_filex)
///
/// Other options for testing (dependency injection etc.) are hard to use here
/// because of the usage of context.findAncestorWidgetOfExactType
/// so this is probably the best way to do it
class ShareService {
  /// Wraps Share.share() (package share_plus)
  Future<void> share(String text) {
    return SharePlus.instance.share(ShareParams(text: text));
  }

  /// Wraps Share.shareXFiles() (package share_plus)
  ///
  /// Not using the same argument List<XFile> because that would make it
  /// harder to verify that the function gets called with correct arguments
  /// with mocktail
  Future<ShareResult> shareFile(String path) {
    return SharePlus.instance.share(ShareParams(files: [XFile(path)]));
  }

  /// Wraps launchUrl (package url_launcher)
  Future<bool> launchUrl(Uri url) {
    return url_launcher.launchUrl(url);
  }

  /// Wraps OpenFilex.open (package open_filex)
  Future<OpenResult> open(String filePath) {
    return OpenFilex.open(filePath);
  }
}

/// A provider for all sharing functionality to enable testing
final shareProvider = Provider<ShareService>((ref) {
  return ShareService();
});
