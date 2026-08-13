import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RagChatMessage {
  String text;
  final bool isUser;
  final DateTime timestamp;

  RagChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Kiểm tra tin nhắn có hợp lệ để đưa vào Lịch sử gửi cho AI LLM hay không
  bool get isValidForHistory {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.startsWith("Lỗi kết nối") ||
        trimmed.startsWith("Không thể kết nối") ||
        trimmed.startsWith("Lỗi hệ thống") ||
        trimmed.startsWith("Đã làm sạch cuộc trò chuyện")) {
      return false;
    }
    return true;
  }

  /// Chuyển đổi sang format JSON chuẩn `MessageItem` mà backend FastAPI yêu cầu ({role, content})
  Map<String, String>? toApiMessage() {
    if (!isValidForHistory) return null;
    return {
      'role': isUser ? 'user' : 'assistant',
      'content': text.trim(),
    };
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
      };

  factory RagChatMessage.fromJson(Map<String, dynamic> json) => RagChatMessage(
        text: json['text'] as String? ?? '',
        isUser: json['isUser'] as bool? ?? false,
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

class RagChatService {
  static final RagChatService _instance = RagChatService._internal();
  factory RagChatService() => _instance;
  RagChatService._internal();

  String _baseUrl = "http://10.0.2.2:8000/api";
  static const String _storageKey = "rag_chat_history_v1";

  /// Cho phép cấu hình Host/Port linh hoạt nếu cần
  void configureHost(String host, {int port = 8000}) {
    _baseUrl = "http://$host:$port/api";
  }

  /// Chuyển đổi danh sách tin nhắn thành history payload theo đúng format backend (`List<MessageItem>`)
  List<Map<String, String>>? _buildHistoryPayload(List<RagChatMessage>? history) {
    if (history == null || history.isEmpty) return null;

    final validMessages = history
        .map((m) => m.toApiMessage())
        .whereType<Map<String, String>>()
        .toList();

    if (validMessages.isEmpty) return null;

    // Giới hạn lấy tối đa 15 tin nhắn gần nhất để tối ưu kích thước HTTP payload
    if (validMessages.length > 15) {
      return validMessages.sublist(validMessages.length - 15);
    }
    return validMessages;
  }

  /// Stream câu trả lời từ Chatbot RAG backend (real-estate-ai) theo thời gian thực (Token-by-token)
  Stream<String> streamQuestion(String question, {List<RagChatMessage>? history}) async* {
    if (question.trim().isEmpty) {
      yield "Câu hỏi không được để trống.";
      return;
    }

    final candidateUrls = {
      "$_baseUrl/chat-rag/stream",
      "http://10.0.2.2:8000/api/chat-rag/stream",
      "http://localhost:8000/api/chat-rag/stream",
      "http://127.0.0.1:8000/api/chat-rag/stream",
    }.toList();

    bool streamSuccess = false;
    final historyList = _buildHistoryPayload(history);

    final payloadMap = <String, dynamic>{
      "question": question.trim(),
    };
    if (historyList != null && historyList.isNotEmpty) {
      payloadMap["history"] = historyList;
    }
    final jsonPayload = jsonEncode(payloadMap);

    for (final url in candidateUrls) {
      try {
        debugPrint("Đang kết nối Stream Chatbot RAG: $url");
        final request = http.Request('POST', Uri.parse(url));
        request.headers['Content-Type'] = 'application/json; charset=UTF-8';
        request.body = jsonPayload;

        final streamedResponse = await request.send().timeout(const Duration(seconds: 10));

        if (streamedResponse.statusCode == 200) {
          _baseUrl = url.replaceAll('/chat-rag/stream', '');
          streamSuccess = true;

          // Đọc từng token chunk nhận về từ server
          await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
            if (chunk.isNotEmpty) {
              yield chunk;
            }
          }
          break;
        }
      } catch (e) {
        debugPrint("Thử kết nối RAG Stream thất bại tại $url: $e");
      }
    }

    // Nếu tất cả các URL stream đều lỗi -> Fallback sang API thường (non-stream)
    if (!streamSuccess) {
      debugPrint("Đang chuyển sang phương thức Fallback (Non-stream)...");
      final fallbackAnswer = await askQuestion(question, history: history);
      yield fallbackAnswer;
    }
  }

  /// Gửi câu hỏi theo kiểu Non-stream (Fallback)
  Future<String> askQuestion(String question, {List<RagChatMessage>? history}) async {
    if (question.trim().isEmpty) {
      return "Câu hỏi không được để trống.";
    }

    final candidateUrls = {
      "$_baseUrl/chat-rag",
      "http://10.0.2.2:8000/api/chat-rag",
      "http://localhost:8000/api/chat-rag",
      "http://127.0.0.1:8000/api/chat-rag",
    }.toList();

    final historyList = _buildHistoryPayload(history);

    final payloadMap = <String, dynamic>{
      "question": question.trim(),
    };
    if (historyList != null && historyList.isNotEmpty) {
      payloadMap["history"] = historyList;
    }
    final bodyJson = jsonEncode(payloadMap);

    for (final url in candidateUrls) {
      try {
        debugPrint("Đang kết nối tới Chatbot RAG (Fallback): $url");
        final response = await http.post(
          Uri.parse(url),
          headers: {"Content-Type": "application/json; charset=UTF-8"},
          body: bodyJson,
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final decoded = utf8.decode(response.bodyBytes);
          final map = jsonDecode(decoded) as Map<String, dynamic>;
          final answer = map['answer'] as String?;
          if (answer != null && answer.isNotEmpty) {
            _baseUrl = url.replaceAll('/chat-rag', '');
            return answer;
          }
        }
      } catch (e) {
        debugPrint("Thử kết nối RAG thất bại tại $url: $e");
      }
    }

    return "Không thể kết nối tới Chatbot RAG. Vui lòng đảm bảo dịch vụ AI tại backend (real-estate-ai) trên cổng 8000 đang hoạt động.";
  }

  // =========================================================================
  // BỘ BỘ NHỚ LƯU TRỮ LỊCH SỬ CHAT (SHARED PREFERENCES PERSISTENCE)
  // =========================================================================

  /// Lưu danh sách tin nhắn vào SharedPreferences (lọc bỏ các tin nhắn lỗi hoặc rỗng)
  Future<void> saveHistory(List<RagChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final validToSave = messages.where((m) => m.isValidForHistory).toList();
      final listJson = validToSave.map((m) => m.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(listJson));
      debugPrint("Đã lưu ${validToSave.length} tin nhắn RAG vào bộ nhớ máy.");
    } catch (e) {
      debugPrint("Lỗi lưu lịch sử RAG chat: $e");
    }
  }

  /// Nạp danh sách tin nhắn từ SharedPreferences
  Future<List<RagChatMessage>> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_storageKey);
      if (str != null && str.isNotEmpty) {
        final list = jsonDecode(str) as List;
        return list.map((item) => RagChatMessage.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint("Lỗi nạp lịch sử RAG chat: $e");
    }
    return [];
  }

  /// Xóa toàn bộ lịch sử RAG chat trong SharedPreferences
  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      debugPrint("Đã làm sạch lịch sử RAG chat khỏi SharedPreferences.");
    } catch (e) {
      debugPrint("Lỗi xóa lịch sử RAG chat: $e");
    }
  }
}

