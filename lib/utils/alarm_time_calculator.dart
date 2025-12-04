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

    // 식사 기준 알람 - specificMeals가 있으면 그것을 사용
    final meals = data.specificMeals ?? ['breakfast', 'lunch', 'dinner'];
    final mealsToUse = data.specificMeals != null
        ? meals // specificMeals가 있으면 그대로 사용
        : meals.take(frequency).toList(); // 없으면 frequency 만큼만 사용

    for (int i = 0; i < mealsToUse.length; i++) {
      final mealTime = defaultMealTimes[mealsToUse[i]]!;
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

  /// 영어 식사명을 한글로 변환
  static String _getMealNameKorean(String mealKey) {
    switch (mealKey) {
      case 'breakfast':
        return '아침';
      case 'lunch':
        return '점심';
      case 'dinner':
        return '저녁';
      default:
        return mealKey;
    }
  }

  /// 알람 라벨 생성
  static String generateLabel(MedicationData data, int index) {
    final name = data.medicationName ?? '약';

    if (data.mealContext == 'at_bedtime') {
      return '$name (취침 전)';
    }

    // specificMeals가 있으면 그것을 사용
    if (data.specificMeals != null && index < data.specificMeals!.length) {
      final mealContext = data.getMealContextKorean();
      final mealName = _getMealNameKorean(data.specificMeals![index]);
      return '$name ($mealName $mealContext)';
    }

    // 기본값: 순서대로 아침, 점심, 저녁
    final defaultMealNames = ['아침', '점심', '저녁'];
    if (index < defaultMealNames.length) {
      final mealContext = data.getMealContextKorean();
      return '$name (${defaultMealNames[index]} $mealContext)';
    }

    return '$name (${index + 1}회차)';
  }
}
