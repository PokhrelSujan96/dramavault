import 'package:dramabyte_app/core/di/injection.dart';
import 'package:dramabyte_app/core/sync/synced_cubit.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';
import 'package:dramabyte_app/features/series/presentation/cubit/series_watch_cubit.dart';
import 'package:dramabyte_app/features/series/presentation/widgets/series_close_button.dart';
import 'package:dramabyte_app/features/series/presentation/widgets/series_message_view.dart';
import 'package:dramabyte_app/features/series/presentation/widgets/series_watch_feed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SeriesWatchPage extends StatelessWidget {
  const SeriesWatchPage({
    super.key,
    required this.seriesId,
    required this.startEpisode,
  });

  final String seriesId;
  final int startEpisode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SeriesWatchCubit>(param1: seriesId)..load(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            BlocBuilder<SeriesWatchCubit, ResourceState<List<Reel>>>(
              builder: (context, state) => switch (state) {
                ResourceLoaded<List<Reel>>(:final value) when value.isEmpty =>
                  const SeriesMessageView(
                    message: 'No episodes available to watch yet.',
                  ),
                ResourceLoaded<List<Reel>>(:final value) => SeriesWatchFeed(
                  reels: value,
                  startEpisode: startEpisode,
                ),
                ResourceError<List<Reel>>(:final message) => SeriesMessageView(
                  message: message,
                  actionLabel: 'Try again',
                  onAction: context.read<SeriesWatchCubit>().retry,
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
            const Align(
              alignment: Alignment.topLeft,
              child: SeriesCloseButton(),
            ),
          ],
        ),
      ),
    );
  }
}
