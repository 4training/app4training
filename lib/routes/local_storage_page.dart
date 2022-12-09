
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:four_training/utils/page_storage.dart';

class LocalStoragePage extends StatefulWidget {
  const LocalStoragePage({super.key, required this.title, required this.storage});
  final String title;
  final LocalPageStorage storage;

  @override
  State<LocalStoragePage> createState() => _LocalStoragePageState();
}

class _LocalStoragePageState extends State<LocalStoragePage> {
  String _htmlData = "";
  String _unzippedHtmlData = "";

  String _pageHtml =
      "<html> <h1>Startseite!</h1><p>Das ist die erste Seite</p></html>";

  @override
  void initState() {
    super.initState();

    widget.storage.writeFile(_pageHtml);

    widget.storage.readFile().then((value) {
      setState(() {
        _htmlData = value;
      });
    });

    widget.storage.extractArchive();

    widget.storage.readUnzippedFile().then((value) {
      setState(() {
        _unzippedHtmlData = value;
      });
    });
  }

  Future<File> _saveFile() {
    return widget.storage.writeFile(_pageHtml);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView(
        children: [
          Html(data: _htmlData),
          Divider(),
          Html(data: _unzippedHtmlData)
        ],
      ),
    );
  }
}