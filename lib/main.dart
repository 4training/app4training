import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:four_training/routes/download_zip_asset_page.dart';
import 'package:four_training/routes/local_storage_page.dart';
import 'package:four_training/utils/page_storage.dart';

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
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: DownloadZipAssetPage(title: 'DownloadZipAsset', storage: LocalPageStorage()),
      //home: LocalStoragePage(title: 'LocalStorage', storage: LocalPageStorage()),
    );
  }
}
