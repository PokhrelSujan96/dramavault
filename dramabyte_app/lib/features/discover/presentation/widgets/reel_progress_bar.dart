import 'package:dramabyte_app/features/discover/presentation/controllers/reel_player_pool.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ReelProgressBar extends StatelessWidget {
  const ReelProgressBar({super.key, required this.slot});

  final PlayerSlot slot;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerController?>(
      valueListenable: slot.controller,
      builder: (_, controller, _) => controller == null
          ? const SizedBox(height: 3)
          : VideoProgressIndicator(
              controller,
              allowScrubbing: true,
              padding: EdgeInsets.zero,
              colors: const VideoProgressColors(
                playedColor: Colors.white,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white12,
              ),
            ),
    );
  }
}
