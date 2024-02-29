import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:quickpost_flutter/screens/blockedcontacts_screen.dart';
import 'package:quickpost_flutter/screens/mutedusers_screen.dart';
import 'package:quickpost_flutter/services/auth_service.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  _PrivacySettingsScreenState createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final _storage = const FlutterSecureStorage();
  bool isAccountPrivate = false;
  bool allowTagging = true;
  bool shareLastSeen = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySetting();
  }

  Future<void> _loadPrivacySetting() async {
    Map<String, bool> privacySetting = await AuthService().getPrivacySetting();
    setState(() {
      isAccountPrivate = privacySetting['isPrivate'] ?? false;
      allowTagging = privacySetting['isTagging'] ?? true;
    });
  }

  _updateAccountPrivacy(bool isPrivate, bool isTagging) async {
    setState(() {
      isAccountPrivate = isPrivate;
      allowTagging = isTagging;
    });
    await _storage.write(key: 'isAccountPrivate', value: isPrivate.toString());

    // Call the AuthService to update the backend
    bool success =
        await AuthService().updatePrivacySetting(isPrivate, isTagging);
    if (!success) {
      // Handle unsuccessful update, possibly revert the switch or show an error message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content:
              const Text('Failed to update privacy setting. Please try again.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        backgroundColor: Colors.deepPurple, // Adjust to match your app theme
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Private Account'),
            subtitle: const Text('Only allow followers to see your posts'),
            value: isAccountPrivate,
            onChanged: (bool value) {
              setState(() {
                isAccountPrivate = value;
              });
              _updateAccountPrivacy(value, allowTagging);
            },
          ),
          SwitchListTile(
            title: const Text('Allow Tagging'),
            subtitle: const Text('Allow others to tag you in posts'),
            value: allowTagging,
            onChanged: (bool value) {
              setState(() {
                allowTagging = value;
              });
              _updateAccountPrivacy(isAccountPrivate, value);
            },
          ),
          SwitchListTile(
            title: const Text('Share Last Seen'),
            subtitle: const Text('Allow others to see your last active time'),
            value: shareLastSeen,
            onChanged: (bool value) {
              setState(() {
                shareLastSeen = value;
              });
              // Add your update logic here
            },
          ),
          ListTile(
            title: const Text('Blocked Accounts'),
            leading: const Icon(Icons.block),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BlockedUsersScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Muted Accounts'),
            leading: const Icon(Icons.volume_off),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MutedUsersScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
