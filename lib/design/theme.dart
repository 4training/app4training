import 'package:flutter/material.dart';
import 'package:four_training/design/textthemes.dart';
import 'appbar_theme.dart';
import 'colorSchemes.dart';


ThemeData lightTheme = ThemeData(
  colorScheme: lightColorScheme,
  //typography: materialTypography,
  appBarTheme: lightAppBarTheme,
  //buttonTheme: materialLightButtonThemeData,
  visualDensity: VisualDensity.adaptivePlatformDensity,
  brightness: Brightness.light,
  textTheme: lightTextTheme,
);

ThemeData darkTheme = ThemeData(
  colorScheme: darkColorScheme,
  //typography: materialTypography,
  appBarTheme: darkAppBarTheme,
  //buttonTheme: materialDarkButtonThemeData,
  visualDensity: VisualDensity.adaptivePlatformDensity,
  brightness: Brightness.dark,
  textTheme: darkTextTheme,
);









