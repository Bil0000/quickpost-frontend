import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:quickpost_flutter/models/comment_model.dart';
import 'package:quickpost_flutter/utils/config.dart';

class CommentService {
  final String baseUrl = AppConfig.baseUrl;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Comment> submitComment(String postId, String text,
      [String? parentCommentId]) async {
    final accessToken = await _storage.read(key: 'accessToken');

    final response = await http.post(
      Uri.parse('$baseUrl/comments'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'text': text,
        'postId': postId,
        'parentCommentId': parentCommentId,
      }),
    );

    if (response.statusCode == 201) {
      // Assuming successful creation returns the created comment in the response body
      final Map<String, dynamic> data = json.decode(response.body);
      return Comment.fromJson(data);
    } else {
      throw Exception(
          "Failed to create comment. Status code: ${response.statusCode}");
    }
  }

  Future<void> deleteComment(String commentId) async {
    final accessToken = await _storage.read(key: 'accessToken');
    final response = await http.delete(
      Uri.parse('$baseUrl/comments/$commentId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode != 200) {
      // Consider logging the response body here to get more insight into the failure
      print('Failed to delete comment: ${response.body}');
      throw Exception('Failed to delete comment');
    }
  }

  Future<void> updateComment(String commentId, String text) async {
    final accessToken = await _storage.read(key: 'accessToken');
    final response = await http.patch(
      Uri.parse('$baseUrl/comments/$commentId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'text': text}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update comment');
    }
  }

  Future<List<Comment>> loadComments(String postId) async {
    final accessToken = await _storage.read(key: 'accessToken');
    final response = await http.get(
      Uri.parse('$baseUrl/posts/$postId/comments'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> commentsJson = json.decode(response.body);
      // Properly map each JSON object to a Comment instance
      final List<Comment> comments =
          commentsJson.map((json) => Comment.fromJson(json)).toList();
      return comments;
    } else {
      // Handle error
      throw Exception('Failed to load comments');
    }
  }

  Future<List<Comment>> fetchUserComments(String userId) async {
    final accessToken = await _storage.read(key: 'accessToken');
    final response = await http.get(
      Uri.parse('$baseUrl/comments/user/$userId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> responseData = json.decode(response.body);
      return responseData.map((data) => Comment.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load user comments');
    }
  }
}
