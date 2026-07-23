import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:real_estate_frontend/dto/UserDTO.dart';
import 'package:shared_preferences/shared_preferences.dart';

mixin ApiLoginMixin {
  final String baseUrl = "http://10.0.2.2:8080/api";

  Future<bool> login(String username, String password) async {
    final url = Uri.parse("$baseUrl/auth/login");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String? token = data['token'];

        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token);
          await prefs.setString('username', username);
          await prefs.setBool('is_logged_in', true);

          try {
            final profileResponse = await http.get(
              Uri.parse("$baseUrl/secure/profile"),
              headers: {
                "Content-Type": "application/json; charset=UTF-8",
                "Authorization": "Bearer $token",
              },
            );

            if (profileResponse.statusCode == 200) {
              final decodedBody = utf8.decode(profileResponse.bodyBytes);
              final profileData = jsonDecode(decodedBody)['data'];

              if (profileData != null) {
                UserDTO user = UserDTO.fromJson(profileData);
                String userJsonString = jsonEncode(user.toJson());

                await prefs.setString('user_profile', userJsonString);
              }
            }
          } catch (e) {
            print("Lỗi khi lấy thông tin Profile lúc đăng nhập: $e");
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      print("Lỗi API Login: $e");
      return false;
    }
  }

  Future<String?> registerUser({
    required String fullname,
    required String username,
    required String password,
    required String email,
    required String phone,
  }) async {
    final url = Uri.parse("$baseUrl/auth/register");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fullname": fullname,
          "username": username,
          "password": password,
          "email": email,
          "phone": phone,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return null;
      }

      final decodedBody = utf8.decode(response.bodyBytes);
      final errorData = jsonDecode(decodedBody);

      if (errorData is Map) {
        if (errorData.containsKey('message') && errorData['message'] != null) {
          return errorData['message'].toString();
        }

        List<String> errorMessages = [];
        errorData.forEach((key, value) {
          errorMessages.add("- $value");
        });

        if (errorMessages.isNotEmpty) {
          return errorMessages.join('\n');
        }
      }
      return "Đã xảy ra lỗi hệ thống (${response.statusCode})";
    } catch (e) {
      debugPrint("Lỗi API Đăng ký: $e");
      return "Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng!";
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<Map<String, String>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();

    String token = prefs.getString('jwt_token') ?? '';
    String username = prefs.getString('username') ?? '';

    String fullname = '';
    String email = '';
    String avatar = '';
    String phone = '';

    String? userProfileJson = prefs.getString('user_profile');
    if (userProfileJson != null && userProfileJson.isNotEmpty) {
      try {
        Map<String, dynamic> userMap = jsonDecode(userProfileJson);
        fullname = userMap['fullname'] ?? userMap['fullName'] ?? '';
        email = userMap['email'] ?? '';
        avatar = userMap['avatar'] ?? '';
        phone = userMap['phone'] ?? '';
        username = userMap['username'] ?? username;
      } catch (e) {
        debugPrint("Lỗi parse user_profile trong getUserInfo: $e");
      }
    }
    return {
      'username': username,
      'token': token,
      'fullname': fullname,
      'email': email,
      'avatar': avatar,
      'phone': phone,
    };
  }
}
