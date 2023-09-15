import 'package:flutter/material.dart';
import 'package:app4training/l10n/l10n.dart';

AlertDialog buildPopupDialogCantDelete(BuildContext context) {
  return AlertDialog(
    title: Text(context.l10n.warning),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(context.l10n.cannotDelete),
      ],
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: Text(context.l10n.close),
      ),
    ],
  );
}
