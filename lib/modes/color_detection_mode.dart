import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class ColorDetectionMode extends StatefulWidget {
  final CameraController controller;

  const ColorDetectionMode({Key? key, required this.controller}) : super(key: key);

  @override
  _ColorDetectionModeState createState() => _ColorDetectionModeState();
}

class _ColorDetectionModeState extends State<ColorDetectionMode> {
  String _targetColor = 'Blue';
  final ValueNotifier<ui.Image?> _imageNotifier = ValueNotifier(null);
  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _receivePort;
  int _frameCount = 0;
  static const int _frameSkip = 2;
  bool _isDisposed = false;
  bool _isProcessing = false;
  bool _isActive = true;

  final List<String> colors = [
    'Red', 'Orange', 'Yellow', 'Green', 'Blue', 'Indigo', 'Violet',
    'Gold', 'Silver', 'Bronze', 'Pink', 'Purple', 'Brown', 'Black', 'White'
  ];

  @override
  void initState() {
    super.initState();
    _initializeProcessing();
  }

  @override
  void didUpdateWidget(ColorDetectionMode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _resetState();
      _initializeProcessing();
    }
  }

  void _resetState() {
    _isDisposed = false;
    _isProcessing = false;
    _isActive = true;
    _frameCount = 0;
    _imageNotifier.value = null;
    _stopIsolate();
  }

  Future<void> _initializeProcessing() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      await _startIsolate();
      _attachStreamListener();
    } catch (e) {
      print('Error initializing processing: $e');
    }
  }

  void _attachStreamListener() {
    if (!_isDisposed && !widget.controller.value.isStreamingImages) {
      widget.controller.startImageStream(_processImageData);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _isActive = false;
    _cleanupResources();
    super.dispose();
  }

  void _cleanupResources() {
    _stopIsolate();
    _imageNotifier.dispose();
  }

  Future<void> _startIsolate() async {
    final initPort = ReceivePort();
    try {
      _isolate = await Isolate.spawn(_isolateEntry, initPort.sendPort);
      _sendPort = await initPort.first as SendPort;
      initPort.close();
      _receivePort = ReceivePort();
      _sendPort!.send(_receivePort!.sendPort);
      _receivePort!.listen(_handleIsolateMessage);
    } catch (e) {
      print('Error starting isolate: $e');
      initPort.close();
    }
  }

  void _stopIsolate() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _receivePort?.close();
    _receivePort = null;
    _sendPort = null;
  }

  void _processImageData(CameraImage image) {
    if (_isDisposed || !_isProcessing || !_isActive) return;

    _frameCount++;
    if (_frameCount % _frameSkip == 0 && _sendPort != null) {
      _sendPort!.send({
        'planes': image.planes.map((plane) => plane.bytes).toList(),
        'targetColor': _targetColor,
        'width': image.width,
        'height': image.height,
        'format': image.format.group == ImageFormatGroup.yuv420 ? 'yuv420' : 'bgra8888',
      });
    }
  }

void _handleIsolateMessage(dynamic message) {
    if (_isDisposed || !_isActive) return;

    if (message is Map<String, dynamic> && message['type'] == 'processedImage') {
      _convertProcessedDataToImage(message).then((processedImage) {
        if (!_isDisposed && _isActive) {
          _imageNotifier.value = processedImage;
        }
      });
    }
  }

  Future<ui.Image?> _convertProcessedDataToImage(Map<String, dynamic> processedData) async {
    final width = processedData['width'] as int;
    final height = processedData['height'] as int;
    final data = processedData['data'] as Uint8List;

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      data,
      width,
      height,
      ui.PixelFormat.rgba8888,
      (ui.Image img) {
        completer.complete(img);
      },
    );

    final image = await completer.future;
    return image;
  }

  static void _isolateEntry(SendPort sendPort) {
    final ReceivePort receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    late SendPort mainSendPort;

    receivePort.listen((message) {
      if (message is SendPort) {
        mainSendPort = message;
      } else if (message is Map<String, dynamic>) {
        final processedData = _processImageIsolate(message);
        mainSendPort.send({
          'type': 'processedImage',
          ...processedData
        });
      }
    });
  }

  static Map<String, dynamic> _processImageIsolate(Map<String, dynamic> args) {
    final planes = args['planes'] as List<Uint8List>;
    final targetColor = args['targetColor'] as String;
    final width = args['width'] as int;
    final height = args['height'] as int;
    final format = args['format'] as String;

    const scaleFactor = 1;
    final scaledWidth = (width * scaleFactor).round();
    final scaledHeight = (height * scaleFactor).round();

    final Uint8List rgbData = (format == 'yuv420')
        ? _convertYUV420toRGB(planes[0], planes[1], planes[2], width, height, scaledWidth, scaledHeight)
        : _convertBGRA8888toRGB(planes[0], width, height, scaledWidth, scaledHeight);

    final targetHSV = _rgbToHSV(_getColorFromName(targetColor));
    final enhancedImageData = _enhanceImage(rgbData, scaledWidth, scaledHeight, targetHSV);

    return {
      'width': scaledWidth,
      'height': scaledHeight,
      'data': enhancedImageData,
    };
  }

  static Uint8List _convertYUV420toRGB(Uint8List yPlane, Uint8List uPlane, Uint8List vPlane,
      int width, int height, int scaledWidth, int scaledHeight) {
    final rgbData = Uint8List(scaledWidth * scaledHeight * 4);
    int rgbIndex = 0;

    for (int y = 0; y < scaledHeight; y++) {
      for (int x = 0; x < scaledWidth; x++) {
        final int origX = (x * width ~/ scaledWidth);
        final int origY = (y * height ~/ scaledHeight);
        final int uvIndex = (origY ~/ 2) * (width ~/ 2) + (origX ~/ 2);
        final int index = origY * width + origX;

        final yp = yPlane[index];
        final up = uPlane[uvIndex];
        final vp = vPlane[uvIndex];

        // Faster YUV to RGB conversion
        int r = (yp + 1.370705 * (vp - 128)).round().clamp(0, 255);
        int g = (yp - 0.698001 * (vp - 128) - 0.337633 * (up - 128)).round().clamp(0, 255);
        int b = (yp + 1.732446 * (up - 128)).round().clamp(0, 255);

        // Reduce color depth to 16-bit (5-6-5)
        r = (r >> 3) << 3;
        g = (g >> 2) << 2;
        b = (b >> 3) << 3;

        rgbData[rgbIndex++] = r;
        rgbData[rgbIndex++] = g;
        rgbData[rgbIndex++] = b;
        rgbData[rgbIndex++] = 255; // Alpha channel
      }
    }

    return rgbData;
  }

  static Uint8List _convertBGRA8888toRGB(Uint8List bgra, int width, int height,
      int scaledWidth, int scaledHeight) {
    final rgbData = Uint8List(scaledWidth * scaledHeight * 4);
    int rgbIndex = 0;

    for (int y = 0; y < scaledHeight; y++) {
      for (int x = 0; x < scaledWidth; x++) {
        final int origX = (x * width ~/ scaledWidth);
        final int origY = (y * height ~/ scaledHeight);
        final int srcIndex = (origY * width + origX) * 4;

        // Reduce color depth to 16-bit (5-6-5)
        int r = (bgra[srcIndex + 2] >> 3) << 3;
        int g = (bgra[srcIndex + 1] >> 2) << 2;
        int b = (bgra[srcIndex] >> 3) << 3;

        rgbData[rgbIndex++] = r;
        rgbData[rgbIndex++] = g;
        rgbData[rgbIndex++] = b;
        rgbData[rgbIndex++] = bgra[srcIndex + 3];
      }
    }

    return rgbData;
  }

  static Uint8List _enhanceImage(Uint8List rgbData, int width, int height, List<double> targetHSV) {
    final enhancedData = Uint8List(width * height * 4);
    final targetHue = targetHSV[0];

    for (int i = 0; i < rgbData.length; i += 4) {
      final r = rgbData[i];
      final g = rgbData[i + 1];
      final b = rgbData[i + 2];

      final hsv = _rgbToHSV(Color.fromARGB(255, r, g, b));
      final hueDifference = (hsv[0] - targetHue).abs();
      final hueDistance = math.min(hueDifference, 360 - hueDifference);

      if (hueDistance < 30 && hsv[1] > 0.2 && hsv[2] > 0.2) {
        final enhancedColor = _increaseContrast(r, g, b);
        enhancedData[i] = enhancedColor[0];
        enhancedData[i + 1] = enhancedColor[1];
        enhancedData[i + 2] = enhancedColor[2];
        enhancedData[i + 3] = 255;
      } else {
        final desaturated = _desaturate(r, g, b);
        enhancedData[i] = desaturated;
        enhancedData[i + 1] = desaturated;
        enhancedData[i + 2] = desaturated;
        enhancedData[i + 3] = 255;
      }
    }

    return enhancedData;
  }

  static List<double> _rgbToHSV(Color color) {
    final r = color.red / 255;
    final g = color.green / 255;
    final b = color.blue / 255;
    final max = math.max(r, math.max(g, b));
    final min = math.min(r, math.min(g, b));
    final diff = max - min;

    double h = 0;
    if (diff == 0) {
      h = 0;
    } else if (max == r) {
      h = 60 * ((g - b) / diff % 6);
    } else if (max == g) {
      h = 60 * ((b - r) / diff + 2);
    } else {
      h = 60 * ((r - g) / diff + 4);
    }

    h = (h + 360) % 360;
    final s = max == 0 ? 0 : diff / max;
    final v = max;

    return [h, s.toDouble(), v];
  }

  static List<int> _increaseContrast(int r, int g, int b) {
    const double factor = 1.5;
    int newR = ((r - 128) * factor + 128).round().clamp(0, 255);
    int newG = ((g - 128) * factor + 128).round().clamp(0, 255);
    int newB = ((b - 128) * factor + 128).round().clamp(0, 255);
    return [newR, newG, newB];
  }

  static int _desaturate(int r, int g, int b) {
    return ((r + g + b) ~/ 3).clamp(0, 255);
  }

  static Color _getColorFromName(String colorName) {
    final colorMap = {
      'red': Colors.red,
      'orange': Colors.orange,
      'yellow': Colors.yellow,
      'green': Colors.green,
      'blue': Colors.blue,
      'indigo': Colors.indigo,
      'violet': Colors.purple,
      'gold': Colors.amber,
      'silver': Colors.grey,
      'bronze': Color(0xCD7F32),
      'pink': Colors.pink,
      'purple': Colors.purple,
      'brown': Colors.brown,
      'black': Colors.black,
      'white': Colors.white,
    };

    return colorMap[colorName.toLowerCase()] ?? Colors.transparent;
  }

 @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        // You can add tap functionality here if needed
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(widget.controller),
          ValueListenableBuilder<ui.Image?>(
            valueListenable: _imageNotifier,
            builder: (context, image, child) {
              return image != null && _isActive
                  ? CustomPaint(
                      painter: EnhancedColorPainter(image: image),
                      size: Size.infinite,
                    )
                  : Container();
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _targetColor,
                      onChanged: (newColor) {
                        if (!_isDisposed && _isActive) {
                          setState(() {
                            _targetColor = newColor ?? '';
                          });
                        }
                      },
                      items: colors.map((color) {
                        return DropdownMenuItem(
                          value: color,
                          child: Text(color, style: TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      dropdownColor: Colors.black54,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EnhancedColorPainter extends CustomPainter {
  final ui.Image image;

  EnhancedColorPainter({required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, src, dst, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}