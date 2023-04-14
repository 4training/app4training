import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:four_training/widgets/loading_animation.dart';
import 'package:four_training/widgets/main_drawer.dart';
import '../data/globals.dart';

class AssetsPage extends StatefulWidget {
  const AssetsPage({Key? key}) : super(key: key);

  @override
  State<AssetsPage> createState() => _AssetsPageState();
}

class _AssetsPageState extends State<AssetsPage> {
  String state = "";
  late String title;
  late Future<dynamic> _htmlData;

  @override
  void initState() {
    super.initState();
    title = "4training";
    _htmlData = currentLanguage!.displayPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      drawer: mainDrawer(context),
      body: FutureBuilder(
        future: _htmlData,
        initialData: "Loading",
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          debugPrint(snapshot.connectionState.toString());

          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
            case ConnectionState.active:
              return loadingAnimation(
                  "Loading content\nState: ${snapshot.connectionState}");
            case ConnectionState.done:
              if (snapshot.hasError) {
                return Text("Couldn't find the content you are looking for.\nLanguage: ${currentLanguage?.lang}");
              } else if (snapshot.hasData) {
                return _page(snapshot.data);
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
        return _pageListElement(pages[index]);
      },
    );
  }

  Widget _pageListElement(String content) {
    return Column(
      children: [Html(data: content), const Divider(), const Divider()],
    );
  }

  Widget _page(String content) {
    return SingleChildScrollView(child: Column(
      children: [Html(data: content), const Divider(), const Divider()],
    ));
  }


}
