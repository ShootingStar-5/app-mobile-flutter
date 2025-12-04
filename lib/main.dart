import 'dart:async';
import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/main_shell.dart';
import 'utils/theme.dart';
import 'screens/splash_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/voice_screen.dart';
import 'screens/alarm_screen.dart';
import 'screens/alarm_ringing_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  await NotificationService().initialize();
  runApp(const YakKkobakApp());
}

class YakKkobakApp extends StatefulWidget {
  const YakKkobakApp({super.key});

  @override
  State<YakKkobakApp> createState() => _YakKkobakAppState();
}

class _YakKkobakAppState extends State<YakKkobakApp> {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    print('YakKkobakApp: initState');
    _subscription = NotificationService().ringStream.listen((event) async {
      print(
        'YakKkobakApp: Alarm ringing event received: $event (${event.runtimeType})',
      );

      AlarmSettings? alarmSettings;

      if (event is AlarmSettings) {
        alarmSettings = event;
      } else if (event is Iterable && event.isNotEmpty) {
        // If event is a list/set of alarms (AlarmSet might be iterable)
        alarmSettings = event.first;
      } else {
        // AlarmSet might be a wrapper class
        try {
          final alarms = (event as dynamic).alarms;
          if (alarms is Iterable && alarms.isNotEmpty) {
            alarmSettings = alarms.first;
          }
        } catch (e) {
          print('YakKkobakApp: Error extracting alarm from event: $e');
        }
      }

      if (alarmSettings != null) {
        print(
          'YakKkobakApp: Navigating to ringing screen with alarm: ${alarmSettings.id}',
        );
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) =>
                AlarmRingingScreen(alarmSettings: alarmSettings!),
          ),
        );
      } else {
        print('YakKkobakApp: Could not resolve AlarmSettings from event');
      }
    });

    // 앱 시작 시 이미 울리고 있는 알람이 있는지 확인 (앱이 종료되었다가 다시 켜진 경우)
    _checkRingingAlarm();
  }

  Future<void> _checkRingingAlarm() async {
    final ringingId = await NotificationService().getRingingAlarmId();
    if (ringingId != null) {
      print('YakKkobakApp: Found ringing alarm id: $ringingId');
      final alarmSettings = await NotificationService().getAlarm(ringingId);
      if (alarmSettings != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) =>
                AlarmRingingScreen(alarmSettings: alarmSettings),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: '찰칵! 약알림',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const MainShell(),
        '/camera': (context) => const CameraScreen(),
        '/voice': (context) => const VoiceScreen(),
        '/alarms': (context) => const AlarmScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
