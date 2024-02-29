import 'package:flutter/material.dart';
import 'package:quickpost_flutter/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home screen'),
        leading: IconButton(
          onPressed: () {
            AuthService().clearTokens();
            Navigator.of(context).pushReplacementNamed('/login');
          },
          icon: const Icon(Icons.logout),
        ),
      ),
      body: const Center(
        child: Text('Welcome to QuickPost'),
      ),
    );
  }
}
