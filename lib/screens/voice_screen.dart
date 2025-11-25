import 'package:flutter/material.dart';
import 'dart:async';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  bool _isListening = false;
  String _statusText = '마이크를 누르고\n말씀해주세요';

  void _startListening() {
    setState(() {
      _isListening = true;
      _statusText = '듣고 있어요...';
    });

    // Simulate listening duration
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isListening = false;
          _statusText = '확인되었습니다!';
        });
        _showConfirmation();
      }
    });
  }

  void _showConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('알람 등록'),
        content: const Text('"점심 먹고 30분 뒤"\n알람을 맞출까요?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _statusText = '마이크를 누르고\n말씀해주세요';
              });
            },
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('알람이 등록되었습니다!')));
            },
            child: const Text(
              '네, 맞아요',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('말로 등록하기')),
      body: Center(
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
              onTap: _isListening ? null : _startListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isListening ? 180 : 150,
                decoration: BoxDecoration(
                  color: _isListening ? Colors.red : Colors.blue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening ? Colors.red : Colors.blue)
                          .withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 40),
            if (!_isListening)
              const Text(
                '예시: "점심 먹고 30분 뒤에 알려줘"',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
