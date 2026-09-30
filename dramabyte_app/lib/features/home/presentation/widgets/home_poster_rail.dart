import 'package:dramabyte_app/features/home/domain/entities/series_card.dart';
import 'package:dramabyte_app/features/home/presentation/widgets/home_poster_card.dart';
import 'package:dramabyte_app/features/home/presentation/widgets/home_section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomePosterRail extends StatelessWidget {
  const HomePosterRail({
    super.key,
    required this.title,
    required this.items,
    required this.onOpen,
  });

  final String title;
  final List<SeriesCard> items;
  final ValueChanged<SeriesCard> onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSectionHeader(title: title),
          SizedBox(height: 12.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              spacing: 12,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final card in items)
                  HomePosterCard(card: card, onTap: () => onOpen(card)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
