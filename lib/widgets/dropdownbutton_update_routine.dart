import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DropDownButtonUpdateRoutine extends StatefulWidget {
  const DropDownButtonUpdateRoutine({Key? key}) : super(key: key);

  @override
  State<DropDownButtonUpdateRoutine> createState() =>
      _DropDownButtonUpdateRoutineState();
}

class _DropDownButtonUpdateRoutineState extends State<DropDownButtonUpdateRoutine> {
  String _updateRoutine = 'daily';
  final List<String> _routines = ["daily", "weekly", "monthly"]; // TODO translateable values

  @override
  void initState() {
    super.initState();
    _getUpdateRoutine();
  }

  Future<void> _getUpdateRoutine() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _updateRoutine = (prefs.getString("update_routine") ?? 'daily');
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
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
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