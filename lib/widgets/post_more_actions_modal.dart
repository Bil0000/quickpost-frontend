import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';

import 'package:quickpost_flutter/models/post_model.dart';
import 'package:quickpost_flutter/models/user_model.dart';
import 'package:quickpost_flutter/screens/editpost_screen.dart';
import 'package:quickpost_flutter/services/auth_service.dart';
import 'package:quickpost_flutter/services/post_service.dart';

class PostMoreActionsModal extends StatefulWidget {
  final String currentUserId;
  final String postUserId;
  final String? postId;
  Post post;

  PostMoreActionsModal({
    Key? key,
    required this.currentUserId,
    required this.postUserId,
    this.postId,
    required this.post,
  }) : super(key: key);

  @override
  State<PostMoreActionsModal> createState() => _PostMoreActionsModalState();
}

class _PostMoreActionsModalState extends State<PostMoreActionsModal> {
  bool isMuted = false;
  bool isBlocked = false;
  bool isFollowing = false;
  bool isLoading = true;
  int followerCount = 0;
  Post? _post;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadFollowStatus();
    _initializeModal();
  }

  void _initializeModal() async {
    final followStatus =
        await AuthService().checkIfFollowing(widget.post.userId.toString());
    final user =
        await AuthService().fetchUserProfile(widget.post.userId.toString());
    final muteStatus = await AuthService().isUserMuted(widget.post.userId);
    final blockStatus = await AuthService().isUserBlocked(widget.post.userId);

    setState(() {
      _user = user;
      isFollowing = followStatus;
      isMuted = muteStatus;
      isBlocked = blockStatus;
      isLoading =
          false; // Ensure you have a loading state to handle UI during async operations
    });
  }

  _loadFollowStatus() async {
    bool followStatus =
        await AuthService().checkIfFollowing(widget.post.userId.toString());

    UserModel? user =
        await AuthService().fetchUserProfile(widget.post.userId.toString());

    setState(() {
      _user = user;
      isFollowing = followStatus;
    });
  }

  void _handleFollowUnfollow() async {
    if (isFollowing) {
      // If currently following, then attempt to unfollow
      final response = await AuthService().unfollowUser(widget.post.userId);
      print("Unfollow response status: ${response.statusCode}");
      if (response.statusCode == 200) {
        setState(() {
          isFollowing = false;
          followerCount = _user!.followerCount--;
          print("Unfollowed successfully. New state: $isFollowing");
        });
      } else {
        // Handle error
        print("Failed to unfollow. Response: ${response.body}");
      }
    } else if (!isFollowing) {
      // If currently not following, then attempt to follow
      final response = await AuthService().followUser(widget.post.userId);
      print("Follow response status: ${response.statusCode}");
      if (response.statusCode == 200) {
        setState(() {
          isFollowing = true;
          followerCount = _user!.followerCount++;
          print("Followed successfully. New state: $isFollowing");
        });
      } else {
        // Handle error
        print("Failed to follow. Response: ${response.body}");
      }
    }
  }

  void _toggleMute(String userId) async {
    final response = isMuted
        ? await AuthService().unmuteUser(userId)
        : await AuthService().muteUser(userId);

    if (response.statusCode == 201) {
      setState(() {
        isMuted = !isMuted; // Toggle the mute state based on the response
      });
      Navigator.of(context).pop();
    } else {
      // Handle error, maybe show a snackbar with the error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update mute status')),
      );
    }
  }

  void _toggleBlock(String userId) async {
    if (isBlocked) {
      // Attempt to unblock the user
      final response = await AuthService().unblockUser(userId);
      if (response.statusCode == 201) {
        setState(() => isBlocked = false);
        Navigator.of(context).pop();
      } else {
        // Handle error
      }
    } else {
      // Attempt to block the user
      final response = await AuthService().blockUser(userId);
      if (response.statusCode == 201) {
        setState(() => isBlocked = true);
        Navigator.of(context).pop();
      } else {
        // Handle error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isOwnPost = widget.currentUserId == widget.postUserId;

    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(
              isFollowing
                  ? Icons.person_remove_alt_1_outlined
                  : Icons.person_add_alt_1_outlined,
              size: 30,
              color: isOwnPost ? Colors.grey : null, // Grey color for own post
            ),
            title: Text(
              isFollowing
                  ? 'Unfollow @${widget.post.username}'
                  : 'Follow @${widget.post.username}',
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isOwnPost
                      ? Colors.grey
                      : null), // Grey color for own post
            ),
            enabled: !isOwnPost,
            onTap: () {
              _handleFollowUnfollow();
              setState(() {
                isFollowing = !isFollowing;
                Navigator.of(context).pop();
              });
            },
          ),
          ListTile(
            leading: Icon(
              isMuted ? Icons.volume_up_outlined : Icons.volume_off_outlined,
              size: 30,
              color:
                  isOwnPost ? Colors.grey : null, // Grey out icon for own post
            ),
            title: Text(
              isMuted
                  ? 'Unmute @${widget.post.username}'
                  : 'Mute @${widget.post.username}',
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isOwnPost ? Colors.grey : null),
            ),
            onTap: () => _toggleMute(widget.postUserId),
            enabled: !isOwnPost,
          ),
          ListTile(
            leading: Icon(
              isBlocked ? Icons.lock_open : Icons.block,
              size: 30,
              color:
                  isOwnPost ? Colors.grey : null, // Grey out icon for own post
            ),
            title: Text(
              isBlocked
                  ? 'Unblock @${widget.post.username}'
                  : 'Block @${widget.post.username}',
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isOwnPost ? Colors.grey : null),
            ),
            onTap: () => _toggleBlock(widget.postUserId),
            enabled: !isOwnPost,
          ),
          // ListTile(
          //   leading: const Icon(
          //     Icons.code_outlined,
          //     size: 30,
          //   ),
          //   title: Text(
          //     'Embed Post',
          //     style: Theme.of(context)
          //         .textTheme
          //         .bodyLarge!
          //         .copyWith(fontWeight: FontWeight.bold),
          //   ),
          // ),
          if (widget.currentUserId == widget.postUserId)
            ListTile(
              leading: const Icon(Icons.update, size: 30),
              title: Text(
                'Update Post',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.of(context).pop();

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EditPostScreen(
                        postId: widget.postId!,
                        initialCaption: widget.post.caption),
                  ),
                );
              },
            ),
          if (widget.currentUserId == widget.postUserId)
            ListTile(
              leading: const Icon(Icons.delete, size: 30),
              title: Text(
                'Delete Post',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              onTap: () => _deletePost(context, widget.postId!),
            ),
          const SizedBox(height: 8.0),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56.0),
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _deletePost(BuildContext context, String postId) async {
    try {
      return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Delete Post?'),
            content: const Text(
                'Are you sure you want to delete this post? This action is irreversible.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();

                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await PostService().deletePost(postId);
                    Navigator.of(context).pop(); // Close the dialog
                    Navigator.of(context).pop(); // Close the modal bottom sheet
                    setState(() {});
                    final snackBar = SnackBar(
                      showCloseIcon: false,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      content: AwesomeSnackbarContent(
                        title: 'Success!',
                        message: 'Post deleted successfully',
                        contentType: ContentType.success,
                      ),
                      behavior: SnackBarBehavior.floating,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    return;

                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   const SnackBar(
                    //     content: Text('Post deleted successfully'),
                    //     backgroundColor: Colors.green,
                    //   ),
                    // );
                  } catch (e) {
                    Navigator.of(context)
                        .pop(); // Close the dialog if there's an error

                    final snackBar = SnackBar(
                      showCloseIcon: false,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      content: AwesomeSnackbarContent(
                        title: 'Error!',
                        message: 'Error deleting post: ${e.toString()}',
                        contentType: ContentType.failure,
                      ),
                      behavior: SnackBarBehavior.floating,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    return;
                  }
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      final snackBar = SnackBar(
        showCloseIcon: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: AwesomeSnackbarContent(
          title: 'Error!',
          message: 'Error: ${e.toString()}',
          contentType: ContentType.failure,
        ),
        behavior: SnackBarBehavior.floating,
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
    }
  }
}
