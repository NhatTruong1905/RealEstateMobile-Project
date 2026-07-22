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

  // ĐỔI KIỂU TRẢ VỀ TỪ Future<bool> THÀNH Future<String?>
  Future<String?> updateProfile({
    required String username,
    required String fullname,
    required String phone,
    required String email,
    String? password,
    File? avatarFile,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) return "Lỗi: Không tìm thấy Token xác thực.";

      final url = Uri.parse('$baseUrl/secure/update/profile');
      var request = http.MultipartRequest('POST', url);
      request.headers.addAll({'Authorization': 'Bearer $token'});

      request.fields['username'] = username;
      request.fields['fullname'] = fullname;
      request.fields['phone'] = phone;
      request.fields['email'] = email;

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

      // Gửi request
      var response = await request.send();

      if (response.statusCode == 200) {
        return null; // Trả về null nghĩa là THÀNH CÔNG
      } else {
        // Đọc dữ liệu stream từ MultipartRequest trả về
        final responseBody = await response.stream.bytesToString();
        try {
          final errorData = jsonDecode(responseBody);

          if (errorData is Map) {
            // Nếu có lỗi dạng Custom Exception
            if (errorData.containsKey('message') &&
                errorData['message'] != null) {
              return errorData['message'].toString();
            }

            // Nếu có lỗi từ @Valid (BindingResult)
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
          debugPrint("Lỗi Parse Error Body Cập nhật: $e");
          return "Cập nhật thất bại. Trạng thái: ${response.statusCode}";
        }
      }
    } catch (e) {
      debugPrint('Exception updateProfile: $e');
      return "Không thể kết nối đến máy chủ!";
    }
  }
}
