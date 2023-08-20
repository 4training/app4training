import 'package:flutter/material.dart';
import 'package:four_training/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DropDownButtonUpdateRoutine extends StatefulWidget {
  const DropDownButtonUpdateRoutine({Key? key}) : super(key: key);

  @override
  State<DropDownButtonUpdateRoutine> createState() =>
      _DropDownButtonUpdateRoutineState();
}

class _DropDownButtonUpdateRoutineState extends State<DropDownButtonUpdateRoutine> {
  late String _updateRoutine;
  final List<String> _routines = ["daily", "weekly", "monthly"];

  @override
  void initState() {
    super.initState();
    _getUpdateRoutine();
  }

  Future<void> _getUpdateRoutine() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _updateRoutine = (prefs.getString("update_routine") ?? 'weekly');
    });
  }

  Future<void> _setUpdateRoutine(String? dropdownValue) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setString("update_routine", (dropdownValue ?? 'daily'));
    });
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton(
        value: _updateRoutine,
        items: _routines.map<DropdownMenuItem<String>>((String value) {
          String text;

          switch(value) {
            case "never":
              text = context.l10n.never;
              break;
            case "daily":
              text = context.l10n.daily;
              break;
            case "weekly":
              text = context.l10n.weekly;
              break;
            case "monthly":
              text = context.l10n.monthly;
              break;
            default:
              text = context.l10n.never;
              break;
          }

          return DropdownMenuItem<String>(
            value: value,
            child: Text(text),
          );
        }).toList(),
        onChanged: (String? value) {

          // TODO change routine
          setState(() {
            _updateRoutine = value!;
            _setUpdateRoutine(value);
          });
        });
  }


}