import 'package:flutter/material.dart';
import 'package:quickpost_flutter/utils/format_number.dart';

class PostStats extends StatefulWidget {
  final bool isLiked;
  final int likeCount;
  final VoidCallback onLikeButtonPressed;

  const PostStats({
    Key? key,
    required this.isLiked,
    required this.likeCount,
    required this.onLikeButtonPressed,
  }) : super(key: key);

  @override
  State<PostStats> createState() => _PostStatsState();
}

class _PostStatsState extends State<PostStats>
    with SingleTickerProviderStateMixin {
  late bool isLiked;
  late AnimationController _controller;
  late Animation<double> _heartBeatAnimation;

  @override
  void initState() {
    super.initState();
    isLiked = widget.isLiked;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _heartBeatAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    int repeatCount = 0; // Counter for the number of repeats
    const int maxRepeats = 5; // Maximum number of repeats

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        if (repeatCount < maxRepeats && isLiked) {
          repeatCount++;
          _controller.forward();
        }
      }
    });

    // React to changes in isLiked by running the animation
    // if (widget.isLiked) {
    //   _controller.forward(from: 0.0); // Start the animation
    // }
  }

  @override
  void didUpdateWidget(covariant PostStats oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if the liked status has changed
    if (oldWidget.isLiked != widget.isLiked) {
      isLiked = widget.isLiked; // Update the local state

      // If the post is now liked, trigger the animation
      if (isLiked) {
        _controller.forward(from: 0.0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.comment_outlined),
              onPressed: () {},
            ),
            const Text('0'),
          ],
        ),
        // const Row(
        //   children: [
        //     Icon(Icons.compare_arrows_outlined),
        //     SizedBox(width: 4.0),
        //     Text('6'),
        //   ],
        // ),
        Row(
          children: [
            IconButton(
              icon: AnimatedBuilder(
                animation: _heartBeatAnimation,
                builder: (_, child) {
                  return Transform.scale(
                    scale: _heartBeatAnimation.value,
                    child: Icon(
                      widget.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: widget.isLiked ? Colors.red : null,
                    ),
                  );
                },
              ),
              onPressed: widget.onLikeButtonPressed,
            ),
            const SizedBox(width: 4.0),
            Text(formatNumber(widget.likeCount)),
          ],
        ),
        const Row(
          children: [
            Icon(Icons.remove_red_eye_outlined),
            SizedBox(width: 4.0),
            Text('0'),
          ],
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () {},
          icon: const Icon(Icons.ios_share_outlined),
        ),
      ],
    );
  }
}
