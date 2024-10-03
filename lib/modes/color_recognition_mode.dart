import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../utils/color_utils.dart';

class ColorRecognitionMode extends StatefulWidget {
  final CameraController controller;

  const ColorRecognitionMode({Key? key, required this.controller}) : super(key: key);

  @override
  _ColorRecognitionModeState createState() => _ColorRecognitionModeState();
}

class _ColorRecognitionModeState extends State<ColorRecognitionMode> {
  String _colorName = '';

  Future<void> _getColorFromTap(TapDownDetails details) async {
    if (!widget.controller.value.isInitialized) {
      return;
    }

    final image = await widget.controller.takePicture();
    final imageFile = await image.readAsBytes();

    final Size size = MediaQuery.of(context).size;
    final double x = details.localPosition.dx;
    final double y = details.localPosition.dy;

    final Color tappedColor = await ColorUtils.getColorFromImage(imageFile, x, y, size);
    final String colorName = ColorUtils.getColorName(tappedColor);

    setState(() {
      _colorName = colorName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _getColorFromTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(widget.controller),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(top: 20, left: 20),
              child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Color: $_colorName',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}