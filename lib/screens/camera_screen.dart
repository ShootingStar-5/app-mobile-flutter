import 'package:flutter/material.dart';
import 'dart:async';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isAnalyzing = false;

  void _takePhoto() {
    setState(() {
      _isAnalyzing = true;
    });

    // Simulate analysis delay
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        _showAnalysisResult();
      }
    });
  }

  void _showAnalysisResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('분석 완료!'),
        content: const Text('약 봉투에서 "아침 식후 30분"을 찾았습니다.\n알람을 등록하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to Home
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('알람이 등록되었습니다!')));
            },
            child: const Text('등록하기', style: TextStyle(fontSize: 20)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('약 봉투 찍기')),
      body: Stack(
        children: [
          // Mock Camera Viewfinder
          Container(
            color: Colors.black87,
            child: Center(
              child: Container(
                width: 300,
                height: 400,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    '약 봉투를\n네모 안에 맞춰주세요',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
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
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey, width: 4),
                  ),
                  child: _isAnalyzing
                      ? const CircularProgressIndicator()
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
                      '약을 분석하고 있어요...',
                      style: TextStyle(color: Colors.white, fontSize: 24),
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
