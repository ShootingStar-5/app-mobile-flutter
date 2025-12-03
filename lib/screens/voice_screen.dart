import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import '../services/medication_extract_service.dart';
import '../models/medication_data.dart';
import '../utils/theme.dart';
import 'alarm_edit_screen.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final MedicationExtractService _extractService = MedicationExtractService();

  bool _isListening = false;
  bool _isProcessing = false;
  String _statusText = '마이크를 누르고\n말씀해주세요';
  String? _recordingPath;

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<bool> _checkPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _startRecording() async {
    if (!await _checkPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('마이크 권한이 필요합니다')),
        );
      }
      return;
    }

    try {
      final directory = await getTemporaryDirectory();
      _recordingPath = '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 256000,
        ),
        path: _recordingPath!,
      );

      setState(() {
        _isListening = true;
        _statusText = '듣고 있어요...\n(다시 누르면 중지)';
      });
    } catch (e) {
      debugPrint('녹음 시작 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('녹음 시작 실패: $e')),
        );
      }
    }
  }

  Future<void> _stopRecordingAndProcess() async {
    try {
      final path = await _audioRecorder.stop();

      setState(() {
        _isListening = false;
        _isProcessing = true;
        _statusText = '분석 중...';
      });

      if (path != null) {
        final result = await _extractService.extractFromVoice(path);

        if (mounted) {
          setState(() {
            _isProcessing = false;
          });

          if (result.success && result.data != null) {
            _showConfirmation(result.sttText, result.data!);
          } else {
            setState(() {
              _statusText = '마이크를 누르고\n말씀해주세요';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result.message)),
            );
          }
        }

        // 임시 파일 삭제
        try {
          await File(path).delete();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('녹음 중지 오류: $e');
      if (mounted) {
        setState(() {
          _isListening = false;
          _isProcessing = false;
          _statusText = '마이크를 누르고\n말씀해주세요';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('처리 실패: $e')),
        );
      }
    }
  }

  void _toggleRecording() {
    if (_isListening) {
      _stopRecordingAndProcess();
    } else {
      _startRecording();
    }
  }

  void _showConfirmation(String sttText, MedicationData data) {
    setState(() {
      _statusText = '마이크를 누르고\n말씀해주세요';
    });

    // AlarmEditScreen으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlarmEditScreen(
          medicationData: data,
          sttText: sttText,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('말로 등록하기')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            return SingleChildScrollView(
              padding: EdgeInsets.all(isLandscape ? 16 : 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: isLandscape ? 10 : 20),

                  // Status Card
                  _buildStatusCard(),
                  SizedBox(height: isLandscape ? 20 : 40),

                  // Mic Button
                  _buildMicButton(isLandscape: isLandscape),
                  SizedBox(height: isLandscape ? 20 : 40),

                  // Example Phrases
                  if (!_isListening && !_isProcessing) _buildExamplePhrases(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: _isListening
            ? AppColors.primary.withValues(alpha: 0.2)
            : (_isProcessing
                ? AppColors.secondaryLight.withValues(alpha: 0.1)
                : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isListening
              ? AppColors.primary
              : (_isProcessing ? AppColors.secondaryLight : AppColors.primaryLight),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isListening)
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: 12),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
          if (_isProcessing)
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 12),
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.secondary,
              ),
            ),
          Flexible(
            child: Text(
              _statusText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _isListening ? AppColors.secondary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicButton({bool isLandscape = false}) {
    final Color buttonColor = _isProcessing
        ? AppColors.textLight
        : (_isListening ? AppColors.error : AppColors.primary);

    final double baseSize = isLandscape ? 100 : 140;
    final double activeSize = isLandscape ? 110 : 160;

    return GestureDetector(
      onTap: _isProcessing ? null : _toggleRecording,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _isListening ? activeSize : baseSize,
        height: _isListening ? activeSize : baseSize,
        decoration: BoxDecoration(
          color: buttonColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: buttonColor.withValues(alpha: 0.4),
              blurRadius: _isListening ? 30 : 20,
              spreadRadius: _isListening ? 8 : 4,
            ),
          ],
        ),
        child: Icon(
          _isListening ? Icons.stop_rounded : Icons.mic,
          size: 70,
          color: _isListening ? Colors.white : AppColors.secondary,
        ),
      ),
    );
  }

  Widget _buildExamplePhrases() {
    final examples = [
      '"1일 3회, 4일분, 식후 30분"',
      '"하루에 두 번, 아침 저녁으로"',
      '"타이레놀, 하루 세 번, 일주일"',
    ];

    return Column(
      children: [
        const Text(
          '이렇게 말해보세요',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        ...examples.map((example) => Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.format_quote,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  example,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
