import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:language_picker/language_picker_dialog.dart';
import 'package:language_picker/languages.dart';
import 'package:quickpost_flutter/models/post_model.dart';
import 'package:quickpost_flutter/models/user_model.dart';
import 'package:quickpost_flutter/screens/hashtagposts_screen.dart';
import 'package:quickpost_flutter/screens/profile_screen.dart';
import 'package:quickpost_flutter/screens/viewimage_screen.dart';
import 'package:quickpost_flutter/services/auth_service.dart';
import 'package:quickpost_flutter/services/post_service.dart';
import 'package:quickpost_flutter/services/socket_service.dart';
import 'package:quickpost_flutter/widgets/post_more_actions_modal.dart';
import 'package:quickpost_flutter/widgets/post_stats.dart';
import 'package:translator/translator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:visibility_detector/visibility_detector.dart';

class PostWidget extends StatefulWidget {
  final Post post;

  const PostWidget({Key? key, required this.post}) : super(key: key);

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  bool isExpanded = false;
  bool isLiked = false;
  final PostService postService = PostService();
  String? currentUserId;
  final AuthService authService = AuthService();
  final _storage = const FlutterSecureStorage();
  late bool showMoreButton;
  UserModel? _user;
  Timer? _visibilityTimer;
  final Duration _visibilityDuration = const Duration(seconds: 0);
  late StreamSubscription _likeSubscription;
  late StreamSubscription _unlikeSubscription;
  String? translatedText;
  bool _isTranslated = false;
  bool _isTranslating = false;

  @override
  void initState() {
    isLiked = widget.post.isLikedByCurrentUser;
    bool showMoreButton = widget.post.caption.length > 100 && !isExpanded;
    _getCurrentUserId();
    _loadUserInfo();
    // postService.markPostSeen(widget.post.id.toString());
    super.initState();
    _listenToLikeEvents();
    _listenToUnlikeEvents();
  }

  void _showLanguagePicker(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => LanguagePickerDialog(
          titlePadding: const EdgeInsets.all(8.0),
          searchCursorColor: Colors.pink,
          searchInputDecoration: const InputDecoration(hintText: 'Search...'),
          isSearchable: true,
          title: const Text('Select your language'),
          onValuePicked: (Language language) {
            // When a language is picked, translate the text
            translatePost(widget.post.caption, language.isoCode);
          },
          itemBuilder: _buildDialogItem),
    );
  }

  Widget _buildDialogItem(Language language) {
    return Row(
      children: <Widget>[
        Text(language.name),
        const SizedBox(width: 8.0),
        Flexible(child: Text("(${language.isoCode})"))
      ],
    );
  }

  void translatePost(String text, String langCode) async {
    try {
      if (!_isTranslated) {
        setState(() {
          _isTranslating = true; // Start translating
        });
        final translator = GoogleTranslator();
        var translation = await translator.translate(text, to: langCode);
        setState(() {
          translatedText = translation.text;
          _isTranslated = true;
          _isTranslating = false; // Translation finished
        });
      } else {
        revertToOriginal();
      }
    } catch (e) {
      setState(() {
        _isTranslating =
            false; // Ensure we reset translating state on error too
      });
      _showErrorDialog(context, "Error",
          "Language not supported or other translation error occurred.");
    }
  }

  void revertToOriginal() {
    setState(() {
      translatedText = null; // Reset translated text to null
      _isTranslated = false;
    });
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(); // Dismiss the dialog
            },
          ),
        ],
      ),
    );
  }

  void _listenToLikeEvents() {
    _likeSubscription = SocketService().likeStream.listen((data) {
      // Only update if the likerUserId matches the current user's ID
      if (data['postId'] == widget.post.id &&
          data['likerUserId'] == currentUserId) {
        setState(() {
          widget.post.likeCount = data['likeCount'];
          // Update isLikedByCurrentUser only if the current user is the one who liked the post
          widget.post.isLikedByCurrentUser =
              data['likerUserId'] == currentUserId;
        });
      } else if (data['postId'] == widget.post.id) {
        // For other users, only update the like count
        setState(() {
          widget.post.likeCount = data['likeCount'];
        });
      }
    });
  }

  void _listenToUnlikeEvents() {
    _unlikeSubscription = SocketService().unlikeStream.listen((data) {
      if (data['postId'] == widget.post.id) {
        setState(() {
          widget.post.isLikedByCurrentUser = false;
          widget.post.likeCount = data['likeCount'];
        });
      }
    });
  }

  void _getCurrentUserId() async {
    final token = await _storage.read(key: 'accessToken');
    if (token != null && !Jwt.isExpired(token)) {
      try {
        // Decode the JWT token to get payload
        Map<String, dynamic> decodedToken = Jwt.parseJwt(token);
        setState(() {
          // Assuming 'id' is the key in the payload containing the user ID
          currentUserId = decodedToken['id'];
        });
      } catch (e) {
        // Handle JWT parsing error
        print("Error parsing JWT: $e");
      }
    }
  }

  void _loadUserInfo() async {
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token != null && !Jwt.isExpired(token)) {
        Map<String, dynamic> decodedToken = Jwt.parseJwt(token);
        currentUserId = decodedToken['id'];

        UserModel? user = await AuthService().fetchUserProfile(currentUserId!);

        if (user != null) {
          setState(() {
            _user = user;
          });
        }
      } else {
        print("Token not found or expired");
      }
    } catch (e) {
      print("Error loading user profile or follow status: $e");
    }
  }

  // void _getCurrentUserId() async {
  //   currentUserId = await authService.getCurrentUserId();
  //   setState(() {
  //     isLiked = currentUserId != null && widget.post.likedUserIds.contains(currentUserId);
  //   });
  // }

  String formatDate(DateTime date) {
    return DateFormat('d MMM y').format(date);
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
                if (userId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(userId: userId),
                    ),
                  );
                }
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

  void _handleLikeButtonPressed() async {
    try {
      if (widget.post.isLikedByCurrentUser) {
        // User unliked the post locally
        setState(() {
          widget.post.isLikedByCurrentUser = false;
          if (widget.post.likeCount > 0) {
            widget.post.likeCount--; // Decrement like count if unliked
          }
        });

        if (widget.post.id != null) {
          await postService.unlikePost(widget.post.id!);
        }
      } else {
        // User liked the post locally
        setState(() {
          widget.post.isLikedByCurrentUser = true;
          widget.post.likeCount++; // Increment like count if liked
        });

        if (widget.post.id != null) {
          await postService.likePost(widget.post.id!);
        }
      }
    } catch (e) {
      // Handle errors here
    }
  }

  @override
  Widget build(BuildContext context) {
    // String creationDate = formatDate(widget.post.createdat);

    return VisibilityDetector(
      key: Key('post-${widget.post.id}'),
      onVisibilityChanged: (visibilityInfo) {
        var visiblePercentage = visibilityInfo.visibleFraction * 100;
        if (visiblePercentage > 50) {
          // Considered visible if more than 50% visible
          _startVisibilityTimer();
        } else {
          _cancelVisibilityTimer();
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: Container(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 16.0,
            bottom: 8.0,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withAlpha(200),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      // Navigate to the profile screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(
                            userId: widget.post.userId,
                          ),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 26,
                      backgroundImage:
                          NetworkImage(widget.post.profileImageUrl),
                    ),
                  ),
                  const SizedBox(width: 8.5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FutureBuilder<String>(
                                    future: postService.fetchUserFullName(
                                        widget.post.userId ?? ''),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.done) {
                                        if (snapshot.hasData) {
                                          return Text(snapshot
                                              .data!); // Display the user's full name
                                        } else {
                                          return const Text('User not found');
                                        }
                                      } else {
                                        return const CircularProgressIndicator(); // Loading indicator
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8.0),
                                  const Icon(
                                    Icons.verified,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4.0),
                                  Flexible(
                                    child: GestureDetector(
                                      onTap: () {},
                                      child: Text(
                                        '@${widget.post.username} - ${formatDate(widget.post.createdAt)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(
                                                color: Colors.white
                                                    .withAlpha(100)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // InkWell(
                            //   onTap: () {
                            //     showModalBottomSheet(
                            //       context: context,
                            //       builder: (context) {
                            //         return FutureBuilder<int>(
                            //           future: ,
                            //           builder: (context, snapshot) {
                            //             if (snapshot.connectionState ==
                            //                 ConnectionState.done) {
                            //               if (snapshot.hasData) {
                            //                 return PostMoreActionsModal(
                            //                   currentUserId: snapshot.data!,
                            //                   postUserId: widget.post.userId,
                            //                   postId: widget.post.id,
                            //                 );
                            //               } else {
                            //                 // Handle the scenario when snapshot doesn't have data
                            //                 return const Center(
                            //                     child: Text(
                            //                         'Error retrieving user data'));
                            //               }
                            //             } else {
                            //               // Show loading indicator while waiting for future to complete
                            //               return const Center(
                            //                   child: CircularProgressIndicator());
                            //             }
                            //           },
                            //         );
                            //       },
                            //     );
                            //   },
                            //   customBorder: const CircleBorder(),
                            //   child: const Icon(Icons.more_horiz),
                            // ),
                            InkWell(
                              onTap: () {
                                if (currentUserId == null) {
                                  // Show an error message or a loading indicator
                                  print("User ID is not available yet.");
                                } else {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return PostMoreActionsModal(
                                        currentUserId: currentUserId!,
                                        postUserId: widget.post.userId,
                                        postId: widget.post.id,
                                        post: widget.post,
                                      );
                                    },
                                  );
                                }
                              },
                              child: const Icon(Icons.more_horiz),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4.0),
                        FutureBuilder<List<TextSpan>>(
                          future: _highlightText(
                            // Check if the caption is longer than the limit and adjust accordingly
                            isExpanded || widget.post.caption.length <= 100
                                ? translatedText ?? widget.post.caption
                                : '${widget.post.caption.substring(0, min(100, widget.post.caption.length))}...',
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.done &&
                                snapshot.hasData) {
                              List<TextSpan> textSpans = snapshot.data!;

                              // Check again before adding "Show More" to ensure caption length exceeds the limit
                              if (!isExpanded &&
                                  widget.post.caption.length > 100) {
                                textSpans.add(
                                  TextSpan(
                                    text: "Show More",
                                    style: const TextStyle(color: Colors.blue),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        setState(() {
                                          isExpanded =
                                              true; // Expand to show the full text
                                        });
                                      },
                                  ),
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        isExpanded = !isExpanded;
                                      });
                                    },
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15.0),
                                        children: textSpans,
                                      ),
                                    ),
                                  ),
                                  // Provide a "Show Less" button if the text is expanded
                                  if (isExpanded)
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          isExpanded =
                                              false; // Collapse the text
                                        });
                                      },
                                      child: const Text("Show Less",
                                          style: TextStyle(color: Colors.blue)),
                                    ),
                                ],
                              );
                            } else {
                              return const CircularProgressIndicator();
                            }
                          },
                        ),
                        TextButton(
                          onPressed: () {
                            if (!_isTranslated) {
                              _showLanguagePicker(context);
                            } else {
                              revertToOriginal();
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isTranslated
                                    ? 'Revert to Original'
                                    : 'Translate',
                                style: const TextStyle(
                                  color: Colors.blue,
                                ),
                              ),
                              if (_isTranslating) ...[
                                const SizedBox(width: 10),
                                const SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        if (widget.post.imageUrl?.isNotEmpty == true)
                          Column(
                            children: [
                              const SizedBox(height: 8.0),
                              InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ViewImageScreen(
                                          imageUrl: widget.post.imageUrl!),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.0),
                                    border: Border.all(
                                      color: Colors.white.withAlpha(200),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Image.network(widget.post.imageUrl!),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 8.0),
                        PostStats(
                          post: widget.post,
                          isLiked: widget.post.isLikedByCurrentUser,
                          likeCount: widget.post.likeCount,
                          onLikeButtonPressed: _handleLikeButtonPressed,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startVisibilityTimer() {
    _cancelVisibilityTimer(); // Cancel any existing timer
    _visibilityTimer = Timer(_visibilityDuration, () {
      // Mark the post as seen
      _markPostAsSeen();
    });
  }

  void _cancelVisibilityTimer() {
    if (_visibilityTimer != null) {
      _visibilityTimer!.cancel();
      _visibilityTimer = null;
    }
  }

  void _markPostAsSeen() {
    // Implement the logic to mark the post as seen
    // This could involve calling a method on your PostService
    // print("Marking post as seen: ${widget.post.id}");
    postService.markPostSeen(widget.post.id.toString());
  }

  @override
  void dispose() {
    _cancelVisibilityTimer();
    _likeSubscription.cancel();
    _unlikeSubscription.cancel();
    super.dispose();
  }
}
