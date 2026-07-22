import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../dto/UserDTO.dart';

mixin ApiUserMixin {
  final String baseUrl = "http://10.0.2.2:8080/api";

  Future<UserDTO?> getProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        debugPrint('Không tìm thấy Token.');
        return null;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/secure/profile'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final responseData = jsonDecode(decodedBody);

        if (responseData['data'] != null) {
          return UserDTO.fromJson(responseData['data']);
        }
      } else {
        debugPrint('Lỗi API: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      debugPrint('Lỗi gọi API getProfile: $e');
      return null;
    }
  }

  Future<bool> updateProfile({
    required String username,
    required String fullname,
    required String phone,
    required String email,
    String? password, // THÊM THAM SỐ PASSWORD (Có thể null)
    File? avatarFile,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) return false;

      final url = Uri.parse('$baseUrl/secure/update/profile');
      var request = http.MultipartRequest('POST', url);
      request.headers.addAll({'Authorization': 'Bearer $token'});

      // Map đúng tên với UserInfoDTO.java
      request.fields['username'] = username;
      request.fields['fullname'] = fullname;
      request.fields['phone'] = phone;
      request.fields['email'] = email;

      // Nếu có nhập password mới thì mới nhét vào form gửi lên
      if (password != null && password.isNotEmpty) {
        request.fields['password'] = password;
      }

      if (avatarFile != null) {
        var multipartFile = await http.MultipartFile.fromPath(
          'file',
          avatarFile.path,
        );
        request.files.add(multipartFile);
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Lỗi Cập nhật: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Exception updateProfile: $e');
      return false;
    }
  }
}
