import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quickpost_flutter/models/comment_model.dart';

import '../widgets/comment_widget.dart';

class CommentsScreen extends StatefulWidget {
  final Comment? comment;
  final String postId;
  final String userId;

  const CommentsScreen(
      {Key? key, required this.postId, required this.userId, this.comment})
      : super(key: key);

  @override
  _CommentsScreenState createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  File? _image;
  String? _base64Image;
  List<Comment> comments = [];
  int page = 0;
  bool _isReplying = false;

  Future pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      final bytes = await _image!.readAsBytes();
      setState(() {
        _base64Image = base64Encode(bytes);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (comments.isEmpty)
            const Center(
              child: Text(
                'Currently this post has no Comments',
                style: TextStyle(fontSize: 17),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: comments.length,
              itemBuilder: (context, index) {
                // Check if the comment is a top-level comment
                if (comments[index].parentComment == null) {
                  return CommentWidget(
                    comment: comments[index],
                    currentUserId: widget.userId,
                    onCommentDeleted: () {
                      setState(() {
                        // Remove the comment from the list and update UI
                        comments.removeWhere((c) => c.id == comments[index].id);
                      });
                    },
                    onStartReplying: () => setState(() => _isReplying = true),
                    onStopReplying: () => setState(() => _isReplying = false),
                  );
                } else {
                  // For replies, either handle them here or ensure they're not added to the main comments list
                  return Container(); // Or your custom logic for replies
                }
              },
            ),
          ),
          if (_image != null) // Image display condition
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    constraints: const BoxConstraints(
                      maxHeight: 250,
                    ),
                    child: Image.file(_image!),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _image = null;
                        _base64Image = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          _buildCommentInputField(),
        ],
      ),
    );
  }

  Widget _buildCommentInputField() {
    final TextEditingController commentController = TextEditingController();

    if (_isReplying) {
      return Container(); // Return an empty container when replying
    }

    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 10),
          child: IconButton(
              onPressed: pickImage, icon: const Icon(Icons.photo_camera)),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 5, bottom: 20),
            child: TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: 'Write a comment...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}
