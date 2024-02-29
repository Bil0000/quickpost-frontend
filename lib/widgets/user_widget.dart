import 'package:flutter/material.dart';
import 'package:quickpost_flutter/models/user_model.dart';
import 'package:quickpost_flutter/screens/profile_screen.dart';
import 'package:quickpost_flutter/services/auth_service.dart';

class UserWidget extends StatefulWidget {
  final UserModel user;

  const UserWidget({Key? key, required this.user}) : super(key: key);

  @override
  _UserWidgetState createState() => _UserWidgetState();
}

class _UserWidgetState extends State<UserWidget> {
  bool currentUserIsFollowing = false;
  String? currentUserID;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    currentUserID = await _authService.getCurrentUserId();
    if (currentUserID != null && widget.user.id != currentUserID) {
      var isFollowing = await _authService.checkIfFollowing(widget.user.id);
      setState(() {
        currentUserIsFollowing = isFollowing;
      });
    }
  }

  Future<void> _toggleFollowStatus() async {
    if (currentUserID != null && widget.user.id != currentUserID) {
      if (currentUserIsFollowing) {
        await _authService.unfollowUser(widget.user.id);
      } else {
        await _authService.followUser(widget.user.id);
      }
      setState(() {
        currentUserIsFollowing = !currentUserIsFollowing;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isCurrentUserProfile = currentUserID == widget.user.id;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userId: widget.user.id),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.all(4.0), // Reduced margin
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 8.0, vertical: 12.0), // Adjusted padding
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProfileScreen(userId: widget.user.id),
                    ),
                  );
                },
                child: CircleAvatar(
                  backgroundImage: NetworkImage(
                    widget.user.profileImageUrl,
                  ),
                  radius: 25.0,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.user.fullname,
                                style: Theme.of(context).textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '@${widget.user.username}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall, // Styling for username
                              ),
                            ],
                          ),
                        ),

                        const Spacer(), // Add this Spacer
                        if (!isCurrentUserProfile) // Conditionally render the button
                          ElevatedButton.icon(
                            onPressed: _toggleFollowStatus,
                            icon: currentUserIsFollowing
                                ? const Icon(
                                    Icons.person_remove,
                                    color: Colors.white,
                                  )
                                : const Icon(
                                    Icons.person_add,
                                    color: Colors.white,
                                  ),
                            label: Text(
                              currentUserIsFollowing ? 'Unfollow' : 'Follow',
                              style: const TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: currentUserIsFollowing
                                  ? Colors.red
                                  : Colors.blue, // Color based on follow status
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4.0), // Adjusted spacing
                    Text(
                      widget.user.bio.isEmpty ?? true
                          ? 'No bio'
                          : widget.user.bio,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium, // Changed text style
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
