import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/constants/app_colors.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';
import 'package:dramabyte_app/features/discover/presentation/controllers/reel_player_pool.dart';
import 'package:dramabyte_app/features/discover/presentation/widgets/reel_action_rail.dart';
import 'package:dramabyte_app/features/discover/presentation/widgets/reel_bottom_scrim.dart';
import 'package:dramabyte_app/features/discover/presentation/widgets/reel_info.dart';
import 'package:dramabyte_app/features/discover/presentation/widgets/reel_progress_bar.dart';
import 'package:dramabyte_app/features/discover/presentation/widgets/reel_video.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReelView extends StatelessWidget {
  const ReelView({super.key, required this.reel, required this.pool});

  final Reel reel;
  final ReelPlayerPool pool;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ReelVideo(reel: reel, pool: pool),
          const ReelBottomScrim(),
          Positioned(
            left: 16.w,
            right: 84.w,
            bottom: 20.h,
            child: ReelInfo(reel: reel),
          ),
          Positioned(
            right: 12.w,
            bottom: 24.h,
            top: 72.h,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.bottomRight,
              child: ReelActionRail(reel: reel, pool: pool),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ReelProgressBar(slot: pool.slot(reel.episodeId)),
          ),
          Positioned(left: 0, right: 0, top: 0, child: Container()),
        ],
      ),
    );
  }
}
