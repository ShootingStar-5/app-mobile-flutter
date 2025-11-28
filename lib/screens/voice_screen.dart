import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import '../services/medication_extract_service.dart';
import '../models/medication_data.dart';
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
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _statusText,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 60),
                  GestureDetector(
                    onTap: _isProcessing ? null : _toggleRecording,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _isListening ? 180 : 150,
                      height: _isListening ? 180 : 150,
                      decoration: BoxDecoration(
                        color: _isProcessing
                            ? Colors.grey
                            : (_isListening ? Colors.red : Colors.blue),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isProcessing
                                    ? Colors.grey
                                    : (_isListening ? Colors.red : Colors.blue))
                                .withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Icon(
                              _isListening ? Icons.stop : Icons.mic_none,
                              size: 80,
                              color: Colors.white,
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (!_isListening && !_isProcessing)
                    const Text(
                      '예시: "1일 3회, 4일분, 식후 30분"',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
