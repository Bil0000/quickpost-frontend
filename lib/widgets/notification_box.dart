import 'package:flutter/material.dart';

class NotificationsPopup extends PopupRoute {
  final Widget child;
  final BuildContext
      appBarContext; // Context of the AppBar to find the location of the icon.

  NotificationsPopup({required this.child, required this.appBarContext});

  @override
  Color get barrierColor => Colors.transparent;

  @override
  bool get barrierDismissible => true;

  @override
  String get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration => Duration(milliseconds: 300);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    // Find the render box of the AppBar icon to position the popup below it.
    final RenderBox appBarBox = appBarContext.findRenderObject() as RenderBox;
    final Offset appBarPosition =
        appBarBox.localToGlobal(appBarBox.size.bottomLeft(Offset.zero));

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned(
            top: appBarPosition
                .dy, // Positioning at the bottom of the AppBar icon
            right: 0, // Align to the right side of the screen
            left:
                0, // You can adjust this to align the notification box as you want
            child: child,
          ),
        ],
      ),
    );
  }
}

class NotificationBox extends StatelessWidget {
  final List<String> notifications; // Replace with your notification model

  const NotificationBox({
    Key? key,
    required this.notifications,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: notifications
              .map((notification) => ListTile(
                    leading: CircleAvatar(
                        child: Icon(Icons.person)), // Replace with actual data
                    title: Text(notification),
                    subtitle: Text('Commented 2h ago'),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
