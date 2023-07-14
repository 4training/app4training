import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:four_training/widgets/loading_animation.dart';
import 'package:four_training/widgets/main_drawer.dart';
import 'package:four_training/data/globals.dart';
import 'package:four_training/widgets/settings_button.dart';

/// The standard view of this app:
/// Show a page (worksheet)
class ViewPage extends StatefulWidget {
  const ViewPage({super.key});
  @override
  State<ViewPage> createState() => _ViewPageState();
}

class _ViewPageState extends State<ViewPage> {
  static const title = "4training";
  late Future<dynamic> _htmlData;

  @override
  void initState() {
    super.initState();
    _htmlData = currentLanguage!.getPageContent(currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          appBar: AppBar(
            title: const Text(title),
            actions: [settingsButton(context)],
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
                        "Couldn't find the content you are looking for.\nLanguage: ${currentLanguage?.languageCode}");
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
            debugPrint("link tapped $url $context $attributes");
            if (url != null) {
              int? newIndex = currentLanguage!.getIndexByTitle(url);
              if (newIndex != null) {
                currentIndex = newIndex;
                Navigator.of(ctx).pushReplacement(
                    MaterialPageRoute(builder: (context) => const ViewPage()));
              } else {
                debugPrint("TODO Error couldn't find link destination");
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
                child: const Text('Yes'),
              ),
            ],
          ),
        )) ??
        false;
  }
}
