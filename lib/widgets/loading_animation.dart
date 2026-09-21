import 'package:flutter/material.dart';

/// Full-screen spinner with a [caption] underneath it.
///
/// The caption is a widget so that it can rebuild on its own (e.g. a
/// Consumer watching a provider) without touching the spinner.
class LoadingAnimation extends StatelessWidget {
  final Widget caption;
  const LoadingAnimation({required this.caption, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const Spacer(flex: 10),
          const Expanded(child: CircularProgressIndicator()),
          const Spacer(),
          Expanded(child: caption),
          const Spacer(flex: 10)
        ],
      ),
    ));
  }
}

/// [LoadingAnimation] with a fixed text as its caption
Widget loadingAnimation(String msg) => LoadingAnimation(caption: Text(msg));
