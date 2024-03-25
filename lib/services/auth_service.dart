import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:jwt_decode/jwt_decode.dart';
import 'package:quickpost_flutter/models/follower_model.dart';
import 'package:quickpost_flutter/models/following_model.dart';
import 'package:quickpost_flutter/models/user_model.dart';
import 'package:quickpost_flutter/utils/config.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  final String baseUrl = '${AppConfig.baseUrl}/auth'; // Server url

  Future<http.Response> registerUser(
      Map<String, dynamic> userData, File? profileImage) async {
    var uri = Uri.parse('$baseUrl/signup');
    var request = http.MultipartRequest('POST', uri)
      ..fields['username'] = userData['username']
      ..fields['email'] = userData['email']
      ..fields['password'] = userData['password']
      ..fields['fullname'] = userData['fullname']
      ..fields['bio'] = userData['bio'];

    if (profileImage != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'profileImage',
        profileImage.path,
      ));
    }

    var streamedResponse = await request.send();
    return http.Response.fromStream(streamedResponse);
  }

  Future<http.Response> verifyOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    return response;
  }

  Future<http.Response> resendOtp(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/resend-otp'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'email': email}),
    );
    return response;
  }

  Future<http.Response> loginUser(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/signin'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'username': username, 'password': password}),
    );
    return response;
  }

  // save tokens
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'accessToken', value: accessToken);
    await _storage.write(key: 'refreshToken', value: refreshToken);
  }

  // Get access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'accessToken');
  }

  // Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refreshToken');
  }

  // Clear tokens (for logout)
  Future<void> clearTokens() async {
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
  }

  Future<void> logoutFromAllDevices() async {
    final String? token = await _storage.read(key: 'accessToken');
    final response = await http.post(
      Uri.parse('$baseUrl/logout-all'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 201) {
      await clearTokens(); // Clear local tokens
    } else {
      // Handle error
      print('Error logging out from all devices');
    }
  }

  Future<String?> getCurrentUserId() async {
    try {
      String? token = await getAccessToken();
      if (token != null) {
        Map<String, dynamic> tokenPayload = Jwt.parseJwt(token);
        String? userId = tokenPayload['id'];
        return userId;
      }
    } catch (e) {
      print("Error decoding token: $e");
      return null;
    }
    return null;
  }

  Future<String?> getEmailByUsername(String username) async {
    final apiUrl = '$baseUrl/get-email-by-username/$username';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final email = data['email'];
        return email;
      } else {
        return null; // Username not found or other error
      }
    } catch (e) {
      return null; // Error occurred
    }
  }

  Future<String?> getUserIdByUsername(String username) async {
    final Uri uri = Uri.parse('$baseUrl/get-user-id/$username');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer ${await _storage.read(key: 'accessToken')}',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['id']; // Assuming the response contains the user ID
    } else {
      // Handle error or return null if the user ID can't be fetched
      return null;
    }
  }

  Future<http.Response> forgotPassword(String userEmail) async {
    final Uri forgotPasswordUrl = Uri.parse('$baseUrl/forgot-password');

    final Map<String, dynamic> requestBody = {'email': userEmail};

    final response = await http.post(
      forgotPasswordUrl,
      body: json.encode(requestBody),
      headers: {'Content-Type': 'application/json'},
    );

    return response;
  }

  Future<http.Response> resetPassword(
      String userEmail, String otp, String newPassword) async {
    final Uri resetPasswordUrl = Uri.parse('$baseUrl/reset-password');

    final Map<String, dynamic> requestBody = {
      'email': userEmail,
      'otp': otp,
      'newPassword': newPassword,
    };

    final response = await http.post(
      resetPasswordUrl,
      body: json.encode(requestBody),
      headers: {'Content-Type': 'application/json'},
    );

    return response;
  }

  Future<UserModel?> fetchUserProfile(String userId) async {
    final String url = '$baseUrl/profile/$userId';
    try {
      final token =
          await getAccessToken(); // Get the current user's access token
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $token', // Include the token in the Authorization header
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserModel.fromJson(
            data); // Deserialize the JSON data into a UserModel
      } else {
        print('Failed to load user profile: ${response.body}');
      }
    } catch (e) {
      print("Error fetching user profile: $e");
    }
    return null;
  }

  Future<bool> isRefreshTokenExpired() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken != null) {
      try {
        final tokenPayload = Jwt.parseJwt(refreshToken);
        final expiryDate =
            DateTime.fromMillisecondsSinceEpoch(tokenPayload['exp'] * 1000);
        return DateTime.now().isAfter(expiryDate);
      } catch (e) {
        print("Error decoding token: $e");
        return true; // Assume expired if error occurs
      }
    }
    return true; // Assume expired if no token is found
  }

  // Method to handle logout if the refresh token is expired
  Future<void> logoutIfTokenExpired(BuildContext context) async {
    if (await isRefreshTokenExpired()) {
      await clearTokens();
      Navigator.of(context).pushNamed('/login');
    }
  }

  Future<http.Response> followUser(String followingId) async {
    final Uri followUrl = Uri.parse('$baseUrl/$followingId/follow');
    final token = await _storage.read(key: 'accessToken');
    final response = await http.post(
      followUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response;
  }

  Future<http.Response> unfollowUser(String followingId) async {
    final Uri unfollowUrl = Uri.parse('$baseUrl/$followingId/unfollow');
    final token = await _storage.read(key: 'accessToken');
    final response = await http.post(
      unfollowUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response;
  }

  Future<bool> checkIfFollowing(String userId) async {
    final token = await _storage.read(key: 'accessToken');
    final response = await http.get(
      Uri.parse('$baseUrl/isFollowing/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      // Assuming the endpoint returns a JSON object with a boolean field `isFollowing`
      return json.decode(response.body)['isFollowing'];
    } else {
      // Handle error or return false if the status cannot be determined
      return false;
    }
  }

  Future<List<FollowerModel>> getFollowers(String userId) async {
    final accessToken = await _storage.read(key: 'accessToken');
    final uri = Uri.parse('$baseUrl/$userId/followers');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $accessToken',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((item) => FollowerModel.fromJson(item)).toList();
    } else {
      // Logging the status code and response body for debugging
      print(
          'Failed to load followers: ${response.statusCode}, ${response.body}');
      throw Exception('Failed to load followers');
    }
  }

  Future<List<FollowingModel>> getFollowing(String userId) async {
    final accessToken = await _storage.read(key: 'accessToken');
    final response =
        await http.get(Uri.parse('$baseUrl/$userId/following'), headers: {
      'Authorization': 'Bearer $accessToken',
    });
    if (response.statusCode == 200) {
      List<dynamic> followingJson = json.decode(response.body);
      return followingJson
          .map((data) => FollowingModel.fromJson(data))
          .toList();
    } else {
      throw Exception('Failed to load following');
    }
  }

  Future<bool> isUsernameValid(String username) async {
    final Uri uri = Uri.parse('$baseUrl/validate-username/$username');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer ${await _storage.read(key: 'accessToken')}',
    });

    if (response.statusCode == 200) {
      // Assuming the endpoint returns {"isValid": true} or {"isValid": false}
      final Map<String, dynamic> data = json.decode(response.body);
      return data['isValid'];
    } else {
      // Handle error or assume invalid if unable to verify
      return false;
    }
  }

  Future<bool> editProfile(
    String userId,
    String username,
    String email,
    String fullname,
    String bio,
    File? profileImage,
    File? bannerImage, // Add this parameter for the banner image
  ) async {
    final Uri url = Uri.parse('$baseUrl/profile/update');
    final accessToken = await _storage.read(key: 'accessToken');

    var request = http.MultipartRequest('PATCH', url)
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..fields['id'] = userId
      ..fields['username'] = username
      ..fields['email'] = email
      ..fields['fullname'] = fullname
      ..fields['bio'] = bio;

    if (profileImage != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'profileImage',
        profileImage.path,
      ));
    }

    // Add banner image to the request if it's not null
    if (bannerImage != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'bannerImage',
        bannerImage.path,
      ));
    }

    final response = await request.send();
    return response.statusCode == 200;
  }

  Future<void> deleteProfile() async {
    final url = Uri.parse('$baseUrl/profile/delete');

    // Retrieve the access token from secure storage
    final accessToken = await _storage.read(key: 'accessToken');

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete profile');
    }
  }

  Future<bool> updatePrivacySetting(bool isPrivate, bool isTagging) async {
    final userId = await getCurrentUserId();
    final response = await http.patch(
      Uri.parse('$baseUrl/$userId/privacy'),
      headers: {
        'Authorization': 'Bearer ${await getAccessToken()}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'isPrivate': isPrivate, 'isTagging': isTagging}),
    );

    return response.statusCode == 200;
  }

  // Fetch user's privacy setting
  Future<Map<String, bool>> getPrivacySetting() async {
    final userId = await getCurrentUserId();
    final response = await http.get(
      Uri.parse('$baseUrl/$userId/privacy'),
      headers: {'Authorization': 'Bearer ${await getAccessToken()}'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final bool isPrivate = data['isPrivate'];
      final bool isTagging = data['isTagging'];
      return {'isPrivate': isPrivate, 'isTagging': isTagging};
    } else {
      throw Exception('Failed to fetch privacy setting');
    }
  }

  // Method to mute a user
  Future<http.Response> muteUser(String mutedId) async {
    final token = await _storage.read(key: 'accessToken');
    final Uri muteUrl = Uri.parse('$baseUrl/mute/$mutedId');
    final response = await http.post(
      muteUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response;
  }

// Method to unmute a user
  Future<http.Response> unmuteUser(String mutedId) async {
    final token = await _storage.read(key: 'accessToken');
    final Uri unmuteUrl = Uri.parse('$baseUrl/unmute/$mutedId');
    final response = await http.post(
      unmuteUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response;
  }

  // Inside AuthService class

  Future<List<UserModel>> fetchMutedUsers() async {
    final accessToken = await _storage.read(key: 'accessToken');
    final Uri fetchMutedUsersUrl = Uri.parse('$baseUrl/muted/users');

    final response = await http.get(fetchMutedUsersUrl, headers: {
      'Authorization': 'Bearer $accessToken',
    });

    if (response.statusCode == 200) {
      List<dynamic> mutedUsersJson = json.decode(response.body);
      return mutedUsersJson.map((data) => UserModel.fromJson(data)).toList();
    } else {
      // Handle errors or return an empty list if no muted users found
      return [];
    }
  }

  Future<bool> isUserMuted(String mutedUserId) async {
    final accessToken = await _storage.read(key: 'accessToken');
    final Uri checkMuteUrl = Uri.parse('$baseUrl/isMuted/$mutedUserId');

    final response = await http.get(checkMuteUrl, headers: {
      'Authorization': 'Bearer $accessToken',
    });

    if (response.statusCode == 200) {
      // Assuming the backend returns a JSON object with a "isMuted" boolean field
      final data = json.decode(response.body);
      return data['isMuted'];
    } else {
      // Handle error or default to not muted
      return false;
    }
  }

  Future<http.Response> blockUser(String blockedId) async {
    final token = await _storage.read(key: 'accessToken');
    final Uri blockUrl = Uri.parse('$baseUrl/block/$blockedId');
    final response = await http.post(
      blockUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response;
  }

  Future<http.Response> unblockUser(String blockedId) async {
    final token = await _storage.read(key: 'accessToken');
    final Uri unblockUrl = Uri.parse('$baseUrl/unblock/$blockedId');
    final response = await http.post(
      unblockUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response;
  }

  Future<bool> isUserBlocked(String userId) async {
    final token = await _storage.read(key: 'accessToken');
    final Uri checkBlockUrl = Uri.parse('$baseUrl/isBlocked/$userId');

    final response = await http.get(checkBlockUrl, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['isBlocked'];
    } else {
      return false;
    }
  }

  Future<List<UserModel>> fetchBlockedUsers() async {
    final String url = '$baseUrl/blocked/users';
    final token = await _storage.read(key: 'accessToken');

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map<UserModel>((json) => UserModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch blocked users');
    }
  }
}
