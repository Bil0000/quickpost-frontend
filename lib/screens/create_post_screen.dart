import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:giphy_picker/giphy_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:quickpost_flutter/models/post_model.dart';
import 'package:quickpost_flutter/models/user_model.dart';
import 'package:quickpost_flutter/services/auth_service.dart';
import 'package:quickpost_flutter/services/post_service.dart';
import 'package:video_player/video_player.dart';

typedef OnPostSaved = void Function(String postText, String? postImage);

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  VideoPlayerController? _videoPlayerController;
  final _storage = const FlutterSecureStorage();
  Post? _currentPost;
  String? _imagePath;
  String? _videoPath;
  UserModel? _user;
  bool _isPosting = false;
  final ValueNotifier<bool> _isPostButtonEnabled = ValueNotifier(false);
  final TextEditingController _postTextController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final bool _showBackButton = true;
  bool _isEmojiVisible = false;
  final String _errorMessage = '';
  String? currentUserID;
  String? _selectedGifUrl;

  final PostService _postService = PostService();
  final int _maxCharacterCount = 1500;
  // Add a ValueNotifier to hold the current character count
  final ValueNotifier<int> _currentCharacterCount = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _postTextController.addListener(_updatePostButtonState);
    _loadUserInfo();
  }

  void _loadUserInfo() async {
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token != null && !Jwt.isExpired(token)) {
        Map<String, dynamic> decodedToken = Jwt.parseJwt(token);
        currentUserID = decodedToken['id'];

        UserModel? user = await AuthService().fetchUserProfile(currentUserID!);

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

  void _updatePostButtonState() {
    final textLength = _postTextController.text.length;

    // Update the current character count
    _currentCharacterCount.value = textLength;

    // Check if the content is available and does not exceed the maximum character count
    bool isContentAvailable =
        textLength > 0 && textLength <= _maxCharacterCount ||
            _imagePath != null ||
            _videoPath != null ||
            _selectedGifUrl != null;
    _isPostButtonEnabled.value = isContentAvailable;
  }

  void _toggleEmojiKeyboard() {
    setState(() {
      _isEmojiVisible = !_isEmojiVisible;
    });
  }

  // void _connectionFailed(dynamic exception) {
  //   setState(() {
  //     _posts = null;
  //     _connectionException = exception;
  //   });
  // }

  // Future<void> _createPost(Post post) async {
  //   try {
  //     final caption = _postTextController.text;
  //     final userId = post.userId; // Replace with the actual user ID
  //     final username = post.username; // Replace with the actual username

  //     // Call the createPost method from PostService to create the post
  //     final createdPost = await _postService.createPost(caption);

  //     Timer(const Duration(seconds: 2), () {
  //       if (mounted) {
  //         setState(() {
  //           _showBackButton = true;
  //           _currentPost =
  //               createdPost; // Assign the created post to _currentPost
  //         });
  //       }
  //     });
  //   } catch (e) {
  //     print(e);
  //   }
  // }

  @override
  void dispose() {
    _postTextController.removeListener(_updatePostButtonState);
    _postTextController.dispose();
    _isPostButtonEnabled.dispose();
    _currentCharacterCount.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  // Future<void> _handlePost(Post postData) async {
  //   setState(() {
  //     _isPosting = true;
  //   });

  //   try {
  //     String userId = postData.userId;
  //     String username = postData.username;
  //     // User? user = await client.user.getUserById(userId);

  //     var post = Post(
  //       caption: _postTextController.text,
  //       userId: userId,
  //       username: username,
  //       createdAt: DateTime.now(),
  //       likeCount: 0,
  //       views: 0,
  //       commentCount: 0,
  //     );

  //     await _createPost(post);
  //     Navigator.of(context).pop();
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(
  //           '$e',
  //         ),
  //         backgroundColor: Colors.green,
  //       ),
  //     );
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         _isPosting = false;
  //       });
  //     }
  //   }
  // }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imagePath = image.path;
        _videoPath = null;
        _updatePostButtonState();
      });
    }
  }

  Future<void> _pickVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _videoPath = video.path;
        _imagePath = null;
        _initializeVideoPlayer(video.path);
        _updatePostButtonState();
      });
    }
  }

  Future<void> _initializeVideoPlayer(String videoPath) async {
    _videoPlayerController?.dispose(); // Dispose any existing controller
    _videoPlayerController = VideoPlayerController.file(File(videoPath))
      ..initialize().then((_) {
        setState(() {}); // Trigger a rebuild when video is initialized
      })
      ..setLooping(true)
      ..addListener(() {
        final error = _videoPlayerController?.value.errorDescription;
        if (error != null) {
          print("Video Player Error: $error");
        }
      });

    // Attempt to play the video
    _videoPlayerController?.play();
  }

  Future<void> pickGif() async {
    // Implementation for picking a GIF
    // Assuming you're using a package or API to pick GIFs, like GiphyPicker
    final gif = await GiphyPicker.pickGif(
      context: context,
      apiKey:
          'Jc7hcx5iY8NgHwS1MNai3mcnb0ZmFZGN', // Use your actual Giphy API key here
    );

    if (gif != null) {
      setState(() {
        // Assuming you have a state variable to store the selected GIF URL
        _selectedGifUrl = gif.images.original!.url;
        _updatePostButtonState();
        // Reset other media selections to ensure only one media type is selected
        _imagePath = null;
      });

      _handleCreatePost(gifUrl: _selectedGifUrl);
    }
  }

  void removeGif() {
    setState(() {
      _selectedGifUrl = null;
      _updatePostButtonState();
    });
  }

  Future<void> _handleCreatePost({String? gifUrl}) async {
    if (_postTextController.text.isEmpty && _imagePath == null) {
      return;
    }

    setState(() => _isPosting = true);

    String? mediaPath = _imagePath; // Default to image path if available
    if (gifUrl != null) {
      // If a GIF URL is provided, use it directly
      mediaPath = gifUrl;
    } else if (_imagePath != null) {
      // If an image is selected, use the image path
      mediaPath = _imagePath;
    }

    try {
      var response = await _postService.createPost(
        _postTextController.text,
        imagePath: mediaPath,
        videoPath: _videoPath,
        gifUrl: _selectedGifUrl,
      );

      if (response.statusCode == 201) {
        final createdPost = Post.fromJson(json.decode(response.body));
        setState(() {
          _currentPost = createdPost;
          _isPosting = false;
        });

        _postTextController.clear();
        _updatePostButtonState();

        Navigator.of(context).pop();

        // Using AwesomeSnackbarContent for success message
        final successSnackBar = SnackBar(
          showCloseIcon: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: AwesomeSnackbarContent(
            title: 'Success!',
            message: 'Post created successfully',
            contentType: ContentType.success,
            inMaterialBanner: true,
          ),
          behavior: SnackBarBehavior.floating,
        );

        ScaffoldMessenger.of(context).showSnackBar(successSnackBar);
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

        setState(() {
          _isPosting = false;
        });
      } else {
        throw Exception('Failed to create post');
      }
    } catch (e) {
      setState(() => _isPosting = false);

      // Using AwesomeSnackbarContent for error message
      final errorSnackBar = SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: AwesomeSnackbarContent(
          title: 'Error',
          message: 'Failed to create post: $e',
          contentType: ContentType.failure,
        ),
        behavior: SnackBarBehavior.floating,
      );

      ScaffoldMessenger.of(context).showSnackBar(errorSnackBar);

      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          Padding(
              padding: const EdgeInsets.only(right: 15),
              child: ValueListenableBuilder<bool>(
                valueListenable: _isPostButtonEnabled,
                builder: (context, isButtonEnabled, child) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: _isPosting
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.grey,
                            ),
                            onPressed: null,
                            child: const Row(
                              children: [
                                Text('Post'),
                                SizedBox(width: 10),
                                SizedBox(
                                  height: 10,
                                  width: 10,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor:
                                  isButtonEnabled ? Colors.blue : Colors.grey,
                            ),
                            onPressed: _isPostButtonEnabled.value
                                ? _handleCreatePost
                                : null,
                            child: const Text('Post'),
                          ),
                  );
                },
              )),
        ],
        leading: _showBackButton
            ? IconButton(
                icon: const Icon(Icons.close, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 7),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ValueListenableBuilder<int>(
                      valueListenable: _currentCharacterCount,
                      builder: (context, count, child) {
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              "$count/$_maxCharacterCount",
                              style: TextStyle(
                                color: count == _maxCharacterCount
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment
                        .start, // Align items to the start of the Row
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10, top: 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment
                              .start, // Align avatar to the start of the Column
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (_focusNode.hasFocus) {
                                  _focusNode.unfocus();
                                } else {
                                  FocusScope.of(context)
                                      .requestFocus(_focusNode);
                                }
                              },
                              child: CircleAvatar(
                                backgroundImage:
                                    NetworkImage(_user?.profileImageUrl ?? ''),
                                radius: 30,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextField(
                          focusNode: _focusNode,
                          controller: _postTextController,
                          style: const TextStyle(fontSize: 22),
                          decoration: const InputDecoration(
                            hintText: "Write your post here...",
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                            border: InputBorder.none,
                          ),
                          maxLines: null,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(
                                _maxCharacterCount), // Limit input length
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_isEmojiVisible)
                    SizedBox(
                      height: 250, // Set a height for the emoji picker
                      child: EmojiPicker(
                        onEmojiSelected: (category, emoji) {
                          // Append the selected emoji to the text controller
                          _postTextController.text += emoji.emoji;
                        },
                      ),
                    ),
                  if (_selectedGifUrl != null)
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Image.network(_selectedGifUrl!),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed:
                              removeGif, // Call removeGif when button is pressed
                        ),
                      ],
                    ),
                  if (_imagePath != null) // Show selected image
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Container(
                            constraints: const BoxConstraints(
                              maxHeight: 300,
                            ),
                            child: Image.file(File(_imagePath!)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _imagePath = null;
                                _updatePostButtonState();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  if (_videoPath != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          GestureDetector(
                            onTap: () {
                              // Toggle play/pause state on tap
                              if (_videoPlayerController != null) {
                                if (_videoPlayerController!.value.isPlaying) {
                                  _videoPlayerController!.pause();
                                } else {
                                  _videoPlayerController!.play();
                                }
                              }
                            },
                            child: Container(
                              constraints: const BoxConstraints(
                                maxHeight:
                                    300, // Adjust the max height as per your UI needs
                              ),
                              child: _videoPlayerController != null &&
                                      _videoPlayerController!
                                          .value.isInitialized
                                  ? AspectRatio(
                                      aspectRatio: _videoPlayerController!
                                          .value.aspectRatio,
                                      child:
                                          VideoPlayer(_videoPlayerController!),
                                    )
                                  : const Center(
                                      child:
                                          CircularProgressIndicator()), // Show loading indicator while the video is initializing
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _videoPath = null;
                                _videoPlayerController =
                                    null; // Make sure to dispose of the controller
                                _updatePostButtonState();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.grey,
              width: 0.3,
            ),
          ),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0).copyWith(
                left: 15,
                right: 15,
              ),
              child: GestureDetector(
                onTap: _pickImage,
                child: const Icon(Icons.image),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0).copyWith(
                left: 15,
                right: 15,
              ),
              child: GestureDetector(
                onTap: _pickVideo,
                child: const Icon(Icons.video_collection_sharp),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0).copyWith(
                left: 15,
                right: 15,
              ),
              child: GestureDetector(
                onTap: pickGif,
                child: const Icon(Icons.gif),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0).copyWith(
                left: 15,
                right: 15,
              ),
              child: GestureDetector(
                onTap: _toggleEmojiKeyboard,
                child: const Icon(Icons.emoji_emotions_outlined),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
      // _posts == null
      //     ? Container()
      //     : ListView.builder(
      //         itemCount: _posts!.length,
      //         itemBuilder: ((context, index) {
      //           return ListTile(
      //             title: Text(_posts![index].caption),
      //           );
      //         }),
      //       ),
    );
  }

//   void showNoteDialog({
//     required BuildContext context,
//     String text = '',
//     required OnPostSaved onSaved, // Updated type
//   }) {
//     showDialog(
//       context: context,
//       builder: (context) => NoteDialog(
//         text: text,
//         onSaved: onSaved,
//       ),
//     );
//   }
// }

// class NoteDialog extends StatefulWidget {
//   const NoteDialog({
//     required this.text,
//     required this.onSaved,
//     super.key,
//   });

//   final String text;
//   final OnPostSaved onSaved;

//   @override
//   NoteDialogState createState() => NoteDialogState();
// }

// class NoteDialogState extends State<NoteDialog> {
//   final TextEditingController controller = TextEditingController();
//   File? image;
//   String? base64Image;

//   @override
//   void initState() {
//     super.initState();
//     controller.text = widget.text;
//   }

//   Future pickImage() async {
//     final pickedFile =
//         await ImagePicker().pickImage(source: ImageSource.gallery);

//     if (pickedFile != null) {
//       setState(() {
//         image = File(pickedFile.path);
//       });

//       final bytes = await image!.readAsBytes();
//       setState(() {
//         base64Image = base64Encode(bytes);
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Expanded(
//               child: TextField(
//                 controller: controller,
//                 expands: true,
//                 maxLines: null,
//                 minLines: null,
//                 decoration: const InputDecoration(
//                   border: InputBorder.none,
//                   hintText: 'Write your post here...',
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             image == null
//                 ? ElevatedButton(
//                     onPressed: pickImage,
//                     child: const Text('Pick Image from Gallery'),
//                   )
//                 : Container(
//                     constraints: const BoxConstraints(
//                       maxHeight: 300, // Maximum height for the image
//                     ),
//                     child: Image.file(image!),
//                   ),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: () {
//                 // Pass the Base64 string instead of a static URL
//                 widget.onSaved(controller.text,
//                     base64Image); // Modify the onSaved method accordingly
//                 Navigator.of(context).pop();
//               },
//               child: const Text('Save'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
}
