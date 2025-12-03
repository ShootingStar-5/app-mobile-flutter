import 'package:flutter/material.dart';
import '../utils/theme.dart';

class HealthFaqScreen extends StatefulWidget {
  const HealthFaqScreen({super.key});

  @override
  State<HealthFaqScreen> createState() => _HealthFaqScreenState();
}

class _HealthFaqScreenState extends State<HealthFaqScreen> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // 자주 묻는 질문 예시
  final List<String> _suggestedQuestions = [
    '혈압약은 언제 먹어야 해요?',
    '약을 깜빡하고 못 먹었어요',
    '약 먹고 졸려요, 괜찮나요?',
    '약과 음식 함께 먹어도 되나요?',
  ];

  @override
  void initState() {
    super.initState();
    // 환영 메시지 추가
    _messages.add(ChatMessage(
      text: '안녕하세요! 약 복용에 관해 궁금한 점이 있으시면 편하게 물어보세요.',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
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

    // 데모용 응답 (실제로는 RAG API 호출)
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
    // 데모용 응답 로직
    if (question.contains('혈압') || question.contains('언제')) {
      return '혈압약은 보통 아침에 일정한 시간에 드시는 것이 좋아요. 의사 선생님이 특별히 지시하신 시간이 있다면 그 시간에 드세요. 규칙적으로 같은 시간에 드시는 것이 효과적입니다.';
    } else if (question.contains('깜빡') || question.contains('못 먹')) {
      return '약을 깜빡 잊으셨다면, 생각났을 때 바로 드세요. 단, 다음 복용 시간이 가까우면 건너뛰고 다음 시간에 드시는 게 좋아요. 두 번 분량을 한꺼번에 드시면 안 돼요!';
    } else if (question.contains('졸려') || question.contains('졸음')) {
      return '일부 약은 졸음을 유발할 수 있어요. 운전이나 위험한 작업 전에는 주의하세요. 증상이 심하시면 담당 의사 선생님과 상담해보시는 것이 좋겠어요.';
    } else if (question.contains('음식') || question.contains('함께')) {
      return '대부분의 약은 음식과 함께 드셔도 괜찮아요. 하지만 자몽주스나 우유는 일부 약과 상호작용할 수 있으니 주의하세요. 궁금하시면 약사님께 여쭤보세요!';
    } else {
      return '좋은 질문이에요! 약에 대해 궁금하신 점이 있으시면 담당 의사 선생님이나 가까운 약국의 약사님께 상담받으시는 것을 권해드려요. 건강을 위해 약을 꼬박꼬박 챙겨 드세요!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('건강고민'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // 채팅 메시지 목록
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading) {
                        return _buildLoadingIndicator();
                      }
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),

          // 추천 질문 (메시지가 적을 때만)
          if (_messages.length <= 2) _buildSuggestedQuestions(),

          // 입력 영역
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 50,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '건강에 대해 물어보세요',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '약 복용, 부작용, 주의사항 등\n궁금한 점을 질문해주세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.health_and_safety,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppColors.primary
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.5,
                  color: message.isUser
                      ? AppColors.secondary
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.health_and_safety,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(16),
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
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.3 + (value * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildSuggestedQuestions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이런 질문은 어때요?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestedQuestions.map((q) {
              return GestureDetector(
                onTap: () => _sendQuestion(q),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    q,
                    style: const TextStyle(
                      fontSize: 14,
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

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _questionController,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  hintText: '질문을 입력하세요...',
                  hintStyle: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 18,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
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
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: AppColors.secondary,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }
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
