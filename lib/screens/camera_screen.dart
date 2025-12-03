import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../services/medication_extract_service.dart';
import '../models/medication_data.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _controller = CameraController(_cameras![0], ResolutionPreset.high);
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } catch (e) {
      print('카메라 초기화 오류: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      // 사진 촬영
      final image = await _controller!.takePicture();

      // 백엔드로 전송
      final url = '${MedicationExtractService.baseUrl}/api/v1/ocr/extract-medication';
      final uri = Uri.parse(url);
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      var response = await request.send().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('서버 응답 시간 초과');
        },
      );

      var responseBody = await response.stream.bytesToString();
      var json = jsonDecode(responseBody);

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });

        if (json['success'] == true && json['medication_data'] != null) {
          _showAnalysisResult(
            MedicationData.fromJson(json['medication_data']),
            json['ocr_text'] ?? '',
          );
        } else {
          _showError(json['message'] ?? '분석 실패\n다시 촬영해주세요.', showRetry: true);
        }
      }
    } on SocketException catch (e) {
      print('❌ SocketException: $e');
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        _showError(
          '서버에 연결할 수 없습니다.\n\n'
          '확인사항:\n'
          '• PC와 휴대폰이 같은 Wi-Fi에 연결되어 있는지\n'
          '• 백엔드 서버가 실행 중인지\n'
          '• 방화벽 설정\n\n'
          '다시 시도하시겠습니까?',
          showRetry: true,
        );
      }
    } on TimeoutException catch (e) {
      print('❌ TimeoutException: $e');
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        _showError(
          '서버 응답 시간 초과 (30초)\n\n'
          '네트워크가 느리거나 서버가 응답하지 않습니다.\n'
          '다시 시도해주세요.',
          showRetry: true,
        );
      }
    } catch (e, stackTrace) {
      print('❌ 기타 오류: $e');
      print('❌ 스택트레이스: $stackTrace');
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        _showError('오류: $e', showRetry: true);
      }
    }
  }

  void _showAnalysisResult(MedicationData data, String ocrText) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('분석 완료!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('약 이름: ${data.medicationName ?? "알 수 없음"}'),
            Text('복용 기간: ${data.totalDurationDays ?? 0}일'),
            Text('일 복용 횟수: ${data.dailyFrequency ?? 0}회'),
            Text(
              '식사 기준: ${_getMealContextText(data.mealContext ?? "post_meal")}',
            ),
            if (data.specialInstructions != null &&
                data.specialInstructions!.isNotEmpty)
              Text('특이사항: ${data.specialInstructions}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to Home
            },
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, data); // Back to Home with data
            },
            child: const Text(
              '알람 생성',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message, {bool showRetry = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
          if (showRetry)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _takePhoto(); // 재시도
              },
              child: const Text(
                '다시 시도',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  String _getMealContextText(String context) {
    switch (context) {
      case 'pre_meal':
        return '식전';
      case 'post_meal':
        return '식후';
      case 'at_bedtime':
        return '취침전';
      default:
        return context;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('약 봉투 촬영'),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          // Camera Preview
          if (_isInitialized && _controller != null)
            SizedBox.expand(child: CameraPreview(_controller!))
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // Guide Frame
          Center(
            child: Container(
              width: 300,
              height: 400,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // Guide Text
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                '약 봉투를 네모 안에 맞춰주세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black,
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Shutter Button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _isAnalyzing ? null : _takePhoto,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _isAnalyzing ? Colors.grey : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey, width: 4),
                  ),
                  child: _isAnalyzing
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          size: 40,
                          color: Colors.black,
                        ),
                ),
              ),
            ),
          ),

          // Analysis Overlay
          if (_isAnalyzing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      '약 봉투를 분석하고 있어요...',
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '최대 15초 소요',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
