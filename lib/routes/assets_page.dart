import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:four_training/widgets/loading_animation.dart';
import 'package:four_training/widgets/main_drawer.dart';

import '../data/globals.dart';
import '../data/languages.dart';

class AssetsPage extends StatefulWidget {
  const AssetsPage({Key? key}) : super(key: key);

  @override
  State<AssetsPage> createState() => _AssetsPageState();
}

class _AssetsPageState extends State<AssetsPage> {
  String state = "";
  late String title;

  @override
  void initState() {
    super.initState();
    title = "4training";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
              return loadingAnimation(
                  "Loading content\n State: ${snapshot.connectionState}");
            case ConnectionState.done:
              if (snapshot.hasError) {
                debugPrint(snapshot.error.toString());
                return Text("Couldn't find the content you are looking for.\nLanguage: ${currentLanguage?.lang}");
              } else if (snapshot.hasData) {
                return _pagesList(snapshot.data);
              } else {
                return loadingAnimation("Empty Data");
              }
            default:
              return Text("State: ${snapshot.connectionState}");
          }
        },
      ),
    );
  }

  Widget _pagesList(List<String> pages) {
    return ListView.builder(
      itemCount: pages.length,
      itemBuilder: (context, index) {
        return _page(pages[index]);
      },
    );
  }

  Widget _page(String content) {
    return Column(
      children: [Html(data: content), const Divider(), const Divider()],
    );
  }

  Future<dynamic> _displayAssets(Language? language) async {
    state = "displaying assets";
    debugPrint(state);
    List<String> htmlData = [];

    if (language == null) {
      return Future.error("Language is null");
    }

    try {
      debugPrint(language.path);
      var dir = Directory(language.path);

      await for (var file in dir.list(recursive: false, followLinks: false)) {
        if (file.statSync().type == FileSystemEntityType.file) {
          htmlData.add(await File(file.path).readAsString());
        }
      }

      state = "Finished creating html data";
      debugPrint(state);
      return htmlData;
    } catch (e) {
      String msg = e.toString();

      state = "Error creating html data. ";
      debugPrint(state + msg);
      
      return Future.error(msg);
    }

  }
}
