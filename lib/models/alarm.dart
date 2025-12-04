import 'package:flutter/material.dart';

class Alarm {
  final int id;
  String label;
  TimeOfDay time;
  bool isActive;
  DateTime startDate; // 알람 시작 날짜
  int durationDays; // 복용 기간 (일)

  Alarm({
    required this.id,
    required this.label,
    required this.time,
    this.isActive = true,
    DateTime? startDate,
    this.durationDays = 1,
  }) : startDate = startDate ?? DateTime.now();

  // TimeOfDay를 문자열로 변환 (예: "08:00")
  String get timeString {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // 특정 날짜에 이 알람이 활성화되어야 하는지 확인
  bool isActiveOnDate(DateTime date) {
    if (!isActive) return false;

    // 날짜만 비교 (시간 제외)
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final endDate = startOnly.add(Duration(days: durationDays));

    return !dateOnly.isBefore(startOnly) && dateOnly.isBefore(endDate);
  }

  // 알람 종료 날짜
  DateTime get endDate => DateTime(startDate.year, startDate.month, startDate.day)
      .add(Duration(days: durationDays));
}
