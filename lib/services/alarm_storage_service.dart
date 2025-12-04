import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm.dart';

class AlarmStorageService {
  static const String _alarmsKey = 'saved_alarms';
  static final AlarmStorageService _instance = AlarmStorageService._internal();

  factory AlarmStorageService() => _instance;
  AlarmStorageService._internal();

  /// 모든 알람 불러오기
  Future<List<Alarm>> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final String? alarmsJson = prefs.getString(_alarmsKey);

    if (alarmsJson == null) return [];

    final List<dynamic> alarmsList = jsonDecode(alarmsJson);
    return alarmsList.map((json) => _alarmFromJson(json)).toList();
  }

  /// 알람 저장하기
  Future<void> saveAlarms(List<Alarm> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final String alarmsJson = jsonEncode(alarms.map((a) => _alarmToJson(a)).toList());
    await prefs.setString(_alarmsKey, alarmsJson);
  }

  /// 알람 추가
  Future<void> addAlarm(Alarm alarm) async {
    final alarms = await loadAlarms();
    alarms.add(alarm);
    await saveAlarms(alarms);
  }

  /// 알람 업데이트
  Future<void> updateAlarm(Alarm alarm) async {
    final alarms = await loadAlarms();
    final index = alarms.indexWhere((a) => a.id == alarm.id);
    if (index != -1) {
      alarms[index] = alarm;
      await saveAlarms(alarms);
    }
  }

  /// 알람 삭제
  Future<void> deleteAlarm(int id) async {
    final alarms = await loadAlarms();
    alarms.removeWhere((a) => a.id == id);
    await saveAlarms(alarms);
  }

  /// 새 알람 ID 생성
  Future<int> generateNewId() async {
    final alarms = await loadAlarms();
    if (alarms.isEmpty) return 1;
    return alarms.map((a) => a.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  /// JSON → Alarm
  Alarm _alarmFromJson(Map<String, dynamic> json) {
    return Alarm(
      id: json['id'],
      label: json['label'],
      time: TimeOfDay(hour: json['hour'], minute: json['minute']),
      isActive: json['isActive'] ?? true,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      durationDays: json['durationDays'] ?? 1,
    );
  }

  /// Alarm → JSON
  Map<String, dynamic> _alarmToJson(Alarm alarm) {
    return {
      'id': alarm.id,
      'label': alarm.label,
      'hour': alarm.time.hour,
      'minute': alarm.time.minute,
      'isActive': alarm.isActive,
      'startDate': alarm.startDate.toIso8601String(),
      'durationDays': alarm.durationDays,
    };
  }
}
