import 'package:flutter/material.dart';
import 'package:yakkkobak_flutter/models/alarm.dart';
import 'package:yakkkobak_flutter/services/notification_service.dart';
import 'package:yakkkobak_flutter/services/alarm_storage_service.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> with WidgetsBindingObserver {
  final AlarmStorageService _storageService = AlarmStorageService();
  List<Alarm> _alarms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAlarms();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadAlarms();
    }
  }

  Future<void> _loadAlarms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final alarms = await _storageService.loadAlarms();
      if (mounted) {
        setState(() {
          _alarms = alarms;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('알람 불러오기 실패: $e')),
        );
      }
    }
  }

  Future<void> _updateAlarm(Alarm alarm) async {
    setState(() {}); // UI 갱신

    // 저장소에 업데이트
    await _storageService.updateAlarm(alarm);

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

  Future<void> _deleteAlarm(Alarm alarm) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('알람 삭제'),
        content: Text('${alarm.label} 알람을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await NotificationService().cancelAlarm(alarm.id);
      await _storageService.deleteAlarm(alarm.id);
      setState(() {
        _alarms.removeWhere((a) => a.id == alarm.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${alarm.label} 알람이 삭제되었습니다.')),
        );
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
      appBar: AppBar(
        title: const Text('내 약 알람'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlarms,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alarms.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _alarms.length,
                  itemBuilder: (context, index) {
                    final alarm = _alarms[index];
                    return Dismissible(
                      key: Key('alarm_${alarm.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('알람 삭제'),
                            content: Text('${alarm.label} 알람을 삭제하시겠습니까?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('취소'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('삭제', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) async {
                        final messenger = ScaffoldMessenger.of(context);
                        await NotificationService().cancelAlarm(alarm.id);
                        await _storageService.deleteAlarm(alarm.id);
                        setState(() {
                          _alarms.removeAt(index);
                        });
                        messenger.showSnackBar(
                          SnackBar(content: Text('${alarm.label} 알람이 삭제되었습니다.')),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          onTap: () => _editTime(alarm),
                          onLongPress: () => _deleteAlarm(alarm),
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
                                  scale: 1.5,
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
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () {
          Navigator.pushNamed(context, '/voice').then((_) => _loadAlarms());
        },
        child: const Icon(Icons.mic),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.alarm_off,
            size: 100,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 24),
          Text(
            '등록된 알람이 없습니다',
            style: TextStyle(
              fontSize: 24,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '마이크 버튼을 눌러\n음성으로 약 알람을 등록해보세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
