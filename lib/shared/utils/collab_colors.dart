import 'package:flutter/material.dart';

class CollabColors {
  static const List<Color> palette = [
    Color(0xFFE57373), // red
    Color(0xFF64B5F6), // blue
    Color(0xFF81C784), // green
    Color(0xFFFFD54F), // amber
    Color(0xFFBA68C8), // purple
    Color(0xFF4DB6AC), // teal
    Color(0xFFFF8A65), // deep orange
    Color(0xFF90A4AE), // blue grey
    Color(0xFFF06292), // pink
    Color(0xFFAED581), // light green
  ];

  static Color getColor(int index) {
    return palette[index % palette.length];
  }
}
