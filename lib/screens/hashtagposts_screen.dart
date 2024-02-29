import 'package:flutter/material.dart';
import 'package:quickpost_flutter/models/post_model.dart';
import 'package:quickpost_flutter/services/post_service.dart';
import 'package:quickpost_flutter/widgets/post_widget.dart';

class HashtagPostsScreen extends StatefulWidget {
  final String hashtag;

  const HashtagPostsScreen({Key? key, required this.hashtag}) : super(key: key);

  @override
  _HashtagPostsScreenState createState() => _HashtagPostsScreenState();
}

class _HashtagPostsScreenState extends State<HashtagPostsScreen> {
  late Future<List<Post>> postsFuture;

  @override
  void initState() {
    super.initState();
    postsFuture =
        PostService().fetchPostsByHashtag(widget.hashtag.replaceAll('#', ''));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Posts with ${widget.hashtag}'),
      ),
      body: FutureBuilder<List<Post>>(
        future: postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Text('No posts found with this hashtag.');
          } else {
            // Display the list of posts
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                Post post = snapshot.data![index];
                return PostWidget(post: post);
              },
            );
          }
        },
      ),
    );
  }
}
