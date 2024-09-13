import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:colorconvert/colorconvert.dart';


class ColorDetectorWidget extends StatefulWidget {
  const ColorDetectorWidget({Key? key}) : super(key: key);

  @override
  _ColorDetectorWidgetState createState() => _ColorDetectorWidgetState();
}

class _ColorDetectorWidgetState extends State<ColorDetectorWidget>{
    CameraController? _controller;
    String _targetColor = '';
    img.Image? _processedImage;
    List<CameraDescription>? _cameras;
     @override
  void initState() {
    super.initState();
    _initializeCamera();
  }
   final List<String> colors = [
    'Red', 'Orange', 'Yellow', 'Green', 'Blue', 'Indigo', 'Violet',
    'Gold', 'Silver', 'Bronze', 'Pink', 'Purple', 'Brown', 'Black', 'White'
  ];

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
      );

      await _controller!.initialize();
      if (!mounted) return;
      setState(() {});
      _startImageProcessing();
    
  }
   void _startImageProcessing() {
    _controller!.startImageStream((CameraImage image) {
      _processImage(image);
    });
  }

  void _processImage(CameraImage image) {
    final img.Image capturedImage = _convertCameraImage(image);
    final img.Image processedImage = _detectColorAndAdjustContrast(capturedImage, _targetColor);
    
    setState(() {
      _processedImage = processedImage;
    });
  }
 img.Image _convertCameraImage(CameraImage image) {
    return img.Image.fromBytes(
      image.width,
      image.height,
      image.planes[0].bytes,
      format: img.Format.yuv420,
    );
  }

  img.Image _detectColorAndAdjustContrast(img.Image src, String targetColor) {
    var dst = img.Image(src.width, src.height);

    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        int pixel = src.getPixel(x, y);
        int r = img.getRed(pixel);
        int g = img.getGreen(pixel);
        int b = img.getBlue(pixel);
        
        var hsv = RgbToHsv(r, g, b);
        
        if (_isColorInRange(hsv.h.toInt(), hsv.s.toInt(), hsv.v.toInt(), targetColor)) {
          // Color detected, increase contrast
          int newR = ((r - 128) * 1.2 + 128).round().clamp(0, 255);
          int newG = ((g - 128) * 1.2 + 128).round().clamp(0, 255);
          int newB = ((b - 128) * 1.2 + 128).round().clamp(0, 255);
          
          dst.setPixel(x, y, img.getColor(newR, newG, newB));
        } else {
          dst.setPixel(x, y, pixel);
        }
      }
    }

    return dst;
  }

  bool _isColorInRange(int h, int s, int v, String colorName) {
  switch (colorName.toLowerCase()) {
    case 'red':
      return (h >= 350 || h <= 10) && s >= 50 && v >= 50;
    case 'orange':
      return h >= 11 && h <= 30 && s >= 50 && v >= 50;
    case 'yellow':
      return h >= 31 && h <= 60 && s >= 50 && v >= 50;
    case 'green':
      return h >= 61 && h <= 140 && s >= 50 && v >= 50;
    case 'blue':
      return h >= 141 && h <= 250 && s >= 50 && v >= 50;
    case 'indigo':
      return h >= 251 && h <= 280 && s >= 50 && v >= 50;
    case 'violet':
      return h >= 281 && h <= 320 && s >= 50 && v >= 50;
    case 'gold':
      return h >= 30 && h <= 45 && s >= 70 && v >= 70;
    case 'silver':
      return h >= 0 && h <= 360 && s <= 10 && v >= 70 && v <= 90;
    case 'bronze':
      return h >= 20 && h <= 35 && s >= 50 && v >= 40 && v <= 70;
    case 'pink':
      return h >= 321 && h <= 349 && s >= 20 && v >= 80;
    case 'purple':
      return h >= 270 && h <= 300 && s >= 50 && v >= 50;
    case 'brown':
      return h >= 10 && h <= 40 && s >= 40 && v >= 20 && v <= 60;
    case 'black':
      return v <= 20;
    case 'white':
      return v >= 90 && s <= 10;
    default:
      return false;
  }
}

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        Expanded(
          child: _processedImage != null
              ? Image.memory(img.encodePng(_processedImage!) as Uint8List)
              : CameraPreview(_controller!),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: DropdownButton<String>(
            value: _targetColor.isEmpty ? null : _targetColor,
            hint: const Text('Select a color'),
            items: colors.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _targetColor = newValue ?? '';
              });
            },
          ),
        ),
      ],
    );
  }
}
}