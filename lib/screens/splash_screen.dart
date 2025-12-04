import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../utils/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _startAutoNavigation();
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.asset(
      'assets/videos/mascot_home_01.mp4',
    );

    try {
      await _videoController.initialize();
      _videoController.setLooping(true);
      _videoController.setVolume(0); // 소리 끄기
      _videoController.play();

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('비디오 초기화 오류: $e');
    }
  }

  void _startAutoNavigation() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // 시연용: 항상 온보딩부터 시작
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // 마스코트 비디오
              Expanded(
                flex: 40,
                child: _isVideoInitialized
                    ? FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: _videoController.value.size.width,
                          height: _videoController.value.size.height,
                          child: VideoPlayer(_videoController),
                        ),
                      )
                    : const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
              ),
              const SizedBox(height: 10),

              // 인사 텍스트 (약=노란색, 꼬박=파란색)
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(
                    fontFamily: 'SUITE',
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                  children: [
                    TextSpan(
                      text: '안녕하세요,\n',
                      style: TextStyle(color: AppColors.secondary),
                    ),
                    TextSpan(
                      text: '약',
                      style: TextStyle(color: AppColors.primary),
                    ),
                    TextSpan(
                      text: '꼬박',
                      style: TextStyle(color: AppColors.secondary),
                    ),
                    TextSpan(
                      text: '입니다',
                      style: TextStyle(color: AppColors.secondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // 설명 텍스트
              const Text(
                '말로, 사진으로 쉽게 등록하는 약 알람',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SUITE',
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 5),

              // 로딩 인디케이터
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
