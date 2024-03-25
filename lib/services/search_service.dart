import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:quickpost_flutter/utils/config.dart';

class SearchService {
  final String baseUrl = AppConfig.baseUrl;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> search(String query) async {
    final accessToken = await _storage.read(key: 'accessToken');
    final response = await http.get(
      Uri.parse('$baseUrl/search?q=$query'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load search results');
    }
  }
}
