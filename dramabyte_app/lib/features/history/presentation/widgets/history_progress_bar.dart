import 'package:dramabyte_app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class HistoryProgressBar extends StatelessWidget {
  const HistoryProgressBar({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: value,
      minHeight: 3,
      color: FlareColors.primary,
      backgroundColor: Colors.white24,
    );
  }
}
