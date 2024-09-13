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
    // Implement color recognition logic here
    // You can reuse most of the logic from the original _getColorFromTap method
    // Don't forget to update the state with setState(() { _colorName = ...; });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _getColorFromTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            bottom: 150,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.all(8),
                color: Colors.black54,
                child: Text(
                  'Color: $_colorName',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}