import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:yakkkobak_flutter/services/notification_service.dart';

class AlarmRingingScreen extends StatelessWidget {
  final AlarmSettings alarmSettings;

  const AlarmRingingScreen({super.key, required this.alarmSettings});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // 알람 아이콘
            Icon(
              Icons.alarm,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 32),
            Text(
              alarmSettings.notificationSettings.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              alarmSettings.notificationSettings.body,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: () {
                    NotificationService().stopAlarm(alarmSettings.id);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  child: const Text(
                    '약 복용 완료',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // 10분 뒤 다시 알림 (Snooze)
                final now = DateTime.now();
                NotificationService().scheduleAlarm(
                  id: alarmSettings.id,
                  title: alarmSettings.notificationSettings.title,
                  body: alarmSettings.notificationSettings.body,
                  time: TimeOfDay(hour: now.hour, minute: now.minute + 10),
                );
                NotificationService().stopAlarm(alarmSettings.id);
                Navigator.pop(context);
              },
              child: const Text(
                '10분 뒤 다시 알림',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
