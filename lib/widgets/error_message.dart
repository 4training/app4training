import 'package:flutter/material.dart';

class ErrorMessage extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  const ErrorMessage(this.title, this.message,
      {this.icon = Icons.error, this.iconColor = Colors.red, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.grey,
        alignment: Alignment.center,
        child: Column(children: [
          Expanded(child: Container()),
          Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Icon(
                  icon,
                  color: iconColor,
                  size: 48,
                ),
                const SizedBox(height: 10),
                Text(title, style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 20),
                Text(message)
              ])),
          Expanded(child: Container())
        ]));
  }
}
