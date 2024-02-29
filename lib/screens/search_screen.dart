import 'package:flutter/material.dart';
import 'package:quickpost_flutter/models/post_model.dart';
import 'package:quickpost_flutter/models/user_model.dart';
import 'package:quickpost_flutter/services/search_service.dart';
import 'package:quickpost_flutter/widgets/post_widget.dart';
import 'package:quickpost_flutter/widgets/user_widget.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<dynamic> _searchResults = [];
  final List<dynamic> _userResults = [];
  final List<dynamic> _postResults = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> search() async {
    try {
      final results = await SearchService().search(_searchController.text);
      setState(() {
        _searchResults.clear();
        _searchResults
            .addAll(results['users'].map((user) => UserModel.fromJson(user)));
        _searchResults
            .addAll(results['posts'].map((post) => Post.fromJson(post)));
      });
    } catch (e) {
      // Handle error
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white, // Background color of the search bar
            borderRadius: BorderRadius.circular(30), // Rounded border
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for posts and users...',
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.grey[800]),
              suffixIcon: IconButton(
                icon: Icon(Icons.search, color: Colors.grey[800]),
                onPressed: search, // Call the search function here
              ),
            ),
            style: const TextStyle(color: Colors.black),
          ),
        ),
      ),
      body: _buildSearchResults(),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        if (result is UserModel) {
          return UserWidget(user: result);
        } else if (result is Post) {
          return PostWidget(post: result);
        } else {
          return const ListTile(title: Text('Unknown type'));
        }
      },
    );
  }
}
