import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DropDownButtonTheme extends StatefulWidget {
  const DropDownButtonTheme({Key? key}) : super(key: key);

  @override
  State<DropDownButtonTheme> createState() => _DropDownButtonThemeState();
}

class _DropDownButtonThemeState extends State<DropDownButtonTheme> {
  String _appTheme = 'system';
  final List<String> themesList = ["system", "light", "dark"]; // TODO translateable values

  @override
  void initState() {
    super.initState();
    _getAppTheme();
  }

  Future<void> _getAppTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _appTheme = (prefs.getString('appTheme') ?? 'light');
    });
  }

  Future<void> _setAppTheme(String? dropdownValue) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setString("appTheme", (dropdownValue ?? 'system'));
    });
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton(
        value: _appTheme,
        items: themesList.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (String? value) {
           // TODO change theme (write function)

          setState(() {
            _appTheme = value!;
            _setAppTheme(value);
          });
        });
  }
}
