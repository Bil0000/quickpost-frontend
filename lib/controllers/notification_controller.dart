import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:quickpost_flutter/screens/post_details_screen.dart';

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

    if (postId != null) {
      // Navigate to your PostDetailsScreen
      // Ensure you have a BuildContext or a way to navigate without context
      // For example, using a GlobalKey<NavigatorState>
      _navigatorKey!.currentState?.push(MaterialPageRoute(
          builder: (context) => PostDetailsScreen(postId: postId)));
    }
  }
}
