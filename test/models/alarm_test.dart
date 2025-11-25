import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakkkobak_flutter/models/alarm.dart';

void main() {
  group('Alarm Model Tests', () {
    test('should create alarm with correct values', () {
      final alarm = Alarm(
        id: 1,
        label: 'Test Alarm',
        time: const TimeOfDay(hour: 9, minute: 30),
      );

      expect(alarm.id, 1);
      expect(alarm.label, 'Test Alarm');
      expect(alarm.time.hour, 9);
      expect(alarm.time.minute, 30);
      expect(alarm.isActive, true); // Default value
    });

    test('timeString should return formatted string', () {
      final alarm1 = Alarm(
        id: 1,
        label: 'Morning',
        time: const TimeOfDay(hour: 8, minute: 5),
      );
      expect(alarm1.timeString, '08:05');

      final alarm2 = Alarm(
        id: 2,
        label: 'Evening',
        time: const TimeOfDay(hour: 20, minute: 0),
      );
      expect(alarm2.timeString, '20:00');
    });
  });
}
