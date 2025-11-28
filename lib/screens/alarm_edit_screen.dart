import 'package:flutter/material.dart';
import '../models/medication_data.dart';
import '../models/alarm.dart';
import '../utils/alarm_time_calculator.dart';
import '../services/alarm_storage_service.dart';
import '../services/notification_service.dart';

class AlarmEditScreen extends StatefulWidget {
  final MedicationData medicationData;
  final String? sttText;

  const AlarmEditScreen({
    super.key,
    required this.medicationData,
    this.sttText,
  });

  @override
  State<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends State<AlarmEditScreen> {
  final AlarmStorageService _storageService = AlarmStorageService();
  late List<TimeOfDay> _alarmTimes;
  late List<String> _alarmLabels;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeAlarms();
  }

  void _initializeAlarms() {
    _alarmTimes = AlarmTimeCalculator.calculateAlarmTimes(widget.medicationData);
    _alarmLabels = List.generate(
      _alarmTimes.length,
      (index) => AlarmTimeCalculator.generateLabel(widget.medicationData, index),
    );
  }

  Future<void> _editTime(int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _alarmTimes[index],
      helpText: '${_alarmLabels[index]} 시간 설정',
      cancelText: '취소',
      confirmText: '확인',
    );

    if (picked != null && picked != _alarmTimes[index]) {
      setState(() {
        _alarmTimes[index] = picked;
      });
    }
  }

  Future<void> _saveAlarms() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final existingAlarms = await _storageService.loadAlarms();
      int nextId = existingAlarms.isEmpty
          ? 1
          : existingAlarms.map((a) => a.id).reduce((a, b) => a > b ? a : b) + 1;

      for (int i = 0; i < _alarmTimes.length; i++) {
        final alarm = Alarm(
          id: nextId + i,
          label: _alarmLabels[i],
          time: _alarmTimes[i],
          isActive: true,
        );

        await _storageService.addAlarm(alarm);

        // 알람 스케줄링
        await NotificationService().scheduleAlarm(
          id: alarm.id,
          title: '약 드실 시간입니다!',
          body: '${alarm.label}을(를) 복용해주세요.',
          time: alarm.time,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_alarmTimes.length}개의 알람이 등록되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
        // 알람 화면으로 이동 (이전 화면들 모두 제거하고 알람 화면으로)
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/alarms',
          (route) => route.settings.name == '/home',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('알람 저장 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알람 확인'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // STT 인식 결과
            if (widget.sttText != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mic, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '"${widget.sttText}"',
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 약 정보 요약
            _buildInfoSection(),
            const SizedBox(height: 32),

            // 알람 시간 목록
            const Text(
              '알람 시간',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '터치하여 시간을 변경할 수 있습니다',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            ..._buildAlarmList(),

            const SizedBox(height: 32),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveAlarms,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        '알람 등록하기',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    final data = widget.medicationData;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.medicationName != null)
            _buildInfoRow(Icons.medication, '약 이름', data.medicationName!),
          if (data.dailyFrequency != null)
            _buildInfoRow(Icons.repeat, '복용 횟수', '하루 ${data.dailyFrequency}회'),
          if (data.totalDurationDays != null)
            _buildInfoRow(Icons.calendar_today, '복용 기간', '${data.totalDurationDays}일'),
          if (data.mealContext != null) ...[
            _buildInfoRow(
              Icons.restaurant,
              '복용 시점',
              data.specificOffsetMinutes != null
                  ? '${data.getMealContextKorean()} ${data.specificOffsetMinutes}분'
                  : data.getMealContextKorean(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAlarmList() {
    return List.generate(_alarmTimes.length, (index) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _editTime(index),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.alarm,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _alarmLabels[index],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(_alarmTimes[index]),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.edit, color: Colors.grey),
              ],
            ),
          ),
        ),
      );
    });
  }
}
