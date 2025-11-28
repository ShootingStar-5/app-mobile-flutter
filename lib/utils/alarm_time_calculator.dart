import 'package:flutter/material.dart';
import '../models/medication_data.dart';

class AlarmTimeCalculator {
  // 기본 식사 시간 (사용자 설정 가능하게 만들 수 있음)
  static const Map<String, TimeOfDay> defaultMealTimes = {
    'breakfast': TimeOfDay(hour: 8, minute: 0),
    'lunch': TimeOfDay(hour: 12, minute: 0),
    'dinner': TimeOfDay(hour: 18, minute: 0),
  };

  /// MedicationData에서 알람 시간들 계산
  static List<TimeOfDay> calculateAlarmTimes(MedicationData data) {
    final alarms = <TimeOfDay>[];
    final frequency = data.dailyFrequency ?? 1;
    final offsetMinutes = data.specificOffsetMinutes ?? 30;
    final isPostMeal = data.mealContext == 'post_meal';
    final isPreMeal = data.mealContext == 'pre_meal';
    final isBedtime = data.mealContext == 'at_bedtime';

    if (isBedtime) {
      // 취침 전: 밤 10시 기준
      alarms.add(const TimeOfDay(hour: 22, minute: 0));
      return alarms;
    }

    // 식사 기준 알람
    final meals = ['breakfast', 'lunch', 'dinner'];

    for (int i = 0; i < frequency && i < meals.length; i++) {
      final mealTime = defaultMealTimes[meals[i]]!;
      TimeOfDay alarmTime;

      if (isPostMeal) {
        alarmTime = _addMinutes(mealTime, offsetMinutes);
      } else if (isPreMeal) {
        alarmTime = _subtractMinutes(mealTime, offsetMinutes);
      } else {
        // 식사 시간 기준 없으면 일정 간격으로
        alarmTime = TimeOfDay(hour: 8 + (i * 6), minute: 0);
      }

      alarms.add(alarmTime);
    }

    return alarms;
  }

  /// 시간에 분 더하기
  static TimeOfDay _addMinutes(TimeOfDay time, int minutes) {
    final totalMinutes = time.hour * 60 + time.minute + minutes;
    return TimeOfDay(
      hour: (totalMinutes ~/ 60) % 24,
      minute: totalMinutes % 60,
    );
  }

  /// 시간에서 분 빼기
  static TimeOfDay _subtractMinutes(TimeOfDay time, int minutes) {
    var totalMinutes = time.hour * 60 + time.minute - minutes;
    if (totalMinutes < 0) totalMinutes += 24 * 60;
    return TimeOfDay(
      hour: (totalMinutes ~/ 60) % 24,
      minute: totalMinutes % 60,
    );
  }

  /// 알람 라벨 생성
  static String generateLabel(MedicationData data, int index) {
    final name = data.medicationName ?? '약';
    final mealNames = ['아침', '점심', '저녁'];

    if (data.mealContext == 'at_bedtime') {
      return '$name (취침 전)';
    }

    if (index < mealNames.length) {
      final mealContext = data.getMealContextKorean();
      return '$name (${mealNames[index]} $mealContext)';
    }

    return '$name (${index + 1}회차)';
  }
}
