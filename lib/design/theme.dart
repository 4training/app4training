
import 'package:flutter/material.dart';

ThemeData customLightTheme() { // TODO Theming

  TextTheme customLightThemesTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontFamily: 'Roboto',
        fontSize: 22.0,
        color: Colors.green,
      ),
      titleLarge: base.titleLarge?.copyWith(
          fontSize: 15.0,
          color: Colors.orange
      ),
      headlineMedium: base.displayLarge?.copyWith(
        fontSize: 24.0,
        color: Colors.white,
      ),
      displaySmall: base.displayLarge?.copyWith(
        fontSize: 22.0,
        color: Colors.grey,
      ),
      bodySmall: base.bodySmall?.copyWith(
        color: const Color(0xFFCCC5AF),
      ),
      bodyMedium: base.bodyMedium?.copyWith(color: const Color(0xFF807A6B)),
      bodyLarge: base.bodyLarge?.copyWith(color: Colors.brown),
    );
  }

  final ThemeData lightTheme = ThemeData.light();
  return lightTheme.copyWith(
    textTheme: customLightThemesTextTheme(lightTheme.textTheme),
    primaryColor: const Color(0xffb40303),
    indicatorColor: const Color(0xFF807A6B),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    accentColor: const Color(0xFFFFF8E1),
    primaryIconTheme: lightTheme.primaryIconTheme.copyWith(
      color: Colors.white,
      size: 20,
    ),
    iconTheme: lightTheme.iconTheme.copyWith(
      color: Colors.white,
    ),
    buttonColor: Colors.white,
    backgroundColor: Colors.white,
    tabBarTheme: lightTheme.tabBarTheme.copyWith(
      labelColor: const Color(0xffce107c),
      unselectedLabelColor: Colors.grey,
    ),
    buttonTheme: lightTheme.buttonTheme.copyWith(buttonColor: Colors.red),
    errorColor: Colors.red,
  );
}


ThemeData customDarkTheme() {
  final ThemeData darkTheme = ThemeData.dark();
  return darkTheme.copyWith(
    primaryColor: const Color(0xFF830101),
    scaffoldBackgroundColor: const Color(0xFF171717),
    indicatorColor: const Color(0xFF807A6B),
    accentColor: const Color(0xFFFFF8E1),
    primaryIconTheme: darkTheme.primaryIconTheme.copyWith(
      color: Colors.green,
      size: 20,
    ),

  );
}