import 'package:flutter/material.dart';

/// App Color Palette — lifted from the MVP screen board.
/// Brand: Deep Green #2F5D43, Orange #EE8A38, Cream #F1F0EA.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF2F5D43); // Deep green CTAs
  static const Color primaryDark = Color(0xFF234833);
  static const Color primarySoft = Color(0xFFE4EDE4);
  static const Color accent = Color(0xFFEE8A38); // Orange highlights
  static const Color accentSoft = Color(0xFFFBEBDA);

  // Neutrals
  static const Color background = Color(0xFFF1F0EA); // Warm cream
  static const Color surface = Colors.white;
  static const Color ink = Color(0xFF1E2B20); // Near-black green text
  static const Color inkSoft = Color(0xFF4A564C);
  static const Color muted = Color(0xFF8B928A);
  static const Color line = Color(0xFFE4E3DB);

  // Semantic
  static const Color gold = Color(0xFFEDB13F); // Rating stars
  static const Color blue = Color(0xFF4A7BD0); // Live location

  // Stylized map
  static const Color mapBase = Color(0xFFE8EAE2);
  static const Color mapPark = Color(0xFFDCE5D2);
  static const Color mapWater = Color(0xFFC7D6E6);
  static const Color mapRoad = Colors.white;
  static const Color mapRoadEdge = Color(0xFFDFE1D8);
}
