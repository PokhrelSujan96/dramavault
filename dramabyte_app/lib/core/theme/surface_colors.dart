import 'package:flutter/material.dart';

extension SurfaceColors on BuildContext {
  Color get surfaceTint =>
      Theme.of(this).colorScheme.onSurface.withValues(alpha: 0.06);

  Color get surfaceStrong =>
      Theme.of(this).colorScheme.onSurface.withValues(alpha: 0.1);
}
