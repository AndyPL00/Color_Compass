import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:sample_flutter_app/screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(camera: cameras.first));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({Key? key, required this.camera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CameraScreen(camera: camera),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({Key? key, required this.camera}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  String _colorName = '';
  Size? _previewSize;

  // Expanded color map based on HTML Color Codes
  final Map<String, Color> colorMap = {
    'AliceBlue': Color(0xFFF0F8FF),
    'AntiqueWhite': Color(0xFFFAEBD7),
    'Aqua': Color(0xFF00FFFF),
    'Aquamarine': Color(0xFF7FFFD4),
    'Azure': Color(0xFFF0FFFF),
    'Beige': Color(0xFFF5F5DC),
    'Bisque': Color(0xFFFFE4C4),
    'Black': Color(0xFF000000),
    'BlanchedAlmond': Color(0xFFFFEBCD),
    'Blue': Color(0xFF0000FF),
    'BlueViolet': Color(0xFF8A2BE2),
    'Brown': Color(0xFFA52A2A),
    'BurlyWood': Color(0xFFDEB887),
    'CadetBlue': Color(0xFF5F9EA0),
    'Chartreuse': Color(0xFF7FFF00),
    'Chocolate': Color(0xFFD2691E),
    'Coral': Color(0xFFFF7F50),
    'CornflowerBlue': Color(0xFF6495ED),
    'Cornsilk': Color(0xFFFFF8DC),
    'Crimson': Color(0xFFDC143C),
    'Cyan': Color(0xFF00FFFF),
    'DarkBlue': Color(0xFF00008B),
    'DarkCyan': Color(0xFF008B8B),
    'DarkGoldenRod': Color(0xFFB8860B),
    'DarkGray': Color(0xFFA9A9A9),
    'DarkGreen': Color(0xFF006400),
    'DarkKhaki': Color(0xFFBDB76B),
    'DarkMagenta': Color(0xFF8B008B),
    'DarkOliveGreen': Color(0xFF556B2F),
    'DarkOrange': Color(0xFFFF8C00),
    'DarkOrchid': Color(0xFF9932CC),
    'DarkRed': Color(0xFF8B0000),
    'DarkSalmon': Color(0xFFE9967A),
    'DarkSeaGreen': Color(0xFF8FBC8F),
    'DarkSlateBlue': Color(0xFF483D8B),
    'DarkSlateGray': Color(0xFF2F4F4F),
    'DarkTurquoise': Color(0xFF00CED1),
    'DarkViolet': Color(0xFF9400D3),
    'DeepPink': Color(0xFFFF1493),
    'DeepSkyBlue': Color(0xFF00BFFF),
    'DimGray': Color(0xFF696969),
    'DodgerBlue': Color(0xFF1E90FF),
    'FireBrick': Color(0xFFB22222),
    'FloralWhite': Color(0xFFFFFAF0),
    'ForestGreen': Color(0xFF228B22),
    'Fuchsia': Color(0xFFFF00FF),
    'Gainsboro': Color(0xFFDCDCDC),
    'GhostWhite': Color(0xFFF8F8FF),
    'Gold': Color(0xFFFFD700),
    'GoldenRod': Color(0xFFDAA520),
    'Gray': Color(0xFF808080),
    'Green': Color(0xFF008000),
    'GreenYellow': Color(0xFFADFF2F),
    'HoneyDew': Color(0xFFF0FFF0),
    'HotPink': Color(0xFFFF69B4),
    'IndianRed': Color(0xFFCD5C5C),
    'Indigo': Color(0xFF4B0082),
    'Ivory': Color(0xFFFFFFF0),
    'Khaki': Color(0xFFF0E68C),
    'Lavender': Color(0xFFE6E6FA),
    'LavenderBlush': Color(0xFFFFF0F5),
    'LawnGreen': Color(0xFF7CFC00),
    'LemonChiffon': Color(0xFFFFFACD),
    'LightBlue': Color(0xFFADD8E6),
    'LightCoral': Color(0xFFF08080),
    'LightCyan': Color(0xFFE0FFFF),
    'LightGoldenRodYellow': Color(0xFFFAFAD2),
    'LightGray': Color(0xFFD3D3D3),
    'LightGreen': Color(0xFF90EE90),
    'LightPink': Color(0xFFFFB6C1),
    'LightSalmon': Color(0xFFFFA07A),
    'LightSeaGreen': Color(0xFF20B2AA),
    'LightSkyBlue': Color(0xFF87CEFA),
    'LightSlateGray': Color(0xFF778899),
    'LightSteelBlue': Color(0xFFB0C4DE),
    'LightYellow': Color(0xFFFFFFE0),
    'Lime': Color(0xFF00FF00),
    'LimeGreen': Color(0xFF32CD32),
    'Linen': Color(0xFFFAF0E6),
    'Magenta': Color(0xFFFF00FF),
    'Maroon': Color(0xFF800000),
    'MediumAquaMarine': Color(0xFF66CDAA),
    'MediumBlue': Color(0xFF0000CD),
    'MediumOrchid': Color(0xFFBA55D3),
    'MediumPurple': Color(0xFF9370DB),
    'MediumSeaGreen': Color(0xFF3CB371),
    'MediumSlateBlue': Color(0xFF7B68EE),
    'MediumSpringGreen': Color(0xFF00FA9A),
    'MediumTurquoise': Color(0xFF48D1CC),
    'MediumVioletRed': Color(0xFFC71585),
    'MidnightBlue': Color(0xFF191970),
    'MintCream': Color(0xFFF5FFFA),
    'MistyRose': Color(0xFFFFE4E1),
    'Moccasin': Color(0xFFFFE4B5),
    'NavajoWhite': Color(0xFFFFDEAD),
    'Navy': Color(0xFF000080),
    'OldLace': Color(0xFFFDF5E6),
    'Olive': Color(0xFF808000),
    'OliveDrab': Color(0xFF6B8E23),
    'Orange': Color(0xFFFFA500),
    'OrangeRed': Color(0xFFFF4500),
    'Orchid': Color(0xFFDA70D6),
    'PaleGoldenRod': Color(0xFFEEE8AA),
    'PaleGreen': Color(0xFF98FB98),
    'PaleTurquoise': Color(0xFFAFEEEE),
    'PaleVioletRed': Color(0xFFDB7093),
    'PapayaWhip': Color(0xFFFFEFD5),
    'PeachPuff': Color(0xFFFFDAB9),
    'Peru': Color(0xFFCD853F),
    'Pink': Color(0xFFFFC0CB),
    'Plum': Color(0xFFDDA0DD),
    'PowderBlue': Color(0xFFB0E0E6),
    'Purple': Color(0xFF800080),
    'RebeccaPurple': Color(0xFF663399),
    'Red': Color(0xFFFF0000),
    'RosyBrown': Color(0xFFBC8F8F),
    'RoyalBlue': Color(0xFF4169E1),
    'SaddleBrown': Color(0xFF8B4513),
    'Salmon': Color(0xFFFA8072),
    'SandyBrown': Color(0xFFF4A460),
    'SeaGreen': Color(0xFF2E8B57),
    'SeaShell': Color(0xFFFFF5EE),
    'Sienna': Color(0xFFA0522D),
    'Silver': Color(0xFFC0C0C0),
    'SkyBlue': Color(0xFF87CEEB),
    'SlateBlue': Color(0xFF6A5ACD),
    'SlateGray': Color(0xFF708090),
    'Snow': Color(0xFFFFFAFA),
    'SpringGreen': Color(0xFF00FF7F),
    'SteelBlue': Color(0xFF4682B4),
    'Tan': Color(0xFFD2B48C),
    'Teal': Color(0xFF008080),
    'Thistle': Color(0xFFD8BFD8),
    'Tomato': Color(0xFFFF6347),
    'Turquoise': Color(0xFF40E0D0),
    'Violet': Color(0xFFEE82EE),
    'Wheat': Color(0xFFF5DEB3),
    'White': Color(0xFFFFFFFF),
    'WhiteSmoke': Color(0xFFF5F5F5),
    'Yellow': Color(0xFFFFFF00),
    'YellowGreen': Color(0xFF9ACD32),
  };

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize().then((_) {
      setState(() {
        _previewSize = _controller.value.previewSize;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _getColorFromTap(TapDownDetails details) async {
    if (!_controller.value.isInitialized || _previewSize == null) return;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(details.globalPosition);

    final double xProportion = localPosition.dx / box.size.width;
    final double yProportion = localPosition.dy / box.size.height;

    final image = await _controller.takePicture();
    final bytes = await image.readAsBytes();
    final ui.Image decodedImage = await decodeImageFromList(bytes);

    final pixelColor = await _getPixelColorFromImage(
      decodedImage, 
      (xProportion * decodedImage.width).round(),
      (yProportion * decodedImage.height).round()
    );
    final colorName = getClosestColorName(pixelColor);

    setState(() {
      _colorName = colorName;
    });
  }

  Future<Color> _getPixelColorFromImage(ui.Image image, int x, int y) async {
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) throw Exception('Unable to get image data');

    x = x.clamp(0, image.width - 1);
    y = y.clamp(0, image.height - 1);

    final int pixelOffset = (y * image.width + x) * 4;
    final int r = byteData.getUint8(pixelOffset);
    final int g = byteData.getUint8(pixelOffset + 1);
    final int b = byteData.getUint8(pixelOffset + 2);
    return Color.fromARGB(255, r, g, b);
  }

  String getClosestColorName(Color color) {
    String closestColor = '';
    double minDistance = double.infinity;

    colorMap.forEach((name, mapColor) {
      double distance = _calculateColorDistance(color, mapColor);
      if (distance < minDistance) {
        minDistance = distance;
        closestColor = name;
      }
    });

    return closestColor;
  }

  double _calculateColorDistance(Color c1, Color c2) {
    final int rDiff = c1.red - c2.red;
    final int gDiff = c1.green - c2.green;
    final int bDiff = c1.blue - c2.blue;
    return math.sqrt(rDiff * rDiff + gDiff * gDiff + bDiff * bDiff);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return GestureDetector(
              onTapDown: _getColorFromTap,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: CameraPreview(_controller),
                  ),
                  Positioned(
                    bottom: 50,
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
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}