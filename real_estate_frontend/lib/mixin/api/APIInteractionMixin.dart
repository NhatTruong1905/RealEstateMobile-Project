import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

mixin ApiInteractionMixin {
  final String baseUrl = "http://10.0.2.2:8080/api";

  /// Lấy danh sách tương tác của user hiện tại đối với bất động sản [propertyId]
  Future<List<Map<String, dynamic>>> fetchPropertyInteractions(int propertyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      // 1. Gọi trực tiếp endpoint secure /secure/interactions/property/{propertyId} khi có token
      var uri = Uri.parse('$baseUrl/secure/interactions/property/$propertyId');
      var response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      // 2. Thử sang endpoint public nếu secure 404/401
      if (response.statusCode != 200) {
        uri = Uri.parse('$baseUrl/interactions/property/$propertyId');
        response = await http.get(
          uri,
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        );
      }

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final responseData = jsonDecode(decodedBody);
        dynamic data = responseData['data'] ?? responseData;

        // Giải nén nếu Backend trả về dạng phân trang { "data": { "content": [...] } }
        if (data is Map<String, dynamic> && data['content'] is List) {
          data = data['content'];
        }

        if (data is List) {
          debugPrint('fetchPropertyInteractions thành công: ${data.length} items');
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map<String, dynamic>) {
          debugPrint('fetchPropertyInteractions thành công: 1 item object');
          return [data];
        }
      }
    } catch (e) {
      debugPrint('Lỗi fetchPropertyInteractions: $e');
    }
    return [];
  }

  /// Lấy senderId từ cache hoặc gọi /secure/profile nếu chưa có
  Future<int?> _getSenderId(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final userProfileStr = prefs.getString('user_profile');
    if (userProfileStr != null) {
      try {
        final userMap = jsonDecode(userProfileStr) as Map<String, dynamic>;
        final id = (userMap['id'] as num?)?.toInt();
        if (id != null) return id;
      } catch (e) {
        debugPrint('Lỗi parse user_profile: $e');
      }
    }

    // Nếu không tìm thấy id trong cache, gọi API lấy profile trực tiếp
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/secure/profile'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );
      if (res.statusCode == 200) {
        final decoded = utf8.decode(res.bodyBytes);
        final data = jsonDecode(decoded)['data'];
        if (data != null && data['id'] != null) {
          final id = (data['id'] as num).toInt();
          await prefs.setString('user_profile', jsonEncode(data));
          return id;
        }
      }
    } catch (e) {
      debugPrint('Lỗi fetch profile khi lấy senderId: $e');
    }
    return null;
  }

  /// Tạo interaction với CODE ('CALL', 'VIEWING', 'MESSAGE') kèm message
  Future<bool> createInteraction({
    required int propertyId,
    required int receiverId,
    required String code,
    String? message,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) {
        debugPrint('createInteraction thất bại: jwt_token null (chưa đăng nhập)');
        return false;
      }

      final senderId = await _getSenderId(token);
      if (senderId == null) {
        debugPrint('createInteraction thất bại: không lấy được senderId');
        return false;
      }

      final bodyMap = {
        'propertyId': propertyId,
        'receiverId': receiverId,
        'senderId': senderId,
        'interactionTypeCode': code,
        'code': code,
        if (message != null && message.isNotEmpty) 'message': message,
      };

      final body = jsonEncode(bodyMap);
      debugPrint('Gửi API createInteraction ($code): $body');

      final response = await http.post(
        Uri.parse('$baseUrl/secure/interactions'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      debugPrint('Response createInteraction status: ${response.statusCode}, body: ${response.body}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Lỗi createInteraction: $e');
      return false;
    }
  }
}
