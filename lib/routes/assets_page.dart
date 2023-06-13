import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:four_training/widgets/loading_animation.dart';
import 'package:four_training/widgets/main_drawer.dart';
import '../data/globals.dart';
import '../widgets/settings_btn.dart';

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
    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [settingsTile(context)],
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
                    return Text(
                        "Couldn't find the content you are looking for.\nLanguage: ${currentLanguage?.lang}");
                  } else if (snapshot.hasData) {
                    return _page(snapshot.data, context);
                  } else {
                    return loadingAnimation("Empty Data");
                  }
                default:
                  return Text("State: ${snapshot.connectionState}");
              }
            },
          ),
        ));
  }

  Widget _page(String content, BuildContext ctx) {
    return SingleChildScrollView(
        child: Column(
      children: [
        Html(
          data: content,
          onAnchorTap: (url, context, attributes) {
            //debugPrint("link tapped $url $context $attributes $element");
            for (int i = 0; i < currentLanguage!.pages.length; i++) {
              String pageName =
                  currentLanguage!.pages.elementAt(i).elementAt(0);
              pageName = pageName.replaceAll(".html", "");
              pageName = pageName.replaceAll("/",
                  ""); // TODO doe we need this or can we fix it in the html file?
              url = url!.replaceAll("/", "");
              url = url.replaceAll(".html",
                  ""); // TODO doe we need this or can we fix it in the html file?
              debugPrint("pageName $pageName url $url");

              if (pageName == url) {
                currentIndex = i;
                Navigator.of(ctx).pushReplacement(MaterialPageRoute(
                    builder: (context) => const AssetsPage()));
              }
            }
          },
        )
      ],
    ));
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Are you sure?'),
            content: const Text('Do you want to exit the App'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Yes'),
              ),
            ],
          ),
        )) ??
        false;
  }
}
