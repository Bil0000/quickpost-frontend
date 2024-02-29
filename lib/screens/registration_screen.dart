import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:quickpost_flutter/screens/otp_screen.dart';
import 'package:quickpost_flutter/services/auth_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final ImagePicker _picker = ImagePicker();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  String _errorMessage = '';
  bool _passwordVisible = false;
  File? _profileImage;

  @override
  void dispose() {
    // Dispose controllers when the widget is disposed
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : null,
                    child: _profileImage == null
                        ? const Icon(Icons.camera_alt, size: 60)
                        : null,
                  ),
                ),
                TextFormField(
                  controller: _fullNameController,
                  decoration:
                      const InputDecoration(labelText: 'First & Last name'),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    errorStyle: TextStyle(
                      fontSize: 12, // Adjust font size for error text
                    ),
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                TextFormField(
                  controller: _bioController,
                  decoration:
                      const InputDecoration(labelText: 'Bio (Optional)'),
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                      icon: _passwordVisible
                          ? const Icon(Icons.visibility_off_outlined)
                          : const Icon(Icons.visibility_outlined),
                    ),
                  ),
                  obscureText: !_passwordVisible,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Text('Already have an account '),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  child: const Text(
                    'Login?',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // Collect user data
                      Map<String, dynamic> userData = {
                        'username': _usernameController.text.toLowerCase(),
                        'email': _emailController.text.toLowerCase(),
                        'password': _passwordController.text,
                        'fullname': _fullNameController.text,
                        'bio': _bioController.text,
                      };

                      // Call the AuthService to send data
                      AuthService authService = AuthService();
                      try {
                        var response = await authService.registerUser(
                            userData, _profileImage);
                        if (response.statusCode == 201) {
                          // Handle successful registration
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => OtpScreen(
                                userEmail: _emailController.text.toLowerCase(),
                              ),
                            ),
                          );
                          await Posthog().capture(
                            eventName: 'user_signed_up',
                            properties: {
                              "fullname": _fullNameController.text,
                              "username":
                                  _usernameController.text.toLowerCase(),
                              "email": _emailController.text.toLowerCase(),
                            },
                          );
                          print("Registration successful");
                        } else {
                          // Check if response body is not empty
                          if (response.body.isNotEmpty) {
                            try {
                              var responseData = json.decode(response.body);
                              var message = responseData['message'];
                              setState(() {
                                if (message is String) {
                                  _errorMessage = message;
                                } else if (message is List) {
                                  _errorMessage = message.join(' ');
                                } else {
                                  _errorMessage = 'An unknown error occurred';
                                }
                              });

                              Timer(const Duration(seconds: 5), () {
                                setState(() {
                                  _errorMessage = ''; // Clear the error message
                                });
                              });
                            } catch (e) {
                              // Handle JSON parsing error
                              setState(() {
                                _errorMessage =
                                    'Error parsing server response: ${e.toString()}';
                              });
                            }
                          }
                        }
                      } catch (e) {
                        // Handle network errors, etc.
                        setState(() {
                          _errorMessage = e.toString();
                        });
                      }
                    }
                  },
                  child: const Text('Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
