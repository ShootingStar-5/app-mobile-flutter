import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';
import '../services/alarm_storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _vibrationEnabled = true;
  bool _soundEnabled = true;

  // 식사 시간 설정
  TimeOfDay _breakfastTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _lunchTime = const TimeOfDay(hour: 12, minute: 30);
  TimeOfDay _dinnerTime = const TimeOfDay(hour: 18, minute: 30);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;

      _breakfastTime = TimeOfDay(
        hour: prefs.getInt('breakfast_hour') ?? 8,
        minute: prefs.getInt('breakfast_minute') ?? 0,
      );
      _lunchTime = TimeOfDay(
        hour: prefs.getInt('lunch_hour') ?? 12,
        minute: prefs.getInt('lunch_minute') ?? 30,
      );
      _dinnerTime = TimeOfDay(
        hour: prefs.getInt('dinner_hour') ?? 18,
        minute: prefs.getInt('dinner_minute') ?? 30,
      );
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('vibration_enabled', _vibrationEnabled);
    await prefs.setBool('sound_enabled', _soundEnabled);

    await prefs.setInt('breakfast_hour', _breakfastTime.hour);
    await prefs.setInt('breakfast_minute', _breakfastTime.minute);
    await prefs.setInt('lunch_hour', _lunchTime.hour);
    await prefs.setInt('lunch_minute', _lunchTime.minute);
    await prefs.setInt('dinner_hour', _dinnerTime.hour);
    await prefs.setInt('dinner_minute', _dinnerTime.minute);
  }

  Future<void> _selectTime(String mealType) async {
    TimeOfDay initialTime;
    switch (mealType) {
      case 'breakfast':
        initialTime = _breakfastTime;
        break;
      case 'lunch':
        initialTime = _lunchTime;
        break;
      case 'dinner':
        initialTime = _dinnerTime;
        break;
      default:
        return;
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
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
        switch (mealType) {
          case 'breakfast':
            _breakfastTime = picked;
            break;
          case 'lunch':
            _lunchTime = picked;
            break;
          case 'dinner':
            _dinnerTime = picked;
            break;
        }
      });
      await _saveSettings();
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
            SizedBox(width: 12),
            Text('알람 전체 삭제'),
          ],
        ),
        content: const Text(
          '등록된 모든 알람이 삭제됩니다.\n정말 삭제하시겠습니까?',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              '취소',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('삭제', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AlarmStorageService().saveAlarms([]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('모든 알람이 삭제되었습니다'),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 알림 설정 섹션
            _buildSectionTitle('알림 설정', Icons.notifications),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildSwitchTile(
                '알림 받기',
                '약 복용 시간에 알림을 받습니다',
                Icons.notifications_active,
                _notificationsEnabled,
                (value) {
                  setState(() => _notificationsEnabled = value);
                  _saveSettings();
                },
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                '진동',
                '알림 시 진동이 울립니다',
                Icons.vibration,
                _vibrationEnabled,
                (value) {
                  setState(() => _vibrationEnabled = value);
                  _saveSettings();
                },
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                '소리',
                '알림 시 소리가 납니다',
                Icons.volume_up,
                _soundEnabled,
                (value) {
                  setState(() => _soundEnabled = value);
                  _saveSettings();
                },
              ),
            ]),

            const SizedBox(height: 28),

            // 식사 시간 설정 섹션
            _buildSectionTitle('식사 시간', Icons.restaurant),
            const SizedBox(height: 8),
            const Text(
              '식전/식후 알람 계산에 사용됩니다',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildTimeTile(
                '아침',
                _breakfastTime,
                Icons.wb_sunny,
                () => _selectTime('breakfast'),
              ),
              const Divider(height: 1),
              _buildTimeTile(
                '점심',
                _lunchTime,
                Icons.wb_cloudy,
                () => _selectTime('lunch'),
              ),
              const Divider(height: 1),
              _buildTimeTile(
                '저녁',
                _dinnerTime,
                Icons.nights_stay,
                () => _selectTime('dinner'),
              ),
            ]),

            const SizedBox(height: 28),

            // 데이터 관리 섹션
            _buildSectionTitle('데이터 관리', Icons.storage),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildActionTile(
                '모든 알람 삭제',
                '등록된 알람을 모두 삭제합니다',
                Icons.delete_forever,
                AppColors.error,
                _showDeleteConfirmation,
              ),
            ]),

            const SizedBox(height: 28),

            // 앱 정보 섹션
            _buildSectionTitle('앱 정보', Icons.info_outline),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildInfoTile('앱 버전', '1.0.0'),
              const Divider(height: 1),
              _buildInfoTile('개발', '약꼬박 팀'),
            ]),

            const SizedBox(height: 40),

            // 앱 로고
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.medication,
                      size: 40,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '약꼬박',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '꼬박꼬박 약 챙겨드세요',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.secondary, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.secondary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primaryLight,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTile(
    String title,
    TimeOfDay time,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.secondary, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatTime(time),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textLight,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: iconColor.withValues(alpha: 0.5),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
