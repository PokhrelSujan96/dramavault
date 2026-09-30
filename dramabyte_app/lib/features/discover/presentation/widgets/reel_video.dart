import 'package:dramabyte_app/components/flare_network_image.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';
import 'package:dramabyte_app/features/discover/presentation/controllers/reel_player_pool.dart';
import 'package:dramabyte_app/features/discover/presentation/widgets/reel_player_surface.dart';
import 'package:dramabyte_app/features/discover/presentation/widgets/reel_status_view.dart';
import 'package:dramabyte_app/features/engagement/presentation/cubit/engagement_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

class ReelVideo extends StatelessWidget {
  const ReelVideo({super.key, required this.reel, required this.pool});

  final Reel reel;
  final ReelPlayerPool pool;

  @override
  Widget build(BuildContext context) {
    final slot = pool.slot(reel.episodeId);
    return Stack(
      fit: StackFit.expand,
      children: [
        FlareNetworkImage(
          reel.thumbnailUrl,
          cacheWidth: 720,
          background: Colors.black,
        ),
        ValueListenableBuilder<VideoPlayerController?>(
          valueListenable: slot.controller,
          builder: (_, controller, _) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: controller != null && controller.value.isInitialized
                ? ReelPlayerSurface(
                    key: ValueKey(controller),
                    controller: controller,
                    onTap: () => pool.toggle(reel.episodeId),
                    onDoubleTap: () =>
                        context.read<EngagementCubit>().like(reel.episodeId),
                  )
                : const SizedBox.shrink(),
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: slot.failed,
          builder: (_, failed, _) => failed
              ? ColoredBox(
                  color: Colors.black54,
                  child: ReelStatusView(
                    icon: Icons.wifi_off_rounded,
                    message: "This episode can't be played right now.",
                    actionLabel: 'Try again',
                    onAction: () => pool.retry(reel),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
