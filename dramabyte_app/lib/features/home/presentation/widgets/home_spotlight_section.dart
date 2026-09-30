import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/features/home/domain/entities/series_card.dart';
import 'package:dramabyte_app/features/home/presentation/widgets/home_spotlight_backdrop.dart';
import 'package:dramabyte_app/features/home/presentation/widgets/home_spotlight_details.dart';
import 'package:dramabyte_app/features/home/presentation/widgets/home_spotlight_poster.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeSpotlightSection extends StatefulWidget {
  const HomeSpotlightSection({
    super.key,
    required this.items,
    required this.onOpen,
  });

  final List<SeriesCard> items;
  final ValueChanged<SeriesCard> onOpen;

  @override
  State<HomeSpotlightSection> createState() => _HomeSpotlightSectionState();
}

class _HomeSpotlightSectionState extends State<HomeSpotlightSection> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final index = _selected.clamp(0, widget.items.length - 1);
    final card = widget.items[index];
    return Padding(
      padding: EdgeInsets.only(top: 12.h),
      child: Stack(
        children: [
          Positioned.fill(
            child: HomeSpotlightBackdrop(imageUrl: card.thumbnailUrl),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FlareText('Featured in DramaByte').xl2.bold.white,
                      SizedBox(height: 4.h),
                      FlareText(
                        'Best featured for you today',
                      ).sm.setColor(Colors.white70),
                      SizedBox(height: 20.h),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: KeyedSubtree(
                          key: ValueKey(card.seriesId),
                          child: HomeSpotlightDetails(
                            card: card,
                            rank: index + 1,
                            onPlay: () => widget.onOpen(card),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    spacing: 12,
                    children: [
                      for (var i = 0; i < widget.items.length; i++)
                        HomeSpotlightPoster(
                          card: widget.items[i],
                          selected: i == index,
                          onTap: () => i == index
                              ? widget.onOpen(widget.items[i])
                              : setState(() => _selected = i),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
