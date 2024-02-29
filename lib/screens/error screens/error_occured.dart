import 'package:flutter/material.dart';
import 'package:quickpost_flutter/screens/login_screen.dart';
import 'package:quickpost_flutter/services/auth_service.dart';

class ErrorOccuredScreen extends StatelessWidget {
  const ErrorOccuredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Image.asset('assets/logo.png', height: 106, color: Colors.black),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset("assets/error_image.png", fit: BoxFit.cover),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height *
                    0.05, // Adjust this value as needed
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('OR',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  _buildButton(context, "try login"),
                  const SizedBox(height: 5),
                  const Text('OR',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  _buildButton(context, "retry"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
              offset: const Offset(0, 13),
              blurRadius: 25,
              color: const Color(0xFF5666C2).withOpacity(0.17)),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        ),
        onPressed: () async {
          if (text == "try login") {
            await AuthService().clearTokens();
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const LoginScreen()));
          } else {
            Navigator.of(context).pushNamed('/feed');
          }
        },
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(color: Colors.black),
        ),
      ),
    );
  }
}
