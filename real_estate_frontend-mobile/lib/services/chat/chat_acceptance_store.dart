// ignore_for_file: library_private_types_in_public_api
part of '../ChatService.dart';

extension ChatAcceptanceStore on ChatService {
  Future<bool> sendAcceptanceSignal({
    required int propertyId,
    required int senderId,
    required int receiverId,
  }) async {
    final acceptMsg = ChatMessageDTO(
      id: DateTime.now().millisecondsSinceEpoch % 1000000000,
      propertyId: propertyId,
      senderId: senderId,
      receiverId: receiverId,
      message: "__SYS_ACCEPT_APPOINTMENT__",
      timestamp: DateFormat('HH:mm').format(DateTime.now()),
    );
    return await sendMessage(acceptMsg);
  }

  Future<bool> sendCancelAcceptanceSignal({
    required int propertyId,
    required int senderId,
    required int receiverId,
  }) async {
    final cancelMsg = ChatMessageDTO(
      id: DateTime.now().millisecondsSinceEpoch % 1000000000,
      propertyId: propertyId,
      senderId: senderId,
      receiverId: receiverId,
      message: "__SYS_CANCEL_APPOINTMENT__",
      timestamp: DateFormat('HH:mm').format(DateTime.now()),
    );
    return await sendMessage(cancelMsg);
  }

  Future<bool> sendCompleteViewingSignal({
    required int propertyId,
    required int senderId,
    required int receiverId,
  }) async {
    final completeMsg = ChatMessageDTO(
      id: DateTime.now().millisecondsSinceEpoch % 1000000000,
      propertyId: propertyId,
      senderId: senderId,
      receiverId: receiverId,
      message: "__SYS_COMPLETE_VIEWING__",
      timestamp: DateFormat('HH:mm').format(DateTime.now()),
    );
    return await sendMessage(completeMsg);
  }

  String _getAcceptanceKey(int propertyId, int? receiverId) {
    if (receiverId == null || receiverId == 0) return '';
    return 'accept_state_${propertyId}_$receiverId';
  }

  Future<List<Map<String, dynamic>>> getAllChatCustomers() async {
    final List<Map<String, dynamic>> chatCustomers = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs
          .getKeys()
          .where((k) => k.startsWith('chat_session_'))
          .toList();

      for (final key in keys) {
        final str = prefs.getString(key);
        if (str == null || str.isEmpty) continue;
        try {
          final map = jsonDecode(str) as Map<String, dynamic>;
          final propertyId = map['propertyId'] as int?;
          final receiverId = map['receiverId'] as int?;
          final partnerId = map['partnerId'] as int? ?? receiverId;
          final storedPartnerName = map['partnerName'] as String?;

          final rawMsgs = map['messages'] as List?;
          if (rawMsgs == null || rawMsgs.isEmpty) continue;

          final msgs = rawMsgs.map((m) => ChatMessageDTO.fromJson(m)).toList();

          final normalMsgs = msgs
              .where((m) => !m.text.startsWith('__SYS_'))
              .toList();

          if (normalMsgs.isEmpty) continue;
          final displayMsg = normalMsgs.last;

          final partnerMsg = msgs.firstWhere(
            (m) => m.getSenderId != null && m.getSenderId != _currentUserId,
            orElse: () => displayMsg,
          );

          final customerId = (partnerId != null && partnerId != _currentUserId)
              ? partnerId
              : (partnerMsg.getSenderId != _currentUserId
                    ? partnerMsg.getSenderId
                    : receiverId);

          if (customerId == null || customerId == _currentUserId) continue;

          final customerName =
              (storedPartnerName != null && storedPartnerName.isNotEmpty)
              ? storedPartnerName
              : ((partnerMsg.senderName != null &&
                        partnerMsg.senderName!.isNotEmpty)
                    ? partnerMsg.senderName!
                    : 'Khách hàng #$customerId');

          chatCustomers.add({
            'senderId': customerId,
            'phone': 'Chưa cập nhật SĐT',
            'name': customerName,
            'latestPropertyId': propertyId,
            'latestPropertyTitle': 'Bất động sản quan tâm',
            'latestMessage': displayMsg.text,
            'latestTime': displayMsg.timestamp ?? 'Mới đây',
            'messageCount': normalMsgs.length,
          });
        } catch (e) {
          debugPrint('Lỗi parse chat session $key: $e');
        }
      }
    } catch (e) {
      debugPrint('Lỗi getAllChatCustomers: $e');
    }
    return chatCustomers;
  }

  Future<void> markViewingCompleted(int propertyId, int? receiverId) async {
    try {
      final key = _getAcceptanceKey(propertyId, receiverId);
      if (key.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'myAccept': false,
        'partnerAccept': false,
        'fullyAccepted': false,
        'isCompleted': true,
        'acceptTimestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(key, jsonEncode(data));
      debugPrint('Đã đánh dấu hoàn tất lượt xem nhà ($key)');
    } catch (e) {
      debugPrint('Lỗi markViewingCompleted: $e');
    }
  }

  Future<void> saveLocalAcceptance(
    int propertyId,
    int? receiverId, {
    bool? myAccept,
    bool? partnerAccept,
    bool? fullyAccepted,
  }) async {
    try {
      final key = _getAcceptanceKey(propertyId, receiverId);
      if (key.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final existingStr = prefs.getString(key);

      bool currentMy = false;
      bool currentPartner = false;
      bool currentFully = false;
      int acceptTimestamp = DateTime.now().millisecondsSinceEpoch;

      if (existingStr != null) {
        try {
          final map = jsonDecode(existingStr);
          currentMy = map['myAccept'] as bool? ?? false;
          currentPartner = map['partnerAccept'] as bool? ?? false;
          currentFully = map['fullyAccepted'] as bool? ?? false;
          if (map['acceptTimestamp'] != null) {
            acceptTimestamp = map['acceptTimestamp'] as int;
          }
        } catch (_) {}
      }

      if (myAccept != null) currentMy = myAccept;
      if (partnerAccept != null) currentPartner = partnerAccept;
      if (fullyAccepted != null) currentFully = fullyAccepted;

      final data = {
        'myAccept': currentMy,
        'partnerAccept': currentPartner,
        'fullyAccepted': currentFully || (currentMy && currentPartner),
        'isCompleted': false,
        'acceptTimestamp': acceptTimestamp,
      };

      await prefs.setString(key, jsonEncode(data));
      debugPrint('Đã lưu trạng thái chấp nhận 2 bên ($key): $data');
    } catch (e) {
      debugPrint('Lỗi saveLocalAcceptance: $e');
    }
  }

  Future<Map<String, dynamic>> loadLocalAcceptance(
    int propertyId,
    int? receiverId,
  ) async {
    try {
      final key = _getAcceptanceKey(propertyId, receiverId);
      if (key.isEmpty) {
        return {
          'myAccept': false,
          'partnerAccept': false,
          'fullyAccepted': false,
          'isCompleted': false,
          'acceptTimestamp': DateTime.now().millisecondsSinceEpoch,
        };
      }
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(key);
      if (str != null) {
        final map = jsonDecode(str) as Map<String, dynamic>;
        final isCompleted = map['isCompleted'] as bool? ?? false;
        if (isCompleted) {
          return {
            'myAccept': false,
            'partnerAccept': false,
            'fullyAccepted': false,
            'isCompleted': true,
            'acceptTimestamp': DateTime.now().millisecondsSinceEpoch,
          };
        }

        final myAccept = map['myAccept'] as bool? ?? false;
        final partnerAccept = map['partnerAccept'] as bool? ?? false;
        final fullyAccepted =
            map['fullyAccepted'] as bool? ?? (myAccept && partnerAccept);
        final acceptTimestamp =
            map['acceptTimestamp'] as int? ??
            DateTime.now().millisecondsSinceEpoch;
        return {
          'myAccept': myAccept,
          'partnerAccept': partnerAccept,
          'fullyAccepted': fullyAccepted,
          'isCompleted': false,
          'acceptTimestamp': acceptTimestamp,
        };
      }
    } catch (e) {
      debugPrint('Lỗi loadLocalAcceptance: $e');
    }
    return {
      'myAccept': false,
      'partnerAccept': false,
      'fullyAccepted': false,
      'isCompleted': false,
      'acceptTimestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Future<void> clearLocalAcceptance(int propertyId, int? receiverId) async {
    try {
      final key = _getAcceptanceKey(propertyId, receiverId);
      if (key.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      debugPrint('Đã xóa trạng thái chấp nhận $key');
    } catch (e) {
      debugPrint('Lỗi clearLocalAcceptance: $e');
    }
  }
}
