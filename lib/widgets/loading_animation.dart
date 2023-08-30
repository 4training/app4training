import 'package:flutter/material.dart';

Widget loadingAnimation(String msg) {
  return Scaffold(
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          flex: 10,
          child: Container(),
        ),
        const Expanded(child: CircularProgressIndicator()),
        Expanded(child: Container()),
        Expanded(child: Text(msg)),
        Expanded(
          flex: 10,
          child: Container(),
        ),
      ],
    ),
  );
}
