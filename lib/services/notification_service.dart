import 'dart:async';
import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  // 알람 링 스트림 (UI에서 구독)
  dynamic get ringStream => Alarm.ringing;

  Future<void> initialize() async {
    await Alarm.init();
    await _requestPermissions();

    // 스트림 리스너 등록하여 알람 울림 상태 저장
    Alarm.ringing.listen((event) async {
      await _saveRingingState(event);
    });
  }

  Future<void> _saveRingingState(dynamic event) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int? id;
      if (event is AlarmSettings) {
        id = event.id;
      } else {
        id = (event as dynamic).id;
      }

      if (id != null) {
        await prefs.setInt('ringing_alarm_id', id);
      }
    } catch (e) {
      print('NotificationService: Error saving ringing state: $e');
    }
  }

  Future<void> clearRingingState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ringing_alarm_id');
  }

  Future<int?> getRingingAlarmId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('ringing_alarm_id');
  }

  Future<void> _requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    // Android 12+ 정확한 알람 스케줄링 권한
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
    // 다른 앱 위에 그리기 권한 (전체 화면 알람을 위해 필요할 수 있음)
    if (await Permission.systemAlertWindow.isDenied) {
      await Permission.systemAlertWindow.request();
    }
    // 배터리 최적화 무시 요청 (알람이 제때 울리도록)
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }

  Future<void> scheduleAlarm({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: scheduledDate,
      assetAudioPath: 'assets/schumann.mp3',
      loopAudio: true,
      vibrate: true,
      androidFullScreenIntent: true,
      volumeSettings: VolumeSettings.fixed(volume: 0.8, volumeEnforced: true),
      notificationSettings: NotificationSettings(
        title: title,
        body: body,
        stopButton: '약 복용 완료',
        icon: 'ic_launcher',
      ),
    );

    await Alarm.set(alarmSettings: alarmSettings);
  }

  Future<void> stopAlarm(int id) async {
    await Alarm.stop(id);
    await clearRingingState();
  }

  Future<void> cancelAlarm(int id) async {
    await Alarm.stop(id);
  }

  Future<AlarmSettings?> getAlarm(int id) async {
    return Alarm.getAlarm(id);
  }
}
