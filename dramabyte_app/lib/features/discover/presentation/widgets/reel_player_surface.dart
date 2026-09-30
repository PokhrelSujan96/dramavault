import 'package:dramabyte_app/core/gestures/double_tap_detector.dart';
import 'package:dramabyte_app/features/discover/presentation/widgets/reel_buffering_indicator.dart';
import 'package:dramabyte_app/features/discover/presentation/widgets/reel_like_burst.dart';
import 'package:dramabyte_app/features/discover/presentation/widgets/reel_pause_icon.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ReelPlayerSurface extends StatefulWidget {
  const ReelPlayerSurface({
    super.key,
    required this.controller,
    required this.onTap,
    required this.onDoubleTap,
  });

  final VideoPlayerController controller;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  @override
  State<ReelPlayerSurface> createState() => _ReelPlayerSurfaceState();
}

class _ReelPlayerSurfaceState extends State<ReelPlayerSurface> {
  final _detector = DoubleTapDetector();
  final _burst = ValueNotifier<Offset?>(null);

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  void _onTapUp(TapUpDetails details) {
    widget.onTap();
    if (!_detector.register()) return;
    widget.onTap();
    widget.onDoubleTap();
    _burst.value = details.localPosition;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: _onTapUp,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          ),
          ReelBufferingIndicator(controller: controller),
          ReelPauseIcon(controller: controller),
          ReelLikeBurst(position: _burst),
        ],
      ),
    );
  }
}
