import 'package:flutter/material.dart';

class ViewImageScreen extends StatefulWidget {
  final String imageUrl;

  const ViewImageScreen({super.key, required this.imageUrl});

  @override
  State<ViewImageScreen> createState() => _ViewImageScreenState();
}

class _ViewImageScreenState extends State<ViewImageScreen> {
  double scale = 1.0;
  double previousScale = 1.0;
  bool hasError = false;

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
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(scale, scale, scale),
            child: Image.network(
              widget.imageUrl,
              errorBuilder: (context, error, stackTrace) {
                if (error is Exception) {
                  hasError = true;
                  return Image.network(
                      'https://www.shutterstock.com/image-vector/blue-wide-screen-webpage-business-600nw-695161762.jpg');
                } else {
                  return const Placeholder();
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
