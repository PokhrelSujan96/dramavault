import 'dart:async';

import 'package:dramabyte_app/features/home/domain/entities/series_card.dart';
import 'package:dramabyte_app/features/home/presentation/widgets/home_hero_card.dart';
import 'package:dramabyte_app/features/home/presentation/widgets/home_page_dots.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeHeroCarousel extends StatefulWidget {
  const HomeHeroCarousel({
    super.key,
    required this.items,
    required this.isActive,
    required this.onOpen,
  });

  final List<SeriesCard> items;
  final bool isActive;
  final ValueChanged<SeriesCard> onOpen;

  @override
  State<HomeHeroCarousel> createState() => _HomeHeroCarouselState();
}

class _HomeHeroCarouselState extends State<HomeHeroCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(HomeHeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive ||
        oldWidget.items.length != widget.items.length) {
      _syncTimer();
    }
  }

  void _syncTimer() {
    _timer?.cancel();
    _timer = widget.isActive && widget.items.length > 1
        ? Timer.periodic(const Duration(seconds: 5), (_) => _next())
        : null;
  }

  void _next() {
    if (!_controller.hasClients) return;
    _controller.animateToPage(
      (_index + 1) % widget.items.length,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 190.h,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (_, index) => HomeHeroCard(
              card: widget.items[index],
              onPlay: () => widget.onOpen(widget.items[index]),
            ),
          ),
        ),
        if (widget.items.length > 1) ...[
          SizedBox(height: 10.h),
          Positioned(
            bottom: 25.h,
            left: 40.w,
            child: HomePageDots(count: widget.items.length, index: _index),
          ),
        ],
      ],
    );
  }
}
