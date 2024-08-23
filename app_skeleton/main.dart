import 'package:flutter/material.dart';
import 'camera_screen.dart';

void main() => runApp(PhotoAnalyzerApp());

class PhotoAnalyzerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: CameraScreen(),
    );
  }
}