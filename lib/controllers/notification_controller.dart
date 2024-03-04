import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:quickpost_flutter/screens/post_details_screen.dart';
import 'package:quickpost_flutter/screens/profile_screen.dart';

class NotificationController {
  static GlobalKey<NavigatorState>? _navigatorKey;
  static String? notificationRoute;

  static void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {}

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {}

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    AwesomeNotifications().decrementGlobalBadgeCounter();
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    String? postId = receivedAction.payload?['postId'];
    String? userId =
        receivedAction.payload?['userId']; // Extract userId from payload

    if (postId != null) {
      // Navigate to PostDetailsScreen if postId is present
      _navigatorKey!.currentState?.push(MaterialPageRoute(
          builder: (context) => PostDetailsScreen(postId: postId)));
    } else if (userId != null) {
      // Navigate to UserProfileScreen if userId is present
      _navigatorKey!.currentState?.push(MaterialPageRoute(
          builder: (context) => ProfileScreen(userId: userId)));
    }
  }
}
