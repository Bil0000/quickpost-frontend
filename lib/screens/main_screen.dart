import 'package:flutter/material.dart';
import 'package:quickpost_flutter/models/post_model.dart';
import 'package:quickpost_flutter/screens/create_post_screen.dart';
import 'package:quickpost_flutter/screens/feed_screen.dart';
import 'package:quickpost_flutter/screens/myprofile_screen.dart';
import 'package:quickpost_flutter/screens/search_screen.dart';
import 'package:quickpost_flutter/screens/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Post> posts = [];
  int _selectedIndex = 0;

  final List<Widget> screens = [
    const FeedScreen(),
    const SearchScreen(),
    MyProfileScreen(),
    const SettingsScreen(),
  ];

  final PageStorageBucket bucket = PageStorageBucket();
  Widget currentScreen = const FeedScreen();

  Widget _buildBottomAppBarItem(
      {required IconData icon, required int index, required Widget screen}) {
    return IconButton(
      icon: Icon(
        icon,
        size: 30,
        color: _selectedIndex == index ? Colors.blue : Colors.grey,
      ),
      onPressed: () {
        setState(() {
          _selectedIndex = index;
          currentScreen = screen;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageStorage(
        bucket: bucket,
        child: currentScreen,
      ),
      floatingActionButton: FloatingActionButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MyHomePage()),
          );
        },
        elevation: 2.0,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 13.0,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildBottomAppBarItem(
                icon: Icons.home_filled, index: 0, screen: const FeedScreen()),
            _buildBottomAppBarItem(
                icon: Icons.search, index: 1, screen: const SearchScreen()),
            const SizedBox(width: 48), // The dummy child for the notch
            _buildBottomAppBarItem(
                icon: Icons.person, index: 2, screen: MyProfileScreen()),
            _buildBottomAppBarItem(
                icon: Icons.settings, index: 3, screen: const SettingsScreen()),
          ],
        ),
      ),
    );
  }
}
