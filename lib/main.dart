
import 'package:flutter/material.dart';
import 'package:four_training/routes/download_zip_asset_page.dart';

import 'design/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '4training',
      darkTheme: darkTheme,
      theme: lightTheme,
      themeMode: ThemeMode.system,
      home: const DownloadZipAssetPage(title: 'DownloadZipAsset'),
      //home: LocalStoragePage(title: 'LocalStorage', storage: LocalPageStorage()),
    );
  }
}
