import 'dart:convert';
import 'dart:io';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quickpost_flutter/models/user_model.dart';
import 'package:quickpost_flutter/screens/get_email_update_pass_screen.dart';
import 'package:quickpost_flutter/services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String profileBannerUrl; // Replace with your actual banner URL
  final String profileImageUrl;
  final UserModel user;

  const EditProfileScreen({
    super.key,
    required this.profileBannerUrl,
    required this.profileImageUrl,
    required this.user,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  File? _profileimage;
  File? _bannerimage;
  String? _base64ProfileImage;
  String? _base64BannerImage;

  double avatarRadius = 50;
  double bannerHeight = 200;

  @override
  void initState() {
    _nameController.text = widget.user.fullname;
    _usernameController.text = widget.user.username;
    _bioController.text = widget.user.bio;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Edit Profile'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: ElevatedButton(
              onPressed: _updateProfile,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor:
                    Colors.blue, // Use the theme color for the button
              ),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none, // Allow overflow outside of the Stack
                alignment: Alignment.center,
                children: <Widget>[
                  GestureDetector(
                    onTap: _selectBannerImage,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: <Widget>[
                        if (_bannerimage != null)
                          Image.file(
                            _bannerimage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 200,
                          )
                        else if (widget.profileBannerUrl.isNotEmpty)
                          Image.network(
                            widget.profileBannerUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 200,
                          )
                        else
                          Container(
                            color: Colors.grey, // Placeholder color
                            width: double.infinity,
                            height: 200,
                            child: const Center(
                              child: Icon(Icons.add_a_photo),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: -avatarRadius,
                    child: GestureDetector(
                      onTap:
                          _selectProfileImage, // Call _selectProfileImage when tapped
                      child: CircleAvatar(
                        backgroundImage: _profileimage != null
                            ? FileImage(_profileimage!)
                                as ImageProvider<Object>?
                            : NetworkImage(widget.profileImageUrl),
                        radius: avatarRadius,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: avatarRadius + 16), // Padding for the avatar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Edit First & Last name',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Name cannot be empty';
                        }
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                    TextFormField(
                      controller: _usernameController,
                      decoration:
                          const InputDecoration(labelText: 'Edit Username'),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'Edit Bio',
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ChangePassEmailScreen(),
                            ),
                          );
                        },
                        child: const Text('Change Password'))
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return; // Ensures all validations are passed
    }

    final newName = _nameController.text.trim();
    final newUsername = _usernameController.text.trim().toLowerCase();
    // Removed email as it's not present in the UI form
    final newBio = _bioController.text.trim();

    final AuthService authService = AuthService();
    final bool success = await authService.editProfile(
      widget.user.id,
      newUsername,
      widget.user.email,
      newName,
      newBio,
      _profileimage,
      _bannerimage,
    );

    if (success) {
      final snackBar = SnackBar(
        showCloseIcon: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: AwesomeSnackbarContent(
          title: 'Success!',
          message: 'Profile updated successfully',
          contentType: ContentType.success,
        ),
        behavior: SnackBarBehavior.floating,
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);

      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text('Profile updated successfully'),
      //     backgroundColor: Colors.green,
      //   ),
      // );

      Navigator.of(context)
          .pop(true); // Optionally return true to indicate success
    } else {
      final snackBar = SnackBar(
        showCloseIcon: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: AwesomeSnackbarContent(
          title: 'Error Occured!',
          message: 'Failed to update profile, please try again later.',
          contentType: ContentType.failure,
        ),
        behavior: SnackBarBehavior.floating,
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text('Failed to update profile, please try again later.'),
      //     backgroundColor: Colors.red,
      //   ),
      // );
    }
  }

  Future<void> _selectProfileImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileimage = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectBannerImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _bannerimage = File(pickedFile.path);
      });
    }
  }
}
