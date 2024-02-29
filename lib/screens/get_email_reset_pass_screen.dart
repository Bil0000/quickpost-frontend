import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:quickpost_flutter/screens/reset_password_screen.dart';
import 'package:quickpost_flutter/services/auth_service.dart';

class RestPassEmailScreen extends StatefulWidget {
  const RestPassEmailScreen({super.key});

  @override
  State<RestPassEmailScreen> createState() => _RestPassEmailScreenState();
}

class _RestPassEmailScreenState extends State<RestPassEmailScreen> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Forgot Your Password?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Please enter the email associated with your account.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final authService = AuthService();
                    var response = await authService
                        .forgotPassword(_emailController.text.toLowerCase());

                    if (response.statusCode == 201) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ResetPasswordScreen(
                            userEmail: _emailController.text.toLowerCase(),
                          ),
                        ),
                      );
                    } else {
                      var responseData = json.decode(response.body);
                      var message = responseData['message'] ??
                          'An unknown error occurred';
                      setState(() {
                        _errorMessage = message;
                      });
                    }
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
