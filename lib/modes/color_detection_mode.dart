import 'dart:typed_data';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

class ColorDetectionMode extends StatefulWidget {
  final CameraController controller;

  const ColorDetectionMode({Key? key, required this.controller}) : super(key: key);

  @override
  _ColorDetectionModeState createState() => _ColorDetectionModeState();
}

class _ColorDetectionModeState extends State<ColorDetectionMode> {
  String _targetColor = '';
  final ValueNotifier<ui.Image?> _imageNotifier = ValueNotifier(null);
  final List<String> colors = [
    'Red', 'Orange', 'Yellow', 'Green', 'Blue', 'Indigo', 'Violet',
    'Gold', 'Silver', 'Bronze', 'Pink', 'Purple', 'Brown', 'Black', 'White'
  ];

  @override
  void initState() {
    super.initState();
    _startImageProcessing();
  }

  @override
  void dispose() {
    _stopImageProcessing();
    _imageNotifier.dispose();
    super.dispose();
  }

  void _startImageProcessing() {
    widget.controller.startImageStream((image) {
      _processImageData(image);
    });
  }

  void _stopImageProcessing() {
    widget.controller.stopImageStream();
  }

  void _processImageData(CameraImage image) async {
    final processedImage = await _processImage(
      image.planes.map((plane) => plane.bytes).toList(),
      _targetColor,
      image.width,
      image.height,
      image.format.group,
    );
    _imageNotifier.value = processedImage;
  }

  Future<ui.Image> _processImage(
    List<Uint8List> planes,
    String targetColor,
    int width,
    int height,
    ImageFormatGroup format,
  ) async {
    img.Image? image;
    if (format == ImageFormatGroup.yuv420) {
      image = _convertYUV420toImage(planes[0], planes[1], planes[2], width, height);
    } else if (format == ImageFormatGroup.bgra8888) {
      image = img.Image.fromBytes(width, height, planes[0], format: img.Format.bgra);
    }

    if (image == null) {
      return _createEmptyImage();
    }

    final targetRGB = _getColorFromName(targetColor);
    img.Image enhancedImage = img.Image(width, height);

    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        final pixel = image.getPixel(x, y);
        final r = img.getRed(pixel);
        final g = img.getGreen(pixel);
        final b = img.getBlue(pixel);

        if (_isColorClose(r, g, b, targetRGB)) {
          final enhancedColor = _increaseContrast(r, g, b);
          enhancedImage.setPixelRgba(x, y, img.getRed(enhancedColor), img.getGreen(enhancedColor), img.getBlue(enhancedColor));
        } else {
          final desaturated = _desaturate(r, g, b);
          enhancedImage.setPixelRgba(x, y, desaturated, desaturated, desaturated);
        }
      }
    }

    final pngBytes = Uint8List.fromList(img.encodePng(enhancedImage));
    final codec = await ui.instantiateImageCodec(pngBytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  img.Image _convertYUV420toImage(Uint8List yPlane, Uint8List uPlane, Uint8List vPlane, int width, int height) {
    final img.Image image = img.Image(width, height);
    final int uvRowStride = (width + 1) ~/ 2;
    final int uvPixelStride = 1;

    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        final int uvIndex = uvPixelStride * ((x ~/ 2) + (y ~/ 2) * uvRowStride);
        final int index = y * width + x;

        final yp = yPlane[index];
        final up = uPlane[uvIndex];
        final vp = vPlane[uvIndex];

        int r = (yp + vp * 1436 ~/ 1024 - 179).clamp(0, 255);
        int g = (yp - up * 46549 ~/ 131072 + 44 - vp * 93604 ~/ 131072 + 91).clamp(0, 255);
        int b = (yp + up * 1814 ~/ 1024 - 227).clamp(0, 255);

        image.setPixelRgba(x, y, r, g, b);
      }
    }
    return image;
  }

  Future<ui.Image> _createEmptyImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 1, 1), paint);
    final picture = recorder.endRecording();
    return await picture.toImage(1, 1);
  }

  bool _isColorClose(int r, int g, int b, Color targetColor) {
    const int threshold = 50;
    return (r - targetColor.red).abs() < threshold &&
           (g - targetColor.green).abs() < threshold &&
           (b - targetColor.blue).abs() < threshold;
  }

  int _increaseContrast(int r, int g, int b) {
    const double factor = 1.5;
    int newR = ((r - 128) * factor + 128).round().clamp(0, 255);
    int newG = ((g - 128) * factor + 128).round().clamp(0, 255);
    int newB = ((b - 128) * factor + 128).round().clamp(0, 255);
    return img.getColor(newR, newG, newB);
  }

  int _desaturate(int r, int g, int b) {
    return ((r + g + b) ~/ 3).clamp(0, 255);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ValueListenableBuilder<ui.Image?>(
            valueListenable: _imageNotifier,
            builder: (context, image, child) {
              return image != null
                  ? CustomPaint(
                      painter: EnhancedColorPainter(image: image),
                      child: Container(),
                    )
                  : Container();
            },
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.all(16),
            color: Colors.black.withOpacity(0.7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Select a color to enhance:',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colors.map((colorName) => 
                    ElevatedButton(
                      child: Text(colorName),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(_getColorFromName(colorName)),
                        foregroundColor: MaterialStateProperty.all(
                          _getColorFromName(colorName).computeLuminance() > 0.5 ? Colors.black : Colors.white
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _targetColor = colorName;
                        });
                      },
                    )
                  ).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red': return Colors.red;
      case 'orange': return Colors.orange;
      case 'yellow': return Colors.yellow;
      case 'green': return Colors.green;
      case 'blue': return Colors.blue;
      case 'indigo': return Colors.indigo;
      case 'violet': return Colors.purple;
      case 'gold': return Colors.amber;
      case 'silver': return Colors.grey;
      case 'bronze': return Color(0xCD7F32);
      case 'pink': return Colors.pink;
      case 'purple': return Colors.purple;
      case 'brown': return Colors.brown;
      case 'black': return Colors.black;
      case 'white': return Colors.white;
      default: return Colors.grey;
    }
  }
}

class EnhancedColorPainter extends CustomPainter {
  final ui.Image image;

  EnhancedColorPainter({required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}