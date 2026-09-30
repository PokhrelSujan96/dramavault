import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ReelBufferingIndicator extends StatelessWidget {
  const ReelBufferingIndicator({super.key, required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (_, value, _) => value.isBuffering
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : const SizedBox.shrink(),
    );
  }
}
