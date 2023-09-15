import 'package:flutter/material.dart';
import 'package:app4training/design/colors.dart';
import 'package:app4training/design/textthemes.dart';
import 'appbar_theme.dart';
import 'color_schemes.dart';

ThemeData lightTheme = ThemeData(
    colorScheme: lightColorScheme,
    //typography: materialTypography,
    appBarTheme: lightAppBarTheme,
    //buttonTheme: materialLightButtonThemeData,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    brightness: Brightness.light,
    textTheme: lightTextTheme,
    scaffoldBackgroundColor: lightBackground);

ThemeData darkTheme = ThemeData(
    colorScheme: darkColorScheme,
    //typography: materialTypography,
    appBarTheme: darkAppBarTheme,
    //buttonTheme: materialDarkButtonThemeData,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    brightness: Brightness.dark,
    textTheme: darkTextTheme,
    scaffoldBackgroundColor: darkBackground);
