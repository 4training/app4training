import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// Our primary red color (a little bit darker than the red of FlexScheme.red)
Color lightPrimaryColor = Colors.red[900]!;

/// How long should the snackbar show up?
/// Used when managing languages.
const snackBarQuickSuccessDuration = Duration(seconds: 1);
const snackBarErrorDuration = Duration(seconds: 10);

/// Using the red theme of flex_color_scheme - see
/// https://rydmike.com/flexcolorscheme/themesplayground-latest/
/// and select "red tornado"
ThemeData _defaultLightTheme =
    FlexThemeData.light(scheme: FlexScheme.red, useMaterial3: true);

/// Customize the design of our app bar
AppBarTheme lightAppBarTheme = AppBarTheme(
    backgroundColor: lightPrimaryColor,
    centerTitle: true,
    // increase font size and make it bold
    titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
    // let the burger menu icon be white (instead of black)
    iconTheme: const IconThemeData(color: Colors.white));

AppBarTheme darkAppBarTheme = AppBarTheme(
  backgroundColor: _defaultLightTheme.colorScheme.primary,
  centerTitle: true,
  titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
);

/// Our standard (light) theme
ThemeData lightTheme = _defaultLightTheme.copyWith(
    // change the primary red color a bit
    colorScheme:
        _defaultLightTheme.colorScheme.copyWith(primary: lightPrimaryColor),
    appBarTheme: lightAppBarTheme);

/// Our dark theme
ThemeData darkTheme =
    FlexThemeData.dark(scheme: FlexScheme.red, useMaterial3: true)
        .copyWith(appBarTheme: darkAppBarTheme);

/// Size of smileys (used on "sorry, not yet available" dialogs)
const double smileySize = 50;
