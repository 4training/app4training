import 'package:flutter/material.dart';
import 'package:four_training/data/languages.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckBoxDownloadLanguage extends StatefulWidget {
  final String languageCode;

  const CheckBoxDownloadLanguage({Key? key, required this.languageCode})
      : super(key: key);

  @override
  State<CheckBoxDownloadLanguage> createState() =>
      _CheckBoxDownloadLanguageState();
}

class _CheckBoxDownloadLanguageState extends State<CheckBoxDownloadLanguage> {
  bool _download = true;

  @override
  void initState() {
    super.initState();
    _getDownload();
  }

  Future<void> _getDownload() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _download =
          (prefs.getBool('download${widget.languageCode}') ?? true);
    });
  }

  Future<void> _setDownload(bool? checkboxValue) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setBool(
          'download${widget.languageCode}', (checkboxValue ?? true));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Checkbox(
        value: _download,
        checkColor: Theme.of(context).colorScheme.primary,
        onChanged: (bool? value) {
          setState(() {
            _download = value!;
            _setDownload(value);
          });
        });
  }
}
