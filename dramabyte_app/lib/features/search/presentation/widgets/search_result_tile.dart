import 'package:dramabyte_app/components/flare_network_image.dart';
import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/constants/app_colors.dart';
import 'package:dramabyte_app/features/search/domain/entities/search_result.dart';
import 'package:dramabyte_app/features/search/presentation/widgets/search_highlighted_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SearchResultTile extends StatelessWidget {
  const SearchResultTile({
    super.key,
    required this.result,
    required this.query,
    required this.onTap,
  });

  final SearchResult result;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Row(
          children: [
            SizedBox(
              width: 56.w,
              child: AspectRatio(
                aspectRatio: 2 / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: FlareNetworkImage(
                    result.thumbnailUrl,
                    cacheWidth: 200,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SearchHighlightedText(text: result.title, query: query),
                  SizedBox(height: 4.h),
                  FlareText(result.subtitle).sm.setColor(FlareColors.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
