import 'package:flutter/material.dart';
import 'package:four_training/data/languages.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/globals.dart';

/// Button on the settings page to check for available updates
class CheckNowButton extends StatefulWidget {
  const CheckNowButton(
      {Key? key, required this.buttonText, required this.callback})
      : super(key: key);

  final String buttonText;
  final Function callback;

  @override
  State<CheckNowButton> createState() => _CheckNowButtonState();
}

class _CheckNowButtonState extends State<CheckNowButton> {
  final List<String> _updateList = [];
  bool _isLoading = false;

  // Get the data which languages should be updated
  Future<void> _getUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (String languageCode in Globals.availableLanguages) {
        bool update = prefs.getBool('update_$languageCode') ?? false;
        if (update) _updateList.add(languageCode);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _getUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(), fixedSize: const Size(150, 36)),
        onPressed: () async {
          // Loading animation while loading
          setState(() {
            _isLoading = true;
          });

          // Each language in the list first gets deleted and then initialized again
/*          for (String languageCode in _updateList) {
            Language language = context.global.languages
                .firstWhere((element) => element.languageCode == languageCode);
            await language.removeResources();
            if(mounted) context.global.languages.remove(language);

            Language newLanguage = Language(languageCode);
            await newLanguage.init();
            if(mounted) context.global.languages.add(newLanguage);
          } TODO */
          await Future.delayed(const Duration(seconds: 2));
          setState(() {
            _isLoading = false;
          });

          widget.callback();
        },
        child: _isLoading // Show Text or loading animation depending on state
            ? SizedBox(
                height: 25,
                width: 25,
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.onPrimary,
                ))
            : Text(widget.buttonText));
  }
}
