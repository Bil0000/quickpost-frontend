import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:quickpost_flutter/models/post_model.dart';
import 'package:quickpost_flutter/utils/config.dart';

class PostService {
  final String baseUrl = AppConfig.baseUrl;

  final _storage = const FlutterSecureStorage();

  Future<List<Post>> fetchPosts() async {
    // Retrieve the access token from secure storage
    final accessToken = await _storage.read(key: 'accessToken');

    // Include the token in the header
    final response = await http.get(
      Uri.parse('$baseUrl/post/posts'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> responseData = json.decode(response.body);
      return responseData.map((data) => Post.fromJson(data)).toList();
    } else {
      throw Exception(
          'Failed to load posts, please try logging out and logging in again');
    }
  }

  Future<String> fetchUserFullName(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/auth/$userId'));
    if (response.statusCode == 200) {
      var userData = json.decode(response.body);
      return userData['fullname'];
    } else {
      throw Exception('Failed to fetch user data');
    }
  }

  // Future<http.Response> createPost(String caption, [String? imagePath]) async {
  //   final url = Uri.parse('$baseUrl/post/create');
  //   final accessToken = await _storage.read(key: 'accessToken');

  //   var request = http.MultipartRequest('POST', url)
  //     ..fields['caption'] = caption
  //     ..headers['Authorization'] = 'Bearer $accessToken';

  //   if (imagePath != null) {
  //     request.files.add(await http.MultipartFile.fromPath('image', imagePath));
  //   }

  //   var streamedResponse = await request.send();

  //   // Convert the streamed response to a http.Response object
  //   var response = await http.Response.fromStream(streamedResponse);

  //   // Check the status code of the response
  //   if (response.statusCode != 201) {
  //     throw Exception('Failed to create post');
  //   }

  //   // Return the response object
  //   return response;
  // }

  Future<http.Response> createPost(String caption,
      {String? imagePath, String? videoPath, String? gifUrl}) async {
    var url = Uri.parse('$baseUrl/post/create');
    final accessToken = await _storage.read(key: 'accessToken');
    var headers = {
      'Authorization': 'Bearer $accessToken',
    };

    // If there's a GIF URL, prioritize it over image and video paths.
    if (gifUrl != null) {
      var body = jsonEncode({
        'caption': caption,
        'gifUrl': gifUrl,
      });
      headers['Content-Type'] = 'application/json';
      return http.post(url, headers: headers, body: body);
    } else {
      var request = http.MultipartRequest('POST', url)
        ..fields['caption'] = caption
        ..headers.addAll(headers);
      if (imagePath != null) {
        request.files
            .add(await http.MultipartFile.fromPath('image', imagePath));
      } else if (videoPath != null) {
        request.files
            .add(await http.MultipartFile.fromPath('video', videoPath));
      }

      var streamedResponse = await request.send();
      return http.Response.fromStream(streamedResponse);
    }
  }

  Future<void> likePost(String postId) async {
    final url = Uri.parse('$baseUrl/post/$postId/like');

    final accessToken = await _storage.read(key: 'accessToken');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to like post');
    }
  }

  Future<void> unlikePost(String postId) async {
    final url = Uri.parse('$baseUrl/post/$postId/unlike');

    final accessToken = await _storage.read(key: 'accessToken');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to unlike post');
    }
  }

  Future<int> fetchPostCount(String userId) async {
    final url = '$baseUrl/post/user/$userId/post-count';
    final token = await _storage.read(key: 'accessToken');
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['postCount'];
    } else {
      throw Exception('Failed to load post count');
    }
  }

  Future<List<Post>> fetchUserPosts(String userId) async {
    final accessToken = await _storage.read(key: 'accessToken');
    final response = await http.get(
      Uri.parse('$baseUrl/post/user/$userId/posts'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> responseData = json.decode(response.body);
      return responseData.map((data) => Post.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load user posts');
    }
  }

  Future<void> deletePost(String postId) async {
    final url = Uri.parse('$baseUrl/post/delete/$postId');

    // Retrieve the access token from secure storage
    final accessToken = await _storage.read(key: 'accessToken');

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete post');
    }
  }

  Future<http.Response> editPost(String postId, String caption) async {
    final url = Uri.parse('$baseUrl/post/edit/$postId');

    // Retrieve the access token from secure storage
    final accessToken = await _storage.read(key: 'accessToken');

    final Map<String, dynamic> postData = {
      'caption': caption,
    };

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(postData),
    );

    return response;
  }

  Future<List<Post>> fetchPostsByHashtag(String hashtag) async {
    final url = Uri.parse('$baseUrl/post/hashtag/$hashtag');
    final accessToken = await _storage.read(key: 'accessToken');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> responseData = json.decode(response.body);
      return responseData.map((data) => Post.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load posts by hashtag');
    }
  }

  Future<http.Response> markPostSeen(String postId) async {
    final url = '$baseUrl/post/$postId/seen';
    final token = await _storage.read(key: 'accessToken');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return response;
  }

  Future<Post> getPostById(String postId) async {
    final accessToken = await _storage.read(key: 'accessToken');
    final response = await http.get(
      Uri.parse('$baseUrl/post/$postId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      return Post.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load post');
    }
  }
}
