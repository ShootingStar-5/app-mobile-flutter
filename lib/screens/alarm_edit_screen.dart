import 'package:flutter/material.dart';
import '../models/medication_data.dart';
import '../models/alarm.dart';
import '../utils/alarm_time_calculator.dart';
import '../utils/theme.dart';
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

  Future<void> _confirmDeleteAlarm(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '지우시겠습니까?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('${_alarmLabels[index]} 알람을 삭제합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              '아니오',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '네',
              style: TextStyle(color: AppColors.error, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _alarmTimes.removeAt(index);
        _alarmLabels.removeAt(index);
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
          startDate: DateTime.now(),
          durationDays: widget.medicationData.totalDurationDays ?? 7,
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
            if (widget.sttText != null) _buildSttResult(),

            // 약 정보 요약 (칩 스타일)
            _buildInfoChips(),
            const SizedBox(height: 28),

            // 알람 시간 목록
            Row(
              children: [
                const Icon(Icons.alarm, color: AppColors.secondary, size: 24),
                const SizedBox(width: 8),
                const Text(
                  '알람 시간',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '터치하여 시간을 변경할 수 있습니다',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),

            _buildAlarmChips(),

            const SizedBox(height: 24),

            // 저장 버튼
            _buildSaveButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSttResult() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondaryLight.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.mic, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '인식된 내용',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '"${widget.sttText}"',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChips() {
    final data = widget.medicationData;
    final chips = <Widget>[];

    if (data.medicationName != null) {
      chips.add(_buildChip(Icons.medication, data.medicationName!));
    }
    if (data.dailyFrequency != null) {
      chips.add(_buildChip(Icons.repeat, '하루 ${data.dailyFrequency}회'));
    }
    if (data.totalDurationDays != null) {
      chips.add(_buildChip(Icons.calendar_today, '${data.totalDurationDays}일'));
    }
    if (data.mealContext != null) {
      final mealText = data.specificOffsetMinutes != null
          ? '${data.getMealContextKorean()} ${data.specificOffsetMinutes}분'
          : data.getMealContextKorean();
      chips.add(_buildChip(Icons.restaurant, mealText));
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: chips,
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.secondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmChips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(_alarmTimes.length, (index) {
          return _buildAlarmChipRow(index);
        }),
      ),
    );
  }

  Widget _buildAlarmChipRow(int index) {
    return Container(
      margin: EdgeInsets.only(bottom: index < _alarmTimes.length - 1 ? 12 : 0),
      child: Row(
        children: [
          // 라벨 칩
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.alarm, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  _alarmLabels[index],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 시간 칩 (탭하면 수정)
          Expanded(
            child: GestureDetector(
              onTap: () => _editTime(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatTime(_alarmTimes[index]),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: AppColors.secondary,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 삭제 버튼
          GestureDetector(
            onTap: () => _confirmDeleteAlarm(index),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.close,
                color: AppColors.error,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveAlarms,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.secondary,
          disabledBackgroundColor: AppColors.textLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.secondary,
                  strokeWidth: 3,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 24),
                  SizedBox(width: 10),
                  Text(
                    '알람 등록하기',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
