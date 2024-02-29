import 'package:flutter/material.dart';
import 'package:quickpost_flutter/models/post_model.dart';

class PostManager {
  static final PostManager _instance = PostManager._internal();
  List<Post> posts = [];
  VoidCallback? onPostsUpdated;

  factory PostManager() {
    return _instance;
  }

  PostManager._internal();

  void addPost(Post post) {
    posts.insert(0, post);
    onPostsUpdated?.call();
  }
}
