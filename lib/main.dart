import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:quickpost_flutter/controllers/notification_controller.dart';
import 'package:quickpost_flutter/screens/contact_form_screen.dart';
import 'package:quickpost_flutter/screens/feed_screen.dart';
import 'package:quickpost_flutter/screens/login_screen.dart';
import 'package:quickpost_flutter/screens/main_screen.dart';
import 'package:quickpost_flutter/screens/post_details_screen.dart';
import 'package:quickpost_flutter/screens/profile_screen.dart';
import 'package:quickpost_flutter/screens/registration_screen.dart';
import 'package:quickpost_flutter/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_links/uni_links.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SocketService socketService = SocketService();
  // socketService.connect();

  // Initialize AuthService
  AuthService authService = AuthService();

  // Check if the refresh token is present
  String? refreshToken = await authService.getRefreshToken();

  runApp(MyApp(refreshToken: refreshToken));

  SharedPreferences prefs = await SharedPreferences.getInstance();

  bool soundEnabled = prefs.getBool('soundEnabled') ?? true;
  bool vibrateEnabled = prefs.getBool('vibrateEnabled') ?? true;

  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic notifications',
        channelDescription: 'Notification channel for basic messages',
        defaultColor: const Color(0xFF9D50DD),
        ledColor: Colors.white,
        // importance:
        //     NotificationImportance.High, // For Android heads-up notification
        channelShowBadge: true,
        enableVibration: vibrateEnabled,
        playSound: soundEnabled,
      )
    ],
  );
}

class MyApp extends StatefulWidget {
  final String? refreshToken;

  const MyApp({Key? key, this.refreshToken}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    initUniLinks();
    NotificationController.setNavigatorKey(navigatorKey);
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
      onNotificationCreatedMethod:
          NotificationController.onNotificationCreatedMethod,
      onNotificationDisplayedMethod:
          NotificationController.onNotificationDisplayedMethod,
      onDismissActionReceivedMethod:
          NotificationController.onDismissActionReceivedMethod,
    );
  }

  void initUniLinks() async {
    // Handle any initial link that might have triggered the app to open
    try {
      final initialUri = await getInitialUri();
      if (initialUri != null) {
        handleIncomingLink(initialUri);
      }
    } catch (e) {
      // Handle error, could be a malformed URI, etc.
    }

    // Listen for new links coming in while the app is running
    uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        handleIncomingLink(uri);
      }
    }, onError: (err) {
      // Handle errors from stream (if any)
    });
  }

  void handleIncomingLink(Uri uri) {
    // Check the link and navigate to the appropriate screen
    if (uri.host == 'viewpost') {
      String? postId = uri.queryParameters['postId'];
      if (postId != null) {
        navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (context) => PostDetailsScreen(postId: postId),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Note how we now use widget.refreshToken to access the refreshToken, since we're inside the State class
    if (widget.refreshToken != null && widget.refreshToken!.isNotEmpty) {
      AuthService authService = AuthService();
      authService.logoutIfTokenExpired(context);
    }
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'QuickPost-nest',
      theme: ThemeData.dark(
        useMaterial3: true,
      ),
      initialRoute:
          widget.refreshToken != null && widget.refreshToken!.isNotEmpty
              ? '/main'
              : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/feed': (context) => const FeedScreen(),
        '/main': (context) => const MainScreen(),
        '/profile': (context) => ProfileScreen(),
        '/contact': (context) => const ContactFormScreen(),
      },
    );
  }
}
