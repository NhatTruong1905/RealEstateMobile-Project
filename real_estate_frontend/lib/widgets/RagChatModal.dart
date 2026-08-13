import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:real_estate_frontend/services/RagChatService.dart';

class RagChatModal extends StatefulWidget {
  const RagChatModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RagChatModal(),
    );
  }

  @override
  State<RagChatModal> createState() => _RagChatModalState();
}

class _RagChatModalState extends State<RagChatModal> {
  List<RagChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final RagChatService _ragChatService = RagChatService();
  bool _isLoading = false;
  bool _isInitialLoading = true;

  final List<String> _quickSuggestions = [
    "Gợi ý căn hộ 2PN dưới 3 tỷ",
    "Tòa nhà văn phòng nổi bật?",
    "Tìm biệt thự có sân vườn",
    "Tư vấn căn hộ phù hợp tài chính",
  ];

  @override
  void initState() {
    super.initState();
    _loadPersistedHistory();
  }

  /// Nạp lịch sử trò chuyện đã lưu từ SharedPreferences
  Future<void> _loadPersistedHistory() async {
    final history = await _ragChatService.loadHistory();
    if (mounted) {
      setState(() {
        if (history.isNotEmpty) {
          _messages = history;
        } else {
          _messages = [
            RagChatMessage(
              text: "Xin chào! Tôi là Trợ lý AI Gợi ý Tòa nhà & Bất động sản. Bạn cần tìm tòa nhà hay căn hộ như thế nào?",
              isUser: false,
            ),
          ];
        }
        _isInitialLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Gửi câu hỏi và nhận Token Stream từ AI Backend theo thời gian thực (Real-time Stream)
  Future<void> _handleSendMessage([String? textToSend]) async {
    final text = textToSend ?? _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    if (textToSend == null) {
      _controller.clear();
    }

    // Lưu lại lịch sử trước khi thêm câu hỏi mới
    final previousHistory = List<RagChatMessage>.from(_messages);

    final aiMsg = RagChatMessage(text: "", isUser: false);

    setState(() {
      _messages.add(RagChatMessage(text: text, isUser: true));
      _messages.add(aiMsg);
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final stream = _ragChatService.streamQuestion(text, history: previousHistory);
      await for (final token in stream) {
        if (!mounted) break;
        setState(() {
          aiMsg.text += token;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (aiMsg.text.isEmpty) {
            aiMsg.text = "Lỗi kết nối tới AI Backend: $e";
          }
          _isLoading = false;
        });
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _scrollToBottom();
      // Lưu lại lịch sử sau khi stream hoàn tất
      await _ragChatService.saveHistory(_messages);
    }
  }

  /// Xóa lịch sử khi người dùng nhấn nút Reload ở header
  Future<void> _clearHistory() async {
    await _ragChatService.clearHistory();
    if (mounted) {
      setState(() {
        _messages = [
          RagChatMessage(
            text: "Đã làm sạch cuộc trò chuyện. Hãy nhập câu hỏi mới cho AI nhé!",
            isUser: false,
          ),
        ];
      });
      await _ragChatService.saveHistory(_messages);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.82,
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFFFCFBFA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. HEADER CÔNG NGHỆ VỚI ICON AI CHUYÊN NGHIỆP MỚI
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF334155)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded, // Icon AI Chatbot mới siêu nét
                    color: Color(0xFFFFD700),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Trợ lý AI Gợi ý Tòa nhà",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Georgia',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "Online",
                            style: TextStyle(
                              color: Color(0xFFE5E7EB),
                              fontSize: 11,
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: "Reload & Xóa lịch sử chat",
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                  onPressed: _clearHistory,
                ),
                IconButton(
                  tooltip: "Đóng",
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // 2. QUICK SUGGESTION CHIPS
          if (_messages.length <= 2 && !_isInitialLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFF9F6F0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _quickSuggestions.map((suggestion) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        elevation: 0,
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFE5DECE)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        avatar: const Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: Color(0xFF1E293B),
                        ),
                        label: Text(
                          suggestion,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1A1918),
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onPressed: () => _handleSendMessage(suggestion),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // 3. CHAT MESSAGES LIST
          Expanded(
            child: _isInitialLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1E293B)),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isLastMessage = index == _messages.length - 1;
                      final isStreamingThisMsg = _isLoading && isLastMessage && !msg.isUser;

                      return _buildMessageBubble(msg, isStreamingThisMsg: isStreamingThisMsg);
                    },
                  ),
          ),

          // 4. INPUT SECTION
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE5DECE), width: 0.8),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4EEE6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _handleSendMessage(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1A1918),
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                        decoration: const InputDecoration(
                          hintText: "Hỏi AI về tòa nhà, căn hộ, vị trí...",
                          hintStyle: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _handleSendMessage(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E293B), Color(0xFF334155)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E293B).withAlpha(76),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(RagChatMessage msg, {bool isStreamingThisMsg = false}) {
    final timeStr = DateFormat('HH:mm').format(msg.timestamp);

    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(
                msg.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent_rounded, // Icon AI Chatbot mới
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4EEE6),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    border: Border.all(color: const Color(0xFFE5DECE), width: 0.6),
                  ),
                  child: msg.text.isEmpty && isStreamingThisMsg
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          child: _MessengerTypingDots(),
                        )
                      : Text(
                          msg.text + (isStreamingThisMsg ? " ▌" : ""),
                          style: const TextStyle(
                            color: Color(0xFF1A1918),
                            fontSize: 14,
                            height: 1.45,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hiệu ứng 3 dấu chấm nhảy động phong cách Messenger / iMessage
class _MessengerTypingDots extends StatefulWidget {
  const _MessengerTypingDots();

  @override
  State<_MessengerTypingDots> createState() => _MessengerTypingDotsState();
}

class _MessengerTypingDotsState extends State<_MessengerTypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final double rawVal = (_controller.value - delay) % 1.0;
            final double value = rawVal < 0 ? rawVal + 1.0 : rawVal;
            final double bounce = (value >= 0 && value <= 0.5)
                ? (1.0 - ((value - 0.25).abs() * 4))
                : 0.0;
            final double offsetY = -5.0 * bounce.clamp(0.0, 1.0);
            final double opacity = 0.35 + (0.65 * bounce.clamp(0.0, 1.0));

            return Transform.translate(
              offset: Offset(0, offsetY),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: const Color(0xFF64748B).withAlpha((255 * opacity).round()),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
