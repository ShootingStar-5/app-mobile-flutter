import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utils/theme.dart';

class InitialSetupScreen extends StatefulWidget {
  const InitialSetupScreen({super.key});

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 3;

  // 알림 설정
  String _alarmType = 'sound_vibration';

  // 알람 소리 설정
  String _alarmSound = '03_dingdong'; // 디폴트는 띵동

  // 오디오 플레이어
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingSound;

  // 식사/취침 시간 설정
  TimeOfDay _breakfastTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _lunchTime = const TimeOfDay(hour: 12, minute: 30);
  TimeOfDay _dinnerTime = const TimeOfDay(hour: 18, minute: 30);
  TimeOfDay _bedTime = const TimeOfDay(hour: 22, minute: 0);

  final List<Map<String, String>> _alarmSounds = [
    {'id': '01_alarm', 'name': '01 사이렌', 'file': '01_alarm.wav'},
    {'id': '02_schumann', 'name': '02 슈만', 'file': '02_schumann.mp3'},
    {'id': '03_dingdong', 'name': '03 띵동~ 약 먹을 시간입니다', 'file': '03_dingdong.wav'},
    {'id': '04_seoul', 'name': '04 서울 지하철', 'file': '04_seoul.mp3'},
  ];

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSound(String soundId) async {
    try {
      // 이미 재생 중이면 정지
      if (_playingSound == soundId) {
        await _audioPlayer.stop();
        setState(() {
          _playingSound = null;
        });
        return;
      }

      // 무음/진동 모드 체크
      await _checkSilentMode();

      final sound = _alarmSounds.firstWhere((s) => s['id'] == soundId);
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('bell/${sound['file']}'));
      setState(() {
        _playingSound = soundId;
      });

      // 재생 완료 시 상태 초기화
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _playingSound = null;
          });
        }
      });
    } catch (e) {
      debugPrint('소리 재생 오류: $e');
    }
  }

  Future<void> _checkSilentMode() async {
    // 볼륨 체크는 플랫폼별로 다르므로 간단한 메시지만 표시
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('무음 진동시 소리가 안들립니다.\n소리를 켜주세요'),
          backgroundColor: AppColors.secondary,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _saveAndFinish();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveAndFinish() async {
    final prefs = await SharedPreferences.getInstance();

    // 알림 설정 저장
    await prefs.setString('alarm_type', _alarmType);
    await prefs.setBool('sound_enabled', _alarmType.contains('sound'));
    await prefs.setBool('vibration_enabled', _alarmType.contains('vibration'));
    await prefs.setBool('forced_sound', _alarmType == 'forced_sound');

    // 알람 소리 저장
    await prefs.setString('alarm_sound', _alarmSound);

    // 식사 시간 저장
    await prefs.setInt('breakfast_hour', _breakfastTime.hour);
    await prefs.setInt('breakfast_minute', _breakfastTime.minute);
    await prefs.setInt('lunch_hour', _lunchTime.hour);
    await prefs.setInt('lunch_minute', _lunchTime.minute);
    await prefs.setInt('dinner_hour', _dinnerTime.hour);
    await prefs.setInt('dinner_minute', _dinnerTime.minute);
    await prefs.setInt('bed_hour', _bedTime.hour);
    await prefs.setInt('bed_minute', _bedTime.minute);

    // 초기 설정 완료 표시
    await prefs.setBool('initial_setup_done', true);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _selectTime(String type) async {
    TimeOfDay initialTime;
    String helpText;

    switch (type) {
      case 'breakfast':
        initialTime = _breakfastTime;
        helpText = '아침 식사 시간';
        break;
      case 'lunch':
        initialTime = _lunchTime;
        helpText = '점심 식사 시간';
        break;
      case 'dinner':
        initialTime = _dinnerTime;
        helpText = '저녁 식사 시간';
        break;
      case 'bed':
        initialTime = _bedTime;
        helpText = '취침 시간';
        break;
      default:
        return;
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: helpText,
      cancelText: '취소',
      confirmText: '확인',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.secondary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        switch (type) {
          case 'breakfast':
            _breakfastTime = picked;
            break;
          case 'lunch':
            _lunchTime = picked;
            break;
          case 'dinner':
            _dinnerTime = picked;
            break;
          case 'bed':
            _bedTime = picked;
            break;
        }
      });
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 진행 표시
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        '초기 설정',
                        style: TextStyle(
                          fontFamily: 'SUITE',
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_currentPage + 1} / $_totalPages',
                        style: const TextStyle(
                          fontFamily: 'SUITE',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 진행 바
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_currentPage + 1) / _totalPages,
                      backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),

            // 페이지 콘텐츠
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildAlarmTypePage(),
                  _buildAlarmSoundPage(),
                  _buildMealTimePage(),
                ],
              ),
            ),

            // 하단 버튼
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmTypePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: AppColors.secondary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '알림 방식 설정',
                      style: TextStyle(
                        fontFamily: 'SUITE',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '약 복용 시간에 어떻게 알려드릴까요?',
                      style: TextStyle(
                        fontFamily: 'SUITE',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildAlarmTypeOption(
            'sound_vibration',
            '소리 + 진동',
            null,
            Icons.volume_up,
            Icons.vibration,
          ),
          const SizedBox(height: 12),
          _buildAlarmTypeOption(
            'sound',
            '소리만',
            null,
            Icons.volume_up,
            null,
          ),
          const SizedBox(height: 12),
          _buildAlarmTypeOption(
            'vibration',
            '진동만',
            null,
            Icons.vibration,
            null,
          ),
          const SizedBox(height: 12),
          _buildAlarmTypeOption(
            'forced_sound',
            '강제 소리',
            '무음이나 진동에서도\n큰 소리가 나요',
            Icons.volume_up,
            Icons.priority_high,
            isHighlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmTypeOption(
    String value,
    String title,
    String? description,
    IconData icon1,
    IconData? icon2, {
    bool isHighlight = false,
  }) {
    final isSelected = _alarmType == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _alarmType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.primaryLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.secondary.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.primaryLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon1,
                    color: isSelected ? Colors.white : AppColors.secondary,
                    size: icon2 != null ? 22 : 28,
                  ),
                  if (icon2 != null) ...[
                    const SizedBox(width: 2),
                    Icon(
                      icon2,
                      color: isSelected
                          ? (isHighlight ? AppColors.primary : Colors.white)
                          : (isHighlight ? AppColors.error : AppColors.secondary),
                      size: 18,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'SUITE',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontFamily: 'SUITE',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.85)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppColors.primary : AppColors.textLight,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmSoundPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.music_note,
                  color: AppColors.secondary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '알람 소리 선택',
                      style: TextStyle(
                        fontFamily: 'SUITE',
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '터치하면 미리 들어볼 수 있어요',
                      style: TextStyle(
                        fontFamily: 'SUITE',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          ...(_alarmSounds.map((sound) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSoundOption(sound['id']!, sound['name']!),
          ))),
        ],
      ),
    );
  }

  Widget _buildSoundOption(String id, String name) {
    final isSelected = _alarmSound == id;
    final isPlaying = _playingSound == id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _alarmSound = id;
        });
        _playSound(id);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.primaryLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.secondary.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.primaryLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isPlaying ? Icons.pause_circle_filled :
                id == '01_alarm' ? Icons.warning_amber_rounded :
                id == '02_schumann' ? Icons.piano :
                id == '03_dingdong' ? Icons.notifications_active :
                Icons.train,
                color: isSelected ? Colors.white : AppColors.secondary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontFamily: 'SUITE',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppColors.primary : AppColors.textLight,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTimePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.schedule,
                  color: AppColors.secondary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '식사/취침 시간 설정',
                      style: TextStyle(
                        fontFamily: 'SUITE',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '식전/식후 알람 시간 계산에 사용돼요',
                      style: TextStyle(
                        fontFamily: 'SUITE',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          _buildTimeSettingCard(
            '아침 식사',
            _breakfastTime,
            Icons.wb_sunny,
            AppColors.warning,
            () => _selectTime('breakfast'),
          ),
          const SizedBox(height: 14),
          _buildTimeSettingCard(
            '점심 식사',
            _lunchTime,
            Icons.wb_cloudy,
            AppColors.secondaryLight,
            () => _selectTime('lunch'),
          ),
          const SizedBox(height: 14),
          _buildTimeSettingCard(
            '저녁 식사',
            _dinnerTime,
            Icons.nights_stay,
            AppColors.secondary,
            () => _selectTime('dinner'),
          ),
          const SizedBox(height: 14),
          _buildTimeSettingCard(
            '취침 시간',
            _bedTime,
            Icons.bedtime,
            const Color(0xFF5C6BC0),
            () => _selectTime('bed'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSettingCard(
    String title,
    TimeOfDay time,
    IconData icon,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            // 고정 너비로 타이틀 (한 줄)
            SizedBox(
              width: 80,
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'SUITE',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Spacer(),
            // 고정 너비로 시간 표시
            Container(
              width: 130,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  _formatTime(time),
                  style: const TextStyle(
                    fontFamily: 'SUITE',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textLight,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Container(
              width: 56,
              height: 56,
              margin: const EdgeInsets.only(right: 12),
              child: IconButton(
                onPressed: _previousPage,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(
                  Icons.chevron_left,
                  size: 30,
                  color: AppColors.secondary,
                ),
              ),
            ),
          Expanded(
            child: SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentPage == _totalPages - 1 ? '설정 완료' : '다음',
                      style: const TextStyle(
                        fontFamily: 'SUITE',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _currentPage == _totalPages - 1 ? Icons.check : Icons.chevron_right,
                      size: 26,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
