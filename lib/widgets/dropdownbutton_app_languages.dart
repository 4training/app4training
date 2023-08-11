import 'package:flutter/material.dart';
import 'package:four_training/data/globals.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DropDownButtonAppLanguage extends StatefulWidget {
  final Function callback;

  const DropDownButtonAppLanguage({Key? key, required this.callback})
      : super(key: key);

  @override
  State<DropDownButtonAppLanguage> createState() =>
      _DropDownButtonAppLanguageState(callback: callback);
}

class _DropDownButtonAppLanguageState extends State<DropDownButtonAppLanguage> {
  Function callback;
  _DropDownButtonAppLanguageState({required this.callback});

  String _appLanguage = "system";

  @override
  void initState() {
    super.initState();
    _getAppLanguage();
  }

  Future<void> _getAppLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _appLanguage = (prefs.getString('appLanguage') ?? 'system');
    });
  }

  Future<void> _setAppLanguage(String? dropdownValue) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setString("appLanguage", (dropdownValue ?? "system"));
    });
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton(
        value: _appLanguage,
        items: // TODO
            availableAppLanguages.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value.toUpperCase()),
          );
        }).toList(),
        onChanged: (String? value) {

          String selectedLanguageCode = value!;

          // If the selected language is system, set the value to the local language
          selectedLanguageCode = selectedLanguageCode == 'system' ? localLanguageCode : selectedLanguageCode;

          // Set the app language
          for (var element in availableAppLanguages) {
            if (element == selectedLanguageCode) {
              appLanguageCode = element;
              break;
            }
          }

          setState(() {
            // Set the app language for the dropdown field
            _appLanguage = value;
            // Save the app language in preferences
            _setAppLanguage(selectedLanguageCode);
          });

          // That's the callback for the parent widget to update the text on the page
          callback();
        });
  }
}
