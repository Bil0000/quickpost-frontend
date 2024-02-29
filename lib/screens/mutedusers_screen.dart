import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:quickpost_flutter/models/user_model.dart';
import 'package:quickpost_flutter/services/auth_service.dart';

class MutedUsersScreen extends StatefulWidget {
  const MutedUsersScreen({super.key});

  @override
  _MutedUsersScreenState createState() => _MutedUsersScreenState();
}

class _MutedUsersScreenState extends State<MutedUsersScreen> {
  List<UserModel> _mutedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadMutedUsers();
  }

  void _loadMutedUsers() async {
    List<UserModel> mutedUsers = await AuthService().fetchMutedUsers();
    setState(() {
      _mutedUsers = mutedUsers;
    });
  }

  void _unmuteUser(String userId, int index) async {
    final response = await AuthService().unmuteUser(userId);
    if (response.statusCode == 201) {
      setState(() {
        _mutedUsers.removeAt(index);
      });
      final snackBar = SnackBar(
        showCloseIcon: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: AwesomeSnackbarContent(
          title: 'Success!',
          message: 'User unmuted successfuly',
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
        title: const Text('Muted Users'),
      ),
      body: _mutedUsers.isNotEmpty
          ? ListView.builder(
              itemCount: _mutedUsers.length,
              itemBuilder: (context, index) {
                UserModel user = _mutedUsers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(user.profileImageUrl),
                  ),
                  title: Text(user.fullname),
                  subtitle: Text(user.username),
                  trailing: IconButton(
                    tooltip: 'Unmute user',
                    icon: const Icon(Icons.volume_off, color: Colors.grey),
                    onPressed: () => _unmuteUser(user.id, index),
                  ),
                );
              },
            )
          : const Center(
              child: Text("No muted users."),
            ),
    );
  }
}
