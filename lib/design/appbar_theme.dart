import 'package:flutter/material.dart';

import 'colors.dart';

AppBarTheme lightAppBarTheme = AppBarTheme(
  //brightness:
  backgroundColor: lightPrimary,
  shadowColor: lightPrimaryVariant,
  centerTitle: true,
  titleSpacing: 1,
  //iconTheme: materialLightIconThemeData,
  actionsIconTheme: lightActionsIconThemeData,
  titleTextStyle: appBarTitleTextStyle,
  toolbarTextStyle: appBarToolbarTextStyle,
);

AppBarTheme darkAppBarTheme = AppBarTheme(
  backgroundColor: darkPrimary,
  shadowColor: darkPrimaryVariant,
  centerTitle: true,
  titleSpacing: 1,
  //iconTheme: materialDarkIconThemeData,
  actionsIconTheme: darkActionsIconThemeData,
  titleTextStyle: appBarTitleTextStyle,
  toolbarTextStyle: appBarToolbarTextStyle,
);

IconThemeData lightActionsIconThemeData = IconThemeData(
  color: lightSecondary,
);

IconThemeData darkActionsIconThemeData = IconThemeData(
  color: darkSecondary,
);

TextStyle appBarTitleTextStyle =
    const TextStyle(fontWeight: FontWeight.bold, fontSize: 25);

TextStyle appBarToolbarTextStyle = const TextStyle(fontWeight: FontWeight.w600);
