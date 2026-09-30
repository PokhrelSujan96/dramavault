import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FlareSvgIcon extends StatelessWidget {
  const FlareSvgIcon(this.name, {super.key, this.size = 24, this.color});

  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? IconTheme.of(context).color;
    return SvgPicture.asset(
      'assets/svg/$name.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: tint == null
          ? null
          : ColorFilter.mode(tint, BlendMode.srcIn),
    );
  }
}
