import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import '../utils/color_utils.dart';

class ColorDetectionMode extends StatefulWidget {
  final CameraController controller;

  const ColorDetectionMode({Key? key, required this.controller}) : super(key: key);

  @override
  _ColorDetectionModeState createState() => _ColorDetectionModeState();
}

class _ColorDetectionModeState extends State<ColorDetectionMode> {
  List<String> _detectedColors = [];
  Timer? _detectionTimer;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _startColorDetection();
  }

  @override
  void dispose() {
    _isActive = false;
    _detectionTimer?.cancel();
    super.dispose();
  }

  void _startColorDetection() {
    _detectionTimer = Timer.periodic(Duration(seconds: 1), (_) {
      if (_isActive) {
        _detectColors();
      }
    });
  }

  Future<void> _detectColors() async {
    if (!widget.controller.value.isInitialized) return;

    final image = await widget.controller.takePicture();
    final bytes = await image.readAsBytes();

    final List<Color> sampleColors = _getSampleColors(bytes);
    final List<String> colorNames = sampleColors.map((color) => ColorUtils.getClosestColorName(color)).toList();

    if (_isActive) {
      setState(() {
        _detectedColors = colorNames.toSet().toList(); // Remove duplicates
      });
    }
  }

  List<Color> _getSampleColors(List<int> bytes) {
    List<Color> colors = [];
    for (int i = 0; i < bytes.length; i += 4 * 1000) { // Sample every 1000th pixel
      if (i + 3 < bytes.length) {
        colors.add(Color.fromARGB(255, bytes[i], bytes[i + 1], bytes[i + 2]));
      }
    }
    return colors;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 50,
          left: 20,
          right: 20,
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Detected Colors:',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _detectedColors.map((colorName) => Chip(
                    label: Text(colorName),
                    backgroundColor: ColorUtils.colorMap[colorName] ?? Colors.grey,
                    labelStyle: TextStyle(color: Colors.white),
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}