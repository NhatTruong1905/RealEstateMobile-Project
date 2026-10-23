import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:real_estate_frontend/dto/PropertyDTO.dart';
import 'package:real_estate_frontend/dto/PropertyPageResponseDTO.dart';
import 'package:real_estate_frontend/dto/PropertyRequestDTO.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:real_estate_frontend/config/AppConfig.dart';

Set<int> userFavoriteIds = {};
const receivedPropertyMessage =
    'Hệ thống đã tiếp nhận bài đăng của bạn. Bài đăng đang chờ nhân viên xét duyệt và chưa được công khai. Thông báo sẽ được gửi tới email đăng ký.';

String propertyApiError(int status, dynamic body) {
  const hints = {
    401: 'Vui lòng đăng nhập lại.',
    403: 'Bạn không có quyền thao tác.',
    404: 'Không tìm thấy tin đăng.',
    409: 'Tin đã thay đổi. Vui lòng tải lại trước khi thao tác.',
  };
  if (hints.containsKey(status)) return hints[status]!;
  if (body is Map) {
    final fields = body['data'] is Map ? body['data'] as Map : body;
    final messages = fields.entries
        .where((e) => e.value is String && e.key != 'detail')
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');
    return messages.isNotEmpty
        ? messages
        : body['message']?.toString() ?? 'Yêu cầu không hợp lệ ($status)';
  }
  return body is List
      ? body.join('\n')
      : 'Không thể hoàn tất yêu cầu ($status).';
}

dynamic propertyResponseBody(String value) {
  try {
    return jsonDecode(value);
  } catch (_) {
    return value;
  }
}

mixin ApiPropertyMixin {
  http.Client? get propertyClient => null;
  String get baseUrl => AppConfig.springBootBaseUrl;

  Future<Map<String, dynamic>> fetchPropertyOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('Vui lòng đăng nhập.');
    final client = propertyClient ?? http.Client();
    late http.Response response;
    try {
      response = await client.get(
        Uri.parse('$baseUrl/secure/property-options'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } finally {
      if (propertyClient == null) client.close();
    }
    final body = propertyResponseBody(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200) {
      throw Exception(propertyApiError(response.statusCode, body));
    }
    return Map<String, dynamic>.from(body['data']);
  }

  Future<PropertyPageResponseDTO?> fetchPropertiesPage({
    PropertyRequestDTO? request,
  }) async {
    try {
      final queryParams =
          request?.toQueryParams() ?? {'page': '1', 'limit': '6'};
      final uri = Uri.parse(
        '$baseUrl/properties',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> responseData = jsonDecode(decodedBody);

        if (responseData['data'] is Map<String, dynamic>) {
          return PropertyPageResponseDTO.fromJson(responseData['data']);
        }
      }
    } catch (e) {
      debugPrint('Lỗi fetchPropertiesPage: $e');
    }
    return null;
  }

  Future<List<PropertyDTO>> fetchProperties({
    PropertyRequestDTO? request,
  }) async {
    final pageResponse = await fetchPropertiesPage(request: request);
    return pageResponse?.content ?? [];
  }

  Future<List<PropertyDTO>> fetchMyProperties() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) throw Exception('Vui lòng đăng nhập lại.');

      final response =
          await (propertyClient?.get(
                Uri.parse('$baseUrl/secure/properties'),
                headers: {'Authorization': 'Bearer $token'},
              ) ??
              http.get(
                Uri.parse('$baseUrl/secure/properties'),
                headers: {
                  'Content-Type': 'application/json; charset=UTF-8',
                  'Authorization': 'Bearer $token',
                },
              ));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> responseData = jsonDecode(decodedBody);

        if (responseData['data'] != null && responseData['data'] is List) {
          List<dynamic> dataList = responseData['data'];
          return dataList.map((json) => PropertyDTO.fromJson(json)).toList();
        }
      }
      throw Exception(
        propertyApiError(
          response.statusCode,
          propertyResponseBody(utf8.decode(response.bodyBytes)),
        ),
      );
    } catch (e) {
      debugPrint('Lỗi fetchMyProperties: $e');
      rethrow;
    }
  }

  Future<List<PropertyDTO>> fetchFavoriteProperties() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) {
        userFavoriteIds.clear();
        return [];
      }

      final response = await http.get(
        Uri.parse('$baseUrl/secure/favorite-properties'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> responseData = jsonDecode(decodedBody);
        if (responseData['data'] != null) {
          List<dynamic> dataList = responseData['data'];
          List<PropertyDTO> favList = dataList
              .map((json) => PropertyDTO.fromJson(json))
              .toList();

          userFavoriteIds = favList.map((e) => e.id!).whereType<int>().toSet();
          return favList;
        }
      }
    } catch (e) {
      debugPrint('Lỗi fetchFavoriteProperties: $e');
    }
    return [];
  }

  Future<void> syncFavoriteProperties(List<int> propertyIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) return;

      final bodyData = jsonEncode({"propertyIds": propertyIds});

      await http.post(
        Uri.parse('$baseUrl/secure/favorite-properties'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: bodyData,
      );
    } catch (e) {
      debugPrint('Lỗi syncFavoriteProperties: $e');
    }
  }

  Future<PropertyDTO?> fetchPropertyById(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.get(
        Uri.parse('$baseUrl/secure/properties/$id'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> responseData = jsonDecode(decodedBody);

        if (responseData['data'] != null &&
            responseData['data'] is Map<String, dynamic>) {
          PropertyDTO dto = PropertyDTO.fromJson(responseData['data']);
          if (dto.id != null) {
            dto.isSaved = userFavoriteIds.contains(dto.id);
          }
          return dto;
        }
      }
    } catch (e) {
      debugPrint('Lỗi fetchPropertyById: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>> saveProperty(
    PropertyDTO property, {
    List<File>? imageFiles,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) {
        return {'success': false, 'message': 'Chưa đăng nhập'};
      }

      final uri = Uri.parse('$baseUrl/secure/properties');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';

      request.fields.addAll(property.toFields());
      request.fields.remove('userId');
      request.fields.remove('status');

      if (imageFiles != null && imageFiles.isNotEmpty) {
        for (var i = 0; i < imageFiles.length && i < 5; i++) {
          final file = imageFiles[i];
          final multipartFile = await http.MultipartFile.fromPath(
            'files',
            file.path,
          );
          request.files.add(multipartFile);
        }
      }

      final streamedResponse =
          await (propertyClient?.send(request) ?? request.send());
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> responseData = jsonDecode(decodedBody);
        final data = responseData['data'];
        if (data is! Map || data['id'] == null || data['status'] == null) {
          return {
            'success': false,
            'message':
                'Máy chủ chưa xác nhận tin. Kiểm tra Tin đăng trước khi thử lại.',
          };
        }
        return {'success': true, 'data': data};
      } else {
        final decodedBody = utf8.decode(response.bodyBytes);
        debugPrint(
          'Save property failed: ${response.statusCode} - $decodedBody',
        );
        return {
          'success': false,
          'message': propertyApiError(
            response.statusCode,
            propertyResponseBody(decodedBody),
          ),
        };
      }
    } catch (e) {
      debugPrint('Lỗi saveProperty: $e');
      return {
        'success': false,
        'message':
            'Lỗi kết nối máy chủ. Dữ liệu được giữ lại; hãy kiểm tra Tin đăng trước khi thử lại để tránh tạo trùng.',
      };
    }
  }

  Future<bool> deleteProperty(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$baseUrl/secure/properties/$id'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint(
          'Lỗi deleteProperty (${response.statusCode}): ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Lỗi deleteProperty: $e');
      return false;
    }
  }
}
