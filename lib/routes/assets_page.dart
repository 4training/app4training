import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:four_training/widgets/mainDrawer.dart';

import '../data/globals.dart';

class AssetsPage extends StatefulWidget {
  const AssetsPage({Key? key, required this.title})
      : super(key: key);


  final String title;

  @override
  State<AssetsPage> createState() => _AssetsPageState();
}

class _AssetsPageState extends State<AssetsPage> {
  String state = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      drawer: mainDrawer(context),
      //body: SingleChildScrollView(child: Html(data: widget.htmlContent)),
      body: FutureBuilder(
        future: _displayAssets(currentLanguage),
        initialData: "Loading",
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          debugPrint(snapshot.connectionState.toString());

          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
            case ConnectionState.active:
              return Text("State: ${snapshot.connectionState}");
            case ConnectionState.done:
              if (snapshot.hasError) {
                return Text(snapshot.error.toString());
              } else if (snapshot.hasData) {
                return SingleChildScrollView(child: Html(data: snapshot.data),);
              } else {
                return Text("Empty Data");
              }
            default:
              return Text("State: ${snapshot.connectionState}");
          }
        },
      ),
    );
  }

  Future<String> _displayAssets(int lang) async {
    state = "displaying assets";
    debugPrint(state);
    String htmlData = "";

    try {
      String path = languagePaths[lang]!;

      debugPrint(path);
      var dir = Directory(path);

      await for (var file in dir.list(recursive: false, followLinks: false)) {
        if (file.statSync().type == FileSystemEntityType.file) {
          htmlData += await File(file.path).readAsString();
        }
      }

      state = "Finished creating html data";
      debugPrint(state);
    } catch (e) {
      String msg = e.toString();
      htmlData = "<p>$msg</p>";

      state = "Error creating html data";
      debugPrint(state);
    }
    return htmlData;
  }
}
