import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../widgets/mode_selector.dart';
import '../modes/color_recognition_mode.dart';
import '../modes/color_detection_mode.dart';
import '../modes/wardrobe_matching_mode.dart';

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;
  const CameraScreen({Key? key, required this.camera}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  int _currentModeIndex = 0;
  bool _isChangingMode = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
    await _initializeControllerFuture;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onModeChanged(int index) async {
    if (_isChangingMode) return;
    _isChangingMode = true;

    setState(() {
      _currentModeIndex = index;
    });

    // Instead of reinitializing the camera, we'll just ensure it's not streaming
    if (_controller.value.isStreamingImages) {
      await _controller.stopImageStream();
    }

    _isChangingMode = false;
  }

  Widget _buildCurrentMode() {
    // Create a new instance of the mode each time it's built
    switch (_currentModeIndex) {
      case 0:
        return ColorRecognitionMode(key: UniqueKey(), controller: _controller);
      case 1:
        return ColorDetectionMode(key: UniqueKey(), controller: _controller);
      case 2:
        return WardrobeMatchingMode(key: UniqueKey(), controller: _controller);
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_controller),
                _buildCurrentMode(),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ModeSelector(
                    currentIndex: _currentModeIndex,
                    onModeChanged: _onModeChanged,
                  ),
                ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}