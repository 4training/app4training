import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:four_training/data/languages.dart';
import 'package:four_training/widgets/loading_animation.dart';
import 'package:four_training/widgets/main_drawer.dart';
import 'package:four_training/widgets/settings_button.dart';

/// The standard view of this app:
/// Show a page (worksheet)
class ViewPage extends ConsumerStatefulWidget {
  final String page; // currently selected page
  final String langCode;
  const ViewPage(this.page, this.langCode, {super.key});
  @override
  ConsumerState<ViewPage> createState() => _ViewPageState();
}

/// Scrollable display of HTML content, filling most of the screen.
/// Uses the flutter_html package.
class MainHtmlView extends StatelessWidget {
  /// HTML code to display
  final String content;
  const MainHtmlView(this.content, {super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Column(
      children: [
        Html(
            data: content,
            onAnchorTap: (url, _, __) {
              debugPrint("Link tapped: $url");
              if (url != null) {
                // TODO make this more robust
//                currentPage = url.split('/')[1];
                Navigator.pushReplacementNamed(context, '/view$url');
              }
            })
      ],
    ));
  }
}

class _ViewPageState extends ConsumerState<ViewPage> {
  static const title = "4training";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    AsyncValue<String> page = ref.watch(pageContentProvider(widget.page));
    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
            appBar: AppBar(
              title: const Text(title),
              actions: const [SettingsButton()],
            ),
            drawer: const MainDrawer(),
            body: page.when(
                loading: () => loadingAnimation("Loading content..."),
                data: (content) => MainHtmlView(content),
                error: (e, st) => Text(
                    "Couldn't find the content you are looking for: ${e.toString()}\nLanguage: ${ref.read(currentLanguageProvider)}"))));
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

  @override
  void dispose() {
    debugPrint('Disposing the whole ViewPage widget');
    super.dispose();
  }
}
