import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;
import 'package:real_estate_frontend/dto/UserDTO.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:real_estate_frontend/services/ChatService.dart';
import 'package:real_estate_frontend/config/AppConfig.dart';

mixin ApiLoginMixin {
  String get baseUrl => AppConfig.springBootBaseUrl;

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
                await ChatService().initGlobalConnection();
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

  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId:
            '776756757728-95h65i4coqrsdenn5poopd16nabphkp2.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return {'success': false, 'message': 'Đã hủy đăng nhập Google'};
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        return {'success': false, 'message': 'Không lấy được Google ID Token'};
      }

      final url = Uri.parse("$baseUrl/auth/google");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"idToken": idToken}),
      );

      return await _handleOAuthResponse(response, googleUser.email);
    } catch (e, stack) {
      debugPrint("Lỗi loginWithGoogle: $e\n$stack");
      return {
        'success': false,
        'message': 'Lỗi kết nối Google Sign-In: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> loginWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final String tokenString = accessToken.tokenString;

        final url = Uri.parse("$baseUrl/auth/facebook");
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"accessToken": tokenString}),
        );

        return await _handleOAuthResponse(response, null);
      } else if (result.status == LoginStatus.cancelled) {
        return {'success': false, 'message': 'Đã hủy đăng nhập Facebook'};
      } else {
        return {
          'success': false,
          'message': result.message ?? 'Đăng nhập Facebook thất bại',
        };
      }
    } catch (e) {
      debugPrint("Lỗi loginWithFacebook: $e");
      return {
        'success': false,
        'message': 'Lỗi kết nối Facebook Login: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> _handleOAuthResponse(
    http.Response response,
    String? fallbackUsername,
  ) async {
    try {
      final decodedBody = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> data = jsonDecode(decodedBody);

      if (response.statusCode == 200 && data['status'] == 'SUCCESS') {
        final String? token = data['token'];
        final userObj = data['user'];

        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token);

          String username = fallbackUsername ?? '';
          if (userObj != null &&
              userObj is Map &&
              userObj['username'] != null) {
            username = userObj['username'].toString();
          }
          await prefs.setString('username', username);
          await prefs.setBool('is_logged_in', true);

          if (userObj != null) {
            await prefs.setString('user_profile', jsonEncode(userObj));
          }

          http
              .get(
                Uri.parse("$baseUrl/secure/profile"),
                headers: {
                  "Content-Type": "application/json; charset=UTF-8",
                  "Authorization": "Bearer $token",
                },
              )
              .then((profileResponse) async {
                if (profileResponse.statusCode == 200) {
                  final profileDecoded = utf8.decode(profileResponse.bodyBytes);
                  final profileData = jsonDecode(profileDecoded)['data'];
                  if (profileData != null) {
                    UserDTO user = UserDTO.fromJson(profileData);
                    await prefs.setString(
                      'user_profile',
                      jsonEncode(user.toJson()),
                    );
                  }
                }
              })
              .catchError((e) {
                debugPrint("Lỗi sync profile ngầm: $e");
              });

          try {
            ChatService().initGlobalConnection();
          } catch (e) {
            debugPrint("Lỗi kết nối ChatService khi OAuth login: $e");
          }
          return {
            'success': true,
            'message': data['message'] ?? 'Đăng nhập thành công',
          };
        }
      }

      String errorMsg =
          data['message'] ?? 'Đăng nhập thất bại (${response.statusCode})';
      return {'success': false, 'message': errorMsg};
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi xử lý dữ liệu phản hồi từ máy chủ',
      };
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

  Future<Map<String, dynamic>> forgotPassword(
    String identifier, {
    String? email,
  }) async {
    final url = Uri.parse("$baseUrl/auth/forgot-password");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json; charset=UTF-8"},
        body: jsonEncode({
          "identifier": identifier,
          if (email != null && email.trim().isNotEmpty) "email": email.trim(),
        }),
      );

      final decodedBody = utf8.decode(response.bodyBytes);
      final dynamic data = jsonDecode(decodedBody);

      if (data is Map<String, dynamic>) {
        if (response.statusCode == 200) {
          return {
            'success': true,
            'status': data['status'],
            'hasEmail': data['hasEmail'] ?? true,
            'maskedEmail': data['maskedEmail'] ?? '',
            'identifier': data['identifier'] ?? identifier,
            'message': data['message'] ?? 'Thành công',
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Không tìm thấy tài khoản',
          };
        }
      }
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi máy chủ (${response.statusCode})',
      };
    } catch (e) {
      debugPrint("Lỗi forgotPassword: $e");
      return {
        'success': false,
        'message': 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng!',
      };
    }
  }

  Future<Map<String, dynamic>> verifyOtp(
    String identifier,
    String otp, {
    String? email,
  }) async {
    final url = Uri.parse("$baseUrl/auth/verify-otp");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json; charset=UTF-8"},
        body: jsonEncode({
          "identifier": identifier,
          "otp": otp,
          if (email != null && email.trim().isNotEmpty) "email": email.trim(),
        }),
      );

      final decodedBody = utf8.decode(response.bodyBytes);
      final dynamic data = jsonDecode(decodedBody);

      if (data is Map<String, dynamic>) {
        if (response.statusCode == 200 && data['status'] == 'SUCCESS') {
          return {
            'success': true,
            'resetToken': data['resetToken'],
            'message': data['message'] ?? 'Xác thực OTP thành công',
          };
        } else {
          return {
            'success': false,
            'message':
                data['message'] ?? 'Mã OTP không chính xác hoặc đã hết hạn',
          };
        }
      }
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi (${response.statusCode})',
      };
    } catch (e) {
      debugPrint("Lỗi verifyOtp: $e");
      return {
        'success': false,
        'message': 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng!',
      };
    }
  }

  Future<Map<String, dynamic>> resetPassword(
    String identifier,
    String resetToken,
    String newPassword, {
    String? email,
  }) async {
    final url = Uri.parse("$baseUrl/auth/reset-password");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json; charset=UTF-8"},
        body: jsonEncode({
          "identifier": identifier,
          "resetToken": resetToken,
          "newPassword": newPassword,
          if (email != null && email.trim().isNotEmpty) "email": email.trim(),
        }),
      );

      final decodedBody = utf8.decode(response.bodyBytes);
      final dynamic data = jsonDecode(decodedBody);

      if (data is Map<String, dynamic>) {
        if (response.statusCode == 200 && data['status'] == 'SUCCESS') {
          return {
            'success': true,
            'message': data['message'] ?? 'Đặt lại mật khẩu thành công!',
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Đặt lại mật khẩu thất bại',
          };
        }
      }
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi (${response.statusCode})',
      };
    } catch (e) {
      debugPrint("Lỗi resetPassword: $e");
      return {
        'success': false,
        'message': 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng!',
      };
    }
  }

  Future<void> logout() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
    await ChatService().disconnect();
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
