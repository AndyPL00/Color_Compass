import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class ColorUtils {
  static final Map<String, Color> colorMap = {
    // Include your color map here
  };

  static String getClosestColorName(Color color) {
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

  static double _calculateColorDistance(Color c1, Color c2) {
    final int rDiff = c1.red - c2.red;
    final int gDiff = c1.green - c2.green;
    final int bDiff = c1.blue - c2.blue;
    return math.sqrt(rDiff * rDiff + gDiff * gDiff + bDiff * bDiff);
  }

  static Future<Color> getColorFromImage(Uint8List imageBytes, double x, double y, Size size) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) return Colors.transparent;

    // Convert tap coordinates to image coordinates
    final imageX = (x / size.width * image.width).round();
    final imageY = (y / size.height * image.height).round();

    // Get color at the tapped position
    final pixel = image.getPixel(imageX, imageY);
    
    // Extract ARGB values from the integer pixel value
    final a = (pixel >> 24) & 0xFF;
    final r = (pixel >> 16) & 0xFF;
    final g = (pixel >> 8) & 0xFF;
    final b = pixel & 0xFF;

    return Color.fromARGB(a, r, g, b);
  }

  static String getColorName(Color color) {
    // This is a simple implementation. You might want to expand this with more colors and better matching logic.
    final hsl = HSLColor.fromColor(color);
    final hue = hsl.hue;
    final saturation = hsl.saturation;
    final lightness = hsl.lightness;

    if (saturation < 0.1) {
      if (lightness < 0.2) return 'Black';
      if (lightness > 0.8) return 'White';
      return 'Gray';
    }

    if (hue < 30) return 'Red';
    if (hue < 90) return 'Yellow';
    if (hue < 150) return 'Green';
    if (hue < 210) return 'Cyan';
    if (hue < 270) return 'Blue';
    if (hue < 330) return 'Magenta';
    return 'Red';
  }
}