import 'package:flutter/material.dart';
import 'package:yakkkobak_flutter/models/alarm.dart';
import 'package:yakkkobak_flutter/services/notification_service.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  // 초기 데이터 (나중에는 저장소에서 불러와야 함)
  final List<Alarm> _alarms = [];

  @override
  void initState() {
    super.initState();
    // 초기 알람 스케줄링 (이미 되어있다고 가정하거나, 앱 시작 시 체크하는 로직이 필요할 수 있음)
    // 여기서는 데모를 위해 활성화된 알람을 다시 스케줄링하지는 않음 (중복 방지)
  }

  Future<void> _updateAlarm(Alarm alarm) async {
    setState(() {}); // UI 갱신

    if (alarm.isActive) {
      await NotificationService().scheduleAlarm(
        id: alarm.id,
        title: '약 드실 시간입니다!',
        body: '${alarm.label}을(를) 복용해주세요.',
        time: alarm.time,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${alarm.label} 알람이 설정되었습니다.')));
      }
    } else {
      await NotificationService().cancelAlarm(alarm.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${alarm.label} 알람이 해제되었습니다.')));
      }
    }
  }

  Future<void> _editTime(Alarm alarm) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: alarm.time,
      helpText: '${alarm.label} 시간 설정',
      cancelText: '취소',
      confirmText: '확인',
    );

    if (picked != null && picked != alarm.time) {
      setState(() {
        alarm.time = picked;
      });
      // 시간이 변경되면 알람이 켜져있을 경우 재스케줄링
      if (alarm.isActive) {
        await _updateAlarm(alarm);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 약 알람')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _alarms.length,
        itemBuilder: (context, index) {
          final alarm = _alarms[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: () => _editTime(alarm), // 카드 터치 시 시간 수정
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alarm.label,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                alarm.timeString,
                                style: TextStyle(
                                  fontSize: 32,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.edit,
                                size: 20,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      scale: 1.5, // 시니어를 위한 큰 스위치
                      child: Switch(
                        value: alarm.isActive,
                        onChanged: (value) {
                          alarm.isActive = value;
                          _updateAlarm(alarm);
                        },
                        activeTrackColor: Theme.of(context).colorScheme.primary,
                        activeThumbColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () {
          // TODO: 수동 알람 추가 기능
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
