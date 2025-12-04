import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/theme.dart';
import '../models/alarm.dart';
import '../services/alarm_storage_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final AlarmStorageService _storageService = AlarmStorageService();

  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<Alarm> _alarms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    final alarms = await _storageService.loadAlarms();
    if (mounted) {
      setState(() {
        _alarms = alarms;
        _isLoading = false;
      });
    }
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDay = day;
    });
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  bool _isSelected(DateTime day) {
    return day.year == _selectedDay.year &&
        day.month == _selectedDay.month &&
        day.day == _selectedDay.day;
  }

  bool _hasAlarms(DateTime day) {
    // 해당 날짜에 활성화된 알람이 있는지 확인
    return _alarms.any((alarm) => alarm.isActiveOnDate(day));
  }

  List<Alarm> _getAlarmsForDay(DateTime day) {
    // 선택된 날짜에 활성화된 알람 목록 반환
    return _alarms.where((alarm) => alarm.isActiveOnDate(day)).toList();
  }

  Future<void> _toggleAlarm(Alarm alarm) async {
    alarm.isActive = !alarm.isActive;
    await _storageService.updateAlarm(alarm);
    await _loadAlarms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('약달력'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadAlarms,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 월 네비게이션
                    _buildMonthNavigation(),
                    const SizedBox(height: 20),

                    // 요일 헤더
                    _buildWeekdayHeader(),
                    const SizedBox(height: 8),

                    // 달력 그리드
                    _buildCalendarGrid(),
                    const SizedBox(height: 24),

                    // 선택된 날의 알람
                    _buildSelectedDayAlarms(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMonthNavigation() {
    final monthFormat = DateFormat('yyyy년 M월', 'ko_KR');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _previousMonth,
            icon: const Icon(Icons.chevron_left, size: 32),
            color: AppColors.secondary,
            padding: const EdgeInsets.all(8),
          ),
          Text(
            monthFormat.format(_focusedMonth),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          IconButton(
            onPressed: _nextMonth,
            icon: const Icon(Icons.chevron_right, size: 32),
            color: AppColors.secondary,
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];

    return Row(
      children: weekdays.map((day) {
        final isWeekend = day == '일' || day == '토';
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isWeekend
                    ? (day == '일' ? AppColors.error : Colors.blue)
                    : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday
    final daysInMonth = lastDayOfMonth.day;

    final days = <Widget>[];

    // 이전 달의 빈 칸
    for (var i = 0; i < firstWeekday; i++) {
      days.add(const SizedBox());
    }

    // 현재 달의 날짜
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      days.add(_buildDayCell(date));
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: days,
    );
  }

  Widget _buildDayCell(DateTime day) {
    final isToday = _isToday(day);
    final isSelected = _isSelected(day);
    final hasAlarms = _hasAlarms(day);

    return GestureDetector(
      onTap: () => _selectDay(day),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isToday ? AppColors.primaryLight.withValues(alpha: 0.5) : Colors.transparent),
          borderRadius: BorderRadius.circular(12),
          border: isToday && !isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? AppColors.secondary
                    : (day.weekday == DateTime.sunday
                        ? AppColors.error
                        : (day.weekday == DateTime.saturday
                            ? Colors.blue
                            : AppColors.textPrimary)),
              ),
            ),
            // 알람 표시 점
            if (hasAlarms && !isSelected)
              Positioned(
                bottom: 4,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDayAlarms() {
    final dayFormat = DateFormat('M월 d일 (E)', 'ko_KR');
    final alarmsForDay = _getAlarmsForDay(_selectedDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 날짜 헤더
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.event, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                dayFormat.format(_selectedDay),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (_isToday(_selectedDay)) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '오늘',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 알람 목록
        if (alarmsForDay.isEmpty)
          _buildEmptyState()
        else
          ...alarmsForDay.map((alarm) => _buildAlarmCard(alarm, onToggle: () => _toggleAlarm(alarm))),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight),
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
            '등록된 알람이 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '홈에서 알람을 등록해보세요',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmCard(Alarm alarm, {VoidCallback? onToggle}) {
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
          // 시간 표시
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  alarm.timeString,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // 알람 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alarm.label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      alarm.isActive ? Icons.notifications_active : Icons.notifications_off,
                      size: 18,
                      color: alarm.isActive ? AppColors.success : AppColors.textLight,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      alarm.isActive ? '알람 켜짐' : '알람 꺼짐',
                      style: TextStyle(
                        fontSize: 14,
                        color: alarm.isActive ? AppColors.success : AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 알람 켜기/끄기 토글 버튼
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: alarm.isActive
                    ? AppColors.success.withValues(alpha: 0.2)
                    : AppColors.textLight.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                alarm.isActive ? Icons.alarm_on : Icons.alarm_off,
                color: alarm.isActive ? AppColors.success : AppColors.textLight,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
