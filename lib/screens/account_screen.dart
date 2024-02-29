import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:quickpost_flutter/models/user_model.dart';
import 'package:quickpost_flutter/screens/%20privacysettings_screen.dart';
import 'package:quickpost_flutter/screens/edit_profile_screen.dart';
import 'package:quickpost_flutter/screens/get_email_update_pass_screen.dart';
import 'package:quickpost_flutter/screens/help&support_screen.dart';
import 'package:quickpost_flutter/screens/viewimage_screen.dart';
import 'package:quickpost_flutter/services/auth_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String? currentUserID;
  final _storage = const FlutterSecureStorage();
  UserModel? _user;

  @override
  void initState() {
    getUserDetails();
    AuthService().fetchUserProfile(currentUserID.toString());
    super.initState();
  }

  Future<void> getUserDetails() async {
    final token = await _storage.read(key: 'accessToken');
    if (token != null && !Jwt.isExpired(token)) {
      Map<String, dynamic> decodedToken = Jwt.parseJwt(token);
      currentUserID = decodedToken['id'];

      try {
        UserModel? user = await AuthService().fetchUserProfile(
            currentUserID!); // Ensure this is not null before calling

        if (user != null) {
          setState(() {
            _user = user;
          });
        } else {
          // Handle user being null (e.g., show an error or a default state)
        }
      } catch (e) {
        // Handle errors (e.g., show a message)
      }
    } else {
      // Handle expired or missing token (e.g., redirect to login)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: Colors.deepPurple, // Adjust to fit your app theme
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ViewImageScreen(
                    imageUrl: _user?.profileImageUrl ?? '',
                  ),
                ),
              );
            },
            child: CircleAvatar(
              radius: 50,
              // backgroundImage: NetworkImage(
              //   _user?.profileImageUrl ?? '',
              // ),
              backgroundColor: Colors.grey.shade200,
              child: ClipOval(
                  child: Image.network(
                _user?.profileImageUrl ?? '',
                fit: BoxFit.cover,
                width: 100.0,
                height: 100.0,
              )),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _user?.fullname ?? '',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            '@${_user?.username}',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            _user?.email ?? '',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          _buildAccountOption(context, "Edit Profile", Icons.edit),
          _buildAccountOption(context, "Change Password", Icons.lock),
          _buildAccountOption(context, "Privacy Settings", Icons.privacy_tip),
          _buildAccountOption(context, "Help & Support", Icons.help),
          ListTile(
            title: const Text('Log Out From All Devices',
                style: TextStyle(color: Colors.red)),
            subtitle:
                const Text('Logs out from all devices including this device.'),
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            onTap: () async {
              await AuthService().logoutFromAllDevices();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
    );
  }

  void _handleNavigation(BuildContext context, String title) {
    switch (title) {
      case "Edit Profile":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditProfileScreen(
                profileBannerUrl: _user?.bannerImageUrl ?? '',
                profileImageUrl: _user?.profileImageUrl ?? '',
                user: _user!),
          ),
        );
        break;
      case "Change Password":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ChangePassEmailScreen(),
          ),
        );
        break;
      case "Privacy Settings":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PrivacySettingsScreen(),
          ),
        );
        break;
      case "Help & Support":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HelpSupportScreen(),
          ),
        );
        break;
      default:
        break;
    }
  }

  Widget _buildAccountOption(
      BuildContext context, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(fontSize: 18)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () =>
          _handleNavigation(context, title), // Updated to handle navigation
    );
  }
}
