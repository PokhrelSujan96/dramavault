import 'package:dramabyte_app/components/flare_svg_icon.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';
import 'package:dramabyte_app/features/discover/presentation/controllers/reel_player_pool.dart';
import 'package:dramabyte_app/features/discover/presentation/widgets/reel_action_button.dart';
import 'package:dramabyte_app/features/discover/presentation/widgets/reel_bookmark_button.dart';
import 'package:dramabyte_app/features/discover/presentation/widgets/reel_comment_button.dart';
import 'package:dramabyte_app/features/discover/presentation/widgets/reel_like_button.dart';
import 'package:dramabyte_app/features/discover/presentation/widgets/reel_rating_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class ReelActionRail extends StatelessWidget {
  const ReelActionRail({super.key, required this.reel, required this.pool});

  final Reel reel;
  final ReelPlayerPool pool;

  Widget _svg(String name, double size) =>
      FlareSvgIcon(name, size: size, color: Colors.white);

  void _soon(BuildContext context) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Coming soon')));

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ReelActionButton(
          icon: _svg('episodes', 28.sp),
          label: reel.episodeLabel,
        ),
        if (reel.videoVariants.containsKey('hi'))
          ValueListenableBuilder<String>(
            valueListenable: pool.slot(reel.episodeId).language,
            builder: (_, language, _) => ReelActionButton(
              icon: Icon(Icons.translate, size: 27.sp, color: Colors.white),
              label: language == 'hi' ? 'हिन्दी' : 'EN',
              onTap: () => pool.toggleLanguage(reel),
            ),
          ),
        ReelLikeButton(reel: reel),
        ValueListenableBuilder<double>(
          valueListenable: pool.speed,
          builder: (_, speed, _) => ReelActionButton(
            icon: Icon(MdiIcons.playSpeed, size: 28.sp, color: Colors.white),
            label: 'Speed ${speed}x',
            onTap: pool.cycleSpeed,
          ),
        ),

        ReelCommentButton(reel: reel),
        ReelRatingButton(reel: reel),
        ReelBookmarkButton(reel: reel),
        ReelActionButton(
          icon: _svg('share', 25.sp),
          label: 'Share',
          onTap: () => _soon(context),
        ),
      ],
    );
  }
}
