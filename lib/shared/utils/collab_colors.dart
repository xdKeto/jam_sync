import 'package:flutter/material.dart';

class CollabColors {
  static const List<Color> palette = [
    Color(0xFFE57373), 
    Color(0xFF64B5F6), 
    Color(0xFF81C784), 
    Color(0xFFFFD54F), 
    Color(0xFFBA68C8), 
    Color(0xFF4DB6AC), 
    Color(0xFFFF8A65), 
    Color(0xFF90A4AE), 
    Color(0xFFF06292), 
    Color(0xFFAED581), 
  ];

  static Color getColor(int index) {
    return palette[index % palette.length];
  }
}
