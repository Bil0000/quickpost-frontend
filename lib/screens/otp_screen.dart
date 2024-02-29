import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:quickpost_flutter/services/auth_service.dart';

class OtpScreen extends StatefulWidget {
  String userEmail;
  OtpScreen({
    Key? key,
    required this.userEmail,
  }) : super(key: key);

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _errorMessage = '';
  bool _isResendEnabled = false; // Added flag to control button state
  int _resendCountdown = 30; // Initial countdown value
  final List<TextEditingController> _otpControllers =
      List.generate(6, (index) => TextEditingController());

  @override
  void initState() {
    super.initState();
    startCountdown();
  }

  void startCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--; // Decrease countdown value
        });
      } else {
        setState(() {
          _isResendEnabled = true; // Enable the resend button
        });
        timer.cancel(); // Stop the countdown timer
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Verification'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SafeArea(
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Enter the OTP sent to your email.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 50, // Adjust the width as needed
                    child: TextFormField(
                      controller: _otpControllers[index],
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '',
                        border: OutlineInputBorder(),
                      ),
                      textAlign: TextAlign.center,
                      onChanged: (value) {
                        if (value.length == 1 && index < 5) {
                          // Move focus to the next input field
                          FocusScope.of(context).nextFocus();
                        } else if (value.isEmpty && index > 0) {
                          // Move focus to the previous input field
                          FocusScope.of(context).previousFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  TextButton(
                    onPressed: _isResendEnabled
                        ? () async {
                            setState(() {
                              _isResendEnabled = false;
                              _resendCountdown = 30;
                            });

                            final response =
                                await AuthService().resendOtp(widget.userEmail);

                            if (response.statusCode == 201) {
                              print('OTP resent successfully');
                              startCountdown();
                            } else {
                              var responseData = json.decode(response.body);
                              var message = responseData['message'] ??
                                  'An unknown error occurred';
                              setState(() {
                                _errorMessage = message;
                              });

                              Timer(const Duration(seconds: 5), () {
                                setState(() {
                                  _errorMessage = '';
                                });
                              });
                            }
                          }
                        : null, // Disable button if countdown is active
                    child: _resendCountdown > 0
                        ? Row(
                            children: [
                              Text(
                                'Resend OTP',
                                style: TextStyle(
                                  color: _isResendEnabled
                                      ? Colors.blue
                                      : Colors.grey, // Gray out when disabled
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '$_resendCountdown s',
                                style: const TextStyle(
                                  color: Colors.grey, // Gray out the countdown
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Resend OTP',
                            style: TextStyle(
                              color: _isResendEnabled
                                  ? Colors.blue
                                  : Colors.grey, // Gray out when disabled
                            ),
                          ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () async {
                  // Add async here
                  String enteredOTP = _otpControllers
                      .map((controller) => controller.text)
                      .join();

                  // Use await to get the result from isValidOTP
                  bool isValid = await isValidOTP(enteredOTP);

                  if (isValid) {
                    // OTP is valid, navigate to next screen or perform success actions
                    print('OTP verified successfully: $enteredOTP');
                    // Navigation logic...
                  } else {
                    // OTP is not valid, show error message
                    print('Invalid OTP. Please try again.');
                    // Error handling logic...
                  }
                },
                child: const Text('Verify OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to validate the OTP (you can replace this with your own validation logic)
  Future<bool> isValidOTP(String otp) async {
    try {
      final response = await AuthService().verifyOtp(widget.userEmail, otp);

      if (response.statusCode == 200) {
        // Assuming a status code of 200 indicates a successful verification
        // You might need to adjust this based on your API's response
        Navigator.of(context).pushReplacementNamed('/login');
        return true;
      } else {
        // Handle different status codes or errors as needed
        var responseData = json.decode(response.body);
        var message = responseData['message'] ?? 'An unknown error occurred';
        setState(() {
          _errorMessage = message; // Update the error message in the state
        });

        Timer(const Duration(seconds: 5), () {
          setState(() {
            _errorMessage = ''; // Clear the error message
          });
        });

        return false;
      }
    } catch (e) {
      // Handle any exceptions
      setState(() {
        _errorMessage = 'Error verifying OTP: ${e.toString()}';
      });
      return false;
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
