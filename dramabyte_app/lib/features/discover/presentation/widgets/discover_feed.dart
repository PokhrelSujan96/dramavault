import 'package:dramabyte_app/core/di/injection.dart';
import 'package:dramabyte_app/features/discover/presentation/controllers/reel_player_pool.dart';
import 'package:dramabyte_app/features/discover/presentation/cubit/discover_cubit.dart';
import 'package:dramabyte_app/features/discover/presentation/widgets/reel_offline_chip.dart';
import 'package:dramabyte_app/features/discover/presentation/widgets/reel_view.dart';
import 'package:dramabyte_app/features/engagement/presentation/cubit/engagement_cubit.dart';
import 'package:dramabyte_app/features/engagement/presentation/widgets/engagement_notice_listener.dart';
import 'package:dramabyte_app/features/ratings/presentation/cubit/ratings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DiscoverFeed extends StatefulWidget {
  const DiscoverFeed({super.key, required this.state, required this.isActive});

  final DiscoverState state;
  final bool isActive;

  @override
  State<DiscoverFeed> createState() => _DiscoverFeedState();
}

class _DiscoverFeedState extends State<DiscoverFeed>
    with WidgetsBindingObserver {
  final _pool = getIt<ReelPlayerPool>();
  final _controller = PageController();
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pool.updateReels(widget.state.reels);
    context.read<EngagementCubit>().seed(widget.state.reels);
    context.read<RatingsCubit>().seedReels(widget.state.reels);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus());
  }

  @override
  void didUpdateWidget(DiscoverFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = oldWidget.state.reels;
    final after = widget.state.reels;
    final revisionsChanged = _pool.updateReels(after);
    if (before != after) {
      context.read<EngagementCubit>().seed(after);
      context.read<RatingsCubit>().seedReels(after);
    }
    if (before.firstOrNull?.episodeId != after.firstOrNull?.episodeId) {
      _index = 0;
      if (_controller.hasClients) _controller.jumpToPage(0);
    }
    if (before.length != after.length || revisionsChanged) _focus();
    if (oldWidget.isActive != widget.isActive) {
      _pool.setActive(widget.isActive);
      if (widget.isActive) context.read<DiscoverCubit>().refresh();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final active = state == AppLifecycleState.resumed && widget.isActive;
    _pool.setActive(active);
    if (active) context.read<DiscoverCubit>().refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _pool.dispose();
    super.dispose();
  }

  void _focus() => _pool.focus(widget.state.reels, _index);

  void _onPageChanged(int index) {
    _index = index;
    _focus();
    if (index >= widget.state.reels.length - 3) {
      context.read<DiscoverCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reels = widget.state.reels;
    return EngagementNoticeListener(
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            scrollDirection: Axis.vertical,
            itemCount: reels.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (_, index) => ReelView(
              key: ValueKey(reels[index].episodeId),
              reel: reels[index],
              pool: _pool,
            ),
          ),
          if (widget.state.offline)
            Align(
              alignment: Alignment.topCenter,
              child: ReelOfflineChip(
                onRetry: context.read<DiscoverCubit>().load,
              ),
            ),
        ],
      ),
    );
  }
}
