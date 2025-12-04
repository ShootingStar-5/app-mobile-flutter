import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';
import '../models/alarm.dart';
import '../models/medication_data.dart';
import '../services/alarm_storage_service.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToFaq;

  const HomeScreen({super.key, this.onNavigateToFaq});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final AlarmStorageService _storageService = AlarmStorageService();
  List<Alarm> _upcomingAlarms = [];
  bool _isLoading = true;

  /// Public method to refresh alarms (called from MainShell on tab change)
  void refreshAlarms() {
    _loadAlarms();
  }

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
    final alarms = await _storageService.loadAlarms();
    final now = DateTime.now();
    final nowTime = TimeOfDay.now();

    // Filter alarms that are active on today's date
    final todayAlarms = alarms.where((alarm) {
      return alarm.isActiveOnDate(now);
    }).toList();

    // Sort by time, with upcoming alarms first
    final nowMinutes = nowTime.hour * 60 + nowTime.minute;
    todayAlarms.sort((a, b) {
      final aMinutes = a.time.hour * 60 + a.time.minute;
      final bMinutes = b.time.hour * 60 + b.time.minute;

      // Check if alarm is upcoming (hasn't passed yet today)
      final aUpcoming = aMinutes >= nowMinutes;
      final bUpcoming = bMinutes >= nowMinutes;

      // Upcoming alarms come first
      if (aUpcoming && !bUpcoming) return -1;
      if (!aUpcoming && bUpcoming) return 1;

      // Within same category, sort by time
      return aMinutes.compareTo(bMinutes);
    });

    if (mounted) {
      setState(() {
        _upcomingAlarms = todayAlarms.take(3).toList(); // Show max 3
        _isLoading = false;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '좋은 아침이에요!';
    if (hour < 18) return '좋은 오후예요!';
    return '좋은 저녁이에요!';
  }

  /// 카메라 화면으로 이동하고 결과 처리
  Future<void> _navigateToCamera() async {
    final result = await Navigator.pushNamed(context, '/camera');
    if (result != null && result is MedicationData) {
      await _createAlarmsFromMedication(result);
    }
  }

  /// 음성 화면으로 이동하고 결과 처리
  Future<void> _navigateToVoice() async {
    final result = await Navigator.pushNamed(context, '/voice');
    if (result != null && result is MedicationData) {
      await _createAlarmsFromMedication(result);
    }
  }

  /// MedicationData를 기반으로 알람 생성
  Future<void> _createAlarmsFromMedication(MedicationData data) async {
    final prefs = await SharedPreferences.getInstance();

    // 설정에서 식사 시간 가져오기
    final breakfastTime = TimeOfDay(
      hour: prefs.getInt('breakfast_hour') ?? 8,
      minute: prefs.getInt('breakfast_minute') ?? 0,
    );
    final lunchTime = TimeOfDay(
      hour: prefs.getInt('lunch_hour') ?? 12,
      minute: prefs.getInt('lunch_minute') ?? 30,
    );
    final dinnerTime = TimeOfDay(
      hour: prefs.getInt('dinner_hour') ?? 18,
      minute: prefs.getInt('dinner_minute') ?? 30,
    );

    // 식사 기준 오프셋 계산 (분)
    int offsetMinutes = data.specificOffsetMinutes ?? 30;
    if (data.mealContext == 'pre_meal') {
      offsetMinutes = -offsetMinutes.abs();
    } else if (data.mealContext == 'post_meal') {
      offsetMinutes = offsetMinutes.abs();
    } else {
      offsetMinutes = 0; // at_bedtime 또는 기타
    }

    // 복용 횟수에 따라 알람 시간 결정
    List<TimeOfDay> mealTimes = [];
    final frequency = data.dailyFrequency ?? 1;

    if (frequency >= 1) mealTimes.add(breakfastTime);
    if (frequency >= 2) mealTimes.add(lunchTime);
    if (frequency >= 3) mealTimes.add(dinnerTime);

    // 기존 알람 로드
    final existingAlarms = await _storageService.loadAlarms();
    int nextId = existingAlarms.isEmpty
        ? 1
        : existingAlarms.map((a) => a.id).reduce((a, b) => a > b ? a : b) + 1;

    final mealNames = ['아침', '점심', '저녁'];
    final mealContextKorean = data.getMealContextKorean();
    final medicationName = data.medicationName ?? '약';

    List<Alarm> newAlarms = [];

    for (int i = 0; i < mealTimes.length; i++) {
      final mealTime = mealTimes[i];

      // 오프셋 적용
      int totalMinutes = mealTime.hour * 60 + mealTime.minute + offsetMinutes;
      if (totalMinutes < 0) totalMinutes += 24 * 60;
      if (totalMinutes >= 24 * 60) totalMinutes -= 24 * 60;

      final alarmTime = TimeOfDay(
        hour: totalMinutes ~/ 60,
        minute: totalMinutes % 60,
      );

      final alarm = Alarm(
        id: nextId + i,
        label: '$medicationName (${mealNames[i]} $mealContextKorean)',
        time: alarmTime,
        isActive: true,
        startDate: DateTime.now(),
        durationDays: data.totalDurationDays ?? 7,
      );

      newAlarms.add(alarm);

      // 알림 스케줄링
      await NotificationService().scheduleAlarm(
        id: alarm.id,
        title: '약 복용 시간',
        body: alarm.label,
        time: alarmTime,
      );
    }

    // 알람 저장
    final allAlarms = [...existingAlarms, ...newAlarms];
    await _storageService.saveAlarms(allAlarms);

    // UI 업데이트
    await _loadAlarms();

    // 완료 메시지
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newAlarms.length}개의 알람이 등록되었습니다!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$period $displayHour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('M월 d일 EEEE', 'ko_KR').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('약꼬박'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAlarms,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Section
              _buildGreetingSection(today),
              const SizedBox(height: 28),

              // Upcoming Medications Section
              _buildUpcomingSection(),
              const SizedBox(height: 28),

              // Registration Buttons
              _buildRegistrationButtons(),
              const SizedBox(height: 28),

              // FAQ Preview Section
              _buildFaqPreview(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingSection(String today) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            today,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.secondary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getGreeting(),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '오늘도 건강한 하루 되세요',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.secondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '예정된 약',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/alarms'),
              child: const Text(
                '전체 보기',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_upcomingAlarms.isEmpty)
          _buildEmptyState()
        else
          ..._upcomingAlarms.map(_buildAlarmCard),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.5),
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.medication_outlined,
            size: 48,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 12),
          const Text(
            '등록된 약이 없어요',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '아래 버튼으로 약을 등록해보세요',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmCard(Alarm alarm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.medication,
              color: AppColors.secondary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alarm.label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(alarm.time),
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '예정',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '약 등록하기',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRegButton(
                icon: Icons.camera_alt,
                label: '카메라로\n등록',
                onTap: _navigateToCamera,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildRegButton(
                icon: Icons.mic,
                label: '말로\n등록',
                onTap: _navigateToVoice,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryLight,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 32,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '건강 고민 있으세요?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: widget.onNavigateToFaq,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.secondaryLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.secondaryLight.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '약 복용 관련 질문하기',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '예: "혈압약 먹을 때 주의사항이 뭐예요?"',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
