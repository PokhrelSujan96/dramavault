import 'package:dramabyte_app/core/constants/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReelLikeBurst extends StatefulWidget {
  const ReelLikeBurst({super.key, required this.position});

  final ValueListenable<Offset?> position;

  @override
  State<ReelLikeBurst> createState() => _ReelLikeBurstState();
}

class _ReelLikeBurstState extends State<ReelLikeBurst>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    widget.position.addListener(_play);
  }

  void _play() => _controller.forward(from: 0);

  @override
  void dispose() {
    widget.position.removeListener(_play);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final at = widget.position.value;
            if (at == null || !_controller.isAnimating) {
              return const SizedBox.shrink();
            }
            final t = _controller.value;
            final scale =
                0.6 + Curves.elasticOut.transform((t * 2).clamp(0, 1)) * 0.7;
            final size = 96.sp;
            return Stack(
              children: [
                Positioned(
                  left: at.dx - size / 2,
                  top: at.dy - size / 2,
                  child: Opacity(
                    opacity:
                        (1 -
                        Curves.easeIn.transform(((t - 0.4) / 0.6).clamp(0, 1))),
                    child: Transform.scale(
                      scale: scale,
                      child: Icon(
                        Icons.favorite,
                        size: size,
                        color: FlareColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
