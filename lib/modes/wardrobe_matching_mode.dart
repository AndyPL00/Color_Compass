import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import '../utils/color_utils.dart';

class WardrobeMatchingMode extends StatefulWidget {
  final CameraController controller;

  const WardrobeMatchingMode({Key? key, required this.controller}) : super(key: key);

  @override
  _WardrobeMatchingModeState createState() => _WardrobeMatchingModeState();
}

class _WardrobeMatchingModeState extends State<WardrobeMatchingMode> {
  Color _dominantColor = Colors.transparent;
  List<String> _matchingSuggestions = [];
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
    _detectionTimer = Timer.periodic(Duration(seconds: 2), (_) {
      if (_isActive) {
        _detectDominantColor();
      }
    });
  }

  Future<void> _detectDominantColor() async {
    if (!widget.controller.value.isInitialized) return;

    final image = await widget.controller.takePicture();
    final bytes = await image.readAsBytes();

    final Color dominantColor = _getDominantColor(bytes);
    final String colorName = ColorUtils.getClosestColorName(dominantColor);

    if (_isActive) {
      setState(() {
        _dominantColor = dominantColor;
        _matchingSuggestions = _getMatchingSuggestions(colorName);
      });
    }
  }

  Color _getDominantColor(List<int> bytes) {
    Map<Color, int> colorCounts = {};
    for (int i = 0; i < bytes.length; i += 4) {
      if (i + 3 < bytes.length) {
        Color color = Color.fromARGB(255, bytes[i], bytes[i + 1], bytes[i + 2]);
        colorCounts[color] = (colorCounts[color] ?? 0) + 1;
      }
    }
    return colorCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  List<String> _getMatchingSuggestions(String colorName) {
    // This is a very basic color matching logic.
    // In a real app, you'd want to use more sophisticated color theory and fashion rules.
    switch (colorName.toLowerCase()) {
      case 'black':
        return ['White', 'Gray', 'Red'];
      case 'white':
        return ['Black', 'Navy', 'Red'];
      case 'blue':
        return ['White', 'Gray', 'Khaki'];
      case 'red':
        return ['White', 'Black', 'Gray'];
      case 'green':
        return ['White', 'Beige', 'Brown'];
      default:
        return ['White', 'Black', 'Denim'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          bottom: 150,
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
                  'Dominant Color:',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _dominantColor,
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      ColorUtils.getClosestColorName(_dominantColor),
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'Matching Suggestions:',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _matchingSuggestions.map((colorName) => Chip(
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