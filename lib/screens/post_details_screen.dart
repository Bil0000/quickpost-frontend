import 'package:flutter/material.dart';
import 'package:quickpost_flutter/models/post_model.dart';
import 'package:quickpost_flutter/widgets/post_widget.dart';

import '../services/post_service.dart';

class PostDetailsScreen extends StatefulWidget {
  final String postId;

  const PostDetailsScreen({Key? key, required this.postId}) : super(key: key);

  @override
  _PostDetailsScreenState createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  late Future<Post> postDetails;

  @override
  void initState() {
    super.initState();
    // Adjust this line to use your PostService instance
    postDetails = PostService().getPostById(widget.postId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
      ),
      body: FutureBuilder<Post>(
        future: postDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error.toString()}'));
          } else if (snapshot.hasData) {
            return SingleChildScrollView(
              child: PostWidget(post: snapshot.data!),
            );
          } else {
            return const Center(child: Text('Post not found'));
          }
        },
      ),
    );
  }
}
