import 'package:dramabyte_app/core/di/injection.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';
import 'package:dramabyte_app/features/discover/presentation/controllers/reel_player_pool.dart';
import 'package:dramabyte_app/features/discover/presentation/widgets/reel_view.dart';
import 'package:dramabyte_app/features/engagement/presentation/cubit/engagement_cubit.dart';
import 'package:dramabyte_app/features/engagement/presentation/widgets/engagement_notice_listener.dart';
import 'package:dramabyte_app/features/ratings/presentation/cubit/ratings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SeriesWatchFeed extends StatefulWidget {
  const SeriesWatchFeed({
    super.key,
    required this.reels,
    required this.startEpisode,
  });

  final List<Reel> reels;
  final int startEpisode;

  @override
  State<SeriesWatchFeed> createState() => _SeriesWatchFeedState();
}

class _SeriesWatchFeedState extends State<SeriesWatchFeed>
    with WidgetsBindingObserver {
  final _pool = getIt<ReelPlayerPool>();
  late final int _start = widget.reels
      .indexWhere((reel) => reel.episodeNumber == widget.startEpisode)
      .clamp(0, widget.reels.length - 1);
  late final _controller = PageController(initialPage: _start);
  late int _index = _start;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pool.updateReels(widget.reels);
    context.read<EngagementCubit>().seed(widget.reels);
    context.read<RatingsCubit>().seedReels(widget.reels);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus());
  }

  @override
  void didUpdateWidget(SeriesWatchFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_pool.updateReels(widget.reels)) _focus();
    context.read<EngagementCubit>().seed(widget.reels);
    context.read<RatingsCubit>().seedReels(widget.reels);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _pool.setActive(state == AppLifecycleState.resumed);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _pool.dispose();
    super.dispose();
  }

  void _focus() => _pool.focus(widget.reels, _index);

  @override
  Widget build(BuildContext context) {
    return EngagementNoticeListener(
      child: PageView.builder(
        controller: _controller,
        scrollDirection: Axis.vertical,
        itemCount: widget.reels.length,
        onPageChanged: (index) {
          _index = index;
          _focus();
        },
        itemBuilder: (_, index) => ReelView(
          key: ValueKey(widget.reels[index].episodeId),
          reel: widget.reels[index],
          pool: _pool,
        ),
      ),
    );
  }
}
