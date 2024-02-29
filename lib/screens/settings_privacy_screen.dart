import 'package:flutter/material.dart';

class SettingsPrivacySettingsScreen extends StatefulWidget {
  const SettingsPrivacySettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsPrivacySettingsScreenState createState() =>
      _SettingsPrivacySettingsScreenState();
}

class _SettingsPrivacySettingsScreenState
    extends State<SettingsPrivacySettingsScreen> {
  bool locationTrackingEnabled = false;
  bool analyticsCollectionEnabled = true;
  bool personalizedAdsEnabled = true;

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
            title: const Text('Location Tracking'),
            subtitle: const Text('Allow the app to access your location.'),
            value: locationTrackingEnabled,
            onChanged: (bool value) {
              setState(() {
                locationTrackingEnabled = value;
              });
              // Update app settings or inform backend
            },
          ),
          SwitchListTile(
            title: const Text('Analytics Collection'),
            subtitle: const Text('Allow the app to collect usage data.'),
            value: analyticsCollectionEnabled,
            onChanged: (bool value) {
              setState(() {
                analyticsCollectionEnabled = value;
              });
              // Update app settings or inform backend
            },
          ),
          SwitchListTile(
            title: const Text('Personalized Ads'),
            subtitle: const Text('Receive ads based on your activity.'),
            value: personalizedAdsEnabled,
            onChanged: (bool value) {
              setState(() {
                personalizedAdsEnabled = value;
              });
              // Update app settings or inform backend
            },
          ),
          ListTile(
            leading: const Icon(Icons.policy),
            title: const Text('Privacy Policy'),
            onTap: () {
              // Navigate to privacy policy document
            },
          ),
          ListTile(
            leading: const Icon(Icons.document_scanner),
            title: const Text('Terms of Service'),
            onTap: () {
              // Navigate to terms of service document
            },
          ),
          // More options can be added as needed
        ],
      ),
    );
  }
}
