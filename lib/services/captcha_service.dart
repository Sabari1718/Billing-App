import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class CaptchaCategory {
  final int id;
  final String categoryName;
  final String image;

  CaptchaCategory({
    required this.id,
    required this.categoryName,
    required this.image,
  });

  factory CaptchaCategory.fromJson(Map<String, dynamic> json) {
    return CaptchaCategory(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      categoryName: json['category_name']?.toString() ?? json['categoryName']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
    );
  }
}

class CaptchaService {
  static const String _categoriesUrl =
      'https://managelogin.jobes24x7.com/api/outsideapis/captcha/category';

  Future<List<CaptchaCategory>> getCategories() async {
    try {
      debugPrint('[CaptchaService] Fetching captcha categories from API: $_categoriesUrl');
      final response = await http
          .get(Uri.parse(_categoriesUrl))
          .timeout(const Duration(seconds: 15));

      debugPrint('[CaptchaService] Response Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] != null) {
          final List<dynamic> data = decoded['data'];
          final categories = data
              .map((json) => CaptchaCategory.fromJson(json))
              .toList();
          categories.shuffle();
          debugPrint('[CaptchaService] Successfully loaded ${categories.length} categories from API.');
          return categories;
        } else {
          throw Exception(decoded['message'] ?? 'Failed to load categories from API');
        }
      } else {
        throw Exception('Failed to load categories from API. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching captcha categories from API: $e');
      rethrow;
    }
  }
}
