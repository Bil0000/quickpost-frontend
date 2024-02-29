import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:quickpost_flutter/screens/get_email_reset_pass_screen.dart';
import 'package:quickpost_flutter/screens/otp_screen.dart';
import 'package:quickpost_flutter/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _errorMessage = '';
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameEmailController =
      TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _passwordVisible = false;

  @override
  void dispose() {
    // Dispose controllers when the widget is disposed
    _usernameEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _usernameEmailController,
                decoration: const InputDecoration(labelText: 'Username'),
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
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () async {
                      String userEmail = _usernameEmailController.text
                          .toLowerCase(); // Get user's email
                      AuthService authService = AuthService();
                      await authService.forgotPassword(userEmail);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const RestPassEmailScreen(),
                        ),
                      );
                    },
                    child: const Text('Forgot Password?'),
                  ),
                ],
              ),
              const Text('Don\'t have an account '),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/register');
                },
                child: const Text(
                  'Register?',
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
                    // Get the username and password
                    String username =
                        _usernameEmailController.text.toLowerCase();
                    String password = _passwordController.text;

                    // Call loginUser method
                    AuthService authService = AuthService();
                    var response =
                        await authService.loginUser(username, password);

                    // Check the response status code
                    if (response.statusCode == 201) {
                      var responseData = json.decode(response.body);
                      String accessToken = responseData['access_token'];
                      String refreshToken = responseData['refresh_token'];

                      // Save tokens securely
                      await AuthService().saveTokens(accessToken, refreshToken);

                      // Navigate to the next screen
                      Navigator.of(context).pushReplacementNamed('/main');
                      await Posthog().capture(
                        eventName: 'user_logged_in',
                        properties: {
                          'login_type': 'email',
                          'username': username,
                        },
                      );
                    } else if (response.statusCode == 403) {
                      var responseData = json.decode(response.body);
                      var message = responseData['message'] ??
                          'An unknown error occurred';
                      setState(() {
                        _errorMessage =
                            message; // Update the error message in the state
                      });

                      Timer(const Duration(seconds: 3), () {
                        setState(() {
                          _errorMessage = ''; // Clear the error message
                        });
                      });

                      String? userEmail =
                          await authService.getEmailByUsername(username);

                      await Future.delayed(const Duration(seconds: 4));

                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => OtpScreen(
                            userEmail: userEmail!,
                          ),
                        ),
                      );
                    } else {
                      var responseData = json.decode(response.body);
                      var message = responseData['message'] ??
                          'An unknown error occurred';
                      setState(() {
                        _errorMessage =
                            message; // Update the error message in the state
                      });

                      Timer(const Duration(seconds: 5), () {
                        setState(() {
                          _errorMessage = ''; // Clear the error message
                        });
                      });
                    }
                  }
                },
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
