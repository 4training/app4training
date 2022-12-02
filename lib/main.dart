
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:four_training/page_storage.dart';

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
      home: MyHomePage(title: '4training', storage: LocalPageStorage()),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.storage});
  final String title;
  final LocalPageStorage storage;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  String _htmlData = "";

  String _pageHtml = "<html> <h1>Startseite!</h1><p>Das ist die erste Seite</p></html>";

  @override
  void initState() {

    super.initState();

    widget.storage.writeFile(_pageHtml);

    widget.storage.readFile().then((value) {
      setState(() {
        _htmlData = value;
      });
    });
  }

  Future<File> _saveFile () {

    return widget.storage.writeFile(_pageHtml);

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(

        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Html(
          data: _htmlData,
        ),

      ),

    );
  }
}
