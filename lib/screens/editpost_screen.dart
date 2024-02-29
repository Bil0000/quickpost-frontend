import 'dart:convert';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:quickpost_flutter/services/post_service.dart';

class EditPostScreen extends StatefulWidget {
  final String postId;
  final String initialCaption;

  const EditPostScreen({
    Key? key,
    required this.postId,
    required this.initialCaption,
  }) : super(key: key);

  @override
  _EditPostScreenState createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _captionController.text = widget.initialCaption;
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _editPost() async {
    try {
      final response =
          await PostService().editPost(widget.postId, _captionController.text);

      if (response.statusCode == 200) {
        final snackBar = SnackBar(
          showCloseIcon: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: AwesomeSnackbarContent(
            title: 'Success!',
            message: 'Post edited successfully',
            contentType: ContentType.success,
          ),
          behavior: SnackBarBehavior.floating,
        );

        ScaffoldMessenger.of(context).showSnackBar(snackBar);

        Navigator.of(context).pop();
      } else if (response.statusCode == 403 || response.statusCode == 401) {
        // Show Forbidden error message using SnackBar
        final responseData = json.decode(response.body);
        final errorMessage = responseData['message'] ?? 'Forbidden';

        final snackBar = SnackBar(
          showCloseIcon: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: AwesomeSnackbarContent(
            title: 'Error Ocured!',
            message: '$errorMessage',
            contentType: ContentType.failure,
          ),
          behavior: SnackBarBehavior.floating,
        );

        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      } else {
        // handle other status codes
        final responseData = json.decode(response.body);
        final errorMessage = responseData['message'] ?? '';

        final snackBar = SnackBar(
          showCloseIcon: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: AwesomeSnackbarContent(
            title: 'Error!',
            message: 'Error editing post: $errorMessage',
            contentType: ContentType.failure,
          ),
          behavior: SnackBarBehavior.floating,
        );

        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      // Handle other errors
      final snackBar = SnackBar(
        showCloseIcon: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: AwesomeSnackbarContent(
          title: 'Error!',
          message: 'Error editing post: ${e.toString()}',
          contentType: ContentType.failure,
        ),
        behavior: SnackBarBehavior.floating,
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _captionController,
              decoration: const InputDecoration(labelText: 'Caption'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _editPost,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
