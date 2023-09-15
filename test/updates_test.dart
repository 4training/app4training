import 'package:flutter_test/flutter_test.dart';
import 'package:app4training/data/updates.dart';

void main() {
  test('Test stringToCheckFrequency: graceful error handling', () {
    expect(CheckFrequency.fromString('weekly'), CheckFrequency.weekly);
    expect(CheckFrequency.fromString('weird'), CheckFrequency.weekly);
    expect(CheckFrequency.fromString(null), CheckFrequency.weekly);
  });
}
