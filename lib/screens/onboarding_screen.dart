import 'package:flutter/material.dart';
import '../utils/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    // 페이지 1: 앱 소개
    OnboardingPage(
      type: OnboardingType.intro,
      title: '약꼬박',
      subtitle: '말로, 사진으로 쉽게 등록하는 약 알람',
      features: [
        OnboardingFeature(
          icon: Icons.camera_alt,
          title: '사진으로 간편하게',
          description: '약 봉투 사진 한 장이면 자동 등록',
        ),
        OnboardingFeature(
          icon: Icons.mic,
          title: '음성으로 빠르게',
          description: '말 한마디로 약 복용 시간 설정',
        ),
        OnboardingFeature(
          icon: Icons.alarm,
          title: '정확한 알림',
          description: '놓치기 쉬운 복약 시간을 알려드려요',
        ),
        OnboardingFeature(
          icon: Icons.calendar_month,
          title: '한눈에 기록 관리',
          description: '복용 내역을 확인하세요',
        ),
      ],
    ),
    // 페이지 2: 사진 기능
    OnboardingPage(
      type: OnboardingType.feature,
      icon: Icons.camera_alt_rounded,
      title: '약봉투 사진으로\n알람 등록하기',
      description: '약 봉투를 사진으로 찍으면\n자동으로 알람이 등록됩니다',
      backgroundColor: AppColors.secondary,
    ),
    // 페이지 3: 음성 기능
    OnboardingPage(
      type: OnboardingType.feature,
      icon: Icons.mic_rounded,
      title: '말로\n알람 등록하기',
      description: '"3일치 감기약 등록해줘"\n자동으로 식후30분에 설정 됩니다',
      backgroundColor: AppColors.secondaryLight,
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToSetup();
    }
  }

  void _goToSetup() {
    Navigator.pushReplacementNamed(context, '/initial-setup');
  }

  void _skip() {
    Navigator.pushReplacementNamed(context, '/initial-setup');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return _buildPage(_pages[index]);
            },
          ),
          // 건너뛰기 버튼 (마지막 페이지 제외)
          if (_currentPage < _pages.length - 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: TextButton(
                onPressed: _skip,
                style: TextButton.styleFrom(
                  backgroundColor: _pages[_currentPage].type == OnboardingType.intro
                      ? AppColors.secondary.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.2),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  '건너뛰기',
                  style: TextStyle(
                    fontFamily: 'SUITE',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _pages[_currentPage].type == OnboardingType.intro
                        ? AppColors.secondary
                        : Colors.white,
                  ),
                ),
              ),
            ),
          // 하단 네비게이션
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNavigation(),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    if (page.type == OnboardingType.intro) {
      return _buildIntroPage(page);
    } else {
      return _buildFeaturePage(page);
    }
  }

  Widget _buildIntroPage(OnboardingPage page) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
          child: Column(
            children: [
              // 앱 아이콘
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.medication_rounded,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              // 타이틀 (약=노란색, 꼬박=파란색)
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontFamily: 'SUITE',
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                  children: [
                    TextSpan(
                      text: '약',
                      style: TextStyle(color: AppColors.primary),
                    ),
                    TextSpan(
                      text: '꼬박',
                      style: TextStyle(color: AppColors.secondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                page.subtitle ?? '',
                style: const TextStyle(
                  fontFamily: 'SUITE',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              // 기능 리스트
              ...List.generate(page.features?.length ?? 0, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildFeatureItem(page.features![index]),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(OnboardingFeature feature) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              color: AppColors.primaryLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              feature.icon,
              color: AppColors.secondary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: const TextStyle(
                    fontFamily: 'SUITE',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature.description,
                  style: const TextStyle(
                    fontFamily: 'SUITE',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePage(OnboardingPage page) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            page.backgroundColor ?? AppColors.secondary,
            (page.backgroundColor ?? AppColors.secondary).withValues(alpha: 0.85),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 80, 24, 140),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // 아이콘 (첨부파일 스타일)
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  page.icon,
                  size: 70,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 40),
              // 타이틀
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'SUITE',
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 20),
              // 설명 (글씨 키우고 굵게)
              Text(
                page.description ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SUITE',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.95),
                  height: 1.5,
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final isIntroPage = _pages[_currentPage].type == OnboardingType.intro;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: isIntroPage ? AppColors.background : Colors.transparent,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 페이지 인디케이터
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (index) {
              final isActive = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isIntroPage
                      ? (isActive ? AppColors.secondary : AppColors.secondary.withValues(alpha: 0.3))
                      : (isActive ? Colors.white : Colors.white.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          // 버튼
          Row(
            children: [
              if (_currentPage > 0)
                Container(
                  width: 52,
                  height: 52,
                  margin: const EdgeInsets.only(right: 12),
                  child: IconButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: isIntroPage
                          ? AppColors.secondary.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: Icon(
                      Icons.chevron_left,
                      size: 28,
                      color: isIntroPage ? AppColors.secondary : Colors.white,
                    ),
                  ),
                ),
              Expanded(
                child: SizedBox(
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isIntroPage ? AppColors.secondary : Colors.white,
                      foregroundColor: isIntroPage ? Colors.white : AppColors.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentPage == _pages.length - 1 ? '시작하기' : '다음',
                          style: const TextStyle(
                            fontFamily: 'SUITE',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, size: 26),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum OnboardingType { intro, feature }

class OnboardingPage {
  final OnboardingType type;
  final String title;
  final String? subtitle;
  final String? description;
  final IconData? icon;
  final Color? backgroundColor;
  final List<OnboardingFeature>? features;
  final String? characterImage;

  OnboardingPage({
    required this.type,
    required this.title,
    this.subtitle,
    this.description,
    this.icon,
    this.backgroundColor,
    this.features,
    this.characterImage,
  });
}

class OnboardingFeature {
  final IconData icon;
  final String title;
  final String description;

  OnboardingFeature({
    required this.icon,
    required this.title,
    required this.description,
  });
}
