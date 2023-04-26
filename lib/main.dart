import 'package:flutter/material.dart';
import 'package:four_training/routes/assets_page.dart';
import 'package:four_training/routes/download_zip_asset_page.dart';
import 'package:four_training/routes/settings.dart';
import 'design/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: '4training',
      darkTheme: darkTheme,
      theme: lightTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => const DownloadZipAssetPage(title: 'DownloadZipAsset'),
        '/asset' : (context) => const AssetsPage(),
        '/settings' : (context) => const Settings(),
      },
    );
  }
}
