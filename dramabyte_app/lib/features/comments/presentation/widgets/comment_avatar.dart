import 'package:dramabyte_app/components/flare_network_image.dart';
import 'package:dramabyte_app/components/flare_text.dart';
import 'package:flutter/material.dart';

class CommentAvatar extends StatelessWidget {
  const CommentAvatar({
    super.key,
    required this.name,
    this.url,
    this.size = 36,
  });

  final String name;
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    final fallback = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(child: FlareText(initial).size(size * 0.42).semiBold),
    );
    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: url == null || url!.isEmpty
            ? fallback
            : FlareNetworkImage(
                url!,
                cacheWidth: 120,
                background: Colors.black12,
              ),
      ),
    );
  }
}
