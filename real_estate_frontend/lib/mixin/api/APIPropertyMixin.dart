import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:real_estate_frontend/dto/PropertyDTO.dart';
import 'package:real_estate_frontend/dto/PropertyPageResponseDTO.dart';
import 'package:real_estate_frontend/dto/PropertyRequestDTO.dart';
import 'package:shared_preferences/shared_preferences.dart';

Set<int> userFavoriteIds = {};

mixin ApiPropertyMixin {
  final String baseUrl = "http://10.0.2.2:8080/api";

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
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/secure/properties'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> responseData = jsonDecode(decodedBody);

        if (responseData['data'] != null && responseData['data'] is List) {
          List<dynamic> dataList = responseData['data'];
          return dataList.map((json) => PropertyDTO.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint('Lỗi fetchMyProperties: $e');
    }
    return [];
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

      if (property.id != null) {
        request.fields['id'] = property.id.toString();
      }
      if (property.typeId != null) {
        request.fields['typeId'] = property.typeId.toString();
      }
      if (property.categoryId != null) {
        request.fields['categoryId'] = property.categoryId.toString();
      }
      if (property.title != null && property.title!.isNotEmpty) {
        request.fields['title'] = property.title!;
      }
      if (property.description != null && property.description!.isNotEmpty) {
        request.fields['description'] = property.description!;
      }
      if (property.address != null && property.address!.isNotEmpty) {
        request.fields['address'] = property.address!;
      }
      if (property.city != null && property.city!.isNotEmpty) {
        request.fields['city'] = property.city!;
      }
      if (property.wardId != null) {
        request.fields['wardId'] = property.wardId.toString();
      }
      if (property.addressDetail != null && property.addressDetail!.isNotEmpty) {
        request.fields['addressDetail'] = property.addressDetail!;
      }
      if (property.price != null) {
        request.fields['price'] = property.price.toString();
      }
      if (property.area != null) {
        request.fields['area'] = property.area.toString();
      }
      if (property.floorCount != null) {
        request.fields['floorCount'] = property.floorCount.toString();
      }
      if (property.bedroomCount != null) {
        request.fields['bedroomCount'] = property.bedroomCount.toString();
      }
      if (property.bathroomCount != null) {
        request.fields['bathroomCount'] = property.bathroomCount.toString();
      }
      if (property.direction != null && property.direction!.isNotEmpty) {
        request.fields['direction'] = property.direction!;
      }
      if (property.legal != null && property.legal!.isNotEmpty) {
        request.fields['legal'] = property.legal!;
      }
      if (property.status != null && property.status!.isNotEmpty) {
        request.fields['status'] = property.status!;
      }

      if (property.images != null && property.images!.isNotEmpty) {
        for (var i = 0; i < property.images!.length; i++) {
          request.fields['images[$i]'] = property.images![i];
        }
      }

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

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> responseData = jsonDecode(decodedBody);
        return {'success': true, 'data': responseData['data']};
      } else {
        final decodedBody = utf8.decode(response.bodyBytes);
        debugPrint('Save property failed: ${response.statusCode} - $decodedBody');
        return {
          'success': false,
          'message': 'Đã xảy ra lỗi (${response.statusCode}): $decodedBody'
        };
      }
    } catch (e) {
      debugPrint('Lỗi saveProperty: $e');
      return {'success': false, 'message': 'Lỗi kết nối máy chủ: $e'};
    }
  }
}
