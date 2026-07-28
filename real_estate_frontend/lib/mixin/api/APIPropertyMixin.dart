import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:real_estate_frontend/dto/PropertyDTO.dart';
import 'package:real_estate_frontend/dto/PropertyPageResponseDTO.dart';
import 'package:real_estate_frontend/dto/PropertyRequestDTO.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Biến toàn cục lưu trữ tất cả các ID bất động sản đã thả tim của user đăng nhập
Set<int> userFavoriteIds = {};

mixin ApiPropertyMixin {
  final String baseUrl = "http://10.0.2.2:8080/api";

  Future<PropertyPageResponseDTO?> fetchPropertiesPage(
      {PropertyRequestDTO? request}) async {
    try {
      final queryParams =
          request?.toQueryParams() ?? {'page': '1', 'limit': '6'};
      final uri =
          Uri.parse('$baseUrl/properties').replace(queryParameters: queryParams);

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

  Future<List<PropertyDTO>> fetchProperties(
      {PropertyRequestDTO? request}) async {
    final pageResponse = await fetchPropertiesPage(request: request);
    return pageResponse?.content ?? [];
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
          List<PropertyDTO> favList =
              dataList.map((json) => PropertyDTO.fromJson(json)).toList();

          // Cập nhật tập hợp userFavoriteIds toàn cục
          userFavoriteIds =
              favList.map((e) => e.id!).whereType<int>().toSet();
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
}
