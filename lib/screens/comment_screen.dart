import 'dart:convert';
import 'dart:io';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quickpost_flutter/models/comment_model.dart';
import 'package:quickpost_flutter/services/comment_service.dart';

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
  final TextEditingController commentController = TextEditingController();

  File? _image;
  String? _base64Image;
  List<Comment> comments = [];
  int page = 0;
  bool _isReplying = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      List<Comment> loadedComments =
          await CommentService().loadComments(widget.postId);
      setState(() {
        comments = loadedComments;
      });
    } catch (e) {
      print("Failed to load comments: $e");
      // Optionally, show an error message in the UI
    }
  }

  Future<void> _submitComment() async {
    String text = commentController.text.trim();
    if (text.isNotEmpty) {
      try {
        await CommentService().submitComment(widget.postId, text);
        commentController.clear();
        // Optionally, clear _replyingToCommentId if you're replying to a specific comment
        _loadComments(); // Reload comments to show the newly added comment
      } catch (e) {
        print("Failed to submit comment: $e");
        final snackBar = SnackBar(
          showCloseIcon: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: AwesomeSnackbarContent(
            title: 'Error!',
            message: 'Failed to add comment',
            contentType: ContentType.failure,
          ),
          behavior: SnackBarBehavior.floating,
        );

        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

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
            onPressed: _submitComment,
          ),
        ),
      ],
    );
  }
}
