import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  _NotificationSettingsScreenState createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // Assume initial values are set here
  bool receiveNotifications = true;
  bool soundEnabled = true;
  bool vibrateEnabled = true;
  bool showPreviews = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      receiveNotifications = prefs.getBool('receiveNotifications') ?? true;
      soundEnabled = prefs.getBool('soundEnabled') ?? true;
      vibrateEnabled = prefs.getBool('vibrateEnabled') ?? true;
      showPreviews = prefs.getBool('showPreviews') ?? false;
    });
  }

  _saveSetting(String key, bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Colors.deepPurple, // Adjust to match your app theme
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Receive Notifications'),
            value: receiveNotifications,
            onChanged: (bool value) {
              setState(() {
                receiveNotifications = value;
              });
              _saveSetting('receiveNotifications', value);
            },
          ),
          SwitchListTile(
            title: const Text('Sounds'),
            value: soundEnabled,
            onChanged: (bool value) {
              setState(() {
                soundEnabled = value;
              });
              _saveSetting('soundEnabled', value);
            },
          ),
          SwitchListTile(
            title: const Text('Vibrate'),
            value: vibrateEnabled,
            onChanged: (bool value) {
              setState(() {
                vibrateEnabled = value;
              });
              _saveSetting('vibrateEnabled', value);
            },
          ),
          SwitchListTile(
            title: const Text('Show Previews'),
            subtitle: const Text(
                'Show a preview of notifications and will not show original notification.'),
            value: showPreviews,
            onChanged: (bool value) {
              setState(() {
                showPreviews = value;
              });
              _saveSetting('showPreviews', value);
            },
          ),
        ],
      ),
    );
  }
}
