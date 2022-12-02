import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class LocalPageStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;

    return File('$path/page.html');
  }

  Future<String> readFile() async {
    try {
      final file = await _localFile;

      // Read the file
      final content = await file.readAsString();

      return content;
    } catch (e) {

      print(e.toString());
      return "No page found";
    }
  }

  Future<File> writeFile (String content) async {
     final file = await _localFile;

     return file.writeAsString(content);

  }

}
