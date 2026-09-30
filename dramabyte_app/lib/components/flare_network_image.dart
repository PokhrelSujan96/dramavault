import 'package:cached_network_image/cached_network_image.dart';
import 'package:dramabyte_app/core/theme/surface_colors.dart';
import 'package:flutter/material.dart';

class FlareNetworkImage extends StatelessWidget {
  const FlareNetworkImage(
    this.url, {
    super.key,
    this.cacheWidth = 480,
    this.fit = BoxFit.cover,
    this.background,
    this.placeholderAspectRatio,
    this.expandWidth = false,
  });

  final String url;
  final int cacheWidth;
  final BoxFit fit;
  final Color? background;
  final double? placeholderAspectRatio;
  final bool expandWidth;

  String get _stableKey {
    final uri = Uri.tryParse(url);
    return uri == null || !uri.hasAuthority
        ? url
        : '${uri.scheme}://${uri.authority}${uri.path}';
  }

  @override
  Widget build(BuildContext context) {
    final box = ColoredBox(color: background ?? context.surfaceTint);
    final placeholder = placeholderAspectRatio == null
        ? box
        : AspectRatio(aspectRatio: placeholderAspectRatio!, child: box);
    if (url.isEmpty) return placeholder;
    return CachedNetworkImage(
      imageUrl: url,
      cacheKey: _stableKey,
      fit: fit,
      width: expandWidth ? double.infinity : null,
      alignment: Alignment.topCenter,
      memCacheWidth: cacheWidth,
      fadeInDuration: const Duration(milliseconds: 250),
      fadeOutDuration: Duration.zero,
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => placeholder,
    );
  }
}
