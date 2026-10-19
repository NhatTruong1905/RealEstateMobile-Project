// ignore_for_file: library_private_types_in_public_api
part of '../ChatService.dart';

extension ChatInteractionSync on ChatService {
  Future<bool> consolidateAndSaveInteraction({
    required int propertyId,
    required int senderId,
    required int receiverId,
    required List<ChatMessageDTO> messages,
    bool isAppointmentAccepted = true,
  }) async {
    if (messages.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final sb = StringBuffer();
    for (final m in messages) {
      if (m.text == '__SYS_ACCEPT_APPOINTMENT__' ||
          m.text == '__SYS_CANCEL_APPOINTMENT__' ||
          m.text == '__SYS_COMPLETE_VIEWING__') {
        continue;
      }
      final timeStr = m.timestamp ?? '';
      final senderTag = (m.getSenderId == senderId)
          ? "Người dùng"
          : "Chủ BĐS/Đối tác";
      if (sb.isNotEmpty) sb.writeln();
      sb.write("[$timeStr] $senderTag: ${m.text}");
    }

    final interactionBody = {
      'propertyId': propertyId,
      'senderId': senderId,
      'receiverId': receiverId,
      'interactionTypeCode': 'MESSAGE',
      'code': 'MESSAGE',
      'interactionTypeId': 2,
      'message': sb.toString(),
    };

    final url = "$_baseUrl/secure/interactions";
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(interactionBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Đã lưu thành công bản ghi Interaction tổng hợp vào DB!');
        await clearLocalChatSession(propertyId, receiverId);
        final key = _getAcceptanceKey(propertyId, receiverId);
        await prefs.remove(key);
        return true;
      }
    } catch (e) {
      debugPrint('Lỗi consolidateAndSaveInteraction: $e');
    }
    return false;
  }
}
