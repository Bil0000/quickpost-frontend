import 'package:flutter/material.dart';
import 'package:quickpost_flutter/screens/account_screen.dart';
import 'package:quickpost_flutter/screens/help&support_screen.dart';
import 'package:quickpost_flutter/screens/notificationsettings_screen.dart';
import 'package:quickpost_flutter/screens/settings_privacy_screen.dart';
import 'package:quickpost_flutter/services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _logoutUser() async {
    await AuthService().clearTokens();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Account?"),
          content: const Text(
              "Are you sure you want to delete your account? This action is irreversible."),
          actions: <Widget>[
            ElevatedButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
              onPressed: () {
                AuthService().deleteProfile();
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/login');
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.deepPurple, // Example of a premium color
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Account',
                style: TextStyle(fontWeight: FontWeight.bold)),
            leading: const Icon(Icons.person, color: Colors.white),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccountScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Notifications',
                style: TextStyle(fontWeight: FontWeight.bold)),
            leading: const Icon(Icons.notifications, color: Colors.white),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationSettingsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Privacy',
                style: TextStyle(fontWeight: FontWeight.bold)),
            leading: const Icon(Icons.lock, color: Colors.white),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPrivacySettingsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Help & Support',
                style: TextStyle(fontWeight: FontWeight.bold)),
            leading: const Icon(Icons.help, color: Colors.white),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpSupportScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Log Out', style: TextStyle(color: Colors.red)),
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            onTap: _logoutUser,
          ),
          // const Divider(),
          // ListTile(
          //   title: const Text('Log Out From All Devices',
          //       style: TextStyle(color: Colors.red)),
          //   leading: const Icon(Icons.exit_to_app, color: Colors.red),
          //   onTap: () async {
          //     await AuthService().logoutFromAllDevices();
          //     Navigator.of(context).pushReplacementNamed('/login');
          //   },
          // ),
          const Divider(),
          ListTile(
            title: const Text('Delete Account',
                style: TextStyle(color: Colors.red)),
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            onTap: _showDeleteAccountDialog,
          ),
        ],
      ),
    );
  }
}
