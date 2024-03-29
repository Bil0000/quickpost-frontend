import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quickpost_flutter/models/comment_model.dart';
import 'package:quickpost_flutter/models/user_model.dart';
import 'package:quickpost_flutter/screens/hashtagposts_screen.dart';
import 'package:quickpost_flutter/screens/profile_screen.dart';
import 'package:quickpost_flutter/screens/viewimage_screen.dart';
import 'package:quickpost_flutter/services/comment_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/auth_service.dart';

class CommentWidget extends StatefulWidget {
  final Comment comment;
  final String currentUserId;
  final VoidCallback? onCommentDeleted;
  final VoidCallback? onStartReplying;
  final VoidCallback? onStopReplying;

  const CommentWidget({
    Key? key,
    required this.comment,
    this.onCommentDeleted,
    required this.currentUserId,
    this.onStartReplying,
    this.onStopReplying,
  }) : super(key: key);

  @override
  _CommentWidgetState createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  final AuthService authService = AuthService();
  bool _showReplies = false;
  bool _isReplying = false;
  bool _isEditing = false;
  final Map<int, bool> _isEditingReply = {};
  final TextEditingController _replyController = TextEditingController();
  final TextEditingController _editController = TextEditingController();
  final Map<int, TextEditingController> _editReplyControllers = {};
  final List<Comment> _replies = [];

  void _startEditing() {
    _editController.text = widget.comment.text;
    setState(() {
      _isEditing = true;
    });
  }

  void _stopEditing() {
    setState(() {
      _isEditing = false;
    });
  }

  void _handleUpdateComment() async {
    if (_editController.text.isNotEmpty) {
      try {
        await CommentService()
            .updateComment(widget.comment.id.toString(), _editController.text);

        // Close the edit mode
        setState(() {
          _isEditing = false;
          widget.comment.text =
              _editController.text; // Update the local comment text
        });
      } catch (e) {
        print(e); // For debugging
        final snackBar = SnackBar(
          showCloseIcon: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: AwesomeSnackbarContent(
            title: 'Error!',
            message: 'Failed to update comment',
            contentType: ContentType.failure,
          ),
          behavior: SnackBarBehavior.floating,
        );

        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  void _startEditingReply(int replyId, String initialText) {
    _editReplyControllers[replyId] = TextEditingController(text: initialText);
    setState(() {
      _isEditingReply[replyId] = true;
    });
  }

  void _stopEditingReply(int replyId) {
    setState(() {
      _isEditingReply.remove(replyId);
      _editReplyControllers.remove(replyId);
    });
  }

  Future<List<TextSpan>> _highlightText(String text) async {
    List<TextSpan> spans = [];
    int start = 0;
    final RegExp pattern = RegExp(
        r'(@[a-zA-Z0-9_]+)|(https?:\/\/[^\s]+)|(#\w+)',
        caseSensitive: false);
    final matches = pattern.allMatches(text);

    for (final match in matches) {
      final matchedText = match.group(0)!;
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }

      if (matchedText.startsWith('@')) {
        // Extract username without '@'
        String username = matchedText.substring(1);

        // Check if username is valid (asynchronous operation)
        bool isUsernameValid = await authService.isUsernameValid(username);

        // Only highlight if username is valid
        if (isUsernameValid) {
          spans.add(TextSpan(
            text: matchedText,
            style: const TextStyle(
                color: Colors.blue, fontWeight: FontWeight.bold),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                String? userId =
                    await authService.getUserIdByUsername(username);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(userId: userId),
                  ),
                );
              },
          ));
        } else {
          spans.add(TextSpan(text: matchedText)); // Non-highlighted text span
        }
      } else if (matchedText.startsWith('#')) {
        // Handle hashtags
        spans.add(
          TextSpan(
            text: matchedText,
            style:
                TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        HashtagPostsScreen(hashtag: matchedText),
                  ),
                );
              },
          ),
        );
      } else {
        // Handle links
        spans.add(TextSpan(
          text: matchedText,
          style: const TextStyle(color: Colors.blue),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              if (await canLaunch(matchedText)) {
                await launch(matchedText);
              }
            },
        ));
      }
      start = match.end;
    }

    spans.add(TextSpan(text: text.substring(start))); // Add any remaining text
    return spans;
  }

  Widget _buildReplySection() {
    List<Comment>? replies = widget.comment.replies;
    if (replies.isEmpty) {
      return const Text("No replies yet");
    } else {
      return Column(
        children: replies
            .map((reply) => CommentWidget(
                  comment: reply,
                  currentUserId: widget.currentUserId,
                  onCommentDeleted: () =>
                      _handleReplyDeleted(reply.id.toString()),
                  onStartReplying: widget.onStartReplying,
                  onStopReplying: widget.onStopReplying,
                ))
            .toList(),
      );
    }
  }

  void _handleReplyDeleted(String replyId) {
    setState(() {
      widget.comment.replies.removeWhere((reply) => reply.id == replyId);
    });
  }

  Future<void> _submitReply() async {
    String text = _replyController.text.trim();
    if (text.isNotEmpty) {
      try {
        // submitComment now returns a Comment object including the ID
        Comment newReply = await CommentService()
            .submitComment(widget.comment.postId, text, widget.comment.id);

        setState(() {
          widget.comment.replies.insert(
              0, newReply); // Insert the new reply at the beginning of the list
          _replyController.clear();
          _isReplying = false;
        });
      } catch (e) {
        print("Failed to submit comment: $e");
        final snackBar = SnackBar(
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

  void _toggleReplies() {
    setState(() {
      _showReplies = !_showReplies;
    });
  }

  Future<String> _fetchUsername(String userId) async {
    // Replace with your actual method to fetch the username by userId
    String username = '';
    return username;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<UserModel?>(
              future: authService.fetchUserById(widget.comment.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return const Text("Error loading username");
                } else {
                  UserModel user = snapshot.data!;
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(
                            userId: user.id,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(user.profileImageUrl),
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          user.username,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 8.0),
            FutureBuilder<List<TextSpan>>(
              future: _highlightText(widget.comment.text),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData) {
                  return RichText(
                    text: TextSpan(
                      style:
                          const TextStyle(color: Colors.white, fontSize: 16.0),
                      children: snapshot.data!,
                    ),
                  );
                } else {
                  return const CircularProgressIndicator();
                }
              },
            ),
            if (widget.comment.commentImageUrl != null &&
                widget.comment.commentImageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ViewImageScreen(
                              imageUrl:
                                  widget.comment.commentImageUrl.toString()),
                        ),
                      );
                    },
                    child: Image.network(
                      widget.comment.commentImageUrl.toString(),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8.0),
            if (widget.comment.isReply == false)
              Text(
                'Commented on ${DateFormat('dd MMM yyyy').format(widget.comment.createdAt)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12.0),
              ),
            if (widget.comment.isReply == true)
              Text(
                'Replied on ${DateFormat('dd MMM yyyy').format(widget.comment.createdAt)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12.0),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _toggleReplies,
                  child: Text(
                    _showReplies
                        ? 'Hide Replies (${widget.comment.replies.length})'
                        : 'Show Replies (${widget.comment.replies.length})',
                  ),
                ),
                const Spacer(),
                if (widget.currentUserId == widget.comment.userId)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      try {
                        await CommentService()
                            .deleteComment(widget.comment.id.toString());
                        widget.onCommentDeleted?.call();
                      } catch (e) {
                        print(e);
                        final snackBar = SnackBar(
                          showCloseIcon: false,
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          content: AwesomeSnackbarContent(
                            title: 'Error!',
                            message: 'Failed to delete comment',
                            contentType: ContentType.failure,
                          ),
                          behavior: SnackBarBehavior.floating,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      }
                    },
                  ),
                if (widget.currentUserId == widget.comment.userId)
                  IconButton(
                      icon: const Icon(Icons.edit), onPressed: _startEditing),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isReplying = !_isReplying;

                      // Call the appropriate callback based on the new state
                      if (_isReplying) {
                        widget.onStartReplying?.call();
                      } else {
                        widget.onStopReplying?.call();
                      }
                    });
                  },
                  icon: const Icon(Icons.reply),
                ),
              ],
            ),
            if (_showReplies) _buildReplySection(),

            // Reply input field
            if (_isReplying)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        decoration: const InputDecoration(
                          labelText: 'Write a reply...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _submitReply,
                    ),
                  ],
                ),
              ),
            if (_isEditing)
              Column(
                children: [
                  TextField(
                    controller: _editController,
                    decoration: const InputDecoration(
                      labelText: 'Edit your comment',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: _handleUpdateComment,
                        child: const Text('Save'),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isEditing =
                                false; // Exit edit mode without saving changes
                          });
                        },
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ],
              )
          ],
        ),
      ),
    );
  }
}
