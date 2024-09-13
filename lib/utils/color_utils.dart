import 'dart:math' as math;
import 'package:flutter/material.dart';

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
}