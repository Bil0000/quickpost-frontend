import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:quickpost_flutter/models/user_model.dart';
import 'package:quickpost_flutter/services/auth_service.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({Key? key}) : super(key: key);

  @override
  _BlockedUsersScreenState createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<UserModel> _blockedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  void _loadBlockedUsers() async {
    try {
      List<UserModel> blockedUsers = await AuthService().fetchBlockedUsers();
      setState(() {
        _blockedUsers = blockedUsers;
      });
    } catch (e) {
      print("Error fetching blocked users: $e");
    }
  }

  void _unblockUser(String userId, int index) async {
    final response = await AuthService().unblockUser(userId);
    if (response.statusCode == 201) {
      // Adjust the status code based on your API
      setState(() {
        _blockedUsers.removeAt(index);
      });
      final snackBar = SnackBar(
        showCloseIcon: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: AwesomeSnackbarContent(
          title: 'Success!',
          message: 'User unblocked successfully',
          contentType: ContentType.success,
        ),
        behavior: SnackBarBehavior.floating,
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
    } else {
      final snackBar = SnackBar(
        showCloseIcon: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: AwesomeSnackbarContent(
          title: 'Error Ocured!',
          message: 'Unexpected error occured',
          contentType: ContentType.failure,
        ),
        behavior: SnackBarBehavior.floating,
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Users'),
      ),
      body: _blockedUsers.isNotEmpty
          ? ListView.builder(
              itemCount: _blockedUsers.length,
              itemBuilder: (context, index) {
                UserModel user = _blockedUsers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(user.profileImageUrl),
                  ),
                  title: Text(user.fullname),
                  subtitle: Text(user.username),
                  trailing: IconButton(
                    tooltip: 'Unblock user',
                    icon: const Icon(Icons.block, color: Colors.red),
                    onPressed: () => _unblockUser(user.id, index),
                  ),
                );
              },
            )
          : const Center(child: Text("No blocked users found.")),
    );
  }
}
