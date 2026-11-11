import 'package:flutter/material.dart';

export 'category_model.dart';
export 'category_skin_theme.dart';

/// `Category.colorHex`(`#RRGGBB`) ↔ [Color] 변환
String colorToHex(Color color) {
  int channel(double c) => (c * 255).round().clamp(0, 255);
  final r = channel(color.r).toRadixString(16).padLeft(2, '0');
  final g = channel(color.g).toRadixString(16).padLeft(2, '0');
  final b = channel(color.b).toRadixString(16).padLeft(2, '0');
  return '#$r$g$b'.toUpperCase();
}

Color colorFromHex(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
