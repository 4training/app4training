import 'package:flutter_test/flutter_test.dart';
import 'package:four_training/data/updates.dart';

void main() {
  test('Test stringToCheckFrequency: graceful error handling', () {
    expect(CheckFrequency.fromString('weekly'), CheckFrequency.weekly);
    expect(CheckFrequency.fromString('weird'), CheckFrequency.weekly);
    expect(CheckFrequency.fromString(null), CheckFrequency.weekly);
  });
}
