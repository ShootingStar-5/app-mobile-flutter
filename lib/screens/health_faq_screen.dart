import 'package:flutter/material.dart';
import '../utils/theme.dart';

class HealthFaqScreen extends StatefulWidget {
  const HealthFaqScreen({super.key});

  @override
  State<HealthFaqScreen> createState() => _HealthFaqScreenState();
}

class _HealthFaqScreenState extends State<HealthFaqScreen> {
  String? _selectedCategory;
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // 카테고리 정의
  final List<HealthCategory> _categories = [
    HealthCategory(
      id: 'bone',
      title: '관절/뼈',
      icon: Icons.accessibility_new,
      questions: [
        '관절에 좋은 영양제가 뭐예요?',
        '뼈 건강을 위해 칼슘제 먹어도 되나요?',
        '관절염 약 복용 시 주의사항이 있나요?',
      ],
    ),
    HealthCategory(
      id: 'eye',
      title: '눈 건강',
      icon: Icons.visibility,
      questions: [
        '눈 건강에 좋은 영양제가 뭐예요?',
        '루테인은 언제 먹어야 해요?',
        '눈이 피로할 때 어떤 약이 좋아요?',
      ],
    ),
    HealthCategory(
      id: 'brain',
      title: '기억력/뇌',
      icon: Icons.psychology,
      questions: [
        '기억력에 좋은 영양제가 뭐예요?',
        '오메가3가 뇌에 좋다던데 사실인가요?',
        '집중력 향상에 도움되는 약이 있나요?',
      ],
    ),
    HealthCategory(
      id: 'fatigue',
      title: '피로/기력',
      icon: Icons.bolt,
      questions: [
        '피로회복에 좋은 영양제가 뭐예요?',
        '비타민B가 피로에 도움이 되나요?',
        '무기력할 때 어떤 약을 먹어야 하나요?',
      ],
    ),
    HealthCategory(
      id: 'digestion',
      title: '소화/장',
      icon: Icons.spa,
      questions: [
        '소화가 안 될 때 어떤 약이 좋아요?',
        '유산균은 언제 먹어야 해요?',
        '장 건강에 좋은 영양제가 뭐예요?',
      ],
    ),
    HealthCategory(
      id: 'immune',
      title: '면역/호흡기',
      icon: Icons.shield,
      questions: [
        '면역력 향상에 좋은 영양제가 뭐예요?',
        '감기 예방에 비타민C가 도움이 되나요?',
        '호흡기 건강을 위한 약이 있나요?',
      ],
    ),
    HealthCategory(
      id: 'sleep',
      title: '수면/불면증',
      icon: Icons.nightlight_round,
      questions: [
        '잠이 안 올 때 어떤 약이 좋아요?',
        '수면에 좋은 영양제가 있나요?',
        '멜라토닌은 어떻게 먹어야 해요?',
      ],
    ),
    HealthCategory(
      id: 'blood',
      title: '혈행/혈관',
      icon: Icons.favorite,
      questions: [
        '혈액순환에 좋은 영양제가 뭐예요?',
        '오메가3가 혈관에 도움이 되나요?',
        '콜레스테롤 낮추는 약이 있나요?',
      ],
    ),
  ];

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _selectCategory(HealthCategory category) {
    setState(() {
      _selectedCategory = category.id;
      _messages.clear();
      _messages.add(ChatMessage(
        text: '${category.title} 관련해서 궁금한 점이 있으시면 편하게 물어보세요!',
        isUser: false,
      ));
    });
  }

  void _goBack() {
    setState(() {
      _selectedCategory = null;
      _messages.clear();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendQuestion(String question) async {
    if (question.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: question, isUser: true));
      _isLoading = true;
    });
    _questionController.clear();
    _scrollToBottom();

    await Future.delayed(const Duration(seconds: 1));

    final response = _getDemoResponse(question);

    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  String _getDemoResponse(String question) {
    final category = _categories.firstWhere(
      (c) => c.id == _selectedCategory,
      orElse: () => _categories.first,
    );

    if (category.id == 'bone') {
      if (question.contains('칼슘') || question.contains('뼈')) {
        return '뼈 건강을 위해 칼슘제를 드시는 것은 좋아요! 하루 권장량은 1000mg 정도이며, 비타민D와 함께 드시면 흡수가 더 잘 됩니다.';
      } else if (question.contains('관절')) {
        return '관절 건강에는 글루코사민, 콘드로이틴, MSM 등이 도움이 될 수 있어요. 의사 선생님과 상담 후 드시는 것이 좋습니다.';
      }
    } else if (category.id == 'eye') {
      if (question.contains('루테인')) {
        return '루테인은 음식과 함께 드시면 흡수가 잘 됩니다. 하루 한 번, 식사 중이나 식후에 드세요!';
      } else if (question.contains('눈')) {
        return '눈 건강에는 루테인, 지아잔틴, 빌베리 추출물 등이 도움이 돼요. 장시간 화면을 보시면 자주 쉬어주세요!';
      }
    } else if (category.id == 'brain') {
      if (question.contains('오메가') || question.contains('기억력')) {
        return '오메가3의 DHA 성분이 뇌 건강에 도움이 됩니다. 하루 1000mg 정도가 권장량이에요.';
      }
    } else if (category.id == 'fatigue') {
      if (question.contains('피로') || question.contains('비타민')) {
        return '피로 회복에는 비타민B군이 도움이 됩니다. 특히 B1, B2, B6, B12가 에너지 대사에 관여해요.';
      }
    } else if (category.id == 'digestion') {
      if (question.contains('유산균') || question.contains('장')) {
        return '유산균은 공복에 드시면 위산에 의해 사멸될 수 있으니, 식후에 드시는 것이 좋아요!';
      }
    } else if (category.id == 'immune') {
      if (question.contains('면역') || question.contains('비타민C')) {
        return '면역력 향상에는 비타민C, 비타민D, 아연 등이 도움이 됩니다. 균형 잡힌 식사도 중요해요!';
      }
    } else if (category.id == 'sleep') {
      if (question.contains('잠') || question.contains('수면') || question.contains('불면')) {
        return '수면에 도움이 되는 영양제로는 마그네슘, 테아닌, 멜라토닌 등이 있어요. 취침 30분~1시간 전에 드시면 좋습니다.';
      } else if (question.contains('멜라토닌')) {
        return '멜라토닌은 취침 30분 전에 드시면 좋아요. 처음에는 낮은 용량(1~3mg)으로 시작하시는 것을 권해드립니다.';
      }
    } else if (category.id == 'blood') {
      if (question.contains('혈액') || question.contains('순환') || question.contains('혈관')) {
        return '혈액순환에는 오메가3, 코엔자임Q10, 은행잎 추출물 등이 도움이 될 수 있어요. 규칙적인 운동도 함께 하시면 좋습니다!';
      } else if (question.contains('콜레스테롤')) {
        return '콜레스테롤 관리에는 오메가3, 식이섬유, 홍국 등이 도움이 될 수 있어요. 수치가 높으면 의사 선생님과 상담이 필요합니다.';
      }
    }

    return '좋은 질문이에요! ${category.title} 관련해서 더 자세한 내용은 담당 의사 선생님이나 약사님께 상담받으시는 것을 권해드려요.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedCategory == null
          ? _buildCategoryView()
          : _buildChatView(),
    );
  }

  Widget _buildCategoryView() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFF9E6),
            Colors.white,
          ],
          stops: [0.0, 0.3],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 헤더 섹션
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '약꼬박',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '궁금한 것을 물어보세요',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 마스코트 캐릭터
                  Image.asset(
                    'assets/images/char/char_pose_01.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: Icon(
                          Icons.medication,
                          size: 60,
                          color: AppColors.secondary,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 카테고리 카드 그리드
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_hospital,
                          color: AppColors.secondary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '증상별 질문',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.6,
                        ),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          return _buildCategoryCard(_categories[index]);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 하단 입력 영역
            _buildBottomInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(HealthCategory category) {
    return GestureDetector(
      onTap: () => _selectCategory(category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Icon(
              category.icon,
              color: AppColors.secondary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatView() {
    final category = _categories.firstWhere(
      (c) => c.id == _selectedCategory,
      orElse: () => _categories.first,
    );

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/images/04_chat_bg.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.white.withValues(alpha: 0.9),
            BlendMode.srcOver,
          ),
          onError: (exception, stackTrace) {},
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 상단 바
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _goBack,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(category.icon, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    category.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // 채팅 영역
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isLoading) {
                    return _buildLoadingBubble();
                  }
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),

            // 추천 질문
            if (_messages.length <= 2) _buildSuggestedQuestions(category),

            // 입력 영역
            _buildChatInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            // 캐릭터 이미지
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/char/char_pose_02.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.smart_toy,
                      color: AppColors.secondary,
                      size: 24,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? AppColors.secondary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: message.isUser ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/char/char_pose_02.png',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.smart_toy,
                    color: AppColors.secondary,
                    size: 24,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 400 + (index * 150)),
                  builder: (context, value, child) {
                    return Container(
                      margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.3 + (value * 0.7)),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedQuestions(HealthCategory category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이런 질문은 어때요?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: category.questions.map((q) {
              return GestureDetector(
                onTap: () => _sendQuestion(q),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    q,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _questionController,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: '궁금한 점을 입력하세요...',
                      hintStyle: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: (text) {
                      if (_selectedCategory == null && text.isNotEmpty) {
                        _selectCategory(_categories.first);
                      }
                      _sendQuestion(text);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  final text = _questionController.text;
                  if (_selectedCategory == null && text.isNotEmpty) {
                    _selectCategory(_categories.first);
                  }
                  _sendQuestion(text);
                },
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: AppColors.secondary,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '정보 제공용이며, 정확한 진단과 처방은 의사와 상담하세요',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondary,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _questionController,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: '질문을 입력하세요...',
                  hintStyle: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                onSubmitted: _sendQuestion,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _sendQuestion(_questionController.text),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Icon(
                Icons.send_rounded,
                color: AppColors.secondary,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HealthCategory {
  final String id;
  final String title;
  final IconData icon;
  final List<String> questions;

  HealthCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.questions,
  });
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
