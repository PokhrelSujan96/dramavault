import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFFE53935);
  static const primaryDark = Color(0xFFB71C1C);
  static const primaryLight = Color(0xFFFFCDD2);
  static const secondary = Color(0xFFFFB300);
  static const backgroundLight = Color(0xFFF8F7F5);
  static const backgroundDark = Color(0xFF0D0D0F);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF1A1A1E);
  static const textPrimaryLight = Color(0xFF17171A);
  static const textSecondaryLight = Color(0xFF68686F);
  static const textPrimaryDark = Color(0xFFF7F7F8);
  static const textSecondaryDark = Color(0xFFA8A8B0);
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFF57C00);
  static const error = Color(0xFFD32F2F);
  static const dividerLight = Color(0xFFE7E5E4);
  static const dividerDark = Color(0xFF303036);
}

class FlareColors {
  FlareColors._();

  // Primary brand colors - warm terracotta/burnt orange
  static const Color primary = Color(0xFFE8553E);
  static const Color primaryDark = Color(0xFFD14836);
  static const Color primaryLight = Color(0xFFF07A6A);

  static const Color secondaryBackground = Color(0xFFE8F3F0);

  // Background colors - warm off-whites and creams
  static const Color background = Color(0xFFF5F3EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color scaffoldBackground = Color(0xFFF5F3EF);

  // Text colors - warm charcoals instead of harsh blacks
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textTertiary = Color(0xFF9B9B9B);
  static const Color textInverse = Color(0xFFFFFFFF);

  static const Color darkColor = Color(0xFF141414);

  // Accent colors - muted rose and warm tones
  static const Color accentRose = Color(0xFFC4A484);
  static const Color accentGold = Color(0xFFD4A574);
  static const Color accentGreen = Color(0xFF7CB69D);

  // Functional colors
  static const Color error = Color(0xFFE8553E);
  static const Color success = Color(0xFF7CB69D);
  static const Color divider = Color(0xFFEBE8E3);
  static const Color shadow = Color(0x1A000000);

  // Interactive states
  static const Color likeActive = Color(0xFFE8553E);
  static const Color dislikeActive = Color(0xFF6B6B6B);
  static const Color superLike = Color(0xFF5CB8E7);

  // buttons color

  static Color buttonColor = Colors.teal;
}
