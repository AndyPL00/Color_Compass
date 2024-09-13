import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img; // Import the image package
import 'dart:io';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;
  List<CameraDescription>? cameras;
  Future<void>? _initializeControllerFuture;
  String dominantColor = "Analyzing..."; // Text to display the dominant color

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    cameras = await availableCameras();
    controller = CameraController(
      cameras![0],
      ResolutionPreset.high,
    );
    _initializeControllerFuture = controller?.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  // Function to analyze the image and determine the most dominant color
  Future<String> findDominantColor(String imagePath) async {
    final imageFile = File(imagePath);
    final img.Image? image = img.decodeImage(imageFile.readAsBytesSync());

    if (image == null) {
      return "Image not found!";
    }

    Map<int, int> colorCount = {};

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        int pixel = image.getPixel(x, y);
        colorCount[pixel] = (colorCount[pixel] ?? 0) + 1;
      }
    }

    int dominantColor = colorCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    return '#${dominantColor.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Take a picture')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(controller!);
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Dominant Color: $dominantColor',
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await _initializeControllerFuture;

            final path = join(
              (await getTemporaryDirectory()).path,
              '${DateTime.now()}.png',
            );

            await controller?.takePicture();

            // Analyze the image and find the dominant color
            String color = await findDominantColor(path);
            setState(() {
              dominantColor = color;
            });
          } catch (e) {
            print(e);
          }
        },
        child: Icon(Icons.camera_alt),
      ),
    );
  }
}