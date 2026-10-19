// ignore_for_file: library_private_types_in_public_api
part of '../ChatService.dart';

extension ChatLocalSessions on ChatService {
  String _getSessionKey(int propertyId, int? receiverId) {
    return 'chat_session_${propertyId}_${receiverId ?? 0}';
  }

  Future<void> saveLocalChatSession(
    int propertyId,
    int? receiverId,
    List<ChatMessageDTO> messages, {
    String? partnerName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getSessionKey(propertyId, receiverId);
      final existingStr = prefs.getString(key);

      int startTime = DateTime.now().millisecondsSinceEpoch;
      String? existingPartnerName;

      if (existingStr != null) {
        try {
          final existingMap = jsonDecode(existingStr);
          if (existingMap['startTime'] != null) {
            startTime = existingMap['startTime'] as int;
          }
          if (existingMap['partnerName'] != null) {
            existingPartnerName = existingMap['partnerName'] as String;
          }
        } catch (_) {}
      }

      final finalPartnerName = (partnerName != null && partnerName.isNotEmpty)
          ? partnerName
          : existingPartnerName;

      final sessionData = {
        'startTime': startTime,
        'propertyId': propertyId,
        'receiverId': receiverId,
        'partnerId': receiverId,
        if (finalPartnerName != null) 'partnerName': finalPartnerName,
        'messages': messages.map((m) => m.toJson()).toList(),
      };

      await prefs.setString(key, jsonEncode(sessionData));
      debugPrint(
        'Đã lưu phiên chat tạm thời vào Local Storage: $key (${messages.length} tin)',
      );
    } catch (e) {
      debugPrint('Lỗi saveLocalChatSession: $e');
    }
  }

  Future<List<ChatMessageDTO>> loadLocalChatSession(
    int propertyId,
    int? receiverId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getSessionKey(propertyId, receiverId);
      final str = prefs.getString(key);
      if (str == null || str.isEmpty) return [];

      final map = jsonDecode(str) as Map<String, dynamic>;
      final startTime = map['startTime'] as int? ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now - startTime > 86400000) {
        debugPrint(
          'Phiên chat local $key đã hết hạn 24h. Tiến hành tự động lưu DB...',
        );
        final rawMsgs = map['messages'] as List?;
        if (rawMsgs != null && rawMsgs.isNotEmpty) {
          final msgs = rawMsgs.map((m) => ChatMessageDTO.fromJson(m)).toList();
          final senderId = _currentUserId ?? msgs.first.getSenderId ?? 0;
          await consolidateAndSaveInteraction(
            propertyId: propertyId,
            senderId: senderId,
            receiverId: receiverId ?? 0,
            messages: msgs,
            isAppointmentAccepted: false,
          );
        }
        await prefs.remove(key);
        return [];
      }

      final rawMsgs = map['messages'] as List?;
      if (rawMsgs != null) {
        return rawMsgs.map((m) => ChatMessageDTO.fromJson(m)).toList();
      }
    } catch (e) {
      debugPrint('Lỗi loadLocalChatSession: $e');
    }
    return [];
  }

  Future<void> clearLocalChatSession(int propertyId, int? receiverId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getSessionKey(propertyId, receiverId);
      await prefs.remove(key);
      debugPrint('Đã làm sạch bộ nhớ tạm local chat $key');
    } catch (e) {
      debugPrint('Lỗi clearLocalChatSession: $e');
    }
  }
}
