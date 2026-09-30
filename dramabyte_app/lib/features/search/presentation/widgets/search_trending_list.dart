import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/theme/surface_colors.dart';
import 'package:dramabyte_app/features/search/domain/entities/search_suggestion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SearchTrendingList extends StatelessWidget {
  const SearchTrendingList({
    super.key,
    required this.suggestions,
    required this.onOpen,
  });

  final List<SearchSuggestion> suggestions;
  final ValueChanged<SearchSuggestion> onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FlareText('Trending now').lg.semiBold,
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (final item in suggestions)
                GestureDetector(
                  onTap: () => onOpen(item),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: context.surfaceTint,
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                    child: FlareText(item.title).sm.white,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
