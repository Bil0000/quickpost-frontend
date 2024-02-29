import 'package:flutter/material.dart';

class UserGuideScreen extends StatefulWidget {
  const UserGuideScreen({Key? key}) : super(key: key);

  @override
  _UserGuideScreenState createState() => _UserGuideScreenState();
}

class _UserGuideScreenState extends State<UserGuideScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 5,
        vsync: this); // Adjust length based on the number of sections
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Guide'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Getting Started'),
            Tab(text: 'Posting'),
            Tab(text: 'Interacting'),
            Tab(text: 'Settings'),
            Tab(text: 'Safety'),
          ],
          isScrollable: true,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGettingStartedSection(),
          _buildPostingSection(),
          _buildInteractingSection(),
          _buildSettingsSection(context),
          _buildSafetySection(),
        ],
      ),
    );
  }

  Widget _buildGettingStartedSection() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Welcome to QuickPost!',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple),
          ),
          SizedBox(height: 20),
          Text(
            'QuickPost is your go-to social media app where you can share moments, connect with friends, and discover new interests. This guide will help you get started.',
          ),
          // Add more detailed steps and potentially images or icons for visual aid
        ],
      ),
    );
  }

  Widget _buildPostingSection() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Creating a New Post',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple),
          ),
          SizedBox(height: 10),
          Text(
            'Tap the "+" button to start creating new posts. You can upload photos, videos, or write text. Don\'t forget to tag your friends or add a location!',
          ),
          // Include more instructions and possibly images or videos for guidance
        ],
      ),
    );
  }

  Widget _buildInteractingSection() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Liking and Commenting',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple),
          ),
          SizedBox(height: 10),
          Text(
            'Engage with content by liking posts or leaving comments. Show your appreciation and start conversations with the community.',
          ),
          // Expand with more details on interacting with posts and users
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Navigating Settings',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple),
          ),
          const SizedBox(height: 20),
          const Text(
            'QuickPost provides comprehensive settings to customize your experience. Manage your account, set notification preferences, adjust privacy settings, and find help and support.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          _settingsItem(context, 'Account Settings',
              'Manage your account details, change your password, and more.'),
          _settingsItem(context, 'Notification Settings',
              'Customize which notifications you receive and how.'),
          _settingsItem(context, 'Privacy Settings',
              'Control who can see your posts and personal information.'),
          _settingsItem(context, 'Help & Support',
              'Access FAQs, contact support, or report a problem.'),
        ],
      ),
    );
  }

  Widget _settingsItem(BuildContext context, String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSafetySection() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Staying Safe on QuickPost',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple),
          ),
          SizedBox(height: 10),
          Text(
            'Your safety is our top priority. Familiarize yourself with our community guidelines and learn how to report inappropriate content.',
          ),
          // Further elaborate on safety practices, reporting mechanisms, and support resources
        ],
      ),
    );
  }
}
