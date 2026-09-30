import 'package:dramabyte_app/components/flare_network_image.dart';
import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/router/app_routes.dart';
import 'package:dramabyte_app/features/history/domain/entities/history_item.dart';
import 'package:dramabyte_app/features/history/presentation/widgets/history_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class HistoryRow extends StatelessWidget {
  const HistoryRow({super.key, required this.item, required this.onRemove});

  final HistoryItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final row = Dismissible(
      key: ValueKey(item.episodeId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        color: Colors.red,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Row(
          children: [
            SizedBox(
              width: 72.w,
              child: AspectRatio(
                aspectRatio: 2 / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: FlareNetworkImage(item.thumbnailUrl, cacheWidth: 240),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FlareText(item.title).lg.semiBold.ellipsis,
                  SizedBox(height: 2.h),
                  FlareText(
                    '${item.episodeLabel} · ${item.isCompleted ? 'Watched' : '${(item.progress * 100).round()}%'}',
                  ).sm.grey,
                  SizedBox(height: 8.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2.r),
                    child: HistoryProgressBar(value: item.progress),
                  ),
                  SizedBox(height: 6.h),
                  FlareText(item.watchedLabel).xs.grey,
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.pushNamed(
        AppRoutes.seriesName,
        pathParameters: {'seriesId': item.seriesId},
      ),
      child: row,
    );
  }
}
