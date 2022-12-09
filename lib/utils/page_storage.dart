import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

// https://stackoverflow.com/questions/71431463/how-to-access-a-zip-file-asset-directly-without-storing-unpacked-file-temporari

class LocalPageStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;

    return File('$path/page.html');
  }

  Future<File> get _localUnzippedFile async {
    final path = await _localPath;

    return File('$path/page2.html');
  }

  Future<String> readFile() async {
    try {
      final file = await _localFile;

      // Read the file
      final content = await file.readAsString();

      return content;
    } catch (e) {
      debugPrint(e.toString());
      return "No page found";
    }
  }

  Future<String> readUnzippedFile() async {
    try {
      final file = await _localUnzippedFile;

      // Read the file
      final content = await file.readAsString();

      return content;
    } catch (e) {
      debugPrint(e.toString());
      return "No page found";
    }
  }

  Future<File> writeFile(String content) async {
    final file = await _localFile;

    return file.writeAsString(content);
  }

  Future<Archive> loadAssetAsArchive() async {
    final data =
        await rootBundle.load('assets/pages.zip').then((ByteData value) {
      Uint8List wzzip =
          value.buffer.asUint8List(value.offsetInBytes, value.lengthInBytes);
      InputStream ifs = InputStream(wzzip);
      final archive = ZipDecoder().decodeBuffer(ifs);

      return archive;
    });

    return data;
  }

  Future<void> extractArchive() async {
    final archive = await loadAssetAsArchive();

    for (final file in archive) {
      final filename = file.name;

      debugPrint(filename);

      if (file.isFile) {
        final data = file.content as String;
        final path = await _localPath;
        File('$path/page2.html')
          ..createSync(recursive: true)
          ..writeAsString(data);
      }
    }
  }
}
