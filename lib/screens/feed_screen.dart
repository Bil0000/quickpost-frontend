import 'dart:async';
import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:popup_menu/popup_menu.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:quickpost_flutter/models/post_model.dart';
import 'package:quickpost_flutter/screens/myprofile_screen.dart';
import 'package:quickpost_flutter/screens/post_details_screen.dart';
import 'package:quickpost_flutter/screens/profile_screen.dart';
import 'package:quickpost_flutter/screens/search_screen.dart';
import 'package:quickpost_flutter/screens/settings_screen.dart';
import 'package:quickpost_flutter/services/post_service.dart';
import 'package:quickpost_flutter/services/socket_service.dart';
import 'package:quickpost_flutter/widgets/post_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:badges/badges.dart' as badges;

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final PostService postService = PostService();
  List<Post> posts = [];
  TabController? _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  int _selectedIndex = 0;
  int unreadNotificationCount = 0;
  GlobalKey notificationKey = GlobalKey();
  PopupMenu? menu;
  Map<String, String> titleToPostIdMap = {};

  // void updateUnreadNotificationCount(int count) {
  //   setState(() {
  //     unreadNotificationCount = count;
  //   });
  // }

  Future<void> _resetUnreadNotificationCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('badgeNumber', 0);
    setState(() {
      unreadNotificationCount = 0;
    });
    AwesomeNotifications().resetGlobalBadge();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initializeUnreadNotificationCount();
    AwesomeNotifications().isNotificationAllowed().then(
          (isAllowed) => {
            if (!isAllowed)
              {
                AwesomeNotifications().requestPermissionToSendNotifications(),
              }
          },
        );

    // AwesomeNotifications().setListeners(
    //   onActionReceivedMethod: (ReceivedAction receivedAction) async {
    //     // Handle the notification action (e.g., when the notification is tapped)
    //     String? postId = receivedAction.payload?['postId'];
    //     if (postId != null) {
    //       // Navigate to your PostDetailsScreen
    //       // Ensure you have a BuildContext or a way to navigate without context
    //       // For example, using a GlobalKey<NavigatorState>
    //       navigatorKey.currentState?.push(MaterialPageRoute(
    //           builder: (context) => PostDetailsScreen(postId: postId)));
    //     }
    //   },
    // );

    fetchNotifications();
  }

  Future<List<String>> fetchNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notifications = prefs.getStringList('notifications') ?? [];

    // Sort notifications by the time they were added (assuming they are stored in order)
    notifications.sort((a, b) {
      Map<String, dynamic> notificationA = jsonDecode(a);
      Map<String, dynamic> notificationB = jsonDecode(b);

      int timestampA = notificationA['timestamp'] ?? 0;
      int timestampB = notificationB['timestamp'] ?? 0;

      // Sort in descending order to get the most recent notifications first
      return timestampB.compareTo(timestampA);
    });

    // Return only the 5 most recent notifications
    return notifications.take(5).toList();
  }

  void showNotificationsMenu() async {
    List<String> notifications = await fetchNotifications();

    List<MenuItem> items = notifications.map((notificationString) {
      Map<String, dynamic> notification = jsonDecode(notificationString);
      String title =
          notification['body']; // Assuming this is unique enough for mapping
      String? postId = notification['payload']['postId'];
      String? userId = notification['payload']['userId'];
      String? notificationType = notification['payload']['notificationType'];

      // Store notification data as a JSON string
      Map<String, dynamic> data = {
        'postId': postId,
        'userId': userId,
        'notificationType': notificationType
      };
      String jsonData = jsonEncode(data);

      // Map title to JSON string
      titleToPostIdMap[title] = jsonData;

      return MenuItem(
        title: title,
        textAlign: TextAlign.start,
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();

    menu = PopupMenu(
      config: const MenuConfig(
        type: MenuType.list,
        itemWidth: 290,
      ),
      items: items,
      onClickMenu: onClickMenu,
      onDismiss: onDismiss,
      context: context,
    );
    menu!.show(widgetKey: notificationKey);
  }

  void onClickMenu(MenuItemProvider item) {
    String? postData = titleToPostIdMap[item.menuTitle];
    if (postData != null) {
      Map<String, dynamic> data = jsonDecode(postData);
      String? postId = data['postId'];
      String? userId = data['userId'];
      String? notificationType = data['notificationType'];

      if (notificationType == 'follow') {
        // Navigate to profile screen with user ID
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ProfileScreen(userId: userId),
        ));
      } else {
        // Navigate to post details screen
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => PostDetailsScreen(postId: postId ?? ''),
        ));
      }
    }
  }

  void onDismiss() {
    setState(() {
      _resetUnreadNotificationCount();
    });
  }

  Future<void> _initializeUnreadNotificationCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt('badgeNumber') ?? 0;
    setState(() {
      unreadNotificationCount = count;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   super.didChangeAppLifecycleState(state);
  //   // Check if the app is resumed
  //   if (state == AppLifecycleState.resumed) {
  //     resetBadgeNumber();
  //   }
  // }

  // Future<void> resetBadgeNumber() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   await prefs.setInt('badgeNumber', 0);
  //   AwesomeNotifications().resetGlobalBadge();
  // }

  // @override
  // void initState() {
  //   super.initState();
  //   _tabController = TabController(length: 2, vsync: this);
  //   _tabController?.addListener(_handleTabSelection);
  //   BlocProvider.of<FeedBloc>(context).add(const FeedLoadEvent(0, 10));
  //   _scrollController.addListener(_onScroll);
  // }

  // void _handleTabSelection() {
  //   if (_tabController?.index == 1) {
  //     // 1 represents the "Following" tab
  //     _loadFollowingPosts();
  //   }
  // }

  // void _loadFollowingPosts() async {
  //   int currentUserId = await UserSession.getUserId();
  //   UserRepository userRepository = UserRepository(client: client);
  //   List<int> followingUserIds =
  //       await userRepository.getFollowingUserIds(currentUserId);
  //   BlocProvider.of<FeedBloc>(context)
  //       .add(FeedLoadFollowingEvent(currentUserId, followingUserIds, 0, 10));
  // }

  // void _onScroll() {
  //   if (_scrollController.offset >=
  //           _scrollController.position.maxScrollExtent &&
  //       !_scrollController.position.outOfRange) {
  //     print('Reached the bottom - Current Page: $_currentPage');
  //     _currentPage++;
  //     BlocProvider.of<FeedBloc>(context).add(FeedLoadMoreEvent(_currentPage));
  //   }
  // }

  final List<Widget> screens = [
    const FeedScreen(), // Assuming this is the widget for the feed screen
    const SearchScreen(), // Replace with your actual search screen widget
    const MyProfileScreen(), // Replace with your actual profile screen widget
    const SettingsScreen(), // Replace with your actual settings screen widget
  ];

  final PageStorageBucket bucket = PageStorageBucket();
  Widget currentScreen = const FeedScreen();

  Widget _buildBottomAppBarItem({required IconData icon, required int index}) {
    return IconButton(
      icon: Icon(
        icon,
        size: 30,
        color: _selectedIndex == index ? Colors.blue : Colors.grey,
      ),
      onPressed: () {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: Image.asset('assets/logo.png', height: 100),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: badges.Badge(
                badgeContent: Text('$unreadNotificationCount'),
                showBadge: unreadNotificationCount > 0,
                position: badges.BadgePosition.topEnd(top: 0, end: 3),
                child: IconButton(
                  key: notificationKey,
                  icon: const Icon(Icons.notifications),
                  onPressed: () {
                    showNotificationsMenu();
                  },
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56.0),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'For you'),
                Tab(text: 'Following'),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              controller: _tabController,
              children: [
                _FeedForYouTab(scrollController: _scrollController),
                _FeedFollowingTab(scrollController: _scrollController),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedForYouTab extends StatefulWidget {
  final ScrollController scrollController;

  const _FeedForYouTab({Key? key, required this.scrollController})
      : super(key: key);

  @override
  _FeedForYouTabState createState() => _FeedForYouTabState();
}

class _FeedForYouTabState extends State<_FeedForYouTab> {
  final PostService postService = PostService();

  List<Post> _allPosts = [];
  final ValueNotifier<bool> _showNewPostBanner = ValueNotifier(false);
  bool _isLoading = false;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _fetchInitialPosts();
    captureScreen();
    SocketService().connect();

    // Initial fetch of posts
    postService.fetchPosts().then((initialPosts) {
      if (mounted) {
        setState(() {
          _allPosts = initialPosts;
        });
      }
    });

    // Listen to new posts and add them to the list
    // Listen to new posts and add them to the list or show banner based on scroll position
    SocketService().postStream.listen((newPost) {
      if (!mounted) return;

      // Check if the user is at the top of the feed
      bool isAtTop = widget.scrollController.offset <= 100;

      if (isAtTop) {
        // User is at the top, insert new post directly
        setState(() {
          _allPosts.insert(
              0, newPost); // Add new post at the beginning of the list
        });
      } else {
        _allPosts.insert(0, newPost);
        // User has scrolled down, show banner to indicate new posts
        _showNewPostBanner.value = true;
      }
    });

    // Listening to the delete event stream
    SocketService().deleteStream.listen((deletedPost) {
      if (mounted) {
        setState(() {
          // This efficiently updates the list and UI with minimal overhead
          _allPosts.removeWhere((post) => post.id == deletedPost.id);
        });
      }
    });

    SocketService().likeStream.listen((data) {
      final index = _allPosts.indexWhere((post) => post.id == data['postId']);
      if (index != -1) {
        setState(() {
          _allPosts[index].likeCount = data['likeCount'];
        });
      }
    });

    SocketService().unlikeStream.listen((data) {
      final index = _allPosts.indexWhere((post) => post.id == data['postId']);
      if (index != -1) {
        setState(() {
          _allPosts[index].isLikedByCurrentUser = false;
          _allPosts[index].likeCount = data['likeCount'];
        });
      }
    });

    // Listen to scroll position changes
    widget.scrollController.addListener(() {
      if (widget.scrollController.offset <= 100) {
        // If at the top, hide the banner
        _showNewPostBanner.value = false;
      }
    });

    widget.scrollController.addListener(() {
      double maxScroll = widget.scrollController.position.maxScrollExtent;
      double currentScroll = widget.scrollController.position.pixels;
      double delta = 100.0; // or something else you want
      if (maxScroll - currentScroll <= delta) {
        // Start loading more posts earlier
        _fetchMorePosts();
      }
    });
  }

  void _fetchInitialPosts() async {
    List<Post> initialPosts = await postService.fetchPosts();
    setState(() {
      _allPosts = initialPosts;
    });
  }

  void _fetchMorePosts() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads

    setState(() {
      _isLoading = true;
    });

    List<Post> morePosts = await postService.fetchPosts(
        offset: _allPosts.length, limit: _pageSize);

    setState(() {
      _allPosts.addAll(morePosts);
      _isLoading = false;
    });
  }

  Future<void> captureScreen() async {
    return await Posthog().screen(
      screenName: 'For you tab',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView.builder(
          physics: const ClampingScrollPhysics(),
          key: const PageStorageKey<String>('postList'),
          controller: widget.scrollController,
          itemCount: _allPosts.length + (_isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < _allPosts.length) {
              return PostWidget(post: _allPosts[index]);
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _showNewPostBanner,
          builder: (context, value, child) {
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              top: value ? 0 : -60, // Use the value to determine the position
              left: 0,
              right: 0,
              child: child!,
            );
          },
          child: _buildNewPostBanner(), // Passing child here to avoid rebuilds
        ),
      ],
    );
  }

  Widget _buildNewPostBanner() {
    return Container(
      color: Colors.blue,
      padding: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () {
          scrollToTop();
        },
        child: const Text(
          "New posts available - Tap to view",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void scrollToTop() {
    widget.scrollController.animateTo(
      0,
      duration: const Duration(seconds: 1),
      curve: Curves.easeOut,
    );
    _showNewPostBanner.value =
        false; // Update the notifier instead of calling setState
  }
}

class _FeedFollowingTab extends StatefulWidget {
  final ScrollController scrollController;

  const _FeedFollowingTab({super.key, required this.scrollController});

  @override
  State<_FeedFollowingTab> createState() => __FeedFollowingTabState();
}

class __FeedFollowingTabState extends State<_FeedFollowingTab> {
  final PostService postService = PostService();

  List<Post> _allPosts = [];
  final ValueNotifier<bool> _showNewPostBanner = ValueNotifier(false);
  bool _isLoading = false;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _fetchInitialPosts();
    captureScreen();
    SocketService().connect();

    // Initial fetch of posts
    postService.fetchFollowingPosts().then((initialPosts) {
      if (mounted) {
        setState(() {
          _allPosts = initialPosts;
        });
      }
    });

    // Listen to new posts and add them to the list
    // Listen to new posts and add them to the list or show banner based on scroll position
    SocketService().postStream.listen((newPost) {
      if (!mounted) return;

      // Check if the user is at the top of the feed
      bool isAtTop = widget.scrollController.offset <= 100;

      if (isAtTop) {
        // User is at the top, insert new post directly
        setState(() {
          _allPosts.insert(
              0, newPost); // Add new post at the beginning of the list
        });
      } else {
        _allPosts.insert(0, newPost);
        // User has scrolled down, show banner to indicate new posts
        _showNewPostBanner.value = true;
      }
    });

    // Listening to the delete event stream
    SocketService().deleteStream.listen((deletedPost) {
      if (mounted) {
        setState(() {
          // This efficiently updates the list and UI with minimal overhead
          _allPosts.removeWhere((post) => post.id == deletedPost.id);
        });
      }
    });

    SocketService().likeStream.listen((data) {
      final index = _allPosts.indexWhere((post) => post.id == data['postId']);
      if (index != -1) {
        setState(() {
          _allPosts[index].likeCount = data['likeCount'];
        });
      }
    });

    SocketService().unlikeStream.listen((data) {
      final index = _allPosts.indexWhere((post) => post.id == data['postId']);
      if (index != -1) {
        setState(() {
          _allPosts[index].isLikedByCurrentUser = false;
          _allPosts[index].likeCount = data['likeCount'];
        });
      }
    });

    // Listen to scroll position changes
    widget.scrollController.addListener(() {
      if (widget.scrollController.offset <= 100) {
        // If at the top, hide the banner
        _showNewPostBanner.value = false;
      }
    });

    widget.scrollController.addListener(() {
      double maxScroll = widget.scrollController.position.maxScrollExtent;
      double currentScroll = widget.scrollController.position.pixels;
      double delta = 100.0; // or something else you want
      if (maxScroll - currentScroll <= delta) {
        // Start loading more posts earlier
        _fetchMorePosts();
      }
    });
  }

  void _fetchInitialPosts() async {
    List<Post> initialPosts = await postService.fetchFollowingPosts();
    setState(() {
      _allPosts = initialPosts;
    });
  }

  void _fetchMorePosts() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads

    setState(() {
      _isLoading = true;
    });

    List<Post> morePosts = await postService.fetchFollowingPosts(
        offset: _allPosts.length, limit: _pageSize);

    setState(() {
      _allPosts.addAll(morePosts);
      _isLoading = false;
    });
  }

  Future<void> captureScreen() async {
    return await Posthog().screen(
      screenName: 'Following tab',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView.builder(
          physics: const ClampingScrollPhysics(),
          key: const PageStorageKey<String>('postList'),
          controller: widget.scrollController,
          itemCount: _allPosts.length + (_isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < _allPosts.length) {
              return PostWidget(post: _allPosts[index]);
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _showNewPostBanner,
          builder: (context, value, child) {
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              top: value ? 0 : -60, // Use the value to determine the position
              left: 0,
              right: 0,
              child: child!,
            );
          },
          child: _buildNewPostBanner(), // Passing child here to avoid rebuilds
        ),
      ],
    );
  }

  Widget _buildNewPostBanner() {
    return Container(
      color: Colors.blue,
      padding: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () {
          scrollToTop();
        },
        child: const Text(
          "New posts available - Tap to view",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void scrollToTop() {
    widget.scrollController.animateTo(
      0,
      duration: const Duration(seconds: 1),
      curve: Curves.easeOut,
    );
    _showNewPostBanner.value =
        false; // Update the notifier instead of calling setState
  }
}
