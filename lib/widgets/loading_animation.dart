import 'package:flutter/material.dart';

Widget loadingAnimation(String msg) {
  return Scaffold(
      body: Center(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const Spacer(flex: 10),
        const Expanded(child: CircularProgressIndicator()),
        const Spacer(),
        Expanded(child: Text(msg)),
        const Spacer(flex: 10)
      ],
    ),
  ));
}
