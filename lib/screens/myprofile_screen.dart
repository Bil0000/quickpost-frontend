import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:quickpost_flutter/models/comment_model.dart';
import 'package:quickpost_flutter/models/follower_model.dart';
import 'package:quickpost_flutter/models/following_model.dart';
import 'package:quickpost_flutter/models/post_model.dart';

import 'package:quickpost_flutter/models/user_model.dart';
import 'package:quickpost_flutter/screens/edit_profile_screen.dart';
import 'package:quickpost_flutter/screens/profile_screen.dart';
import 'package:quickpost_flutter/screens/viewimage_screen.dart';
import 'package:quickpost_flutter/services/auth_service.dart';
import 'package:quickpost_flutter/services/comment_service.dart';
import 'package:quickpost_flutter/services/post_service.dart';
import 'package:quickpost_flutter/utils/format_number.dart';
import 'package:quickpost_flutter/widgets/comment_widget.dart';
import 'package:quickpost_flutter/widgets/post_widget.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen>
    with SingleTickerProviderStateMixin {
  AuthService authService = AuthService();
  final _storage = const FlutterSecureStorage();
  UserModel? _user;
  late TabController _tabController;
  bool isLoading = true;
  bool currentUserIsFollowing = false;
  int postCount = 0;
  int followerCount = 0;
  int? currentUserID;
  int? profileUserID;
  bool _isLoading = true;
  List<Post> _userPosts = [];
  List<Comment> _userComments = [];
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserId();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 0) {
        _loadUserPosts();
      }
      if (_tabController.index == 1) {
        _loadUserComments();
      }
    });

    // Load user profile and follow status
    _loadUserProfile();

    // Load posts initially without needing to switch tabs
    _loadUserPosts();
    _loadUserComments();
  }

  void _fetchCurrentUserId() async {
    // Fetch the current user ID asynchronously
    String? userId = await AuthService().getCurrentUserId();
    // Check if the widget is still mounted before calling setState
    if (mounted) {
      setState(() {
        currentUserId = userId;
      });
    }
  }

  void _loadUserPosts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token != null && !Jwt.isExpired(token)) {
        Map<String, dynamic> decodedToken = Jwt.parseJwt(token);
        String userId = decodedToken['id'];

        _userPosts = await PostService().fetchUserPosts(userId);
      }
    } catch (e) {
      print("Error loading posts: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadUserProfile() async {
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token != null && !Jwt.isExpired(token)) {
        Map<String, dynamic> decodedToken = Jwt.parseJwt(token);
        String userId = decodedToken['id'];

        UserModel? user = await AuthService().fetchUserProfile(userId);
        int postCount = await PostService().fetchPostCount(userId);

        if (user != null) {
          setState(() {
            _user = user;
            this.postCount = postCount;
            _isLoading = false;
          });
        } else {
          // Handle user not found or unable to fetch user profile
        }
      } else {
        // Handle token not found or expired
      }
    } catch (e) {
      print("Error loading user profile: $e");
      // Handle errors, e.g., token parsing errors, network errors, etc.
    }
  }

  void _loadUserComments() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _userComments = await CommentService().fetchUserComments(_user!.id);
    } catch (e) {
      print("Error loading comments: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showFollowers() async {
    List<FollowerModel> followers = await authService.getFollowers(_user!.id);
    _showModalBottomSheet(followers);
  }

  void _showFollowing() async {
    List<FollowingModel> following = await authService.getFollowing(_user!.id);
    _showModalBottomSheet(following);
  }

  void _showModalBottomSheet(List<dynamic> users) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        if (users.isEmpty) {
          // If the list is empty, display a message in the center
          return const Center(
            child: Text('No followers or following'),
          );
        } else {
          // If the list is not empty, use ListView.builder to display the items
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (BuildContext context, int index) {
              return InkWell(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                        userId: users[index].id,
                      ),
                    ),
                  );
                },
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: users[index].profileImageUrl != null
                        ? NetworkImage(users[index].profileImageUrl!)
                        : ''
                            as ImageProvider, // Provide a default image or handle the null case
                  ),
                  title: Text(users[index].fullname),
                  subtitle: Text('@${users[index].username}'),
                ),
              );
            },
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const double avatarRadius = 50;
    const double avatarDiameter = avatarRadius * 2;
    const double bannerHeight = 200;

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Column(
            children: [
              Text(
                _user?.username ?? '',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                '$postCount Posts',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ViewImageScreen(
                                imageUrl: _user?.bannerImageUrl ?? '',
                              ),
                            ),
                          );
                        },
                        child: Image.network(
                          _user?.bannerImageUrl ?? '',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: bannerHeight,
                        ),
                      ),
                      Positioned(
                        left: 16,
                        bottom: -(avatarDiameter / 2),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ViewImageScreen(
                                  imageUrl: _user?.profileImageUrl ?? '',
                                ),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(
                              _user?.profileImageUrl ?? '',
                            ),
                            radius: avatarRadius,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 16,
                        top: 16,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => EditProfileScreen(
                                  profileBannerUrl: _user?.bannerImageUrl ?? '',
                                  profileImageUrl: _user?.profileImageUrl ?? '',
                                  user: _user!,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor: Colors.white,
                          ),
                          child: const Text('Edit Profile'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: avatarRadius + 16),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${_user?.fullname} (You)',
                            style: Theme.of(context).textTheme.titleLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Handle button press for current user
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                          ),
                          icon: const Icon(
                            Icons.person_add,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Follow',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      '@${_user?.username}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(_user?.bio.isNotEmpty == true
                        ? _user?.bio ?? ''
                        : 'No bio'),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 15),
                        child: InkWell(
                          onTap: () => _showFollowers(),
                          child: _buildCountColumn(
                              'Followers', formatNumber(_user?.followerCount)),
                        ),
                      ),
                      const SizedBox(width: 15),
                      InkWell(
                        onTap: () => _showFollowing(),
                        child: _buildCountColumn(
                            'Following', formatNumber(_user?.followingCount)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Posts'),
                    Tab(text: 'Comments'),
                  ],
                ),
              ),
              pinned: true,
            ),
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Padding(
                          padding: const EdgeInsets.only(top: 45),
                          child: ListView.builder(
                            itemCount: _userPosts.length,
                            itemBuilder: (context, index) {
                              final post = _userPosts[index];
                              return PostWidget(post: post);
                            },
                          ),
                        ),
                  // Comments tab content
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Padding(
                          padding: const EdgeInsets.only(top: 50),
                          child: ListView.builder(
                            itemCount: _userComments.length,
                            itemBuilder: (context, index) {
                              final comment = _userComments[index];
                              return CommentWidget(
                                comment: comment,
                                currentUserId: currentUserId.toString(),
                              );
                            },
                          ),
                        ),
                ],
              ),
            ),
          ],
        )
        // : const Center(child: Text('User not found')),
        );
  }

  // Widget _buildPostsTab(int userId) {
  //   return FutureBuilder<List<Post>>(
  //     future: fetchUserPosts(userId),
  //     builder: (context, snapshot) {
  //       if (snapshot.connectionState == ConnectionState.waiting) {
  //         return const Center(child: CircularProgressIndicator());
  //       } else if (snapshot.hasError) {
  //         return Center(child: Text('Error: ${snapshot.error}'));
  //       } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
  //         return const Center(child: Text('No posts found.'));
  //       } else {
  //         return ListView.builder(
  //           itemCount: snapshot.data!.length,
  //           itemBuilder: (context, index) {
  //             var post = snapshot.data![index];
  //             return PostWidget(post: post); // Use your PostWidget here
  //           },
  //         );
  //       }
  //     },
  //   );
  // }

  // Widget _buildCommentsTab(int userId) {
  //   return FutureBuilder<List<Comment>>(
  //     future: fetchUserComments(userId),
  //     builder: (context, snapshot) {
  //       if (snapshot.connectionState == ConnectionState.waiting) {
  //         return const Center(child: CircularProgressIndicator());
  //       } else if (snapshot.hasError) {
  //         return Center(child: Text('Error: ${snapshot.error}'));
  //       } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
  //         return const Center(child: Text('No comments found.'));
  //       } else {
  //         return ListView.builder(
  //           itemCount: snapshot.data!.length,
  //           itemBuilder: (context, index) {
  //             var comment = snapshot.data![index];
  //             return Padding(
  //               padding: const EdgeInsets.only(top: 10),
  //               child: CommentWidget(
  //                 comment: comment,
  //                 currentUserId: currentUserID!, // Pass the current user's ID
  //                 // You may pass additional callbacks if your CommentWidget requires them
  //               ),
  //             );
  //           },
  //         );
  //       }
  //     },
  //   );
  // }

  Row _buildCountColumn(String label, count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("${count.toString()} ",
            style: const TextStyle(fontSize: 23.5, fontWeight: FontWeight.bold)
            // Theme.of(context).textTheme.titleLarge,
            ),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      elevation: 4.0,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
