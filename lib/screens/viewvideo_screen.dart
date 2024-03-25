import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flick_video_player/flick_video_player.dart';

class ViewVideoScreen extends StatefulWidget {
  final String videoUrl;

  const ViewVideoScreen({super.key, required this.videoUrl});

  @override
  State<ViewVideoScreen> createState() => _ViewVideoScreenState();
}

class _ViewVideoScreenState extends State<ViewVideoScreen> {
  late VideoPlayerController _controller;
  double scale = 1.0;
  double previousScale = 1.0;

  late FlickManager flickManager = FlickManager(
      videoPlayerController:
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl)));

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: GestureDetector(
          onScaleStart: (ScaleStartDetails details) {
            previousScale = scale;
          },
          onScaleUpdate: (ScaleUpdateDetails details) {
            setState(() {
              scale = previousScale * details.scale;
            });
          },
          onScaleEnd: (ScaleEndDetails details) {
            previousScale = 1.0;
          },
          child: _controller.value.isInitialized
              ? Transform.scale(
                  scale: scale,
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: FlickVideoPlayer(flickManager: flickManager),
                  ),
                )
              : const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
