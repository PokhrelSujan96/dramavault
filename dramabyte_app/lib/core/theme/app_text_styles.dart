import 'package:flutter/material.dart';

abstract final class AppTextStyles {
  static const displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.15,
  );
  static const headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static const titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  static const bodyLarge = TextStyle(fontSize: 16, height: 1.5);
  static const bodyMedium = TextStyle(fontSize: 14, height: 1.45);
  static const bodySmall = TextStyle(fontSize: 12, height: 1.4);
  static const labelLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
}
