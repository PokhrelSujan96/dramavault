import 'package:dramabyte_app/components/flare_svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

class ReelPauseIcon extends StatelessWidget {
  const ReelPauseIcon({super.key, required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (_, value, _) => IgnorePointer(
        child: AnimatedOpacity(
          opacity: value.isPlaying || value.isBuffering ? 0 : 1,
          duration: const Duration(milliseconds: 150),
          child: Center(
            child: FlareSvgIcon('play', size: 64.sp, color: Colors.white70),
          ),
        ),
      ),
    );
  }
}
