import 'package:dramabyte_app/components/flare_network_image.dart';
import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/router/app_routes.dart';
import 'package:dramabyte_app/features/history/domain/entities/history_item.dart';
import 'package:dramabyte_app/features/history/presentation/widgets/history_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class HistoryTile extends StatelessWidget {
  const HistoryTile({super.key, required this.item});

  final HistoryItem item;

  @override
  Widget build(BuildContext context) {
    final tile = SizedBox(
      width: MediaQuery.sizeOf(context).width * 0.3,
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              FlareNetworkImage(item.thumbnailUrl, cacheWidth: 360),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
              ),
              Positioned(
                left: 8.w,
                right: 8.w,
                bottom: 10.h,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FlareText(item.title).xs.bold.white.ellipsis,
                    FlareText(item.episodeLabel).xs.setColor(Colors.white70),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: HistoryProgressBar(value: item.progress),
              ),
            ],
          ),
        ),
      ),
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.pushNamed(
        AppRoutes.seriesName,
        pathParameters: {'seriesId': item.seriesId},
      ),
      child: tile,
    );
  }
}
