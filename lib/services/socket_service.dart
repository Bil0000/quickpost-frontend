import 'dart:async';
import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:quickpost_flutter/models/post_model.dart';
import 'package:quickpost_flutter/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  final StreamController<Post> _postController =
      StreamController<Post>.broadcast();
  final StreamController<Post> _deleteController =
      StreamController<Post>.broadcast();
  final StreamController<Post> _updateController =
      StreamController<Post>.broadcast();
  final StreamController<Map<String, dynamic>> _likeController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _unlikeController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Post> get postStream => _postController.stream;
  Stream<Post> get deleteStream => _deleteController.stream;
  Stream<Post> get updateStream => _updateController.stream;
  Stream<Map<String, dynamic>> get likeStream => _likeController.stream;
  Stream<Map<String, dynamic>> get unlikeStream => _unlikeController.stream;

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  late IO.Socket socket;

  Future<String?> getCurrentUserId() async {
    String? token = await AuthService().getAccessToken();
    final payload = Jwt.parseJwt(token.toString());
    return payload['id'];
  }

  void connect() {
    socket = IO.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
    });

    socket.onConnect((_) {
      print('Connected to WebSocket Server');
    });

    socket.on('newPost', (data) {
      try {
        Post newPost = Post.fromJson(data);
        _postController.sink.add(newPost); // Add new post to the stream
      } catch (e) {
        print("Error processing newPost event: $e");
      }
    });

    socket.on('deletePost', (data) {
      String postId = data['id'];
      _deleteController.sink.add(Post(
          id: postId,
          userId: '',
          caption: '',
          imageUrl: '',
          username: '',
          profileImageUrl: '',
          createdAt: DateTime.now(),
          likeCount: 0,
          views: 0,
          commentCount: 0,
          isLikedByCurrentUser: false));
    });

    socket.on('updatePost', (data) {
      Post updatedPost = Post.fromJson(data);
      _updateController.sink.add(updatedPost);
    });

    socket.on('postLiked', (data) async {
      String? currentUserId = await getCurrentUserId();
      _likeController.sink.add(data);
      if (data != null && data['likerUserId'] != currentUserId) {
        String postId = data['postId'].toString();
        _showNotification(data, postId);
      }
    });

    socket.on('postUnliked', (data) {
      _unlikeController.sink.add(data);
      print('post unliked');
    });

    socket.onDisconnect((_) => print('Disconnected from WebSocket Server'));
  }

  Future<void> _showNotification(
      Map<String, dynamic> data, String postId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    bool receiveNotifications = prefs.getBool('receiveNotifications') ?? true;
    if (!receiveNotifications) {
      return;
    }

    int badgeNumber = (prefs.getInt('badgeNumber') ?? 0) + 1;
    await prefs.setInt('badgeNumber', badgeNumber);

    bool showPreviews = prefs.getBool('showPreviews') ?? true;
    String bodyText = showPreviews
        ? 'You have a new notification.'
        : '${data['likerUsername']} liked your post, tap to see post.';

    // Assuming you only want to save the title and body for simplicity
    Map<String, dynamic> notificationData = {
      'title': 'QuickPost',
      'body': bodyText,
      'payload': {'postId': postId}
    };

    // Await the creation of the notification then save its data
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'basic_channel',
        title: 'QuickPost',
        body: bodyText,
        notificationLayout: NotificationLayout.Default,
        displayOnForeground: true,
        displayOnBackground: true,
        category: NotificationCategory.Message,
        payload: {'postId': postId},
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'MARK_AS_READ',
          label: 'Mark as read',
          actionType: ActionType.Default,
        ),
      ],
    );

    await saveNotification(notificationData);
  }

  Future<void> saveNotification(Map<String, dynamic> notificationData) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notifications = prefs.getStringList('notifications') ?? [];
    notifications.add(jsonEncode(
        notificationData)); // Convert notification data to a string and add it to the list
    await prefs.setStringList('notifications', notifications);
  }

  void dispose() {
    _postController.close();
    _deleteController.close();
    _updateController.close();
    socket.dispose();
  }
}
