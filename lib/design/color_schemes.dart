import 'package:flutter/material.dart';

import 'colors.dart';

ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: lightPrimary,
    onPrimary: lightOnPrimary,
    secondary: lightSecondary,
    onSecondary: lightOnSecondary,
    error: lightError,
    onError: lightOnError,
    background: lightBackground,
    onBackground: lightOnBackground,
    surface: lightSurface,
    onSurface: lightOnSurface);

ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: darkPrimary,
    onPrimary: darkOnPrimary,
    secondary: darkSecondary,
    onSecondary: darkOnSecondary,
    error: darkError,
    onError: darkOnError,
    background: darkBackground,
    onBackground: darkOnBackground,
    surface: darkSurface,
    onSurface: darkOnSurface);
