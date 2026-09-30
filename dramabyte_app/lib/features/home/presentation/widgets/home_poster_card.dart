import 'package:dramabyte_app/components/flare_network_image.dart';
import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/constants/app_colors.dart';
import 'package:dramabyte_app/features/home/domain/entities/series_card.dart';
import 'package:dramabyte_app/features/ratings/domain/entities/rating_summary.dart';
import 'package:dramabyte_app/features/ratings/presentation/widgets/rated_builder.dart';
import 'package:dramabyte_app/features/ratings/presentation/widgets/rating_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class HomePosterCard extends StatelessWidget {
  const HomePosterCard({super.key, required this.card, required this.onTap});

  final SeriesCard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageWidth = MediaQuery.sizeOf(context).width * 0.3;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: imageWidth,
                child: AspectRatio(
                  aspectRatio: 2 / 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: FlareNetworkImage(
                      card.thumbnailUrl,
                      cacheWidth: 360,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              FlareText(card.title).base.medium.setMaxLines(1).ellipsis,
              // SizedBox(height: 2.h),
              // FlareText(card.subtitle).sm.setColor(FlareColors.primary),
              SizedBox(height: 4.h),
              Row(
                children: [
                  Icon(MdiIcons.eyeOutline, size: 13.sp, color: Colors.grey),
                  SizedBox(width: 4.w),
                  FlareText(card.viewsLabel).xs.grey,
                ],
              ),
              SizedBox(height: 2.h),
            ],
          ),
        ],
      ),
    );
  }
}
