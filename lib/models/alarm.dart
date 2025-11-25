import 'package:flutter/material.dart';

class Alarm {
  final int id;
  String label;
  TimeOfDay time;
  bool isActive;

  Alarm({
    required this.id,
    required this.label,
    required this.time,
    this.isActive = true,
  });

  // TimeOfDay를 문자열로 변환 (예: "08:00")
  String get timeString {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
