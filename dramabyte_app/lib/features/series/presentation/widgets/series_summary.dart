import 'package:dramabyte_app/components/flare_network_image.dart';
import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/constants/app_colors.dart';
import 'package:dramabyte_app/features/series/domain/entities/series_details.dart';
import 'package:dramabyte_app/features/series/presentation/widgets/series_rating_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SeriesSummary extends StatelessWidget {
  const SeriesSummary({super.key, required this.series});

  final SeriesDetails series;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92.w,
            child: AspectRatio(
              aspectRatio: 2 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: FlareNetworkImage(series.thumbnailUrl, cacheWidth: 300),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FlareText(series.title).xl2.semiBold,
                SizedBox(height: 4.h),
                Text.rich(
                  TextSpan(
                    children: [
                      if (series.freeLabel.isNotEmpty)
                        TextSpan(
                          text: '${series.freeLabel} ',
                          style: const TextStyle(color: FlareColors.primary),
                        ),
                      TextSpan(text: series.totalLabel),
                    ],
                  ),
                  style: TextStyle(fontSize: 13.sp),
                ),
                SizedBox(height: 8.h),
                SeriesRatingRow(series: series),
                if (series.description.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  FlareText(series.description).sm.grey.readMore_
                      .setReadMoreMaxLines(3)
                      .setReadMoreText('See more')
                      .setReadLessText('See less'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
